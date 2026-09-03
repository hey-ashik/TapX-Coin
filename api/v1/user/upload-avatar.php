<?php
// api/v1/user/upload-avatar.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/config/env.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$token = getBearerToken();
if (!$token) {
    jsonError('Authorization token required', 401);
}

$db = Database::getConnection();
$stmt = $db->prepare("SELECT id, name FROM users WHERE auth_token = :token LIMIT 1");
$stmt->execute([':token' => $token]);
$user = $stmt->fetch();

if (!$user) {
    jsonError('Unauthorized user', 401);
}

if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
    jsonError('No valid image file uploaded', 400);
}

$file = $_FILES['avatar'];
$maxSize = 5 * 1024 * 1024; // 5MB

if ($file['size'] > $maxSize) {
    jsonError('Image size exceeds 5MB limit', 422);
}

$mimeMap = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
    'image/gif'  => 'gif',
];

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

if (!isset($mimeMap[$mime])) {
    jsonError('Only JPG, PNG, WEBP, and GIF images are allowed', 422);
}

// Deep inspection: verify file contains valid image header dimensions
$imgSize = @getimagesize($file['tmp_name']);
if ($imgSize === false) {
    jsonError('Invalid image data or corrupted image file', 422);
}

// Ensure uploads directory exists
$uploadDir = dirname(__DIR__, 2) . '/uploads/avatars';
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0755, true);
}

// Strictly derive safe extension from MIME type to prevent extension spoofing / webshell execution
$extension = $mimeMap[$mime];
$safeUserId = preg_replace('/[^a-zA-Z0-9_-]/', '', $user['id']);
$filename = 'avatar_' . $safeUserId . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
$targetPath = $uploadDir . '/' . $filename;

if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    jsonError('Failed to save uploaded file to storage', 500);
}
@chmod($targetPath, 0644);

// Generate public URL
$baseUrl = Env::get('API_BASE_URL', 'https://tapx.ashiik.com/api');
$publicUrl = rtrim($baseUrl, '/') . '/uploads/avatars/' . $filename;

// Update database record
$update = $db->prepare("UPDATE users SET avatar_url = :url, updated_at = NOW() WHERE id = :id");
$update->execute([
    ':url' => $publicUrl,
    ':id'  => $user['id'],
]);

jsonSuccess([
    'avatar_url' => $publicUrl,
    'filename'   => $filename,
], 'Avatar uploaded and updated successfully');
