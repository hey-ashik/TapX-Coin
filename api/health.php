<?php
// api/health.php - TapX Backend Diagnostic & Database Verification

require_once __DIR__ . '/config/cors.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/env.php';

$dbStatus = 'disconnected';
$tables = [];
$dbError = null;

try {
    $db = Database::getConnection();
    $dbStatus = 'connected';

    $stmt = $db->query("SHOW TABLES");
    while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
        $tables[] = $row[0];
    }
} catch (Exception $e) {
    $dbError = $e->getMessage();
}

jsonSuccess([
    'app'          => 'TapX REST API',
    'version'      => '1.0.0',
    'status'       => 'healthy',
    'php_version'  => phpversion(),
    'database'     => [
        'status' => $dbStatus,
        'name'   => Env::get('DB_NAME'),
        'host'   => Env::get('DB_HOST'),
        'user'   => Env::get('DB_USER'),
        'tables' => $tables,
        'error'  => $dbError,
    ],
    'server_time'  => date('Y-m-d H:i:s'),
], 'TapX Backend Diagnostic Online');
