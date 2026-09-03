<?php
// api/v1/app/check-update.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

$currentVersion = $_GET['current_version'] ?? '1.0.0';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = getJsonInput();
    if (!empty($input['current_version'])) {
        $currentVersion = trim($input['current_version']);
    }
}

$db = Database::getConnection();
$stmt = $db->query("SELECT * FROM app_updates ORDER BY id DESC LIMIT 1");
$update = $stmt->fetch();

if (!$update) {
    jsonSuccess([
        'has_update'      => false,
        'is_force_update' => false,
        'latest_version'  => $currentVersion,
        'min_version'     => $currentVersion,
        'apk_url'         => '',
        'release_notes'   => 'Up to date',
    ], 'No updates available');
}

$latestVersion = $update['latest_version'];
$minVersion = $update['min_version'];
$isForced = (bool)$update['is_force_update'];

// Check if current version is older than latest
$hasUpdate = version_compare($currentVersion, $latestVersion, '<');

// Check if current version is below minimum required version
$forceUpdate = $isForced || version_compare($currentVersion, $minVersion, '<');

jsonSuccess([
    'has_update'      => $hasUpdate,
    'is_force_update' => $hasUpdate && $forceUpdate,
    'current_version' => $currentVersion,
    'latest_version'  => $latestVersion,
    'min_version'     => $minVersion,
    'apk_url'         => $update['apk_url'],
    'release_notes'   => $update['release_notes'],
    'updated_at'      => $update['updated_at'],
], $hasUpdate ? 'New update available' : 'Application is up to date');
