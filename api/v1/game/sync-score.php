<?php
// api/v1/game/sync-score.php

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
$stmt = $db->prepare("SELECT id, score, level, streak_days, updated_at FROM users WHERE auth_token = :token LIMIT 1");
$stmt->execute([':token' => $token]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Unauthorized user', 401);
}

$input = getJsonInput();
$newScore = isset($input['score']) ? (int)$input['score'] : null;
$newLevel = isset($input['level']) ? (int)$input['level'] : null;
$streakDays = isset($input['streak_days']) ? (int)$input['streak_days'] : null;
$todayTaps = isset($input['today_taps']) ? (int)$input['today_taps'] : null;

$fields = [];
$params = [':id' => $user['id']];

if ($newScore !== null && $newScore >= (int)$user['score']) {
    $fields[] = "`score` = :score";
    $params[':score'] = $newScore;
}
if ($newLevel !== null) {
    $fields[] = "`level` = :level";
    $params[':level'] = $newLevel;
}
if ($streakDays !== null) {
    $fields[] = "`streak_days` = :streak";
    $params[':streak'] = $streakDays;
}

if (!empty($fields)) {
    $fields[] = "`updated_at` = NOW()";
    $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE id = :id";
    $updateStmt = $db->prepare($sql);
    $updateStmt->execute($params);
}

// Calculate user's rank position dynamically based on score
$rankStmt = $db->prepare("SELECT COUNT(*) + 1 AS user_rank FROM users WHERE score > (SELECT score FROM users WHERE id = :id)");
$rankStmt->execute([':id' => $user['id']]);
$rankResult = $rankStmt->fetch();
$calculatedRank = (int)($rankResult['user_rank'] ?? 1);

// Update rank
$rankUpdate = $db->prepare("UPDATE users SET rank = :rank WHERE id = :id");
$rankUpdate->execute([':rank' => $calculatedRank, ':id' => $user['id']]);

jsonSuccess([
    'score'      => $newScore !== null ? max($newScore, (int)$user['score']) : (int)$user['score'],
    'level'      => $newLevel ?? (int)$user['level'],
    'rank'       => $calculatedRank,
    'today_taps' => $todayTaps ?? 0,
], 'Game state synced successfully');
