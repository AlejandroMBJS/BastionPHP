<?php
use App\Core\DB;

$title = 'User Management';

// Get all users
$users = DB::table('users')->get();
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-white mb-6">👥 User Management</h1>

    <div class="bg-gray-800 rounded-lg shadow-lg p-4 mb-6 flex space-x-4">
        <a href="/admin" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Dashboard</a>
        <a href="/admin/users" class="px-4 py-2 rounded-md bg-blue-600 text-white font-medium">Users</a>
        <a href="/admin/database" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Database</a>
        <a href="/admin/settings" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Settings</a>
        <a href="/" class="ml-auto px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">← Back to Site</a>
    </div>

    <p class="text-gray-300 mb-4">
        <strong>Total Users:</strong> <?= count($users) ?>
    </p>

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
                    <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                        Actions
                    </th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($users as $user): ?>
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
                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white">
                        <button
                            hx-get="/api/admin/users/<?= $user['id'] ?>/edit"
                            hx-target="#editModal"
                            class="px-3 py-1 rounded-md bg-blue-600 hover:bg-blue-700 text-white text-xs font-medium mr-2">
                            Edit
                        </button>
                        <button
                            hx-delete="/api/admin/users/<?= $user['id'] ?>"
                            hx-confirm="Are you sure you want to delete this user?"
                            hx-target="closest tr"
                            hx-swap="outerHTML"
                            class="px-3 py-1 rounded-md bg-red-600 hover:bg-red-700 text-white text-xs font-medium">
                            Delete
                        </button>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <div id="editModal"></div>
</div>
