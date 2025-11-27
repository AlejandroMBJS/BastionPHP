<?php

use App\Core\DB;

$pdo = DB::pdo();

$pdo->exec("
    CREATE TABLE IF NOT EXISTS refresh_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        selector TEXT UNIQUE NOT NULL,
        validator_hash TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
");

echo "✓ Created refresh_tokens table\n";
