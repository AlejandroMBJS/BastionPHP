<?php
use App\Core\DB;

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

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-white mb-6">🛡️ Admin Dashboard</h1>

    <div class="bg-gray-800 rounded-lg shadow-lg p-4 mb-6 flex space-x-4">
        <a href="/admin" class="px-4 py-2 rounded-md bg-blue-600 text-white font-medium">Dashboard</a>
        <a href="/admin/users" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Users</a>
        <a href="/admin/database" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Database</a>
        <a href="/admin/settings" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Settings</a>
        <a href="/" class="ml-auto px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">← Back to Site</a>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg shadow-md p-6 text-white">
            <h3 class="text-sm font-semibold opacity-90 mb-2">Total Users</h3>
            <p class="text-4xl font-bold"><?= $userCount ?></p>
        </div>

        <div class="bg-gradient-to-r from-pink-500 to-red-600 rounded-lg shadow-md p-6 text-white">
            <h3 class="text-sm font-semibold opacity-90 mb-2">Administrators</h3>
            <p class="text-4xl font-bold"><?= $adminCount ?></p>
        </div>

        <div class="bg-gradient-to-r from-green-500 to-teal-600 rounded-lg shadow-md p-6 text-white">
            <h3 class="text-sm font-semibold opacity-90 mb-2">Database Tables</h3>
            <p class="text-4xl font-bold"><?= count($pdo->query("SELECT name FROM sqlite_master WHERE type='table'")->fetchAll()) ?></p>
        </div>
    </div>

    <h2 class="text-2xl font-bold text-white mb-4">Recent Users</h2>
    <div class="bg-gray-800 rounded-lg shadow-md overflow-hidden">
        <table class="min-w-full leading-normal">
            <thead>
                <tr>
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        ID
                    </th>
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        Name
                    </th>
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        Email
                    </th>
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        Role
                    </th>
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        Created
                    </th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($recentUsers as $user): ?>
                <tr>
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <?= e($user['id']) ?>
                    </td>
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <?= e($user['name']) ?>
                    </td>
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <?= e($user['email']) ?>
                    </td>
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <span class="relative inline-block px-3 py-1 font-semibold text-green-900 leading-tight">
                            <span aria-hidden class="absolute inset-0 <?= $user['role'] === 'admin' ? 'bg-yellow-200' : 'bg-blue-200' ?> opacity-50 rounded-full"></span>
                            <span class="relative text-<?= $user['role'] === 'admin' ? 'yellow' : 'blue' ?>-800"><?= e(ucfirst($user['role'])) ?></span>
                        </span>
                    </td>
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <?= date('Y-m-d H:i', $user['created_at']) ?>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
