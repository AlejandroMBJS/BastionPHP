# ROUTPHER Framework

A modern, lightweight PHP framework with file-based routing, JWT authentication, and everything you need to build production-ready applications.

## Features

- 📁 **File-based Routing** - Intuitive routing system inspired by Next.js
- 🔐 **JWT Authentication** - Built-in auth with access & refresh tokens
- 🛡️ **Security First** - CSRF protection, secure headers, XSS prevention
- 🗄️ **Database Ready** - SQLite by default, supports MySQL & PostgreSQL
- ⚡ **HTMX Integration** - Build dynamic interfaces without complex JavaScript
- 🎨 **Modern UI** - Optional Tailwind CSS for production-ready designs
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
