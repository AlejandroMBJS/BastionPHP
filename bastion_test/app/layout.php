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
