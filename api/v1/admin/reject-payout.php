<?php
// api/v1/admin/reject-payout.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$txId = isset($input['transaction_id']) ? trim($input['transaction_id']) : '';
$reason = isset($input['reason']) ? trim($input['reason']) : 'Incorrect payment details or account unverified';

if (empty($txId)) {
    jsonError('Transaction ID is required', 422);
}

$db = Database::getConnection();

$stmt = $db->prepare("SELECT * FROM transactions WHERE id = :tx_id LIMIT 1");
$stmt->execute([':tx_id' => $txId]);
$tx = $stmt->fetch();

if (!$tx) {
    jsonError('Transaction not found', 404);
}

if ($tx['status'] !== 'processing') {
    jsonError('Only processing transactions can be rejected/refunded', 400);
}

$db->beginTransaction();

try {
    // 1. Refund taps balance to user
    $refundStmt = $db->prepare("UPDATE users SET score = score + :taps, updated_at = NOW() WHERE id = :uid");
    $refundStmt->execute([
        ':taps' => (int)$tx['taps_deducted'],
        ':uid'  => $tx['user_id'],
    ]);

    // 2. Mark transaction rejected
    $updateTx = $db->prepare("
        UPDATE transactions 
        SET status = 'rejected', admin_notes = :reason, updated_at = NOW() 
        WHERE id = :tx_id
    ");
    $updateTx->execute([
        ':reason' => $reason,
        ':tx_id'  => $txId,
    ]);

    // 3. Send in-app notification
    $notifTitle = "Withdrawal Request Refunded";
    $notifMessage = "Your payout of {$tx['amount']} {$tx['currency']} could not be completed ($reason). Your {$tx['taps_deducted']} taps have been fully refunded to your balance.";

    $insertNotif = $db->prepare("
        INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
        VALUES (:uid, :title, :msg, 'payout_rejected', 0, NOW())
    ");
    $insertNotif->execute([
        ':uid'   => $tx['user_id'],
        ':title' => $notifTitle,
        ':msg'   => $notifMessage,
    ]);

    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
    jsonError('Failed to reject transaction: ' . $e->getMessage(), 500);
}

jsonSuccess([
    'transaction_id' => $txId,
    'status'         => 'rejected',
    'taps_refunded'  => (int)$tx['taps_deducted'],
], 'Payout rejected and taps refunded to user.');
