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

$dbInfo = [
    'status' => $dbStatus,
];

if (Env::get('APP_ENV') !== 'production' && Env::get('APP_DEBUG') === 'true') {
    $dbInfo['host'] = Env::get('DB_HOST');
    $dbInfo['name'] = Env::get('DB_NAME');
    $dbInfo['tables'] = $tables;
    if ($dbError) {
        $dbInfo['error'] = $dbError;
    }
}

jsonSuccess([
    'app'         => 'TapX REST API',
    'version'     => '1.0.0',
    'status'      => ($dbStatus === 'connected' ? 'healthy' : 'degraded'),
    'database'    => $dbInfo,
    'server_time' => date('Y-m-d H:i:s'),
], 'TapX Backend Diagnostic Online');
