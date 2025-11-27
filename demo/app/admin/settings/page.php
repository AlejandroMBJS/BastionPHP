<?php

$title = 'Admin Settings';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-white mb-6">⚙️ Settings</h1>

    <div class="bg-gray-800 rounded-lg shadow-lg p-4 mb-6 flex space-x-4">
        <a href="/admin" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Dashboard</a>
        <a href="/admin/users" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Users</a>
        <a href="/admin/database" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Database</a>
        <a href="/admin/settings" class="px-4 py-2 rounded-md bg-blue-600 text-white font-medium">Settings</a>
        <a href="/" class="ml-auto px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">← Back to Site</a>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-xl font-semibold text-white mb-4">Application Settings</h3>
            <div class="space-y-4">
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">Environment</span>
                    <span class="text-white"><?= e(env('APP_ENV', 'production')) ?></span>
                </div>
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">Debug Mode</span>
                    <span class="text-white"><?= env('APP_DEBUG', false) ? 'Enabled' : 'Disabled' ?></span>
                </div>
                <div class="flex justify-between items-center">
                    <span class="text-gray-300 font-medium">App URL</span>
                    <span class="text-white"><?= e(env('APP_URL', 'http://localhost')) ?></span>
                </div>
            </div>
        </div>

        <div class="bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-xl font-semibold text-white mb-4">Security Settings</h3>
            <div class="space-y-4">
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">CSRF Protection</span>
                    <span class="text-white"><?= env('CSRF_ENABLED', true) ? 'Enabled' : 'Disabled' ?></span>
                </div>
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">Secure Cookies</span>
                    <span class="text-white"><?= env('SECURE_COOKIES', false) ? 'Enabled' : 'Disabled' ?></span>
                </div>
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">JWT Access Token Expiry</span>
                    <span class="text-white"><?= env('JWT_ACCESS_EXP', 900) ?> seconds</span>
                </div>
                <div class="flex justify-between items-center">
                    <span class="text-gray-300 font-medium">JWT Refresh Token Expiry</span>
                    <span class="text-white"><?= env('JWT_REFRESH_EXP', 604800) ?> seconds</span>
                </div>
            </div>
        </div>

        <div class="bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-xl font-semibold text-white mb-4">Database Settings</h3>
            <div class="space-y-4">
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">Connection</span>
                    <span class="text-white"><?= e(env('DB_CONNECTION', 'sqlite')) ?></span>
                </div>
                <?php if (env('DB_CONNECTION') === 'sqlite'): ?>
                <div class="flex justify-between items-center">
                    <span class="text-gray-300 font-medium">Database Path</span>
                    <span class="text-white"><?= e(env('DB_PATH', 'storage/db/app.db')) ?></span>
                </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-xl font-semibold text-white mb-4">Logging Settings</h3>
            <div class="space-y-4">
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">Log Level</span>
                    <span class="text-white"><?= e(env('LOG_LEVEL', 'debug')) ?></span>
                </div>
                <div class="flex justify-between items-center">
                    <span class="text-gray-300 font-medium">Log File</span>
                    <span class="text-white"><?= e(env('LOG_FILE', 'storage/logs/app.log')) ?></span>
                </div>
            </div>
        </div>

        <div class="bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-xl font-semibold text-white mb-4">System Information</h3>
            <div class="space-y-4">
                <div class="flex justify-between items-center border-b border-gray-700 pb-2">
                    <span class="text-gray-300 font-medium">PHP Version</span>
                    <span class="text-white"><?= PHP_VERSION ?></span>
                </div>
                <div class="flex justify-between items-center">
                    <span class="text-gray-300 font-medium">Framework Version</span>
                    <span class="text-white">Bastion PHP 2.1.0</span>
                </div>
            </div>
        </div>
    </div>
</div>
