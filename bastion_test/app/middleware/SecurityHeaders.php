<?php

namespace App\Middleware;

use App\Core\Request;

class SecurityHeaders
{
    public static function handle(Request $req, callable $next): mixed
    {
        // Generate unique CSP nonce for this request
        $nonce = base64_encode(random_bytes(16));
        $req->meta['csp_nonce'] = $nonce;

        // Security headers
        header("X-Frame-Options: SAMEORIGIN");
        header("X-Content-Type-Options: nosniff");
        header("X-XSS-Protection: 1; mode=block");
        header("Referrer-Policy: strict-origin-when-cross-origin");

        // CSP with nonce
        $csp = "default-src 'self'; " .
               "script-src 'self' 'nonce-{$nonce}' https://unpkg.com; " .
               "style-src 'self'; " .
               "img-src 'self' data: https:; " .
               "font-src 'self' data:;";
        header("Content-Security-Policy: $csp");

        // HSTS (uncomment for production with HTTPS)
        if (env('SECURE_COOKIES', false)) {
            header("Strict-Transport-Security: max-age=31536000; includeSubDomains");
        }

        return $next($req);
    }
}
