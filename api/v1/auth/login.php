<?php
// api/v1/auth/login.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/services/mail_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

try {
    $input = getJsonInput();
    $email = trim(isset($input['email']) ? $input['email'] : '');
    $password = trim(isset($input['password']) ? $input['password'] : '');

    if (empty($email) || empty($password)) {
        jsonError('Email and password are required', 422);
    }

    $db = Database::getConnection();

    // Case-insensitive lookup by email or username
    $stmt = $db->prepare("SELECT * FROM users WHERE LOWER(email) = LOWER(:email) OR LOWER(username) = LOWER(:uname) LIMIT 1");
    $stmt->execute([':email' => $email, ':uname' => $email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        // If guest user fallback
        if ($email === 'guest@tapx.app' || $email === 'guest@soul.network' || $email === 'guest@tapx.ashiik.com') {
            $token = bin2hex(random_bytes(32));
            jsonSuccess([
                'token' => $token,
                'user' => [
                    'id' => 'usr_guest',
                    'name' => 'Guest Tapper',
                    'username' => 'guest_tapper',
                    'email' => 'guest@tapx.app',
                    'avatar_url' => 'https://ui-avatars.com/api/?name=Guest&background=1A1A1E&color=FFFFFF&bold=true&size=256',
                    'rank' => 1,
                    'level' => 1,
                    'score' => 0,
                    'streak_days' => 1,
                    'phone' => '',
                    'twitter_handle' => '',
                    'discord_username' => '',
                    'is_verified' => true,
                ]
            ], 'Signed in as Guest');
        }

        jsonError('Invalid email or password credentials', 401);
    }

    // Strict check: Is the account verified with OTP?
    if (empty($user['is_verified']) || (int)$user['is_verified'] === 0) {
        // Auto re-send OTP code so user can verify immediately
        $otpResult = MailService::generateAndSendOtp($user['email'], $user['name']);
        
        $errData = [
            'needs_verification' => true,
            'email' => $user['email'],
            'name' => $user['name'],
        ];
        if (Env::get('APP_ENV') !== 'production' && Env::get('APP_DEBUG') === 'true') {
            $errData['debug_otp'] = $otpResult['otp_code'] ?? null;
        }

        jsonError('Account not verified. Please enter the 6-digit OTP code sent to your email to activate your account.', 403, $errData);
    }

    // Generate auth token
    $token = bin2hex(random_bytes(32));
    $tokenExpires = date('Y-m-d H:i:s', strtotime('+30 days'));

    $update = $db->prepare("
        UPDATE users 
        SET auth_token = :token, token_expires_at = :expires, updated_at = NOW()
        WHERE id = :id
    ");
    $update->execute([
        ':token'   => $token,
        ':expires' => $tokenExpires,
        ':id'      => $user['id'],
    ]);

    jsonSuccess([
        'token' => $token,
        'token_expires_at' => $tokenExpires,
        'user' => [
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
            'is_verified'      => true,
        ],
    ], 'Login successful');
} catch (Throwable $e) {
    jsonError('Server error: ' . $e->getMessage(), 500);
}
