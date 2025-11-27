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
