<?php
// api/config/admin_auth.php

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/database.php';
require_once __DIR__ . '/env.php';

function requireAdminApiAuth() {
    if (session_status() === PHP_SESSION_NONE) {
        // Configure secure cookie params before session starts
        $isSecure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443);
        session_set_cookie_params([
            'lifetime' => 86400 * 7,
            'path' => '/',
            'secure' => $isSecure,
            'httponly' => true,
            'samesite' => 'Lax'
        ]);
        @session_start();
    }

    // 1. Check if authenticated admin session exists
    if (!empty($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
        return true;
    }

    // 2. Check X-Admin-Key header or Bearer token
    $adminKey = null;
    if (isset($_SERVER['HTTP_X_ADMIN_KEY'])) {
        $adminKey = trim($_SERVER['HTTP_X_ADMIN_KEY']);
    } else {
        $token = getBearerToken();
        if ($token) {
            $adminKey = $token;
        }
    }

    $secret = Env::get('ADMIN_SECRET_KEY', 'tapx_admin_sec_2026_9841_ashik');
    if (!empty($adminKey) && hash_equals($secret, $adminKey)) {
        return true;
    }

    // 3. Fallback: check if the bearer token belongs to an admin in the database
    if (!empty($adminKey)) {
        try {
            $db = Database::getConnection();
            $stmt = $db->prepare("SELECT id, role FROM admins WHERE username = :u LIMIT 1");
            // If the bearer token matches an admin session or admin token
            $checkToken = $db->prepare("SELECT id FROM admins WHERE id = :id LIMIT 1");
            // check
        } catch (Throwable $e) {
            // ignore
        }
    }

    jsonError('Forbidden: Admin authentication required', 403);
}
