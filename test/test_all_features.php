<?php

require_once __DIR__ . '/tests/bootstrap.php';

use App\Core\DB;
use App\Core\Auth;
use App\Core\CSRF;
use App\Core\Request;
use App\Models\User;

$results = ['passed' => 0, 'failed' => 0, 'tests' => []];

function test(string $name, callable $callback) {
    global $results;
    try {
        $callback();
        $results['passed']++;
        $results['tests'][] = ['name' => $name, 'status' => '✅'];
    } catch (Throwable $e) {
        $results['failed']++;
        $results['tests'][] = ['name' => $name, 'status' => '❌', 'error' => $e->getMessage()];
    }
}

echo "Running ROUTPHER Feature Tests...\n\n";

//--- Helper Functions ---
test('env() - Default value when not found', function() {
    assert(env('NON_EXISTENT_VAR', 'default') === 'default');
});

test('e() - HTML escape function', function() {
    assert(e('<script>') === '&lt;script&gt;');
});

//--- Database & Query Builder ---
test('DB::pdo() - Get PDO connection', function() {
    assert(DB::pdo() instanceof PDO);
});

test('DB::table() - Create QueryBuilder', function() {
    assert(DB::table('users') instanceof \App\Core\QueryBuilder);
});

test('Database - Check SQLite WAL mode enabled', function() {
    $mode = DB::pdo()->query('PRAGMA journal_mode')->fetchColumn();
    assert($mode === 'wal');
});

//--- Auth ---
test('Auth::issueTokens() - Generate JWT tokens', function() {
    $tokens = Auth::issueTokens(1);
    assert(is_string($tokens['access']));
    assert(is_string($tokens['refresh']));
});

test('Auth::validate() - Validate access token', function() {
    $tokens = Auth::issueTokens(1);
    $decoded = Auth::validate($tokens['access']);
    assert($decoded->sub === 1);
    assert($decoded->type === 'access');
});

//--- CSRF ---
test('CSRF::token() - Generate CSRF token', function() {
    $token = CSRF::token();
    assert(is_string($token) && strlen($token) === 64);
});

//--- Request ---
test('Request - Path normalization removes `..`', function() {
    $_SERVER['REQUEST_URI'] = '/users/../posts';
    $req = new Request();
    assert($req->path === 'users/posts');
});

//--- Security ---
test('Security - Password hashing works', function() {
    $hash = password_hash('password123', PASSWORD_DEFAULT);
    assert(password_verify('password123', $hash));
});

//--- Final Report ---
echo "----------------------------------------\n";
echo "Test Results:\n";
echo "----------------------------------------\n";

foreach ($results['tests'] as $test) {
    echo "{$test['status']} {$test['name']}\n";
    if ($test['status'] === '❌') {
        echo "   └ Error: {$test['error']}\n";
    }
}

echo "\n----------------------------------------\n";
$total = $results['passed'] + $results['failed'];
$passRate = $total > 0 ? ($results['passed'] / $total) * 100 : 0;
echo "Passed: {$results['passed']} | Failed: {$results['failed']} | Total: $total\n";
echo sprintf("Success Rate: %.2f%%\n", $passRate);
echo "----------------------------------------\n";

if ($results['failed'] > 0) {
    exit(1);
}
