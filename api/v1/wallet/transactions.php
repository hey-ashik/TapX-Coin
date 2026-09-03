<?php
// api/v1/wallet/transactions.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

$token = getBearerToken();
if (!$token) {
    jsonError('Authorization token required', 401);
}

$db = Database::getConnection();
$stmt = $db->prepare("SELECT id FROM users WHERE auth_token = :token LIMIT 1");
$stmt->execute([':token' => $token]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Unauthorized user', 401);
}

$txStmt = $db->prepare("
    SELECT id, amount, currency, taps_deducted, method, account_name, destination, status, created_at
    FROM transactions
    WHERE user_id = :uid
    ORDER BY created_at DESC
");
$txStmt->execute([':uid' => $user['id']]);
$rows = $txStmt->fetchAll();

$transactions = [];
foreach ($rows as $row) {
    $transactions[] = [
        'id'            => $row['id'],
        'amount'        => (float)$row['amount'],
        'currency'      => $row['currency'],
        'taps_deducted' => (int)$row['taps_deducted'],
        'method'        => $row['method'],
        'account_name'  => $row['account_name'] ?? '',
        'destination'   => $row['destination'],
        'status'        => $row['status'],
        'created_at'    => $row['created_at'],
    ];
}

jsonSuccess([
    'transactions' => $transactions,
    'total'        => count($transactions),
], 'Transactions retrieved successfully');
