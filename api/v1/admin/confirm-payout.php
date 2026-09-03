<?php
// api/v1/admin/confirm-payout.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/services/mail_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$txId = isset($input['transaction_id']) ? trim($input['transaction_id']) : '';
$adminNotes = isset($input['notes']) ? trim($input['notes']) : 'Payment transferred by admin';

if (empty($txId)) {
    jsonError('Transaction ID is required', 422);
}

$db = Database::getConnection();

// Fetch transaction and user info
$stmt = $db->prepare("
    SELECT t.*, u.name, u.email, u.username
    FROM transactions t
    JOIN users u ON t.user_id = u.id
    WHERE t.id = :tx_id
    LIMIT 1
");
$stmt->execute([':tx_id' => $txId]);
$tx = $stmt->fetch();

if (!$tx) {
    jsonError('Transaction not found', 404);
}

if ($tx['status'] === 'completed') {
    jsonError('Transaction is already marked as completed', 400);
}

// 1. Update Transaction to Completed
$update = $db->prepare("
    UPDATE transactions 
    SET status = 'completed', admin_notes = :notes, updated_at = NOW() 
    WHERE id = :tx_id
");
$update->execute([
    ':notes' => $adminNotes,
    ':tx_id' => $txId,
]);

// 2. Dispatch Confirmation Email to User
$symbol = strtoupper($tx['currency']) === 'BDT' ? '৳' : '$';
$formattedAmount = $symbol . number_format($tx['amount'], 2);

$emailSent = MailService::sendPayoutConfirmationEmail(
    $tx['email'],
    $tx['name'] ?: $tx['username'],
    $tx['amount'],
    $tx['currency'],
    $tx['method'],
    $tx['destination'],
    $txId
);

// 3. Create In-App Notification for the User
$notifTitle = "Payout Completed ($formattedAmount)";
$notifMessage = "Your withdrawal of $formattedAmount via {$tx['method']} ({$tx['destination']}) has been successfully processed! Reference: $txId";

$insertNotif = $db->prepare("
    INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
    VALUES (:uid, :title, :msg, 'payout_completed', 0, NOW())
");
$insertNotif->execute([
    ':uid'   => $tx['user_id'],
    ':title' => $notifTitle,
    ':msg'   => $notifMessage,
]);

jsonSuccess([
    'transaction_id' => $txId,
    'status'         => 'completed',
    'email_sent'     => $emailSent,
    'notified_user'  => $tx['email'],
], "Payout confirmed successfully! Confirmation email and in-app notification sent to {$tx['email']}.");
