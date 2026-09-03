<?php
// api/v1/auth/resend-otp.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/services/mail_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$input = getJsonInput();
$email = trim(isset($input['email']) ? $input['email'] : '');

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError('A valid email address is required', 422);
}

$db = Database::getConnection();
$stmt = $db->prepare("SELECT name FROM users WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);
$user = $stmt->fetch();

$name = $user ? $user['name'] : 'Tapper';
$otpResult = MailService::generateAndSendOtp($email, $name);

jsonSuccess([
    'email' => $email,
    'otp_sent' => $otpResult['sent'],
    'debug_otp' => $otpResult['otp_code'],
    'expires_at' => $otpResult['expires_at'],
], 'A new 6-digit verification code has been dispatched to your email.');
