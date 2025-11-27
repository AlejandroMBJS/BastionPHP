<?php
use App\Middleware\AdminOnly;
use App\Core\DB;

// Require admin access
AdminOnly::handle(new \App\Core\Request(), function($req) {});

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

.table-list {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
}

.table-list a {
    display: inline-block;
    padding: 0.5rem 1rem;
    margin-right: 0.5rem;
    margin-bottom: 0.5rem;
    background: #edf2f7;
    color: #4a5568;
    text-decoration: none;
    border-radius: 4px;
    transition: all 0.2s;
}

.table-list a:hover,
.table-list a.active {
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
    font-size: 0.875rem;
}

.admin-table th {
    background: #f7fafc;
    padding: 0.75rem;
    text-align: left;
    font-weight: 600;
    color: #4a5568;
    border-bottom: 2px solid #e2e8f0;
}

.admin-table td {
    padding: 0.75rem;
    border-bottom: 1px solid #e2e8f0;
    max-width: 300px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.admin-table tr:last-child td {
    border-bottom: none;
}
</style>

<h1>🗄️ Database Browser</h1>

<div class="admin-nav">
    <a href="/admin">Dashboard</a>
    <a href="/admin/users">Users</a>
    <a href="/admin/database" class="active">Database</a>
    <a href="/admin/settings">Settings</a>
    <a href="/" style="float: right;">← Back to Site</a>
</div>

<h2>Tables</h2>
<div class="table-list">
    <?php foreach ($tables as $table): ?>
        <a href="?table=<?= urlencode($table) ?>" class="<?= $table === $selectedTable ? 'active' : '' ?>">
            <?= e($table) ?>
        </a>
    <?php endforeach; ?>
</div>

<?php if ($selectedTable): ?>
    <h2>Table: <?= e($selectedTable) ?></h2>
    <p><strong>Records:</strong> <?= count($tableData) ?> (showing first 50)</p>

    <?php if (!empty($tableData)): ?>
        <div style="overflow-x: auto;">
            <table class="admin-table">
                <thead>
                    <tr>
                        <?php foreach ($columns as $column): ?>
                            <th><?= e($column) ?></th>
                        <?php endforeach; ?>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($tableData as $row): ?>
                        <tr>
                            <?php foreach ($row as $value): ?>
                                <td title="<?= e($value) ?>"><?= e($value) ?></td>
                            <?php endforeach; ?>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php else: ?>
        <p>No data in this table.</p>
    <?php endif; ?>
<?php endif; ?>
