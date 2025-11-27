<?php

namespace App\Core;

class CSRF
{
    /**
     * Generate CSRF token
     */
    public static function token(): string
    {
        if (!isset($_SESSION['_csrf'])) {
            $_SESSION['_csrf'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['_csrf'];
    }

    /**
     * Verify CSRF token (middleware)
     */
    public static function verify(Request $req, callable $next): mixed
    {
        // Only verify for state-changing methods
        if (in_array($req->method, ['POST', 'PUT', 'DELETE', 'PATCH'])) {

            // Skip CSRF for API routes (use token auth instead)
            if (str_starts_with($req->path, 'api/')) {
                return $next($req);
            }

            // Skip CSRF for JSON API requests (rely on CORS + SameSite cookies)
            if ($req->isJson()) {
                return $next($req);
            }

            $sentToken = $req->input('_csrf') ?? $req->headers['X-CSRF-Token'] ?? null;
            $sessionToken = $_SESSION['_csrf'] ?? '';

            if (!$sentToken || !hash_equals($sessionToken, $sentToken)) {
                logger()->warning('CSRF token mismatch', [
                    'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                    'path' => $req->path
                ]);
                abort(403, 'CSRF token mismatch');
            }
        }

        return $next($req);
    }
}
