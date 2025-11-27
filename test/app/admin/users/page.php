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
