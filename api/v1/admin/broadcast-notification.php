<?php
// api/v1/admin/broadcast-notification.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/config/admin_auth.php';

requireAdminApiAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$title = trim(isset($input['title']) ? $input['title'] : '');
$message = trim(isset($input['message']) ? $input['message'] : '');
$targetUserId = isset($input['user_id']) && !empty($input['user_id']) ? trim($input['user_id']) : null;
$type = isset($input['type']) ? trim($input['type']) : 'announcement';

if (empty($title) || empty($message)) {
    jsonError('Title and message are required', 422);
}

$db = Database::getConnection();

$stmt = $db->prepare("
    INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
    VALUES (:uid, :title, :msg, :type, 0, NOW())
");
$stmt->execute([
    ':uid'   => $targetUserId,
    ':title' => $title,
    ':msg'   => $message,
    ':type'  => $type,
]);

$targetText = $targetUserId ? "User $targetUserId" : "All Users (Global)";

jsonSuccess([
    'notification_id' => $db->lastInsertId(),
    'title'           => $title,
    'target'          => $targetText,
    'type'            => $type,
], "Notification successfully broadcasted to $targetText.");
