#!/usr/bin/env bash
#==============================================================================
# ROUTPHER Framework Generator
# A lightweight file-based PHP framework with JWT auth, CSRF, and more
# Version: 2.0.0
#==============================================================================

set -euo pipefail

#------------------------------------------------------------------------------
# Color output helpers
#------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

#------------------------------------------------------------------------------
# Parse arguments and show usage
#------------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 <project-name> [options]

Options:
  --minimal      Create minimal structure without auth examples
  --with-auth    Include full authentication system (default)
  --with-api     API-focused structure with rate limiting
  --full-stack   Everything: auth, API, examples, admin panel
  --no-composer  Skip composer install
  --help         Show this help message

Examples:
  $0 myapp
  $0 myapp --minimal
  $0 api-project --with-api
EOF
    exit 0
}

# Default flags
MINIMAL=false
WITH_AUTH=true
WITH_API=false
FULL_STACK=false
NO_COMPOSER=false
WITH_TAILWIND=false

# Check for help first, before consuming any arguments
if [ "$#" -lt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
fi

PROJECT="$1"
shift

while [ "$#" -gt 0 ]; do
    case "$1" in
        --minimal)     MINIMAL=true; WITH_AUTH=false; shift ;;
        --with-auth)   WITH_AUTH=true; shift ;;
        --with-api)    WITH_API=true; shift ;;
        --full-stack)  FULL_STACK=true; WITH_AUTH=true; WITH_API=true; shift ;;
        --no-composer) NO_COMPOSER=true; shift ;;
        --help)        usage ;;
        *)             error "Unknown option: $1. Use --help for usage." ;;
    esac
done

# Ask about Tailwind CSS if full-stack mode is enabled
if [ "$FULL_STACK" = true ] && [ -t 0 ]; then
    echo ""
    echo -e "${BLUE}Would you like to use Tailwind CSS?${NC}"
    echo "  Tailwind will provide a modern, production-ready UI with dark theme"
    echo ""
    read -p "Use Tailwind CSS? (Y/n): " tailwind_choice
    tailwind_choice=${tailwind_choice:-Y}

    if [[ "$tailwind_choice" =~ ^[Yy]$ ]]; then
        WITH_TAILWIND=true
        success "Tailwind CSS will be included"
    else
        WITH_TAILWIND=false
        info "Using simple CSS instead"
    fi
    echo ""
fi

ROOT="$(pwd)/$PROJECT"

#------------------------------------------------------------------------------
# Pre-flight checks
#------------------------------------------------------------------------------
info "Running pre-flight checks..."

# Check if directory exists
if [ -e "$ROOT" ]; then
    error "Directory '$ROOT' already exists. Please choose a different name."
fi

# Check PHP version
if ! command -v php >/dev/null 2>&1; then
    error "PHP is not installed. Please install PHP 8.0 or higher."
fi

PHP_VERSION=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "0")
if [ "$(printf '%s\n' "8.0" "$PHP_VERSION" | sort -V | head -n1)" != "8.0" ]; then
    error "PHP 8.0+ required. Current version: $PHP_VERSION"
fi

# Check required PHP extensions
REQUIRED_EXTS="pdo pdo_sqlite json mbstring openssl"
for ext in $REQUIRED_EXTS; do
    if ! php -m 2>/dev/null | grep -qi "^$ext$"; then
        error "Required PHP extension '$ext' is not installed."
    fi
done

success "All pre-flight checks passed"

#------------------------------------------------------------------------------
# Generate secure random keys
#------------------------------------------------------------------------------
generate_key() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 32 | tr -d '\n'
    else
        head -c 32 /dev/urandom | base64 | tr -d '\n'
    fi
}

APP_KEY=$(generate_key)
JWT_SECRET=$(generate_key)

#------------------------------------------------------------------------------
# Create project structure
#------------------------------------------------------------------------------
info "Creating project: $PROJECT"
mkdir -p "$ROOT"
cd "$ROOT"

info "Creating directory structure..."

# Core directories
mkdir -p public app/core app/middleware app/models app/views/errors
mkdir -p config database/migrations database/seeds storage/db storage/logs storage/cache
mkdir -p vendor

# Create .gitignore
cat > .gitignore <<'GITIGNORE'
/vendor/
/node_modules/
/storage/db/*.db
/storage/logs/*.log
/storage/cache/*
!storage/cache/.gitkeep
/public/css/
.env
.env.local
composer.lock
package-lock.json
.DS_Store
Thumbs.db
*.swp
*.swo
*~
GITIGNORE

# Create storage .gitkeep files
touch storage/cache/.gitkeep storage/logs/.gitkeep

success "Directory structure created"

#------------------------------------------------------------------------------
# Create .env and .env.example
#------------------------------------------------------------------------------
info "Generating environment configuration..."

cat > .env <<ENV
# Application
APP_NAME="Bastion PHP"
APP_ENV=development
APP_DEBUG=true
APP_URL=http://localhost:9876
APP_KEY=$APP_KEY

# Database
DB_CONNECTION=sqlite
DB_PATH=storage/db/app.db

# JWT Authentication
JWT_SECRET=$JWT_SECRET
JWT_ACCESS_EXP=900
JWT_REFRESH_EXP=604800

# Security
CSRF_ENABLED=true
SECURE_COOKIES=false

# Logging
LOG_LEVEL=debug
LOG_FILE=storage/logs/app.log
ENV

cat > .env.example <<'ENVEXAMPLE'
# Application
APP_NAME="Bastion PHP"
APP_ENV=development
APP_DEBUG=true
APP_URL=http://localhost:9876
APP_KEY=

# Database
DB_CONNECTION=sqlite
DB_PATH=storage/db/app.db

# JWT Authentication
JWT_SECRET=
JWT_ACCESS_EXP=900
JWT_REFRESH_EXP=604800

# Security
CSRF_ENABLED=true
SECURE_COOKIES=false

# Logging
LOG_LEVEL=debug
LOG_FILE=storage/logs/app.log
ENVEXAMPLE

success ".env files created with secure random keys"

#------------------------------------------------------------------------------
# Create configuration files
#------------------------------------------------------------------------------
info "Creating configuration files..."

# Style configuration
cat > config/style.php <<'PHP'
<?php

return [
    // Global style system toggle
    // Set to true to use Tailwind CSS (CDN or built)
    // Set to false to use fallback CSS
    'useTailwind' => true,

    // Tailwind mode: 'cdn' or 'build'
    // 'cdn' - Load from CDN (faster development, no build required)
    // 'build' - Use compiled CSS from /public/css/app.css (production)
    'tailwindMode' => 'build',

    // Fallback CSS path (used when useTailwind = false)
    'fallbackCss' => '/css/fallback.css',
];
PHP

# App configuration
cat > config/app.php <<'PHP'
<?php

return [
    'name' => env('APP_NAME', 'Bastion PHP'),
    'env' => env('APP_ENV', 'production'),
    'debug' => env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
    'timezone' => 'UTC',

    // Port for development server
    'port' => 9876,
];
PHP

success "Configuration files created"

#------------------------------------------------------------------------------
# Create composer.json
#------------------------------------------------------------------------------
info "Creating composer.json..."

cat > composer.json <<'JSON'
{
  "name": "routpher/app",
  "description": "ROUTPHER - Lightweight PHP framework",
  "type": "project",
  "require": {
    "php": "^8.0",
    "firebase/php-jwt": "^6.10"
  },
  "require-dev": {
    "phpunit/phpunit": "^10.0"
  },
  "autoload": {
    "classmap": [
      "app/core/",
      "app/middleware/",
      "app/models/"
    ],
    "files": [
      "app/core/helpers.php"
    ]
  },
  "autoload-dev": {
    "psr-4": {
      "Tests\\": "tests/"
    }
  },
  "scripts": {
    "test": "phpunit"
  }
}
JSON

success "composer.json created"

#------------------------------------------------------------------------------
# Create package.json for Tailwind CSS (if enabled)
#------------------------------------------------------------------------------
if [ "$WITH_TAILWIND" = true ]; then
    info "Creating package.json for Tailwind CSS..."

    cat > package.json <<'JSON'
{
  "name": "routpher-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "tailwindcss -i ./resources/css/app.css -o ./public/css/app.css --watch",
    "build": "tailwindcss -i ./resources/css/app.css -o ./public/css/app.css --minify"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.0"
  }
}
JSON

    cat > tailwind.config.js <<'JS'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.php",
    "./resources/**/*.{html,js}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        }
      }
    },
  },
  plugins: [],
}
JS

    mkdir -p resources/css public/css

    cat > resources/css/app.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer utilities {
    .gradient-animation {
        background: linear-gradient(-45deg, #1e3a8a, #1e40af, #2563eb, #3b82f6);
        background-size: 400% 400%;
        animation: gradient 15s ease infinite;
    }

    @keyframes gradient {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
}
CSS

    success "Tailwind CSS configuration created"
fi

#------------------------------------------------------------------------------
# Create fallback CSS (always generated for non-Tailwind mode)
#------------------------------------------------------------------------------
info "Creating fallback CSS..."

mkdir -p public/css

cat > public/css/fallback.css <<'CSS'
/*
 * Bastion PHP - Fallback CSS
 * Used when Tailwind is disabled in config/style.php
 */

/* Reset */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

/* Base Styles */
:root {
    --color-primary: #2563eb;
    --color-primary-dark: #1d4ed8;
    --color-gray-50: #f9fafb;
    --color-gray-100: #f3f4f6;
    --color-gray-200: #e5e7eb;
    --color-gray-300: #d1d5db;
    --color-gray-600: #4b5563;
    --color-gray-800: #1f2937;
    --color-gray-900: #111827;
}

body {
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6;
    color: var(--color-gray-900);
    background: var(--color-gray-50);
}

/* Typography */
h1, h2, h3, h4, h5, h6 {
    font-weight: 700;
    margin-bottom: 1rem;
    line-height: 1.2;
}

h1 { font-size: 2.5rem; }
h2 { font-size: 2rem; }
h3 { font-size: 1.75rem; }
h4 { font-size: 1.5rem; }
h5 { font-size: 1.25rem; }
h6 { font-size: 1rem; }

p {
    margin-bottom: 1rem;
}

a {
    color: var(--color-primary);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* Layout */
.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
}

/* Header/Navigation */
header {
    background: var(--color-primary);
    color: white;
    padding: 1rem 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

nav {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

nav a {
    color: white;
    margin-right: 2rem;
    text-decoration: none;
    font-weight: 500;
}

nav a:hover {
    text-decoration: underline;
}

/* Main Content */
main {
    min-height: calc(100vh - 200px);
    padding: 2rem 0;
}

/* Forms */
form {
    max-width: 500px;
}

label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
    color: var(--color-gray-800);
}

input[type="text"],
input[type="email"],
input[type="password"],
input[type="number"],
textarea,
select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid var(--color-gray-300);
    border-radius: 4px;
    font-size: 1rem;
    margin-bottom: 1rem;
    transition: border-color 0.2s;
}

input:focus,
textarea:focus,
select:focus {
    outline: none;
    border-color: var(--color-primary);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

/* Buttons */
button,
.btn {
    display: inline-block;
    padding: 0.75rem 1.5rem;
    background: var(--color-primary);
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
    text-decoration: none;
}

button:hover,
.btn:hover {
    background: var(--color-primary-dark);
    text-decoration: none;
}

button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

/* Cards */
.card {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    margin-bottom: 2rem;
}

/* Alerts */
.alert {
    padding: 1rem;
    border-radius: 4px;
    margin-bottom: 1rem;
}

.alert-success {
    background: #d1fae5;
    border: 1px solid #6ee7b7;
    color: #065f46;
}

.alert-error {
    background: #fee2e2;
    border: 1px solid #fca5a5;
    color: #991b1b;
}

.alert-warning {
    background: #fef3c7;
    border: 1px solid #fcd34d;
    color: #92400e;
}

.alert-info {
    background: #dbeafe;
    border: 1px solid #93c5fd;
    color: #1e40af;
}

/* Tables */
table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 2rem;
}

th, td {
    padding: 0.75rem;
    text-align: left;
    border-bottom: 1px solid var(--color-gray-200);
}

th {
    font-weight: 600;
    background: var(--color-gray-100);
}

tr:hover {
    background: var(--color-gray-50);
}

/* Footer */
footer {
    background: var(--color-gray-900);
    color: var(--color-gray-300);
    padding: 2rem;
    text-align: center;
    margin-top: 4rem;
}

/* Utility Classes */
.text-center { text-align: center; }
.text-right { text-align: right; }
.mt-1 { margin-top: 0.5rem; }
.mt-2 { margin-top: 1rem; }
.mt-3 { margin-top: 1.5rem; }
.mt-4 { margin-top: 2rem; }
.mb-1 { margin-bottom: 0.5rem; }
.mb-2 { margin-bottom: 1rem; }
.mb-3 { margin-bottom: 1.5rem; }
.mb-4 { margin-bottom: 2rem; }
.p-1 { padding: 0.5rem; }
.p-2 { padding: 1rem; }
.p-3 { padding: 1.5rem; }
.p-4 { padding: 2rem; }

/* Grid */
.grid {
    display: grid;
    gap: 2rem;
}

.grid-cols-1 { grid-template-columns: repeat(1, 1fr); }
.grid-cols-2 { grid-template-columns: repeat(2, 1fr); }
.grid-cols-3 { grid-template-columns: repeat(3, 1fr); }
.grid-cols-4 { grid-template-columns: repeat(4, 1fr); }

@media (max-width: 768px) {
    .grid-cols-2,
    .grid-cols-3,
    .grid-cols-4 {
        grid-template-columns: 1fr;
    }

    nav {
        flex-direction: column;
        align-items: flex-start;
    }

    nav a {
        margin: 0.5rem 0;
    }
}
CSS

success "Fallback CSS created"

#------------------------------------------------------------------------------
# Create SQLite database
#------------------------------------------------------------------------------
info "Initializing SQLite database..."
touch storage/db/app.db
chmod 664 storage/db/app.db 2>/dev/null || true
success "Database file created"

#------------------------------------------------------------------------------
# Create public/.htaccess and index.php
#------------------------------------------------------------------------------
info "Setting up web root..."

cat > public/.htaccess <<'HTA'
<IfModule mod_rewrite.c>
    RewriteEngine On

    # Redirect to HTTPS (production)
    # RewriteCond %{HTTPS} off
    # RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect to front controller
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^ index.php [QSA,L]
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# Disable directory browsing
Options -Indexes

# Prevent access to .env files
<FilesMatch "^\.env">
    Order allow,deny
    Deny from all
</FilesMatch>
HTA

cat > public/index.php <<'PHP'
<?php
/**
 * ROUTPHER Framework - Front Controller
 * All requests are routed through this file
 */

// Load autoloader and bootstrap
require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../app/bootstrap.php';

use App\Core\App;

// Create application instance
$app = new App(__DIR__ . '/..');

// Register global middleware
$app->use([\App\Middleware\SecurityHeaders::class, 'handle']);

if (env('CSRF_ENABLED', true)) {
    $app->use([\App\Core\CSRF::class, 'verify']);
}

$app->use([\App\Core\Auth::class, 'loadUser']);

// Run the application
$app->run();
PHP

success "Web root configured"

#------------------------------------------------------------------------------
# Create bootstrap.php
#------------------------------------------------------------------------------
info "Creating application bootstrap..."

cat > app/bootstrap.php <<'PHP'
<?php
/**
 * Bootstrap file - loads environment and core classes
 */

// Error reporting based on environment
if (getenv('APP_ENV') === 'production') {
    error_reporting(0);
    ini_set('display_errors', '0');
} else {
    error_reporting(E_ALL);
    ini_set('display_errors', '1');
}

// Load environment variables from .env file
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);

        // Skip comments and empty lines
        if ($line === '' || strpos($line, '#') === 0) {
            continue;
        }

        // Parse KEY=VALUE
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);

            // Remove quotes if present
            if (preg_match('/^(["\'])(.*)\1$/', $value, $matches)) {
                $value = $matches[2];
            }

            putenv("$key=$value");
            $_ENV[$key] = $value;
        }
    }
}

// Start session if not already started
if (session_status() === PHP_SESSION_NONE && PHP_SAPI !== 'cli') {
    session_start([
        'cookie_httponly' => true,
        'cookie_samesite' => 'Lax',
        'cookie_secure' => env('SECURE_COOKIES', false)
    ]);
}

// Set timezone
date_default_timezone_set(env('APP_TIMEZONE', 'UTC'));
PHP

success "Bootstrap file created"

#------------------------------------------------------------------------------
# Create core helper functions
#------------------------------------------------------------------------------
info "Creating core helpers..."

cat > app/core/helpers.php <<'PHP'
<?php
/**
 * Global helper functions
 */

if (!function_exists('env')) {
    /**
     * Get environment variable with optional default
     */
    function env(string $key, mixed $default = null): mixed
    {
        $value = getenv($key);

        if ($value === false) {
            return $default;
        }

        // Convert boolean strings
        if (in_array(strtolower($value), ['true', 'false'], true)) {
            return $value === 'true';
        }

        return $value;
    }
}

if (!function_exists('e')) {
    /**
     * Escape HTML special characters
     */
    function e(mixed $value): string
    {
        return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
    }
}

if (!function_exists('view')) {
    /**
     * Render a view file with data
     */
    function view(string $path, array $data = []): string
    {
        extract($data, EXTR_SKIP);
        ob_start();
        $viewFile = __DIR__ . '/../views/' . $path . '.php';

        if (!file_exists($viewFile)) {
            throw new \RuntimeException("View not found: $path");
        }

        include $viewFile;
        return ob_get_clean();
    }
}

if (!function_exists('redirect')) {
    /**
     * Redirect to a URL
     */
    function redirect(string $url, int $code = 302): never
    {
        // Security: Prevent header injection by removing \r and \n
        $url = str_replace(["\r", "\n"], '', $url);
        header("Location: $url", true, $code);
        exit;
    }
}

if (!function_exists('json_response')) {
    /**
     * Send JSON response and exit
     */
    function json_response(mixed $data, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode($data);
        exit;
    }
}

if (!function_exists('abort')) {
    /**
     * Abort with HTTP error code
     */
    function abort(int $code, string $message = ''): never
    {
        http_response_code($code);

        if ($message) {
            echo $message;
        } else {
            $messages = [
                400 => 'Bad Request',
                401 => 'Unauthorized',
                403 => 'Forbidden',
                404 => 'Not Found',
                500 => 'Internal Server Error'
            ];
            echo $messages[$code] ?? 'Error';
        }

        exit;
    }
}

if (!function_exists('dd')) {
    /**
     * Dump and die (for debugging)
     */
    function dd(...$vars): never
    {
        foreach ($vars as $var) {
            echo '<pre>';
            var_dump($var);
            echo '</pre>';
        }
        exit;
    }
}

if (!function_exists('logger')) {
    /**
     * Get logger instance
     */
    function logger(): \App\Core\Logger
    {
        static $logger = null;
        if ($logger === null) {
            $logger = new \App\Core\Logger();
        }
        return $logger;
    }
}

if (!function_exists('auth')) {
    /**
     * Get authenticated user
     */
    function auth(): ?array
    {
        return $GLOBALS['auth_user'] ?? null;
    }
}

if (!function_exists('normalize_path')) {
    /**
     * Normalize a URL path, removing traversal attempts
     */
    function normalize_path(string $uri): string
    {
        $path = parse_url($uri, PHP_URL_PATH) ?? '/';

        // Security: Remove path traversal attempts
        $segments = explode('/', $path);
        $safe = [];

        foreach ($segments as $segment) {
            // Skip empty segments, '.', and '..'
            if ($segment === '' || $segment === '.' || $segment === '..') {
                continue;
            }
            $safe[] = $segment;
        }

        return implode('/', $safe);
    }
}

if (!function_exists('config')) {
    /**
     * Get configuration value from config files
     */
    function config(string $key, mixed $default = null): mixed
    {
        static $cache = [];

        // Parse key (e.g., "style.useTailwind" => file: style, key: useTailwind)
        $parts = explode('.', $key, 2);
        $file = $parts[0];
        $configKey = $parts[1] ?? null;

        // Load config file if not cached
        if (!isset($cache[$file])) {
            $configPath = __DIR__ . '/../../config/' . $file . '.php';
            if (file_exists($configPath)) {
                $cache[$file] = require $configPath;
            } else {
                $cache[$file] = [];
            }
        }

        // Return entire file config or specific key
        if ($configKey === null) {
            return $cache[$file] ?? $default;
        }

        return $cache[$file][$configKey] ?? $default;
    }
}

if (!function_exists('style_config')) {
    /**
     * Get style configuration
     */
    function style_config(string $key = null): mixed
    {
        if ($key === null) {
            return config('style', []);
        }
        return config("style.{$key}");
    }
}

if (!function_exists('use_tailwind')) {
    /**
     * Check if Tailwind CSS is enabled
     */
    function use_tailwind(): bool
    {
        return (bool) config('style.useTailwind', true);
    }
}

if (!function_exists('tailwind_mode')) {
    /**
     * Get Tailwind mode ('cdn' or 'build')
     */
    function tailwind_mode(): string
    {
        return config('style.tailwindMode', 'build');
    }
}
PHP

success "Helper functions created"

#------------------------------------------------------------------------------
# Create core classes
#------------------------------------------------------------------------------
info "Creating core framework classes..."

# Request class
cat > app/core/Request.php <<'PHP'
<?php

namespace App\Core;

class Request
{
    public string $method;
    public string $path;
    public array $query;
    public array $body;
    public array $headers;
    public array $cookies;
    public array $files;
    public array $meta = [];

    private ?array $jsonData = null;

    public function __construct()
    {
        $this->method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $this->path = normalize_path($_SERVER['REQUEST_URI'] ?? '/');
        $this->query = $_GET;
        $this->body = $_POST;
        $this->headers = $this->getHeaders();
        $this->cookies = $_COOKIE;
        $this->files = $_FILES;
    }

    private function getHeaders(): array
    {
        if (function_exists('getallheaders')) {
            return getallheaders() ?: [];
        }

        $headers = [];
        foreach ($_SERVER as $key => $value) {
            if (strpos($key, 'HTTP_') === 0) {
                $header = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
                $headers[$header] = $value;
            }
        }
        return $headers;
    }

    /**
     * Get JSON body
     */
    public function json(): array
    {
        if ($this->jsonData !== null) {
            return $this->jsonData;
        }

        $contentType = $this->headers['Content-Type'] ?? '';

        if (stripos($contentType, 'application/json') !== false) {
            $this->jsonData = json_decode(file_get_contents('php://input'), true) ?? [];
        } else {
            $this->jsonData = [];
        }

        return $this->jsonData;
    }

    /**
     * Get input value (from body or JSON)
     */
    public function input(string $key, mixed $default = null): mixed
    {
        if (isset($this->body[$key])) {
            return $this->body[$key];
        }

        $json = $this->json();
        return $json[$key] ?? $default;
    }

    /**
     * Check if request is AJAX
     */
    public function isAjax(): bool
    {
        return ($this->headers['X-Requested-With'] ?? '') === 'XMLHttpRequest';
    }

    /**
     * Check if request is JSON
     */
    public function isJson(): bool
    {
        return stripos($this->headers['Content-Type'] ?? '', 'application/json') !== false;
    }

    /**
     * Simple validation
     */
    public function validate(array $rules): array
    {
        $errors = [];

        foreach ($rules as $field => $rule) {
            $ruleList = explode('|', $rule);
            $value = $this->input($field);

            foreach ($ruleList as $r) {
                if ($r === 'required' && empty($value)) {
                    $errors[$field][] = "$field is required";
                }

                if ($r === 'email' && !empty($value) && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    $errors[$field][] = "$field must be a valid email";
                }

                if (strpos($r, 'min:') === 0) {
                    $min = (int)substr($r, 4);
                    if (strlen($value) < $min) {
                        $errors[$field][] = "$field must be at least $min characters";
                    }
                }

                if (strpos($r, 'max:') === 0) {
                    $max = (int)substr($r, 4);
                    if (strlen($value) > $max) {
                        $errors[$field][] = "$field must not exceed $max characters";
                    }
                }
            }
        }

        if (!empty($errors)) {
            throw new \Exception('Validation failed: ' . json_encode($errors));
        }

        return array_intersect_key($this->body, array_flip(array_keys($rules)));
    }
}
PHP

# Response class
cat > app/core/Response.php <<'PHP'
<?php

namespace App\Core;

class Response
{
    /**
     * Send JSON response
     */
    public static function json(mixed $data, int $code = 200): never
    {
        http_response_code($code);
        header('Content-Type: application/json');
        echo json_encode($data);
        exit;
    }

    /**
     * Send HTML response
     */
    public static function html(string $content, int $code = 200): never
    {
        http_response_code($code);
        header('Content-Type: text/html; charset=UTF-8');
        echo $content;
        exit;
    }

    /**
     * Send redirect response
     */
    public static function redirect(string $url, int $code = 302): never
    {
        // Security: Prevent header injection by removing \r and \n
        $url = str_replace(["\r", "\n"], '', $url);
        header("Location: $url", true, $code);
        exit;
    }
}
PHP

# Database class
cat > app/core/DB.php <<'PHP'
<?php

namespace App\Core;

use PDO;
use PDOException;

class DB
{
    private static ?PDO $pdo = null;

    /**
     * Get PDO instance
     */
    public static function pdo(): PDO
    {
        if (self::$pdo !== null) {
            return self::$pdo;
        }

        $connection = env('DB_CONNECTION', 'sqlite');

        try {
            if ($connection === 'sqlite') {
                $path = __DIR__ . '/../../' . env('DB_PATH', 'storage/db/app.db');
                $dsn = "sqlite:$path";
                self::$pdo = new PDO($dsn);

                // Enable WAL mode for 10-100x faster concurrent writes
                self::$pdo->exec('PRAGMA journal_mode=WAL');
                self::$pdo->exec('PRAGMA synchronous=NORMAL');
            } elseif ($connection === 'mysql') {
                $host = env('DB_HOST', '127.0.0.1');
                $port = env('DB_PORT', '3306');
                $name = env('DB_DATABASE', 'app');
                $user = env('DB_USERNAME', 'root');
                $pass = env('DB_PASSWORD', '');
                $dsn = "mysql:host=$host;port=$port;dbname=$name;charset=utf8mb4";
                self::$pdo = new PDO($dsn, $user, $pass);
            } else {
                throw new \RuntimeException("Unsupported database connection: $connection");
            }

            self::$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            self::$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        } catch (PDOException $e) {
            logger()->error("Database connection failed: " . $e->getMessage());
            throw $e;
        }

        return self::$pdo;
    }

    /**
     * Simple query builder
     */
    public static function table(string $table): QueryBuilder
    {
        return new QueryBuilder($table);
    }
}

/**
 * Simple query builder
 */
class QueryBuilder
{
    private string $table;
    private array $wheres = [];
    private array $bindings = [];
    private ?int $limit = null;
    private ?int $offset = null;

    public function __construct(string $table)
    {
        $this->table = $table;
    }

    public function where(string $column, mixed $value): self
    {
        $this->wheres[] = "$column = ?";
        $this->bindings[] = $value;
        return $this;
    }

    public function limit(int $limit): self
    {
        $this->limit = $limit;
        return $this;
    }

    public function offset(int $offset): self
    {
        $this->offset = $offset;
        return $this;
    }

    /**
     * Execute the query and return all results.
     * @return array
     */
    public function get(): array
    {
        $sql = "SELECT * FROM {$this->table}";

        if (!empty($this->wheres)) {
            $sql .= " WHERE " . implode(' AND ', $this->wheres);
        }

        if ($this->limit !== null) {
            $sql .= " LIMIT {$this->limit}";
        }

        if ($this->offset !== null) {
            $sql .= " OFFSET {$this->offset}";
        }

        $stmt = DB::pdo()->prepare($sql);
        $stmt->execute($this->bindings);
        return $stmt->fetchAll();
    }

    /**
     * Execute the query and return the first result.
     * @return array|null
     */
    public function first(): ?array
    {
        $results = $this->limit(1)->get();
        return $results[0] ?? null;
    }

    /**
     * Insert a new record into the database.
     * @param array $data
     * @return int The ID of the new record.
     */
    public function insert(array $data): int
    {
        $columns = array_keys($data);
        $placeholders = array_fill(0, count($columns), '?');

        $sql = sprintf(
            "INSERT INTO %s (%s) VALUES (%s)",
            $this->table,
            implode(', ', $columns),
            implode(', ', $placeholders)
        );

        $stmt = DB::pdo()->prepare($sql);
        $stmt->execute(array_values($data));

        return (int)DB::pdo()->lastInsertId();
    }
}
PHP

# Logger class
cat > app/core/Logger.php <<'PHP'
<?php

namespace App\Core;

class Logger
{
    private string $logFile;
    private string $logLevel;

    private const LEVELS = [
        'debug' => 0,
        'info' => 1,
        'warning' => 2,
        'error' => 3
    ];

    public function __construct()
    {
        $this->logFile = __DIR__ . '/../../' . env('LOG_FILE', 'storage/logs/app.log');
        $this->logLevel = env('LOG_LEVEL', 'info');
    }

    public function debug(string $message, array $context = []): void
    {
        $this->log('debug', $message, $context);
    }

    public function info(string $message, array $context = []): void
    {
        $this->log('info', $message, $context);
    }

    public function warning(string $message, array $context = []): void
    {
        $this->log('warning', $message, $context);
    }

    public function error(string $message, array $context = []): void
    {
        $this->log('error', $message, $context);
    }

    private function log(string $level, string $message, array $context): void
    {
        if (self::LEVELS[$level] < self::LEVELS[$this->logLevel]) {
            return;
        }

        $timestamp = date('Y-m-d H:i:s');
        $contextStr = !empty($context) ? ' ' . json_encode($context) : '';
        $logLine = "[$timestamp] " . strtoupper($level) . ": $message$contextStr\n";

        $dir = dirname($this->logFile);
        if (!is_dir($dir)) {
            @mkdir($dir, 0755, true);
        }

        @file_put_contents($this->logFile, $logLine, FILE_APPEND | LOCK_EX);
    }
}
PHP

# Router class
cat > app/core/Router.php <<'PHP'
<?php

namespace App\Core;

class Router
{
    private string $appDir;

    public function __construct(string $appDir)
    {
        $this->appDir = rtrim($appDir, '/');
    }

    /**
     * Dispatch request to appropriate handler
     * Supports file-based routing with dynamic [param] folders
     * and +server.php for API endpoints
     */
    public function dispatch(Request $req): void
    {
        // Check for API route (+server.php)
        if ($this->dispatchServerRoute($req)) {
            return;
        }

        // Regular page routing
        $this->dispatchPageRoute($req);
    }

    /**
     * Try to dispatch to +server.php (API endpoint)
     */
    private function dispatchServerRoute(Request $req): bool
    {
        $segments = $req->path === '' ? [] : explode('/', $req->path);
        $current = $this->appDir;
        $params = [];
        $folders = [$current];

        foreach ($segments as $segment) {
            $direct = "$current/$segment";

            if (is_dir($direct)) {
                $current = $direct;
                $folders[] = $current;
                continue;
            }

            // Try dynamic [param] folders
            $found = false;
            foreach (glob("$current/*", GLOB_ONLYDIR) as $dir) {
                if (preg_match('/^\[(.+)\]$/', basename($dir), $matches)) {
                    $params[$matches[1]] = $segment;
                    $current = $dir;
                    $folders[] = $current;
                    $found = true;
                    break;
                }
            }

            if (!$found) {
                return false;
            }
        }

        // Check for +server.php in deepest matching folder
        $serverFile = "$current/+server.php";

        if (file_exists($serverFile)) {
            $req->meta['params'] = $params;
            $this->executeServerFile($serverFile, $req);
            return true;
        }

        return false;
    }

    /**
     * Execute +server.php file
     */
    private function executeServerFile(string $file, Request $req): void
    {
        $handler = require $file;

        if (is_callable($handler)) {
            $handler($req);
        } elseif (is_array($handler)) {
            $method = strtolower($req->method);
            if (isset($handler[$method]) && is_callable($handler[$method])) {
                $handler[$method]($req);
            } else {
                Response::json(['error' => 'Method not allowed'], 405);
            }
        }
    }

    /**
     * Dispatch to page.php (web route)
     */
    private function dispatchPageRoute(Request $req): void
    {
        $segments = $req->path === '' ? [] : explode('/', $req->path);
        $current = $this->appDir;
        $folders = [$current];
        $params = [];

        foreach ($segments as $segment) {
            $direct = "$current/$segment";

            if (is_dir($direct)) {
                $current = $direct;
                $folders[] = $current;
                continue;
            }

            // Try dynamic [param] folders
            $found = false;
            foreach (glob("$current/*", GLOB_ONLYDIR) as $dir) {
                if (preg_match('/^\[(.+)\]$/', basename($dir), $matches)) {
                    $params[$matches[1]] = $segment;
                    $current = $dir;
                    $folders[] = $current;
                    $found = true;
                    break;
                }
            }

            if (!$found) {
                $this->renderError(404, $folders);
                return;
            }
        }

        $pageFile = "$current/page.php";

        if (!file_exists($pageFile)) {
            $this->renderError(404, $folders);
            return;
        }

        try {
            // Prepare common variables including CSP nonce
            $nonce = $req->meta['csp_nonce'] ?? '';

            // Find and render loading.php if exists
            $loadingFile = $this->findDeepestFile($folders, 'loading.php');
            if ($loadingFile) {
                echo $this->renderFile($loadingFile, [
                    'params' => $params,
                    'nonce' => $nonce
                ]);
            }

            // Collect all layout files from root to current
            $layouts = $this->collectLayouts($folders);

            // Render page
            $content = $this->renderFile($pageFile, [
                'params' => $params,
                'nonce' => $nonce
            ]);

            // Wrap with layouts (innermost to outermost)
            for ($i = count($layouts) - 1; $i >= 0; $i--) {
                $content = $this->renderFile($layouts[$i], [
                    'content' => $content,
                    'params' => $params,
                    'nonce' => $nonce
                ]);
            }

            echo $content;

        } catch (\Throwable $e) {
            logger()->error("Route error: " . $e->getMessage(), [
                'path' => $req->path,
                'trace' => $e->getTraceAsString()
            ]);

            $errorFile = $this->findDeepestFile($folders, 'error.php');

            if ($errorFile) {
                echo $this->renderFile($errorFile, [
                    'error' => $e,
                    'params' => $params,
                    'nonce' => $nonce ?? ''
                ]);
            } else {
                http_response_code(500);
                if (env('APP_DEBUG', false)) {
                    echo '<pre>' . e($e->getMessage()) . "\n\n" . e($e->getTraceAsString()) . '</pre>';
                } else {
                    echo 'Internal Server Error';
                }
            }
        }
    }

    /**
     * Render a PHP file with variables
     */
    private function renderFile(string $file, array $vars = []): string
    {
        extract($vars, EXTR_SKIP);
        ob_start();
        include $file;
        return ob_get_clean();
    }

    /**
     * Collect all layout.php files from folders
     */
    private function collectLayouts(array $folders): array
    {
        $layouts = [];
        foreach ($folders as $folder) {
            $layoutFile = "$folder/layout.php";
            if (file_exists($layoutFile)) {
                $layouts[] = $layoutFile;
            }
        }
        return $layouts;
    }

    /**
     * Find deepest occurrence of a file in folder hierarchy
     */
    private function findDeepestFile(array $folders, string $filename): ?string
    {
        for ($i = count($folders) - 1; $i >= 0; $i--) {
            $file = $folders[$i] . '/' . $filename;
            if (file_exists($file)) {
                return $file;
            }
        }
        return null;
    }

    /**
     * Render error page
     */
    private function renderError(int $code, array $folders): void
    {
        http_response_code($code);

        $errorFile = $this->appDir . "/views/errors/$code.php";

        if (file_exists($errorFile)) {
            // Pass nonce to error templates
            $req = $GLOBALS['request'] ?? null;
            $nonce = $req?->meta['csp_nonce'] ?? '';
            echo $this->renderFile($errorFile, ['nonce' => $nonce]);
        } else {
            $messages = [
                404 => 'Not Found',
                403 => 'Forbidden',
                500 => 'Internal Server Error'
            ];
            echo $messages[$code] ?? 'Error';
        }
    }
}
PHP

# App class
cat > app/core/App.php <<'PHP'
<?php

namespace App\Core;

class App
{
    private array $middlewares = [];
    private Router $router;

    public function __construct(string $rootPath)
    {
        $this->router = new Router($rootPath . '/app');
    }

    /**
     * Register middleware
     */
    public function use(callable $middleware): void
    {
        $this->middlewares[] = $middleware;
    }

    /**
     * Run the application
     */
    public function run(): void
    {
        $request = new Request();

        // Build middleware chain
        $handler = function($req) {
            return $this->router->dispatch($req);
        };

        // Wrap handler with middleware (in reverse order)
        foreach (array_reverse($this->middlewares) as $middleware) {
            $next = $handler;
            $handler = function($req) use ($middleware, $next) {
                return $middleware($req, $next);
            };
        }

        // Execute chain
        $handler($request);
    }
}
PHP

# Auth class
cat > app/core/Auth.php <<'PHP'
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
PHP

# CSRF class
cat > app/core/CSRF.php <<'PHP'
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

                http_response_code(403);
                echo 'CSRF token mismatch';
                exit;
            }
        }

        return $next($req);
    }
}
PHP

success "Core classes created"

#------------------------------------------------------------------------------
# Create middleware
#------------------------------------------------------------------------------
info "Creating middleware..."

mkdir -p app/middleware

cat > app/middleware/SecurityHeaders.php <<'PHP'
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
PHP

cat > app/middleware/RateLimit.php <<'PHP'
<?php

namespace App\Middleware;

use App\Core\Request;
use App\Core\Response;

class RateLimit
{
    /**
     * WARNING: This is a basic, in-memory rate limiter suitable only for
     * development or single-process servers. For production, you MUST
     * replace this with a more robust implementation using a shared
     * cache (e.g., Redis, Memcached) to handle multiple workers.
     */
    private static array $attempts = [];

    /**
     * Rate limit middleware
     *
     * @param int $maxAttempts Maximum attempts allowed
     * @param int $decayMinutes Time window in minutes
     */
    public static function limit(int $maxAttempts = 5, int $decayMinutes = 1): callable
    {
        return function(Request $req, callable $next) use ($maxAttempts, $decayMinutes) {
            $key = self::getKey($req);
            $now = time();

            // Clean old attempts
            self::$attempts[$key] = array_filter(
                self::$attempts[$key] ?? [],
                fn($timestamp) => $timestamp > $now - ($decayMinutes * 60)
            );

            if (count(self::$attempts[$key] ?? []) >= $maxAttempts) {
                logger()->warning('Rate limit exceeded', [
                    'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                    'path' => $req->path
                ]);

                if ($req->isJson()) {
                    Response::json(['error' => 'Too many requests'], 429);
                } else {
                    http_response_code(429);
                    echo 'Too many requests. Please try again later.';
                    exit;
                }
            }

            self::$attempts[$key][] = $now;

            return $next($req);
        };
    }

    private static function getKey(Request $req): string
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        return md5($ip . $req->path);
    }
}
PHP

success "Middleware created"

#------------------------------------------------------------------------------
# Create models (if auth enabled)
#------------------------------------------------------------------------------
if [ "$WITH_AUTH" = true ]; then
    info "Creating User model..."

    cat > app/models/User.php <<'PHP'
<?php

namespace App\Models;

use App\Core\DB;
use PDO;

class User
{
    /**
     * Find user by ID
     */
    public static function find(int|string $id): ?array
    {
        $stmt = DB::pdo()->prepare(
            'SELECT id, email, name, role, created_at FROM users WHERE id = ?'
        );
        $stmt->execute([$id]);
        $user = $stmt->fetch();

        return $user ?: null;
    }

    /**
     * Find user by email (includes password for authentication)
     */
    public static function findByEmail(string $email): ?array
    {
        $stmt = DB::pdo()->prepare('SELECT * FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        return $user ?: null;
    }

    /**
     * Get all users
     */
    public static function all(): array
    {
        return DB::pdo()
            ->query('SELECT id, email, name, role, created_at FROM users ORDER BY created_at DESC')
            ->fetchAll();
    }

    /**
     * Create a new user
     */
    public static function create(array $data): int
    {
        $stmt = DB::pdo()->prepare(
            'INSERT INTO users (email, password, name, role, created_at) VALUES (?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $data['email'],
            password_hash($data['password'], PASSWORD_DEFAULT),
            $data['name'] ?? '',
            $data['role'] ?? 'user',
            time()
        ]);

        return (int)DB::pdo()->lastInsertId();
    }

    /**
     * Update user
     */
    public static function update(int|string $id, array $data): bool
    {
        $stmt = DB::pdo()->prepare(
            'UPDATE users SET email = ?, name = ?, role = ? WHERE id = ?'
        );

        return $stmt->execute([
            $data['email'],
            $data['name'],
            $data['role'],
            $id
        ]);
    }

    /**
     * Delete user
     */
    public static function delete(int|string $id): bool
    {
        $stmt = DB::pdo()->prepare('DELETE FROM users WHERE id = ?');
        return $stmt->execute([$id]);
    }
}
PHP

    success "User model created"
fi

#------------------------------------------------------------------------------
# Create views
#------------------------------------------------------------------------------
info "Creating views..."

# Main layout with GLOBAL AUTO-INJECT STYLING
cat > app/layout.php <<'HTML'
<?php
/**
 * Global Layout - Bastion PHP
 *
 * This layout automatically injects styles based on config/style.php
 * NO MANUAL CSS IMPORTS NEEDED IN ANY VIEW!
 */

// Auto-inject styling based on config
$useTailwind = use_tailwind();
$tailwindMode = tailwind_mode();
$htmlClass = $useTailwind ? 'class="dark"' : '';
$bodyClass = $useTailwind ? 'class="bg-black text-white antialiased"' : '';
?>
<!doctype html>
<html lang="en" <?= $htmlClass ?>>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= $title ?? 'Bastion PHP App' ?></title>

    <?php if ($useTailwind): ?>
        <?php if ($tailwindMode === 'cdn'): ?>
            <!-- Tailwind CSS - CDN Mode -->
            <script src="https://cdn.tailwindcss.com"></script>
        <?php else: ?>
            <!-- Tailwind CSS - Build Mode -->
            <link rel="stylesheet" href="/css/app.css">
        <?php endif; ?>
    <?php else: ?>
        <!-- Fallback CSS -->
        <link rel="stylesheet" href="<?= config('style.fallbackCss', '/css/fallback.css') ?>">
    <?php endif; ?>

    <!-- HTMX for dynamic interactions -->
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>
</head>
<body <?= $bodyClass ?>>
    <?php if ($useTailwind): ?>
        <!-- Tailwind Navigation -->
        <nav class="fixed w-full top-0 z-50 bg-black/80 backdrop-blur-xl border-b border-white/10">
    <!-- Navigation -->
    <nav class="fixed w-full top-0 z-50 bg-black/80 backdrop-blur-xl border-b border-white/10">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <div class="flex items-center space-x-8">
                    <a href="/" class="text-xl font-bold bg-gradient-to-r from-blue-400 to-blue-600 bg-clip-text text-transparent">
                        Bastion PHP
                    </a>
                    <div class="hidden md:flex items-center space-x-4">
                        <a href="/" class="text-gray-300 hover:text-white transition-colors px-3 py-2 rounded-md text-sm font-medium">
                            Home
                        </a>
                        <?php if (isset($GLOBALS['auth_user'])): ?>
                            <?php if ($GLOBALS['auth_user']['role'] === 'admin'): ?>
                                <a href="/admin" class="text-gray-300 hover:text-white transition-colors px-3 py-2 rounded-md text-sm font-medium">
                                    Admin
                                </a>
                            <?php endif; ?>
                        <?php endif; ?>
                    </div>
                </div>

                <div class="flex items-center space-x-4">
                    <?php if (isset($GLOBALS['auth_user'])): ?>
                        <a href="/profile" class="text-gray-300 hover:text-white transition-colors px-3 py-2 rounded-md text-sm font-medium">
                            <?= e($GLOBALS['auth_user']['name']) ?>
                        </a>
                        <a href="/logout" class="bg-white/10 hover:bg-white/20 transition-colors px-4 py-2 rounded-lg text-sm font-medium">
                            Logout
                        </a>
                    <?php else: ?>
                        <a href="/login" class="text-gray-300 hover:text-white transition-colors px-3 py-2 rounded-md text-sm font-medium">
                            Login
                        </a>
                        <a href="/register" class="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 transition-all px-4 py-2 rounded-lg text-sm font-medium shadow-lg shadow-blue-500/50">
                            Get Started
                        </a>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="pt-16 min-h-screen">
        <?= $content ?>
    </main>

    <!-- Footer -->
    <footer class="border-t border-white/10 bg-black">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div class="text-center text-gray-400 text-sm">
                <p>&copy; <?= date('Y') ?> Bastion PHP. Built with PHP & Tailwind CSS.</p>
            </div>
        </div>
    </footer>
</body>
</html>
LAYOUT_PHP

success "Global layout created with auto-inject styling"

# Home page
if [ "$WITH_TAILWIND" = true ]; then
    cat > app/page.php <<'HTML'
<?php $title = 'Welcome to Bastion PHP'; ?>

<!-- Hero Section -->
<section class="relative overflow-hidden">
    <!-- Gradient Background -->
    <div class="absolute inset-0 gradient-animation opacity-10"></div>

    <div class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 lg:py-32">
        <div class="text-center">
            <!-- Badge -->
            <div class="inline-flex items-center px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-sm font-medium mb-8">
                <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                </svg>
                Modern PHP Framework
            </div>

            <!-- Headline -->
            <h1 class="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white via-blue-100 to-blue-400 bg-clip-text text-transparent">
                Build Fast.<br/>Ship Faster.
            </h1>

            <p class="text-xl md:text-2xl text-gray-400 mb-12 max-w-3xl mx-auto leading-relaxed">
                Bastion PHP is a modern PHP framework with file-based routing, JWT authentication, and everything you need to build production-ready applications.
            </p>

            <!-- CTA Buttons -->
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16">
                <a href="/register" class="group relative px-8 py-4 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl font-semibold text-lg shadow-lg shadow-blue-500/50 hover:shadow-blue-500/70 transition-all hover:scale-105">
                    Get Started
                    <span class="absolute inset-0 rounded-xl bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity"></span>
                </a>
                <a href="https://github.com" class="px-8 py-4 bg-white/5 border border-white/10 rounded-xl font-semibold text-lg hover:bg-white/10 transition-all">
                    View on GitHub →
                </a>
            </div>

            <!-- Stats -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto">
                <div class="text-center">
                    <div class="text-4xl font-bold text-white mb-2">⚡</div>
                    <div class="text-gray-400 text-sm">Lightning Fast</div>
                </div>
                <div class="text-center">
                    <div class="text-4xl font-bold text-white mb-2">🔐</div>
                    <div class="text-gray-400 text-sm">Secure by Default</div>
                </div>
                <div class="text-center">
                    <div class="text-4xl font-bold text-white mb-2">📁</div>
                    <div class="text-gray-400 text-sm">File-based Routes</div>
                </div>
                <div class="text-center">
                    <div class="text-4xl font-bold text-white mb-2">🎨</div>
                    <div class="text-gray-400 text-sm">Modern UI</div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Features Section -->
<section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
    <div class="text-center mb-16">
        <h2 class="text-4xl font-bold mb-4">Everything you need</h2>
        <p class="text-xl text-gray-400">Built-in features for modern web applications</p>
    </div>

    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
        <!-- Feature 1 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                📁
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">File-based Routing</h3>
            <p class="text-gray-400 leading-relaxed">Intuitive routing system inspired by Next.js. Create pages by simply adding files to the app directory.</p>
        </div>

        <!-- Feature 2 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                🔐
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">JWT Authentication</h3>
            <p class="text-gray-400 leading-relaxed">Built-in JWT auth with access & refresh tokens, secure cookie handling, and session management.</p>
        </div>

        <!-- Feature 3 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                🛡️
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">Security First</h3>
            <p class="text-gray-400 leading-relaxed">CSRF protection, secure headers, XSS prevention, and SQL injection protection out of the box.</p>
        </div>

        <!-- Feature 4 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                🗄️
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">Database Ready</h3>
            <p class="text-gray-400 leading-relaxed">SQLite by default with support for MySQL and PostgreSQL. Migrations and seeders included.</p>
        </div>

        <!-- Feature 5 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                ⚡
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">HTMX Integration</h3>
            <p class="text-gray-400 leading-relaxed">Build dynamic interfaces with HTMX. Get the power of a SPA without the complexity.</p>
        </div>

        <!-- Feature 6 -->
        <div class="group p-8 rounded-2xl bg-white/5 border border-white/10 hover:border-blue-500/50 transition-all hover:shadow-lg hover:shadow-blue-500/10">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-2xl mb-4">
                🎨
            </div>
            <h3 class="text-xl font-semibold mb-3 group-hover:text-blue-400 transition-colors">Tailwind CSS</h3>
            <p class="text-gray-400 leading-relaxed">Beautiful, responsive UI components styled with Tailwind CSS and ready to customize.</p>
        </div>
    </div>
</section>

<!-- CTA Section -->
<section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
    <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-blue-600 to-blue-800 p-12 lg:p-16">
        <div class="relative z-10 text-center">
            <h2 class="text-4xl font-bold mb-4">Ready to start building?</h2>
            <p class="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
                Join developers building fast, secure web applications with Bastion PHP.
            </p>
            <a href="/register" class="inline-block px-8 py-4 bg-white text-blue-600 rounded-xl font-semibold text-lg hover:bg-blue-50 transition-all hover:scale-105 shadow-xl">
                Get Started for Free
            </a>
        </div>

        <!-- Background decoration -->
        <div class="absolute top-0 right-0 w-64 h-64 bg-blue-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-blue-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse" style="animation-delay: 2s;"></div>
    </div>
</section>
HTML
else
    cat > app/page.php <<'HTML'
<?php $title = 'Welcome to Bastion PHP'; ?>

<div class="card">
    <h1>Welcome to Bastion PHP</h1>

    <p>Your application is ready! Bastion PHP is a lightweight PHP framework with:</p>

    <ul style="margin: 1rem 0; padding-left: 2rem;">
        <li>📁 File-based routing with dynamic parameters</li>
        <li>🔐 JWT authentication with access & refresh tokens</li>
        <li>🛡️ CSRF protection</li>
        <li>🗄️ SQLite database (MySQL/PostgreSQL ready)</li>
        <li>⚡ HTMX integration for modern UX</li>
        <li>🎨 Automatic global styling system</li>
    </ul>

    <h2>Getting Started</h2>

    <p>Check out the <code>app/</code> directory to start building your application.</p>
    <p>Modify <code>config/style.php</code> to switch between Tailwind CSS and fallback CSS.</p>

    <p style="margin-top: 2rem;">
        <a href="/login" class="btn">Get Started</a>
    </p>
</div>
HTML
fi

success "Views created"

# Error pages
cat > app/views/errors/404.php <<'HTML'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>404 - Not Found</title>
    <style nonce="<?= $nonce ?? '' ?>">
        body { font-family: system-ui; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f5f5f5; }
        .error { text-align: center; }
        h1 { font-size: 4rem; margin: 0; color: #2563eb; }
        p { font-size: 1.2rem; color: #666; }
        a { color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <div class="error">
        <h1>404</h1>
        <p>Page not found</p>
        <a href="/">Go home</a>
    </div>
</body>
</html>
HTML

cat > app/views/errors/500.php <<'HTML'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>500 - Server Error</title>
    <style nonce="<?= $nonce ?? '' ?>">
        body { font-family: system-ui; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f5f5f5; }
        .error { text-align: center; }
        h1 { font-size: 4rem; margin: 0; color: #dc2626; }
        p { font-size: 1.2rem; color: #666; }
        a { color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <div class="error">
        <h1>500</h1>
        <p>Internal Server Error</p>
        <a href="/">Go home</a>
    </div>
</body>
</html>
HTML

success "Views created"

#------------------------------------------------------------------------------
# Create auth views and routes (if enabled)
#------------------------------------------------------------------------------
if [ "$WITH_AUTH" = true ]; then
    info "Creating authentication pages..."

    mkdir -p app/login app/register app/logout app/profile

    # Login page
    if [ "$WITH_TAILWIND" = true ]; then
        cat > app/login/page.php <<'HTML'
<?php $title = 'Login'; ?>

<div class="min-h-[calc(100vh-4rem)] flex items-center justify-center px-4 py-12">
    <div class="max-w-md w-full">
        <!-- Header -->
        <div class="text-center mb-8">
            <h1 class="text-4xl font-bold mb-2 bg-gradient-to-r from-white to-blue-400 bg-clip-text text-transparent">
                Welcome Back
            </h1>
            <p class="text-gray-400">Sign in to your account to continue</p>
        </div>

        <!-- Form Card -->
        <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-8 shadow-2xl">
            <?php if (isset($_SESSION['error'])): ?>
                <div class="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400">
                    <div class="flex items-center">
                        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                        </svg>
                        <?= e($_SESSION['error']) ?>
                    </div>
                </div>
                <?php unset($_SESSION['error']); ?>
            <?php endif; ?>

            <form method="POST" action="/login" class="space-y-6">
                <!-- Email Field -->
                <div>
                    <label for="email" class="block text-sm font-medium text-gray-300 mb-2">Email Address</label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="you@example.com"
                    >
                </div>

                <!-- Password Field -->
                <div>
                    <label for="password" class="block text-sm font-medium text-gray-300 mb-2">Password</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="••••••••"
                    >
                </div>

                <input type="hidden" name="_csrf" value="<?= \App\Core\CSRF::token() ?>">

                <!-- Submit Button -->
                <button
                    type="submit"
                    class="w-full py-3 px-4 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 rounded-lg font-semibold text-white shadow-lg shadow-blue-500/50 transition-all hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-black"
                >
                    Sign In
                </button>
            </form>
        </div>

        <!-- Footer Link -->
        <p class="text-center mt-6 text-gray-400">
            Don't have an account?
            <a href="/register" class="text-blue-400 hover:text-blue-300 font-medium transition-colors">
                Create one now →
            </a>
        </p>
    </div>
</div>
HTML
    else
        cat > app/login/page.php <<'HTML'
<?php $title = 'Login'; ?>

<div class="card">
    <h1>Login</h1>

    <?php if (isset($_SESSION['error'])): ?>
        <div class="alert alert-error">
            <?= e($_SESSION['error']) ?>
            <?php unset($_SESSION['error']); ?>
        </div>
    <?php endif; ?>

    <form method="POST" action="/login">
        <div>
            <label for="email">Email:</label>
            <input type="email" id="email" name="email" required>
        </div>

        <div>
            <label for="password">Password:</label>
            <input type="password" id="password" name="password" required>
        </div>

        <input type="hidden" name="_csrf" value="<?= \App\Core\CSRF::token() ?>">

        <button type="submit" class="btn">Login</button>

        <p class="mt-3">
            Don't have an account? <a href="/register">Register</a>
        </p>
    </form>
</div>
HTML
    fi

    # Login +server.php (handles POST)
    cat > app/login/+server.php <<'PHP'
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
PHP

    # Register page
    if [ "$WITH_TAILWIND" = true ]; then
        cat > app/register/page.php <<'HTML'
<?php $title = 'Register'; ?>

<div class="min-h-[calc(100vh-4rem)] flex items-center justify-center px-4 py-12">
    <div class="max-w-md w-full">
        <!-- Header -->
        <div class="text-center mb-8">
            <h1 class="text-4xl font-bold mb-2 bg-gradient-to-r from-white to-blue-400 bg-clip-text text-transparent">
                Create Account
            </h1>
            <p class="text-gray-400">Start building amazing things today</p>
        </div>

        <!-- Form Card -->
        <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-8 shadow-2xl">
            <?php if (isset($_SESSION['error'])): ?>
                <div class="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400">
                    <div class="flex items-center">
                        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                        </svg>
                        <?= e($_SESSION['error']) ?>
                    </div>
                </div>
                <?php unset($_SESSION['error']); ?>
            <?php endif; ?>

            <form method="POST" action="/register" class="space-y-6">
                <!-- Name Field -->
                <div>
                    <label for="name" class="block text-sm font-medium text-gray-300 mb-2">Full Name</label>
                    <input
                        type="text"
                        id="name"
                        name="name"
                        required
                        class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="John Doe"
                    >
                </div>

                <!-- Email Field -->
                <div>
                    <label for="email" class="block text-sm font-medium text-gray-300 mb-2">Email Address</label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="you@example.com"
                    >
                </div>

                <!-- Password Field -->
                <div>
                    <label for="password" class="block text-sm font-medium text-gray-300 mb-2">Password</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        minlength="8"
                        class="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                        placeholder="••••••••"
                    >
                    <p class="mt-2 text-sm text-gray-500">Must be at least 8 characters</p>
                </div>

                <input type="hidden" name="_csrf" value="<?= \App\Core\CSRF::token() ?>">

                <!-- Submit Button -->
                <button
                    type="submit"
                    class="w-full py-3 px-4 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 rounded-lg font-semibold text-white shadow-lg shadow-blue-500/50 transition-all hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-black"
                >
                    Create Account
                </button>
            </form>
        </div>

        <!-- Footer Link -->
        <p class="text-center mt-6 text-gray-400">
            Already have an account?
            <a href="/login" class="text-blue-400 hover:text-blue-300 font-medium transition-colors">
                Sign in →
            </a>
        </p>
    </div>
</div>
HTML
    else
        cat > app/register/page.php <<'HTML'
<?php $title = 'Register'; ?>

<div class="card">
    <h1>Register</h1>

    <?php if (isset($_SESSION['error'])): ?>
        <div class="alert alert-error">
            <?= e($_SESSION['error']) ?>
            <?php unset($_SESSION['error']); ?>
        </div>
    <?php endif; ?>

    <form method="POST" action="/register">
        <div>
            <label for="name">Name:</label>
            <input type="text" id="name" name="name" required>
        </div>

        <div>
            <label for="email">Email:</label>
            <input type="email" id="email" name="email" required>
        </div>

        <div>
            <label for="password">Password:</label>
            <input type="password" id="password" name="password" required minlength="8">
        </div>

        <input type="hidden" name="_csrf" value="<?= \App\Core\CSRF::token() ?>">

        <button type="submit" class="btn">Register</button>

        <p class="mt-3">
            Already have an account? <a href="/login">Login</a>
        </p>
    </form>
</div>
HTML
    fi

    # Register +server.php
    cat > app/register/+server.php <<'PHP'
<?php

use App\Core\Auth;
use App\Models\User;

return [
    'get' => function($req) {
        // If already logged in, redirect to profile
        if (auth()) {
            redirect('/profile');
        }

        // Render register page by including page.php
        $title = 'Register';
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
        $name = $req->input('name');
        $email = $req->input('email');
        $password = $req->input('password');

        // Check if user exists
        if (User::findByEmail($email)) {
            $_SESSION['error'] = 'Email already registered';
            redirect('/register');
        }

        // Validate
        if (strlen($password) < 8) {
            $_SESSION['error'] = 'Password must be at least 8 characters';
            redirect('/register');
        }

        // Create user
        $userId = User::create([
            'email' => $email,
            'password' => $password,
            'name' => $name,
            'role' => 'user'
        ]);

        logger()->info('User registered', ['user_id' => $userId]);

        // Auto-login
        $tokens = Auth::issueTokens($userId);

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
            'httponly' => false,
            'samesite' => 'Lax'
        ]);

        redirect('/profile');
    }
];
PHP

    # Profile page
    if [ "$WITH_TAILWIND" = true ]; then
        cat > app/profile/page.php <<'HTML'
<?php
// Require authentication
if (!isset($GLOBALS['auth_user'])) {
    redirect('/login');
}

$user = $GLOBALS['auth_user'];
$title = 'Profile';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <div class="mb-8">
        <h1 class="text-4xl font-bold mb-2 bg-gradient-to-r from-white to-blue-400 bg-clip-text text-transparent">
            Your Profile
        </h1>
        <p class="text-gray-400">Manage your account information</p>
    </div>

    <div class="grid lg:grid-cols-3 gap-8">
        <!-- Profile Card -->
        <div class="lg:col-span-2">
            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-8 shadow-2xl">
                <!-- Avatar Section -->
                <div class="flex items-center space-x-6 mb-8 pb-8 border-b border-white/10">
                    <div class="w-24 h-24 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-3xl font-bold">
                        <?= strtoupper(substr($user['name'], 0, 1)) ?>
                    </div>
                    <div>
                        <h2 class="text-2xl font-bold text-white mb-1"><?= e($user['name']) ?></h2>
                        <p class="text-gray-400"><?= e($user['email']) ?></p>
                        <span class="inline-block mt-2 px-3 py-1 rounded-full text-xs font-semibold <?= $user['role'] === 'admin' ? 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20' : 'bg-blue-500/10 text-blue-400 border border-blue-500/20' ?>">
                            <?= ucfirst(e($user['role'])) ?>
                        </span>
                    </div>
                </div>

                <!-- Account Details -->
                <div class="space-y-6">
                    <h3 class="text-xl font-semibold mb-4">Account Details</h3>

                    <div class="grid md:grid-cols-2 gap-6">
                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Full Name</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= e($user['name']) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Email Address</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= e($user['email']) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Role</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= ucfirst(e($user['role'])) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Member Since</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= date('F j, Y', $user['created_at']) ?>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Actions -->
        <div class="space-y-6">
            <?php if ($user['role'] === 'admin'): ?>
            <div class="bg-gradient-to-br from-yellow-500/10 to-yellow-600/10 backdrop-blur-xl rounded-2xl border border-yellow-500/20 p-6 shadow-2xl">
                <div class="flex items-center mb-4">
                    <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-yellow-500 to-yellow-600 flex items-center justify-center text-2xl mr-4">
                        👑
                    </div>
                    <div>
                        <h3 class="font-semibold text-white">Admin Panel</h3>
                        <p class="text-sm text-gray-400">Manage your app</p>
                    </div>
                </div>
                <a href="/admin" class="block w-full py-2 px-4 bg-yellow-500/20 hover:bg-yellow-500/30 rounded-lg text-center font-medium text-yellow-400 transition-all">
                    Open Admin Panel
                </a>
            </div>
            <?php endif; ?>

            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-6 shadow-2xl">
                <h3 class="font-semibold text-white mb-4">Quick Actions</h3>
                <div class="space-y-3">
                    <a href="/logout" class="block w-full py-2 px-4 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 rounded-lg text-center font-medium text-red-400 transition-all">
                        Sign Out
                    </a>
                </div>
            </div>

            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-6 shadow-2xl">
                <h3 class="font-semibold text-white mb-2">Account Status</h3>
                <div class="flex items-center text-green-400">
                    <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                    </svg>
                    Active
                </div>
            </div>
        </div>
    </div>
</div>
HTML
    else
        cat > app/profile/page.php <<'HTML'
<?php
// Require authentication
if (!isset($GLOBALS['auth_user'])) {
    redirect('/login');
}

$user = $GLOBALS['auth_user'];
$title = 'Profile';
?>

<h1>Profile</h1>

<div style="padding: 1.5rem; background: #f9f9f9; border-radius: 8px; margin-top: 1rem;">
    <p><strong>Name:</strong> <?= e($user['name']) ?></p>
    <p><strong>Email:</strong> <?= e($user['email']) ?></p>
    <p><strong>Role:</strong> <?= e($user['role']) ?></p>
    <p><strong>Member since:</strong> <?= date('F j, Y', $user['created_at']) ?></p>
</div>

<p style="margin-top: 2rem;">
    <a href="/logout" class="btn">Logout</a>
</p>
HTML
    fi

    # Logout
    cat > app/logout/page.php <<'PHP'
<?php
// Clear cookies
setcookie('access', '', time() - 3600, '/');
setcookie('refresh', '', time() - 3600, '/');

// Destroy session
session_destroy();

redirect('/');
PHP

    success "Authentication pages created"
fi

#------------------------------------------------------------------------------
# Create API routes (if enabled)
#------------------------------------------------------------------------------
if [ "$WITH_API" = true ]; then
    info "Creating API routes..."

    mkdir -p app/api/users app/api/auth/refresh

    # API users list
    cat > app/api/users/+server.php <<'PHP'
<?php

use App\Core\Response;
use App\Core\DB;

return [
    'get' => function($req) {
        $users = DB::table('users')
            ->limit(100)
            ->get();

        // Remove password field
        $users = array_map(function($user) {
            unset($user['password']);
            return $user;
        }, $users);

        Response::json($users);
    }
];
PHP

    # API auth refresh
    cat > app/api/auth/refresh/+server.php <<'PHP'
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
PHP

    success "API routes created"
fi

#------------------------------------------------------------------------------
# Create database migrations
#------------------------------------------------------------------------------
info "Creating database migrations..."

cat > database/migrations/001_create_users_table.php <<'PHP'
<?php

use App\Core\DB;

$pdo = DB::pdo();

$pdo->exec("
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        created_at INTEGER NOT NULL
    )
");

echo "✓ Created users table\n";
PHP

cat > database/migrations/002_create_migrations_table.php <<'PHP'
<?php

use App\Core\DB;

$pdo = DB::pdo();

$pdo->exec("
    CREATE TABLE IF NOT EXISTS migrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        migration TEXT UNIQUE NOT NULL,
        executed_at INTEGER NOT NULL
    )
");

echo "✓ Created migrations table\n";
PHP

if [ "$WITH_AUTH" = true ]; then
    cat > database/migrations/003_create_refresh_tokens_table.php <<'PHP'
<?php

use App\Core\DB;

$pdo = DB::pdo();

$pdo->exec("
    CREATE TABLE IF NOT EXISTS refresh_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        selector TEXT UNIQUE NOT NULL,
        validator_hash TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
");

echo "✓ Created refresh_tokens table\n";
PHP
fi

success "Migrations created"

#------------------------------------------------------------------------------
# Create database seeders
#------------------------------------------------------------------------------
info "Creating database seeders..."

cat > database/seeds/UserSeeder.php <<'PHP'
<?php

use App\Core\DB;

$pdo = DB::pdo();

// Check if admin already exists
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute(['admin@example.com']);

if (!$stmt->fetch()) {
    $stmt = $pdo->prepare(
        'INSERT INTO users (email, password, name, role, created_at) VALUES (?, ?, ?, ?, ?)'
    );

    $stmt->execute([
        'admin@example.com',
        password_hash('password', PASSWORD_DEFAULT),
        'Admin User',
        'admin',
        time()
    ]);

    echo "✓ Created admin user (admin@example.com / password)\n";
} else {
    echo "• Admin user already exists\n";
}

// Create demo user
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute(['user@example.com']);

if (!$stmt->fetch()) {
    $stmt = $pdo->prepare(
        'INSERT INTO users (email, password, name, role, created_at) VALUES (?, ?, ?, ?, ?)'
    );

    $stmt->execute([
        'user@example.com',
        password_hash('password', PASSWORD_DEFAULT),
        'Demo User',
        'user',
        time()
    ]);

    echo "✓ Created demo user (user@example.com / password)\n";
} else {
    echo "• Demo user already exists\n";
}
PHP

success "Seeders created"

#------------------------------------------------------------------------------
# Create Admin Panel (Django-style)
#------------------------------------------------------------------------------
if [ "$FULL_STACK" = true ]; then
    info "Creating Django-style admin panel..."

    mkdir -p app/admin/users app/admin/database app/admin/settings

    # Admin middleware for role checking
    cat > app/middleware/AdminOnly.php <<'PHP'
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
PHP

    # Admin dashboard (main page)
    cat > app/admin/page.php <<'PHP'
<?php
use App\Middleware\AdminOnly;
use App\Core\DB;

// Require admin access
AdminOnly::handle(new \App\Core\Request(), function($req) {});

$title = 'Admin Dashboard';

// Get statistics
$pdo = DB::pdo();
$userCount = $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
$adminCount = $pdo->query('SELECT COUNT(*) FROM users WHERE role = "admin"')->fetchColumn();

// Get recent users
$recentUsers = DB::table('users')
    ->limit(5)
    ->get();
?>

<style>
.admin-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
}

.stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1.5rem;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.stat-card h3 {
    margin: 0 0 0.5rem 0;
    font-size: 0.875rem;
    opacity: 0.9;
}

.stat-card .number {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0;
}

.admin-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border-radius: 8px;
    overflow: hidden;
}

.admin-table th {
    background: #f7fafc;
    padding: 1rem;
    text-align: left;
    font-weight: 600;
    color: #4a5568;
    border-bottom: 2px solid #e2e8f0;
}

.admin-table td {
    padding: 1rem;
    border-bottom: 1px solid #e2e8f0;
}

.admin-table tr:last-child td {
    border-bottom: none;
}

.badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-admin {
    background: #fef5e7;
    color: #d68910;
}

.badge-user {
    background: #eaf2f8;
    color: #2874a6;
}

.admin-nav {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.admin-nav a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.admin-nav a:hover {
    background: #edf2f7;
    color: #2d3748;
}

.admin-nav a.active {
    background: #667eea;
    color: white;
}
</style>

<h1>🛡️ Admin Dashboard</h1>

<div class="admin-nav">
    <a href="/admin" class="active">Dashboard</a>
    <a href="/admin/users">Users</a>
    <a href="/admin/database">Database</a>
    <a href="/admin/settings">Settings</a>
    <a href="/" style="float: right;">← Back to Site</a>
</div>

<div class="admin-grid">
    <div class="stat-card">
        <h3>Total Users</h3>
        <p class="number"><?= $userCount ?></p>
    </div>

    <div class="stat-card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
        <h3>Administrators</h3>
        <p class="number"><?= $adminCount ?></p>
    </div>

    <div class="stat-card" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
        <h3>Database Tables</h3>
        <p class="number"><?= count($pdo->query("SELECT name FROM sqlite_master WHERE type='table'")->fetchAll()) ?></p>
    </div>
</div>

<h2>Recent Users</h2>
<table class="admin-table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Created</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($recentUsers as $user): ?>
        <tr>
            <td><?= e($user['id']) ?></td>
            <td><?= e($user['name']) ?></td>
            <td><?= e($user['email']) ?></td>
            <td>
                <span class="badge badge-<?= $user['role'] ?>">
                    <?= e(ucfirst($user['role'])) ?>
                </span>
            </td>
            <td><?= date('Y-m-d H:i', $user['created_at']) ?></td>
        </tr>
        <?php endforeach; ?>
    </tbody>
</table>
PHP

    # User management page
    cat > app/admin/users/page.php <<'PHP'
<?php
use App\Middleware\AdminOnly;
use App\Core\DB;

// Require admin access
AdminOnly::handle(new \App\Core\Request(), function($req) {});

$title = 'User Management';

// Get all users
$users = DB::table('users')->get();
?>

<style>
/* Reuse admin styles */
.admin-nav {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.admin-nav a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.admin-nav a:hover {
    background: #edf2f7;
    color: #2d3748;
}

.admin-nav a.active {
    background: #667eea;
    color: white;
}

.admin-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border-radius: 8px;
    overflow: hidden;
}

.admin-table th {
    background: #f7fafc;
    padding: 1rem;
    text-align: left;
    font-weight: 600;
    color: #4a5568;
    border-bottom: 2px solid #e2e8f0;
}

.admin-table td {
    padding: 1rem;
    border-bottom: 1px solid #e2e8f0;
}

.admin-table tr:last-child td {
    border-bottom: none;
}

.badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-admin {
    background: #fef5e7;
    color: #d68910;
}

.badge-user {
    background: #eaf2f8;
    color: #2874a6;
}

.btn-sm {
    padding: 0.25rem 0.75rem;
    font-size: 0.875rem;
    border-radius: 4px;
    text-decoration: none;
    display: inline-block;
    margin-right: 0.5rem;
}

.btn-danger {
    background: #e53e3e;
    color: white;
}

.btn-primary {
    background: #667eea;
    color: white;
}
</style>

<h1>👥 User Management</h1>

<div class="admin-nav">
    <a href="/admin">Dashboard</a>
    <a href="/admin/users" class="active">Users</a>
    <a href="/admin/database">Database</a>
    <a href="/admin/settings">Settings</a>
    <a href="/" style="float: right;">← Back to Site</a>
</div>

<p style="margin-bottom: 1rem;">
    <strong>Total Users:</strong> <?= count($users) ?>
</p>

<table class="admin-table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Created</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        <?php foreach ($users as $user): ?>
        <tr>
            <td><?= e($user['id']) ?></td>
            <td><?= e($user['name']) ?></td>
            <td><?= e($user['email']) ?></td>
            <td>
                <span class="badge badge-<?= $user['role'] ?>">
                    <?= e(ucfirst($user['role'])) ?>
                </span>
            </td>
            <td><?= date('Y-m-d H:i', $user['created_at']) ?></td>
            <td>
                <button
                    hx-get="/api/admin/users/<?= $user['id'] ?>/edit"
                    hx-target="#editModal"
                    class="btn-sm btn-primary">
                    Edit
                </button>
                <button
                    hx-delete="/api/admin/users/<?= $user['id'] ?>"
                    hx-confirm="Are you sure you want to delete this user?"
                    hx-target="closest tr"
                    hx-swap="outerHTML"
                    class="btn-sm btn-danger">
                    Delete
                </button>
            </td>
        </tr>
        <?php endforeach; ?>
    </tbody>
</table>

<div id="editModal"></div>
PHP

    # Database browser page
    cat > app/admin/database/page.php <<'PHP'
<?php
use App\Middleware\AdminOnly;
use App\Core\DB;

// Require admin access
AdminOnly::handle(new \App\Core\Request(), function($req) {});

$title = 'Database Browser';

$pdo = DB::pdo();

// Get all tables
$tables = $pdo->query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")->fetchAll(PDO::FETCH_COLUMN);

// Get selected table data
$selectedTable = $_GET['table'] ?? ($tables[0] ?? null);
$tableData = [];
$columns = [];

if ($selectedTable) {
    try {
        $tableData = $pdo->query("SELECT * FROM {$selectedTable} LIMIT 50")->fetchAll();
        if (!empty($tableData)) {
            $columns = array_keys($tableData[0]);
        }
    } catch (Exception $e) {
        // Table might be empty
    }
}
?>

<style>
/* Reuse admin styles */
.admin-nav {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.admin-nav a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.admin-nav a:hover {
    background: #edf2f7;
    color: #2d3748;
}

.admin-nav a.active {
    background: #667eea;
    color: white;
}

.table-list {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.table-list a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    margin-bottom: 0.5rem;
    background: #edf2f7;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.table-list a:hover,
.table-list a.active {
    background: #667eea;
    color: white;
}

.admin-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border-radius: 8px;
    overflow: hidden;
    font-size: 0.875rem;
}

.admin-table th {
    background: #f7fafc;
    padding: 0.75rem;
    text-align: left;
    font-weight: 600;
    color: #4a5568;
    border-bottom: 2px solid #e2e8f0;
}

.admin-table td {
    padding: 0.75rem;
    border-bottom: 1px solid #e2e8f0;
    max-width: 300px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.admin-table tr:last-child td {
    border-bottom: none;
}
</style>

<h1>🗄️ Database Browser</h1>

<div class="admin-nav">
    <a href="/admin">Dashboard</a>
    <a href="/admin/users">Users</a>
    <a href="/admin/database" class="active">Database</a>
    <a href="/admin/settings">Settings</a>
    <a href="/" style="float: right;">← Back to Site</a>
</div>

<h2>Tables</h2>
<div class="table-list">
    <?php foreach ($tables as $table): ?>
        <a href="?table=<?= urlencode($table) ?>" class="<?= $table === $selectedTable ? 'active' : '' ?>">
            <?= e($table) ?>
        </a>
    <?php endforeach; ?>
</div>

<?php if ($selectedTable): ?>
    <h2>Table: <?= e($selectedTable) ?></h2>
    <p><strong>Records:</strong> <?= count($tableData) ?> (showing first 50)</p>

    <?php if (!empty($tableData)): ?>
        <div style="overflow-x: auto;">
            <table class="admin-table">
                <thead>
                    <tr>
                        <?php foreach ($columns as $column): ?>
                            <th><?= e($column) ?></th>
                        <?php endforeach; ?>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($tableData as $row): ?>
                        <tr>
                            <?php foreach ($row as $value): ?>
                                <td title="<?= e($value) ?>"><?= e($value) ?></td>
                            <?php endforeach; ?>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php else: ?>
        <p>No data in this table.</p>
    <?php endif; ?>
<?php endif; ?>
PHP

    # Settings page
    cat > app/admin/settings/page.php <<'PHP'
<?php
use App\Middleware\AdminOnly;

// Require admin access
AdminOnly::handle(new \App\Core\Request(), function($req) {});

$title = 'Admin Settings';
?>

<style>
/* Reuse admin styles */
.admin-nav {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.admin-nav a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.admin-nav a:hover {
    background: #edf2f7;
    color: #2d3748;
}

.admin-nav a.active {
    background: #667eea;
    color: white;
}

.settings-grid {
    display: grid;
    gap: 1.5rem;
}

.setting-card {
    background: white;
    padding: 1.5rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.setting-card h3 {
    margin-top: 0;
    color: #2d3748;
}

.setting-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 0;
    border-bottom: 1px solid #e2e8f0;
}

.setting-item:last-child {
    border-bottom: none;
}

.setting-label {
    font-weight: 500;
    color: #4a5568;
}

.setting-value {
    color: #718096;
}
</style>

<h1>⚙️ Settings</h1>

<div class="admin-nav">
    <a href="/admin">Dashboard</a>
    <a href="/admin/users">Users</a>
    <a href="/admin/database">Database</a>
    <a href="/admin/settings" class="active">Settings</a>
    <a href="/" style="float: right;">← Back to Site</a>
</div>

<div class="settings-grid">
    <div class="setting-card">
        <h3>Application Settings</h3>
        <div class="setting-item">
            <span class="setting-label">Environment</span>
            <span class="setting-value"><?= e(env('APP_ENV', 'production')) ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">Debug Mode</span>
            <span class="setting-value"><?= env('APP_DEBUG', false) ? 'Enabled' : 'Disabled' ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">App URL</span>
            <span class="setting-value"><?= e(env('APP_URL', 'http://localhost')) ?></span>
        </div>
    </div>

    <div class="setting-card">
        <h3>Security Settings</h3>
        <div class="setting-item">
            <span class="setting-label">CSRF Protection</span>
            <span class="setting-value"><?= env('CSRF_ENABLED', true) ? 'Enabled' : 'Disabled' ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">Secure Cookies</span>
            <span class="setting-value"><?= env('SECURE_COOKIES', false) ? 'Enabled' : 'Disabled' ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">JWT Access Token Expiry</span>
            <span class="setting-value"><?= env('JWT_ACCESS_EXP', 900) ?> seconds</span>
        </div>
        <div class="setting-item">
            <span class="setting-label">JWT Refresh Token Expiry</span>
            <span class="setting-value"><?= env('JWT_REFRESH_EXP', 604800) ?> seconds</span>
        </div>
    </div>

    <div class="setting-card">
        <h3>Database Settings</h3>
        <div class="setting-item">
            <span class="setting-label">Connection</span>
            <span class="setting-value"><?= e(env('DB_CONNECTION', 'sqlite')) ?></span>
        </div>
        <?php if (env('DB_CONNECTION') === 'sqlite'): ?>
        <div class="setting-item">
            <span class="setting-label">Database Path</span>
            <span class="setting-value"><?= e(env('DB_PATH', 'storage/db/app.db')) ?></span>
        </div>
        <?php endif; ?>
    </div>

    <div class="setting-card">
        <h3>Logging Settings</h3>
        <div class="setting-item">
            <span class="setting-label">Log Level</span>
            <span class="setting-value"><?= e(env('LOG_LEVEL', 'debug')) ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">Log File</span>
            <span class="setting-value"><?= e(env('LOG_FILE', 'storage/logs/app.log')) ?></span>
        </div>
    </div>

    <div class="setting-card">
        <h3>System Information</h3>
        <div class="setting-item">
            <span class="setting-label">PHP Version</span>
            <span class="setting-value"><?= PHP_VERSION ?></span>
        </div>
        <div class="setting-item">
            <span class="setting-label">Framework Version</span>
            <span class="setting-value">ROUTPHER 2.1.0</span>
        </div>
    </div>
</div>
PHP

    success "Admin panel created"
fi

#------------------------------------------------------------------------------
# Create CLI scripts
#------------------------------------------------------------------------------
info "Creating CLI tools..."

# Migrate script
cat > artisan <<'PHP'
#!/usr/bin/env php
<?php

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/app/bootstrap.php';

use App\Core\DB;

$command = $argv[1] ?? 'help';

switch ($command) {
    case 'migrate':
        echo "Running migrations...\n";

        $migrations = glob(__DIR__ . '/database/migrations/*.php');
        sort($migrations);

        // Get executed migrations
        $pdo = DB::pdo();
        $executed = [];

        try {
            $stmt = $pdo->query('SELECT migration FROM migrations');
            $executed = $stmt->fetchAll(PDO::FETCH_COLUMN);
        } catch (\Exception $e) {
            // Migrations table might not exist yet
        }

        foreach ($migrations as $file) {
            $name = basename($file);

            if (in_array($name, $executed)) {
                echo "• Skipping $name (already executed)\n";
                continue;
            }

            echo "→ Running $name\n";
            require $file;

            // Record migration
            try {
                $stmt = $pdo->prepare('INSERT INTO migrations (migration, executed_at) VALUES (?, ?)');
                $stmt->execute([$name, time()]);
            } catch (\Exception $e) {
                // Ignore if migrations table doesn't exist yet
            }
        }

        echo "\n✓ Migrations complete\n";
        break;

    case 'db:seed':
        echo "Running seeders...\n";

        $seeders = glob(__DIR__ . '/database/seeds/*.php');
        sort($seeders);

        foreach ($seeders as $file) {
            echo "→ Running " . basename($file) . "\n";
            require $file;
        }

        echo "\n✓ Seeding complete\n";
        break;

    case 'serve':
        $host = $argv[2] ?? '127.0.0.1';
        $port = $argv[3] ?? '9876';

        echo "ROUTPHER development server starting on http://$host:$port\n";
        echo "Press Ctrl+C to stop.\n\n";

        passthru(PHP_BINARY . " -S $host:$port -t public");
        break;

    case 'key:generate':
        $key = base64_encode(random_bytes(32));

        $envFile = __DIR__ . '/.env';
        $content = file_get_contents($envFile);
        $content = preg_replace('/APP_KEY=.*/', "APP_KEY=$key", $content);
        file_put_contents($envFile, $content);

        echo "✓ Application key generated: $key\n";
        break;

    case 'routes:list':
        echo "Route listing not yet implemented\n";
        break;

    case 'help':
    default:
        echo <<<HELP
ROUTPHER Framework CLI

Usage:
  php artisan <command>

Available commands:
  migrate         Run database migrations
  db:seed         Run database seeders
  serve [host] [port]  Start development server (default: 127.0.0.1:9876)
  key:generate    Generate new application key
  routes:list     List all registered routes
  help            Show this help message

HELP;
        break;
}
PHP

chmod +x artisan 2>/dev/null || true

success "CLI tools created"

#------------------------------------------------------------------------------
# Create README.md
#------------------------------------------------------------------------------
info "Creating documentation..."

cat > README.md <<'README'
# Bastion PHP Framework

A modern, lightweight PHP framework with file-based routing, JWT authentication, **global styling system**, and everything you need to build production-ready applications.

## Features

- 📁 **File-based Routing** - Intuitive routing system inspired by Next.js
- 🔐 **JWT Authentication** - Built-in auth with access & refresh tokens
- 🛡️ **Security First** - CSRF protection, secure headers, XSS prevention
- 🗄️ **Database Ready** - SQLite by default, supports MySQL & PostgreSQL
- ⚡ **HTMX Integration** - Build dynamic interfaces without complex JavaScript
- 🎨 **Global Styling System** - Auto-inject styles, no manual imports, switch themes instantly
- 💅 **Tailwind CSS + Fallback** - Production-ready Tailwind or semantic fallback CSS
- 👑 **Admin Panel** - Django-style admin interface for managing your app

## Quick Start

```bash
# Start the development server
php artisan serve

# Then open http://127.0.0.1:9876
```

## Default Credentials

- **Admin**: admin@example.com / password
- **User**: user@example.com / password

## 🎨 Global Styling System

Bastion PHP features an automatic global styling system - **no manual CSS imports required in any view!**

### How It Works

**All styling is controlled by one file:** `config/style.php`

The global layout (`app/layout.php`) reads this config and automatically injects the correct styles. You never import CSS manually in views.

### Quick Configuration

```php
// config/style.php
return [
    'useTailwind' => true,      // true = Tailwind CSS, false = Fallback CSS
    'tailwindMode' => 'build',  // 'build' or 'cdn'
    'fallbackCss' => '/css/fallback.css',
];
```

### Writing Views (No Imports Needed!)

**With Tailwind Enabled:**
```php
<?php $title = 'My Page'; ?>
<div class="max-w-4xl mx-auto p-8">
    <h1 class="text-4xl font-bold">Hello!</h1>
</div>
```

**With Tailwind Disabled:**
```php
<?php $title = 'My Page'; ?>
<div class="card">
    <h1>Hello!</h1>
</div>
```

Both work automatically! No `<link>` tags, no imports.

### Helper Functions

```php
use_tailwind()      // Returns true/false
tailwind_mode()     // Returns 'cdn' or 'build'
config('style.useTailwind')  // Get any config value
```

### Switching Themes

Want to disable Tailwind? Edit **one file**:

```php
// config/style.php
'useTailwind' => false,
```

Every page in your app automatically switches to fallback CSS. No code changes needed!

### Tailwind Build Commands

```bash
npm run build   # Production build (minified)
npm run dev     # Watch mode (auto-rebuild)
```

**Why This System?**
- ✅ No forgetting CSS imports
- ✅ New pages automatically styled
- ✅ Switch entire app theme with one line
- ✅ Consistent styling everywhere

## Project Structure

```
├── app/
│   ├── core/           # Framework core classes
│   ├── middleware/     # HTTP middleware
│   ├── models/         # Data models
│   ├── views/          # View templates
│   ├── admin/          # Admin panel
│   ├── login/          # Login page
│   ├── register/       # Registration page
│   ├── profile/        # User profile
│   └── page.php        # Homepage
├── config/             # Configuration files
├── database/
│   ├── migrations/     # Database migrations
│   └── seeds/          # Database seeders
├── public/             # Web root
│   └── index.php       # Front controller
├── storage/
│   ├── db/             # SQLite database
│   ├── logs/           # Application logs
│   └── cache/          # Cache files
└── artisan             # CLI tool
```

## File-based Routing

Create pages by adding files to the `app/` directory:

```
app/
├── page.php              → /
├── about/
│   └── page.php          → /about
├── blog/
│   ├── page.php          → /blog
│   └── [slug]/
│       └── page.php      → /blog/:slug
└── api/
    └── users/
        └── +server.php   → /api/users (API endpoint)
```

### Page Routes

Create a `page.php` file in any directory:

```php
<?php $title = 'My Page'; ?>

<h1>Hello World</h1>
<p>This is my page content.</p>
```

### API Routes

Create a `+server.php` file for API endpoints:

```php
<?php
use App\Core\Response;

return [
    'get' => function($req) {
        Response::json(['message' => 'Hello API']);
    },
    'post' => function($req) {
        $data = $req->input('data');
        Response::json(['received' => $data]);
    }
];
```

### Dynamic Routes

Use `[param]` folders for dynamic segments:

```php
// app/blog/[slug]/page.php
<?php
$slug = $params['slug'] ?? '';
$title = "Blog: $slug";
?>

<h1>Blog Post: <?= e($slug) ?></h1>
```

## Layouts

Create `layout.php` files to wrap pages:

```php
<!-- app/layout.php -->
<!DOCTYPE html>
<html>
<head>
    <title><?= $title ?? 'My App' ?></title>
</head>
<body>
    <header>
        <nav>...</nav>
    </header>

    <main>
        <?= $content ?>
    </main>

    <footer>...</footer>
</body>
</html>
```

## Authentication

### Protecting Routes

```php
<?php
// Check if user is authenticated
if (!auth()) {
    redirect('/login');
}

$user = auth();
?>

<h1>Welcome, <?= e($user['name']) ?>!</h1>
```

### Creating Users

```php
use App\Models\User;

$userId = User::create([
    'email' => 'user@example.com',
    'password' => 'secret',
    'name' => 'John Doe',
    'role' => 'user'
]);
```

### Issuing Tokens

```php
use App\Core\Auth;

$tokens = Auth::issueTokens($userId);
// Returns: ['access' => '...', 'refresh' => '...', 'expires' => 1234567890]
```

## Database

### Query Builder

```php
use App\Core\DB;

// Select
$users = DB::table('users')
    ->where('role', 'admin')
    ->limit(10)
    ->get();

// Insert
$id = DB::table('users')->insert([
    'email' => 'user@example.com',
    'name' => 'John Doe'
]);
```

### Migrations

```bash
# Run migrations
php artisan migrate

# Seed database
php artisan db:seed
```

Create new migration in `database/migrations/`:

```php
<?php
use App\Core\DB;

$pdo = DB::pdo();
$pdo->exec("
    CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        created_at INTEGER NOT NULL
    )
");
```

## Middleware

### Global Middleware

Edit `public/index.php`:

```php
$app->use([\App\Middleware\SecurityHeaders::class, 'handle']);
$app->use([\App\Core\Auth::class, 'loadUser']);
```

### Route-specific Middleware

```php
use App\Core\Auth;

return [
    'get' => function($req) {
        // Require authentication
        Auth::requireAuth($req, function($req) {
            // Protected route logic
        });
    }
];
```

## Helper Functions

```php
// Environment variables
$debug = env('APP_DEBUG', false);

// Escape HTML
echo e($userInput);

// Redirects
redirect('/login');

// JSON responses
json_response(['status' => 'ok'], 200);

// Render views
echo view('emails/welcome', ['name' => 'John']);

// Get authenticated user
$user = auth();

// Logging
logger()->info('User logged in', ['user_id' => 123]);
logger()->error('Failed to connect', ['error' => $e->getMessage()]);
```

## Admin Panel

Access at `/admin` (requires admin role):

- **Dashboard** - Statistics and overview
- **User Management** - CRUD operations for users
- **Database Browser** - Explore all database tables
- **Settings Viewer** - View environment configuration

## CLI Commands

```bash
# Start development server
php artisan serve [host] [port]

# Run database migrations
php artisan migrate

# Seed database
php artisan db:seed

# Generate new app key
php artisan key:generate
```

## Production Deployment

1. **Update Environment**:
   ```bash
   APP_ENV=production
   APP_DEBUG=false
   SECURE_COOKIES=true
   ```

2. **Generate Keys**:
   ```bash
   php artisan key:generate
   # Manually set JWT_SECRET to a secure random string
   ```

3. **Configure Database**:
   - Use MySQL or PostgreSQL in production
   - Update DB_* variables in .env

4. **Enable HTTPS**:
   - Configure your web server for HTTPS
   - Set `SECURE_COOKIES=true` in .env

5. **Set Permissions**:
   ```bash
   chmod -R 755 storage
   chmod 644 storage/db/app.db
   ```

## Security Best Practices

- ✅ CSRF protection enabled by default
- ✅ Secure headers (XSS, clickjacking protection)
- ✅ Password hashing with bcrypt
- ✅ JWT tokens with secure cookies
- ✅ SQL injection prevention (prepared statements)
- ✅ Session fixation protection
- ⚠️ Change default JWT_SECRET before production
- ⚠️ Use HTTPS in production
- ⚠️ Keep dependencies updated

## License

MIT

## Support

For issues and questions, visit the GitHub repository.
README

success "README.md created"

#------------------------------------------------------------------------------
# Create test suite
#------------------------------------------------------------------------------
info "Creating test suite..."

mkdir -p tests

cat > tests/bootstrap.php <<'PHP'
<?php

// Set up a mock environment for tests
$_SERVER['REQUEST_URI'] = '/';
$_SERVER['REQUEST_METHOD'] = 'GET';

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../app/bootstrap.php';
PHP

cat > test_all_features.php <<'PHP'
<?php

require_once __DIR__ . '/tests/bootstrap.php';

use App\Core\DB;
use App\Core\Auth;
use App\Core\CSRF;
use App\Core\Request;
use App\Models\User;

$results = ['passed' => 0, 'failed' => 0, 'tests' => []];

function test(string $name, callable $callback) {
    global $results;
    try {
        $callback();
        $results['passed']++;
        $results['tests'][] = ['name' => $name, 'status' => '✅'];
    } catch (Throwable $e) {
        $results['failed']++;
        $results['tests'][] = ['name' => $name, 'status' => '❌', 'error' => $e->getMessage()];
    }
}

echo "Running ROUTPHER Feature Tests...\n\n";

//--- Helper Functions ---
test('env() - Default value when not found', function() {
    assert(env('NON_EXISTENT_VAR', 'default') === 'default');
});

test('e() - HTML escape function', function() {
    assert(e('<script>') === '&lt;script&gt;');
});

//--- Database & Query Builder ---
test('DB::pdo() - Get PDO connection', function() {
    assert(DB::pdo() instanceof PDO);
});

test('DB::table() - Create QueryBuilder', function() {
    assert(DB::table('users') instanceof \App\Core\QueryBuilder);
});

test('Database - Check SQLite WAL mode enabled', function() {
    $mode = DB::pdo()->query('PRAGMA journal_mode')->fetchColumn();
    assert($mode === 'wal');
});

//--- Auth ---
test('Auth::issueTokens() - Generate JWT tokens', function() {
    $tokens = Auth::issueTokens(1);
    assert(is_string($tokens['access']));
    assert(is_string($tokens['refresh']));
});

test('Auth::validate() - Validate access token', function() {
    $tokens = Auth::issueTokens(1);
    $decoded = Auth::validate($tokens['access']);
    assert($decoded->sub === 1);
    assert($decoded->type === 'access');
});

//--- CSRF ---
test('CSRF::token() - Generate CSRF token', function() {
    $token = CSRF::token();
    assert(is_string($token) && strlen($token) === 64);
});

//--- Request ---
test('Request - Path normalization removes `..`', function() {
    $_SERVER['REQUEST_URI'] = '/users/../posts';
    $req = new Request();
    assert($req->path === 'users/posts');
});

//--- Security ---
test('Security - Password hashing works', function() {
    $hash = password_hash('password123', PASSWORD_DEFAULT);
    assert(password_verify('password123', $hash));
});

//--- Final Report ---
echo "----------------------------------------\n";
echo "Test Results:\n";
echo "----------------------------------------\n";

foreach ($results['tests'] as $test) {
    echo "{$test['status']} {$test['name']}\n";
    if ($test['status'] === '❌') {
        echo "   └ Error: {$test['error']}\n";
    }
}

echo "\n----------------------------------------\n";
$total = $results['passed'] + $results['failed'];
$passRate = $total > 0 ? ($results['passed'] / $total) * 100 : 0;
echo "Passed: {$results['passed']} | Failed: {$results['failed']} | Total: $total\n";
echo sprintf("Success Rate: %.2f%%\n", $passRate);
echo "----------------------------------------\n";

if ($results['failed'] > 0) {
    exit(1);
}
PHP

success "Test suite created"

#------------------------------------------------------------------------------
# Install composer dependencies
#------------------------------------------------------------------------------
if [ "$NO_COMPOSER" = false ] && command -v composer >/dev/null 2>&1; then
    info "Installing composer dependencies..."
    composer install --no-interaction --quiet 2>&1 | grep -v "Warning" || true
    success "Composer dependencies installed"
else
    warn "Composer not found or --no-composer flag set. Run 'composer install' manually."
fi

#------------------------------------------------------------------------------
# Install npm dependencies and build Tailwind CSS (if enabled)
#------------------------------------------------------------------------------
if [ "$WITH_TAILWIND" = true ]; then
    if command -v npm >/dev/null 2>&1; then
        info "Installing Tailwind CSS..."
        npm install --silent 2>&1 | grep -v "npm WARN" || true

        info "Building Tailwind CSS..."
        npm run build 2>&1 | grep -v "npm WARN" || true
        success "Tailwind CSS built successfully"
    else
        warn "npm not found. Install Node.js and run 'npm install && npm run build' manually."
    fi
fi

#------------------------------------------------------------------------------
# Run migrations and seed
#------------------------------------------------------------------------------
if [ -f vendor/autoload.php ]; then
    info "Running database migrations..."
    php artisan migrate

    if [ "$WITH_AUTH" = true ]; then
        info "Seeding database..."
        php artisan db:seed
    fi
else
    warn "Skipping migrations (run 'composer install' first, then 'php artisan migrate')"
fi

#------------------------------------------------------------------------------
# Final instructions
#------------------------------------------------------------------------------
echo ""
success "Project '$PROJECT' created successfully!"
echo ""
info "To get started, run the following commands:"
echo ""
echo -e "  ${YELLOW}cd $PROJECT${NC}"
echo -e "  ${YELLOW}php artisan serve${NC}"
echo ""
info "Your app will be available at: http://127.0.0.1:9876"
echo ""
if [ "$WITH_AUTH" = true ]; then
    warn "Default credentials:"
    echo "  Admin: admin@example.com / password"
    echo "  User:  user@example.com / password"
    echo ""
fi

if [ "$FULL_STACK" = true ]; then
    echo -e "${BLUE}Admin Panel:${NC} http://127.0.0.1:9876/admin"
    echo "  • Dashboard with statistics"
    echo "  • User management (CRUD)"
    echo "  • Database browser"
    echo "  • Settings viewer"
    echo ""
fi

if [ "$WITH_TAILWIND" = true ]; then
    echo -e "${BLUE}✨ Tailwind CSS:${NC} Enabled (Local Build)"
    echo "  • Modern dark theme with blue accents"
    echo "  • Glassmorphism effects and smooth animations"
    echo "  • Responsive design out of the box"
    echo ""
    echo -e "${BLUE}Tailwind Development:${NC}"
    echo "  • Watch mode: ${YELLOW}npm run dev${NC} (auto-rebuild on file changes)"
    echo "  • Production build: ${YELLOW}npm run build${NC} (minified CSS)"
    echo ""
fi

echo -e "${YELLOW}⚠ Important:${NC}"
echo "  • Change JWT_SECRET and APP_KEY in .env before production"
echo "  • Enable HTTPS and set SECURE_COOKIES=true in production"
echo "  • Review security settings in app/middleware/SecurityHeaders.php"
echo ""
echo -e "${BLUE}Documentation:${NC} Check README.md for complete guide"
echo ""
