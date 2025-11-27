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
    <?php else: ?>
        <!-- Fallback Navigation -->
        <header>
            <nav>
                <div class="container">
                    <a href="/">Bastion PHP</a>
                    <div>
                        <a href="/">Home</a>
                        <?php if (isset($GLOBALS['auth_user'])): ?>
                            <?php if ($GLOBALS['auth_user']['role'] === 'admin'): ?>
                                <a href="/admin">Admin</a>
                            <?php endif; ?>
                            <a href="/profile"><?= e($GLOBALS['auth_user']['name']) ?></a>
                            <a href="/logout">Logout</a>
                        <?php else: ?>
                            <a href="/login">Login</a>
                            <a href="/register">Register</a>
                        <?php endif; ?>
                    </div>
                </div>
            </nav>
        </header>
    <?php endif; ?>

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
