<?php
// api/v1/auth/register.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/services/mail_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$name = trim(isset($input['name']) ? $input['name'] : '');
$email = trim(isset($input['email']) ? $input['email'] : '');
$password = trim(isset($input['password']) ? $input['password'] : '');

if (empty($email) || empty($password)) {
    jsonError('Email and password are required', 422);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('Invalid email address format', 422);
}

if (strlen($password) < 6) {
    jsonError('Password must be at least 6 characters', 422);
}

if (empty($name)) {
    $name = explode('@', $email)[0];
}

$db = Database::getConnection();

// Check if email already registered
$check = $db->prepare("SELECT id, is_verified FROM users WHERE email = :email LIMIT 1");
$check->execute([':email' => $email]);
$existingUser = $check->fetch();

if ($existingUser && $existingUser['is_verified'] == 1) {
    jsonError('An account with this email already exists. Please sign in.', 409);
}

$passwordHash = password_hash($password, PASSWORD_BCRYPT);
// Dynamic initial avatar (e.g. Ashik -> A)
$encodedName = urlencode($name);
$initialAvatar = "https://ui-avatars.com/api/?name=$encodedName&background=1A1A1E&color=FFFFFF&bold=true&size=256";

$userId = $existingUser ? $existingUser['id'] : 'usr_' . bin2hex(random_bytes(8));
$username = strtolower(preg_replace('/[^a-zA-Z0-9_]/', '', explode('@', $email)[0])) . '_' . substr(uniqid(), -3);

if ($existingUser) {
    // Update existing unverified record
    $update = $db->prepare("
        UPDATE users 
        SET name = :name, password_hash = :hash, avatar_url = :avatar, updated_at = NOW()
        WHERE id = :id
    ");
    $update->execute([
        ':name' => $name,
        ':hash' => $passwordHash,
        ':avatar' => $initialAvatar,
        ':id' => $userId,
    ]);
} else {
    // Insert new user record
    $insert = $db->prepare("
        INSERT INTO users (id, name, username, email, password_hash, avatar_url, is_verified, rank, level, score, streak_days)
        VALUES (:id, :name, :username, :email, :hash, :avatar, 0, 1, 1, 0, 1)
    ");
    $insert->execute([
        ':id' => $userId,
        ':name' => $name,
        ':username' => $username,
        ':email' => $email,
        ':hash' => $passwordHash,
        ':avatar' => $initialAvatar,
    ]);
}

// Generate & Send 6-Digit OTP Code via Email
$otpResult = MailService::generateAndSendOtp($email, $name);

jsonSuccess([
    'user_id' => $userId,
    'email' => $email,
    'name' => $name,
    'avatar_url' => $initialAvatar,
    'otp_sent' => $otpResult['sent'],
    'debug_otp' => $otpResult['otp_code'], // Included for instant testing
    'expires_at' => $otpResult['expires_at'],
], 'Verification code sent to your email. Please check your inbox.');
