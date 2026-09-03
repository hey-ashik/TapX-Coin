<?php
// api/v1/user/notifications.php

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

// Handle Actions (Mark As Read / Delete)
if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $input = getJsonInput();
    $action = $input['action'] ?? ($_SERVER['REQUEST_METHOD'] === 'DELETE' ? 'delete' : 'mark_read');
    $notifId = isset($input['id']) ? (int)$input['id'] : null;

    if ($action === 'delete' && $notifId) {
        $del = $db->prepare("DELETE FROM notifications WHERE id = :id AND (user_id = :uid OR user_id IS NULL)");
        $del->execute([':id' => $notifId, ':uid' => $userId]);
        jsonSuccess(['deleted_id' => $notifId], 'Notification deleted successfully');
    }

    if ($notifId) {
        $update = $db->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id AND (user_id = :uid OR user_id IS NULL)");
        $update->execute([':id' => $notifId, ':uid' => $userId]);
    } else if ($userId) {
        $updateAll = $db->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = :uid OR user_id IS NULL");
        $updateAll->execute([':uid' => $userId]);
    }

    jsonSuccess([], 'Notifications marked as read');
}

// Fetch Notifications (Global announcements + User-specific)
$query = "
    SELECT id, user_id, title, message, type, is_read, created_at
    FROM notifications
    WHERE user_id = :uid OR user_id IS NULL
    ORDER BY created_at DESC
    LIMIT 30
";
$stmt = $db->prepare($query);
$stmt->execute([':uid' => $userId]);
$rows = $stmt->fetchAll();

$notifications = [];
$unreadCount = 0;

foreach ($rows as $row) {
    $isRead = (bool)$row['is_read'];
    if (!$isRead) {
        $unreadCount++;
    }
    $notifications[] = [
        'id'         => (int)$row['id'],
        'title'      => $row['title'],
        'message'    => $row['message'],
        'type'       => $row['type'],
        'is_read'    => $isRead,
        'created_at' => $row['created_at'],
    ];
}

jsonSuccess([
    'notifications' => $notifications,
    'unread_count'  => $unreadCount,
    'total'         => count($notifications),
], 'Notifications retrieved');
