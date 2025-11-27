<?php
/**
 * Bastion PHP Framework - Front Controller
 * All requests are routed through this file
 */

// Load autoloader and bootstrap
require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../app/bootstrap.php';

use App\Core\App;
use App\Core\Request; // Added

// Create application instance
$app = new App(__DIR__ . '/..');

$request = new Request(); // Added

// Register global middleware
$app->use([\App\Middleware\SecurityHeaders::class, 'handle']);

if (env('CSRF_ENABLED', true)) {
    $app->use([\App\Core\CSRF::class, 'verify']);
}

$app->use([\App\Core\Auth::class, 'loadUser']);

// Conditionally add AdminOnly middleware for admin routes
if ($request->path === 'admin' || str_starts_with($request->path, 'admin/')) {
    $app->use([\App\Middleware\AdminOnly::class, 'handle']);
}

// Run the application
$app->run();
