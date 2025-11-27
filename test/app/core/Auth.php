<?php

namespace App\Core;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class Auth
{
    /**
     * Issue access and refresh tokens
     */
    public static function issueTokens(int|string $userId): array
    {
        $now = time();
        $secret = env('JWT_SECRET');
        $accessExp = (int)env('JWT_ACCESS_EXP', 900);
        $refreshExp = (int)env('JWT_REFRESH_EXP', 604800);

        if (!$secret) {
            throw new \RuntimeException('JWT_SECRET not configured');
        }

        $accessPayload = [
            'sub' => $userId,
            'iat' => $now,
            'exp' => $now + $accessExp,
            'type' => 'access'
        ];

        $accessToken = JWT::encode($accessPayload, $secret, 'HS256');

        // Create secure refresh token
        $selector = bin2hex(random_bytes(16));
        $validator = bin2hex(random_bytes(32));
        $validatorHash = hash('sha256', $validator);
        $expiresAt = $now + $refreshExp;

        DB::table('refresh_tokens')->insert([
            'user_id' => $userId,
            'selector' => $selector,
            'validator_hash' => $validatorHash,
            'expires_at' => $expiresAt
        ]);

        $refreshToken = "$selector:$validator";

        return [
            'access' => $accessToken,
            'refresh' => $refreshToken,
            'expires' => $accessPayload['exp']
        ];
    }

    /**
     * Validate and decode token
     */
    public static function validate(string $token): ?object
    {
        try {
            $secret = env('JWT_SECRET');
            if (!$secret) {
                return null;
            }

            $decoded = JWT::decode($token, new Key($secret, 'HS256'));
            return $decoded;

        } catch (\Throwable $e) {
            logger()->debug("JWT validation failed: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Validate refresh token and return user ID if valid
     */
    public static function validateRefreshToken(string $token): ?int
    {
        $parts = explode(':', $token);
        if (count($parts) !== 2) {
            return null;
        }

        $selector = $parts[0];
        $validator = $parts[1];

        $tokenData = DB::table('refresh_tokens')->where('selector', $selector)->first();

        if (!$tokenData) {
            return null;
        }

        // Invalidate token after use
        DB::pdo()->prepare('DELETE FROM refresh_tokens WHERE selector = ?')->execute([$selector]);

        if (time() > $tokenData['expires_at']) {
            return null;
        }

        if (!hash_equals($tokenData['validator_hash'], hash('sha256', $validator))) {
            return null;
        }

        return $tokenData['user_id'];
    }

    /**
     * Middleware to load authenticated user
     */
    public static function loadUser(Request $req, callable $next): mixed
    {
        $token = null;

        // Check Authorization header first
        $authHeader = $req->headers['Authorization'] ?? '';
        if (preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
            $token = $matches[1];
        }

        // Fallback to cookie
        if (!$token && isset($req->cookies['access'])) {
            $token = $req->cookies['access'];
        }

        if ($token) {
            $decoded = self::validate($token);

            if ($decoded && isset($decoded->sub) && ($decoded->type ?? '') === 'access') {
                // Load user from database
                $user = \App\Models\User::find($decoded->sub);
                $GLOBALS['auth_user'] = $user;
                $req->meta['user'] = $user;
            }
        }

        return $next($req);
    }

    /**
     * Require authentication middleware
     */
    public static function requireAuth(Request $req, callable $next): mixed
    {
        if (!isset($GLOBALS['auth_user'])) {
            if ($req->isJson()) {
                Response::json(['error' => 'Unauthorized'], 401);
            } else {
                redirect('/login');
            }
        }

        return $next($req);
    }
}
