<?php
use App\Core\DB;

$title = 'Database Browser';

$pdo = DB::pdo();

// Get all tables
$tables = $pdo->query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")->fetchAll(PDO::FETCH_COLUMN);

// Get selected table data
$selectedTable = $_GET['table'] ?? ($tables[0] ?? null);
$tableData = [];
$columns = [];

if ($selectedTable) {
    try {
        $tableData = $pdo->query("SELECT * FROM {$selectedTable} LIMIT 50")->fetchAll();
        if (!empty($tableData)) {
            $columns = array_keys($tableData[0]);
        }
    } catch (Exception $e) {
        // Table might be empty
    }
}
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-white mb-6">🗄️ Database Browser</h1>

    <div class="bg-gray-800 rounded-lg shadow-lg p-4 mb-6 flex space-x-4">
        <a href="/admin" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Dashboard</a>
        <a href="/admin/users" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Users</a>
        <a href="/admin/database" class="px-4 py-2 rounded-md bg-blue-600 text-white font-medium">Database</a>
        <a href="/admin/settings" class="px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">Settings</a>
        <a href="/" class="ml-auto px-4 py-2 rounded-md text-gray-300 hover:bg-gray-700 hover:text-white">← Back to Site</a>
    </div>

    <h2 class="text-2xl font-bold text-white mb-4">Tables</h2>
    <div class="bg-gray-800 rounded-lg shadow-lg p-4 mb-6 flex flex-wrap gap-2">
        <?php foreach ($tables as $table): ?>
            <a href="?table=<?= urlencode($table) ?>" class="px-4 py-2 rounded-md <?= $table === $selectedTable ? 'bg-blue-600 text-white' : 'bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-white' ?>">
                <?= e($table) ?>
            </a>
        <?php endforeach; ?>
    </div>

    <?php if ($selectedTable): ?>
        <h2 class="text-2xl font-bold text-white mb-4">Table: <?= e($selectedTable) ?></h2>
        <p class="text-gray-300 mb-4"><strong>Records:</strong> <?= count($tableData) ?> (showing first 50)</p>

        <?php if (!empty($tableData)): ?>
            <div class="bg-gray-800 rounded-lg shadow-md overflow-x-auto">
                <table class="min-w-full leading-normal">
                    <thead>
                        <tr>
                            <?php foreach ($columns as $column): ?>
                                <th class="px-5 py-3 border-b-2 border-gray-700 bg-gray-700 text-left text-xs font-semibold text-gray-300 uppercase tracking-wider">
                                    <?= e($column) ?>
                                </th>
                            <?php endforeach; ?>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($tableData as $row): ?>
                            <tr>
                                <?php foreach ($row as $value): ?>
                                    <td class="px-5 py-5 border-b border-gray-700 bg-gray-900 text-sm text-white" title="<?= e($value) ?>">
                                        <?= e($value) ?>
                                    </td>
                                <?php endforeach; ?>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php else: ?>
            <p class="text-gray-300">No data in this table.</p>
        <?php endif; ?>
    <?php endif; ?>
</div>
