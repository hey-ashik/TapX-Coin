<?php
// api/v1/auth/me.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

$token = getBearerToken();

if (!$token) {
    jsonError('Authorization token required', 401);
}

$db = Database::getConnection();
$stmt = $db->prepare("
    SELECT * FROM users 
    WHERE auth_token = :token AND token_expires_at > NOW() 
    LIMIT 1
");
$stmt->execute([':token' => $token]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Session expired or invalid token', 401);
}

jsonSuccess([
    'id'               => $user['id'],
    'name'             => $user['name'],
    'username'         => $user['username'],
    'email'            => $user['email'],
    'avatar_url'       => $user['avatar_url'] ?: "https://ui-avatars.com/api/?name=" . urlencode($user['name']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256",
    'rank'             => (int)$user['rank'],
    'level'            => (int)$user['level'],
    'score'            => (int)$user['score'],
    'streak_days'      => (int)$user['streak_days'],
    'phone'            => $user['phone'] ?? '',
    'twitter_handle'   => $user['twitter_handle'] ?? '',
    'discord_username' => $user['discord_username'] ?? '',
    'is_verified'      => (bool)$user['is_verified'],
], 'User session valid');
