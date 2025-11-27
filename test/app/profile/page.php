<?php
// Require authentication
if (!isset($GLOBALS['auth_user'])) {
    redirect('/login');
}

$user = $GLOBALS['auth_user'];
$title = 'Profile';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <div class="mb-8">
        <h1 class="text-4xl font-bold mb-2 bg-gradient-to-r from-white to-blue-400 bg-clip-text text-transparent">
            Your Profile
        </h1>
        <p class="text-gray-400">Manage your account information</p>
    </div>

    <div class="grid lg:grid-cols-3 gap-8">
        <!-- Profile Card -->
        <div class="lg:col-span-2">
            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-8 shadow-2xl">
                <!-- Avatar Section -->
                <div class="flex items-center space-x-6 mb-8 pb-8 border-b border-white/10">
                    <div class="w-24 h-24 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-3xl font-bold">
                        <?= strtoupper(substr($user['name'], 0, 1)) ?>
                    </div>
                    <div>
                        <h2 class="text-2xl font-bold text-white mb-1"><?= e($user['name']) ?></h2>
                        <p class="text-gray-400"><?= e($user['email']) ?></p>
                        <span class="inline-block mt-2 px-3 py-1 rounded-full text-xs font-semibold <?= $user['role'] === 'admin' ? 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20' : 'bg-blue-500/10 text-blue-400 border border-blue-500/20' ?>">
                            <?= ucfirst(e($user['role'])) ?>
                        </span>
                    </div>
                </div>

                <!-- Account Details -->
                <div class="space-y-6">
                    <h3 class="text-xl font-semibold mb-4">Account Details</h3>

                    <div class="grid md:grid-cols-2 gap-6">
                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Full Name</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= e($user['name']) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Email Address</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= e($user['email']) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Role</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= ucfirst(e($user['role'])) ?>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-400 mb-2">Member Since</label>
                            <div class="px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white">
                                <?= date('F j, Y', $user['created_at']) ?>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Actions -->
        <div class="space-y-6">
            <?php if ($user['role'] === 'admin'): ?>
            <div class="bg-gradient-to-br from-yellow-500/10 to-yellow-600/10 backdrop-blur-xl rounded-2xl border border-yellow-500/20 p-6 shadow-2xl">
                <div class="flex items-center mb-4">
                    <div class="w-12 h-12 rounded-xl bg-gradient-to-r from-yellow-500 to-yellow-600 flex items-center justify-center text-2xl mr-4">
                        👑
                    </div>
                    <div>
                        <h3 class="font-semibold text-white">Admin Panel</h3>
                        <p class="text-sm text-gray-400">Manage your app</p>
                    </div>
                </div>
                <a href="/admin" class="block w-full py-2 px-4 bg-yellow-500/20 hover:bg-yellow-500/30 rounded-lg text-center font-medium text-yellow-400 transition-all">
                    Open Admin Panel
                </a>
            </div>
            <?php endif; ?>

            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-6 shadow-2xl">
                <h3 class="font-semibold text-white mb-4">Quick Actions</h3>
                <div class="space-y-3">
                    <a href="/logout" class="block w-full py-2 px-4 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 rounded-lg text-center font-medium text-red-400 transition-all">
                        Sign Out
                    </a>
                </div>
            </div>

            <div class="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 p-6 shadow-2xl">
                <h3 class="font-semibold text-white mb-2">Account Status</h3>
                <div class="flex items-center text-green-400">
                    <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                    </svg>
                    Active
                </div>
            </div>
        </div>
    </div>
</div>
