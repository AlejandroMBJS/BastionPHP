<?php

namespace App\Middleware;

use App\Core\Request;
use App\Core\Response;

class AdminOnly
{
    public static function handle(Request $req, callable $next): mixed
    {
        $user = auth();

        if (!$user || $user['role'] !== 'admin') {
            if ($req->isJson()) {
                Response::json(['error' => 'Admin access required'], 403);
            } else {
                $_SESSION['error'] = 'Admin access required';
                redirect('/login');
            }
        }

        return $next($req);
    }
}
