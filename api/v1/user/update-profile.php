<?php
// api/v1/user/update-profile.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
}

$token = getBearerToken();
if (!$token) {
    jsonError('Authorization token required', 401);
}

try {
    $db = Database::getConnection();
    $stmt = $db->prepare("SELECT id FROM users WHERE auth_token = :token LIMIT 1");
    $stmt->execute([':token' => $token]);
    $user = $stmt->fetch();

    if (!$user) {
        jsonError('Unauthorized user', 401);
    }

    $input = getJsonInput();
    $name = isset($input['name']) ? trim($input['name']) : null;
    $username = isset($input['username']) ? trim($input['username']) : null;
    $phone = isset($input['phone']) ? trim($input['phone']) : null;
    $twitter = isset($input['twitter_handle']) ? trim($input['twitter_handle']) : null;
    $discord = isset($input['discord_username']) ? trim($input['discord_username']) : null;
    $avatarUrl = isset($input['avatar_url']) ? trim($input['avatar_url']) : null;

    $fields = [];
    $params = [':id' => $user['id']];

    if ($name !== null && $name !== '') {
        $name = strip_tags(trim($name));
        if (mb_strlen($name) > 60) {
            $name = mb_substr($name, 0, 60);
        }
        $fields[] = "`name` = :name";
        $params[':name'] = $name;
    }
    if ($username !== null && $username !== '') {
        $username = trim($username);
        if (!preg_match('/^[a-zA-Z0-9_]{3,30}$/', $username)) {
            jsonError('Username must be 3-30 characters (letters, numbers, underscores only)', 422);
        }
        // Check uniqueness
        $check = $db->prepare("SELECT id FROM users WHERE username = :username AND id != :id LIMIT 1");
        $check->execute([':username' => $username, ':id' => $user['id']]);
        if ($check->fetch()) {
            jsonError('Username is already taken by another user', 409);
        }
        $fields[] = "`username` = :username";
        $params[':username'] = $username;
    }
    if ($phone !== null) {
        $phone = substr(preg_replace('/[^0-9+ -]/', '', $phone), 0, 25);
        $fields[] = "`phone` = :phone";
        $params[':phone'] = $phone;
    }
    if ($twitter !== null) {
        $twitter = substr(preg_replace('/[^a-zA-Z0-9_@]/', '', $twitter), 0, 50);
        $fields[] = "`twitter_handle` = :twitter";
        $params[':twitter'] = $twitter;
    }
    if ($discord !== null) {
        $discord = substr(strip_tags(trim($discord)), 0, 50);
        $fields[] = "`discord_username` = :discord";
        $params[':discord'] = $discord;
    }
    if ($avatarUrl !== null && $avatarUrl !== '') {
        // If it is a base64 Data URL, validate image content and save as physical file
        if (strpos($avatarUrl, 'data:image/') === 0) {
            $uploadDir = dirname(__DIR__, 2) . '/uploads/avatars/';
            if (!is_dir($uploadDir)) {
                @mkdir($uploadDir, 0755, true);
            }
            
            $parts = explode(',', $avatarUrl);
            $base64Data = $parts[1] ?? '';
            $decoded = base64_decode($base64Data, true);
            
            if ($decoded !== false && strlen($decoded) <= 5 * 1024 * 1024) {
                $imgInfo = @getimagesizefromstring($decoded);
                $allowedMimes = [
                    'image/jpeg' => 'jpg',
                    'image/png'  => 'png',
                    'image/webp' => 'webp',
                    'image/gif'  => 'gif',
                ];
                if ($imgInfo !== false && isset($allowedMimes[$imgInfo['mime']])) {
                    $ext = $allowedMimes[$imgInfo['mime']];
                    $filename = 'avatar_' . substr(md5($user['id']), 0, 10) . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
                    $filePath = $uploadDir . $filename;
                    if (file_put_contents($filePath, $decoded)) {
                        @chmod($filePath, 0644);
                        $baseUrl = Env::get('API_BASE_URL', 'https://tapx.ashiik.com/api');
                        $avatarUrl = rtrim($baseUrl, '/') . '/uploads/avatars/' . $filename;
                        $fields[] = "`avatar_url` = :avatar";
                        $params[':avatar'] = $avatarUrl;
                    }
                }
            }
        } elseif (preg_match('/^https?:\/\//i', $avatarUrl)) {
            // Valid external URL
            $fields[] = "`avatar_url` = :avatar";
            $params[':avatar'] = filter_var($avatarUrl, FILTER_SANITIZE_URL);
        }
    }

    if (empty($fields)) {
        jsonError('No fields to update', 400);
    }

    $fields[] = "`updated_at` = NOW()";
    $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE id = :id";
    $updateStmt = $db->prepare($sql);
    $updateStmt->execute($params);

    // Fetch updated profile
    $fetch = $db->prepare("SELECT * FROM users WHERE id = :id LIMIT 1");
    $fetch->execute([':id' => $user['id']]);
    $updatedUser = $fetch->fetch();

    unset($updatedUser['password_hash']);

    jsonSuccess([
        'id'               => $updatedUser['id'],
        'name'             => $updatedUser['name'],
        'username'         => $updatedUser['username'],
        'email'            => $updatedUser['email'],
        'avatar_url'       => $updatedUser['avatar_url'],
        'rank'             => (int)$updatedUser['rank'],
        'level'            => (int)$updatedUser['level'],
        'score'            => (int)$updatedUser['score'],
        'streak_days'      => (int)$updatedUser['streak_days'],
        'phone'            => $updatedUser['phone'] ?? '',
        'twitter_handle'   => $updatedUser['twitter_handle'] ?? '',
        'discord_username' => $updatedUser['discord_username'] ?? '',
        'is_verified'      => (bool)$updatedUser['is_verified'],
    ], 'Profile updated successfully');
} catch (Throwable $e) {
    jsonError('Server error: ' . $e->getMessage(), 500);
}
