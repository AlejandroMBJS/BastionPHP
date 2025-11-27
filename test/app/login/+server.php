<?php

use App\Core\Auth;
use App\Core\Response;
use App\Models\User;

return [
    'get' => function($req) {
        // If already logged in, redirect to profile
        if (auth()) {
            redirect('/profile');
        }

        // Render login page by including page.php
        $title = 'Login';
        $content = (function() {
            ob_start();
            require __DIR__ . '/page.php';
            return ob_get_clean();
        })();

        // Wrap with layout
        $layoutFile = __DIR__ . '/../views/layouts/main.php';
        if (file_exists($layoutFile)) {
            require $layoutFile;
        } else {
            echo $content;
        }
    },

    'post' => function($req) {
        $email = $req->input('email');
        $password = $req->input('password');

        $user = User::findByEmail($email);

        if (!$user || !password_verify($password, $user['password'])) {
            logger()->warning('Failed login attempt', ['email' => $email]);

            $_SESSION['error'] = 'Invalid credentials';
            redirect('/login');
        }

        logger()->info('User logged in', ['user_id' => $user['id']]);

        // SECURITY: Regenerate session ID to prevent session fixation
        session_regenerate_id(true);

        $tokens = Auth::issueTokens($user['id']);

        $cookieOptions = [
            'expires' => time() + (int)env('JWT_REFRESH_EXP', 604800),
            'path' => '/',
            'secure' => env('SECURE_COOKIES', false),
            'httponly' => true,
            'samesite' => 'Lax'
        ];

        setcookie('refresh', $tokens['refresh'], $cookieOptions);
        setcookie('access', $tokens['access'], [
            'expires' => $tokens['expires'],
            'path' => '/',
            'secure' => env('SECURE_COOKIES', false),
            'httponly' => false, // Accessible to JS for API calls
            'samesite' => 'Lax'
        ]);

        redirect('/profile');
    }
];
