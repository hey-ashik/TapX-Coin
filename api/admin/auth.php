<?php
// api/admin/auth.php

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/config/env.php';

function requireAdminAuth() {
    if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
        header('Location: login');
        exit;
    }
}

function getAdminUser() {
    return isset($_SESSION['admin_username']) ? $_SESSION['admin_username'] : 'Admin';
}
