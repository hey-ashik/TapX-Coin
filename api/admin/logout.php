<?php
// api/admin/logout.php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
$_SESSION = [];
session_destroy();
header('Location: login');
exit;
