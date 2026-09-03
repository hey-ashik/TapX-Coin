<?php
// api/v1/wallet/request-payout.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$token = getBearerToken();
if (!$token) {
    jsonError('Authorization token required', 401);
}

$db = Database::getConnection();
$stmt = $db->prepare("SELECT id, score FROM users WHERE auth_token = :token LIMIT 1");
$stmt->execute([':token' => $token]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Unauthorized user', 401);
}

$input = getJsonInput();
$amount = isset($input['amount']) ? (float)$input['amount'] : 0.0;
$currency = strtolower(isset($input['currency']) ? trim($input['currency']) : 'bdt');
$method = isset($input['method']) ? trim($input['method']) : 'bKash';
$accountName = isset($input['account_name']) ? trim($input['account_name']) : '';
$destination = isset($input['destination']) ? trim($input['destination']) : '';

if ($amount <= 0) {
    jsonError('Invalid payout amount', 422);
}

if (empty($destination)) {
    jsonError('Recipient account number or details required', 422);
}

// 10,000 taps = 10 BDT (1,000 taps = 1 BDT)
// 100,000 taps = $1.00 USD
$tapsDeducted = $currency === 'bdt' ? (int)($amount * 1000) : (int)($amount * 100000);

if ($tapsDeducted > (int)$user['score']) {
    jsonError('Insufficient tap balance for this withdrawal request', 400);
}

$txId = 'TX-' . substr(strval(time()), -5) . strtoupper(bin2hex(random_bytes(2)));

// Deduct score and insert transaction atomically
$db->beginTransaction();

try {
    $deductStmt = $db->prepare("UPDATE users SET score = score - :taps, updated_at = NOW() WHERE id = :id");
    $deductStmt->execute([':taps' => $tapsDeducted, ':id' => $user['id']]);

    $insertTx = $db->prepare("
        INSERT INTO transactions (id, user_id, amount, currency, taps_deducted, method, account_name, destination, status)
        VALUES (:id, :user_id, :amount, :currency, :taps, :method, :name, :destination, 'processing')
    ");
    $insertTx->execute([
        ':id'          => $txId,
        ':user_id'     => $user['id'],
        ':amount'      => $amount,
        ':currency'    => $currency,
        ':taps'        => $tapsDeducted,
        ':method'      => $method,
        ':name'        => $accountName,
        ':destination' => $destination,
    ]);

    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
    jsonError('Failed to process withdrawal request: ' . $e->getMessage(), 500);
}

jsonSuccess([
    'transaction_id' => $txId,
    'amount'         => $amount,
    'currency'       => $currency,
    'taps_deducted'  => $tapsDeducted,
    'method'         => $method,
    'account_name'   => $accountName,
    'destination'    => $destination,
    'status'         => 'processing',
    'created_at'     => date('Y-m-d H:i:s'),
], 'Payout request submitted successfully. Awaiting confirmation (1-24h).');
