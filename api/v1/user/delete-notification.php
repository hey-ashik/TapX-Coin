<?php
// api/v1/user/delete-notification.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

$token = getBearerToken();
$db = Database::getConnection();

$userId = null;
if ($token) {
    $stmt = $db->prepare("SELECT id FROM users WHERE auth_token = :token LIMIT 1");
    $stmt->execute([':token' => $token]);
    $user = $stmt->fetch();
    if ($user) {
        $userId = $user['id'];
    }
}

$input = getJsonInput();
$notifId = isset($input['id']) ? (int)$input['id'] : (isset($_GET['id']) ? (int)$_GET['id'] : null);

if (!$notifId) {
    jsonError('Notification ID is required', 400);
}

try {
    if ($userId) {
        $del = $db->prepare("DELETE FROM notifications WHERE id = :id AND (user_id = :uid OR user_id IS NULL)");
        $del->execute([':id' => $notifId, ':uid' => $userId]);
    } else {
        $del = $db->prepare("DELETE FROM notifications WHERE id = :id AND user_id IS NULL");
        $del->execute([':id' => $notifId]);
    }

    jsonSuccess(['deleted_id' => $notifId], 'Notification deleted successfully');
} catch (Throwable $e) {
    jsonError('Failed to delete notification: ' . $e->getMessage(), 500);
}
