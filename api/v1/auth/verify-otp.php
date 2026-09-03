<?php
// api/v1/auth/verify-otp.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/services/mail_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$email = trim(isset($input['email']) ? $input['email'] : '');
$code = trim(isset($input['otp_code']) ? $input['otp_code'] : (isset($input['code']) ? $input['code'] : ''));

if (empty($email) || empty($code)) {
    jsonError('Email and 6-digit verification code are required', 422);
}

$isValid = MailService::verifyOtp($email, $code);

if (!$isValid) {
    jsonError('Invalid or expired verification code. Please check or request a new code.', 400);
}

$db = Database::getConnection();

// Generate auth token
$token = bin2hex(random_bytes(32));
$tokenExpires = date('Y-m-d H:i:s', strtotime('+30 days'));

$stmt = $db->prepare("
    UPDATE users 
    SET is_verified = 1, auth_token = :token, token_expires_at = :expires, updated_at = NOW()
    WHERE email = :email
");
$stmt->execute([
    ':token'   => $token,
    ':expires' => $tokenExpires,
    ':email'   => $email,
]);

// Fetch user profile
$userStmt = $db->prepare("SELECT * FROM users WHERE email = :email LIMIT 1");
$userStmt->execute([':email' => $email]);
$user = $userStmt->fetch();

if (!$user) {
    jsonError('User not found', 404);
}

unset($user['password_hash']);

jsonSuccess([
    'token' => $token,
    'token_expires_at' => $tokenExpires,
    'user' => [
        'id'               => $user['id'],
        'name'             => $user['name'],
        'username'         => $user['username'],
        'email'            => $user['email'],
        'avatar_url'       => $user['avatar_url'],
        'rank'             => (int)$user['rank'],
        'level'            => (int)$user['level'],
        'score'            => (int)$user['score'],
        'streak_days'      => (int)$user['streak_days'],
        'phone'            => $user['phone'] ?? '',
        'twitter_handle'   => $user['twitter_handle'] ?? '',
        'discord_username' => $user['discord_username'] ?? '',
        'is_verified'      => (bool)$user['is_verified'],
    ],
], 'Account verified successfully! Welcome to TapX.');
