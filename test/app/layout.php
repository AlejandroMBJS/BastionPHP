<!doctype html>
<html lang="en" class="dark">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= $title ?? 'ROUTPHER App' ?></title>
    <link rel="stylesheet" href="/css/app.css">
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>
</head>
<body class="bg-black text-white antialiased">
    <!-- Navigation -->
    <nav class="fixed w-full top-0 z-50 bg-black/80 backdrop-blur-xl border-b border-white/10">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <div class="flex items-center space-x-8">
                    <a href="/" class="text-xl font-bold bg-gradient-to-r from-blue-400 to-blue-600 bg-clip-text text-transparent">
                        ROUTPHER
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
                <p>&copy; <?= date('Y') ?> ROUTPHER. Built with PHP & Tailwind CSS.</p>
            </div>
        </div>
    </footer>
</body>
</html>
