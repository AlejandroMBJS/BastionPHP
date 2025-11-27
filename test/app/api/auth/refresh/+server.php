<?php

use App\Core\Auth;
use App\Core\Response;

return [
    'post' => function($req) {
        $refreshToken = $req->cookies['refresh'] ?? null;

        if (!$refreshToken) {
            Response::json(['error' => 'No refresh token'], 401);
        }

        $userId = Auth::validateRefreshToken($refreshToken);

        if (!$userId) {
            // Clear cookie on invalid token
            setcookie('refresh', '', time() - 3600, '/');
            Response::json(['error' => 'Invalid or expired refresh token'], 401);
        }

        // Issue new tokens
        $tokens = Auth::issueTokens($userId);

        // Set new refresh cookie
        setcookie('refresh', $tokens['refresh'], [
            'expires' => time() + (int)env('JWT_REFRESH_EXP', 604800),
            'path' => '/',
            'secure' => env('SECURE_COOKIES', false),
            'httponly' => true,
            'samesite' => 'Lax'
        ]);

        Response::json([
            'access' => $tokens['access'],
            'expires' => $tokens['expires']
        ]);
    }
];
