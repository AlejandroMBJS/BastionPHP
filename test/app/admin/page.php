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
