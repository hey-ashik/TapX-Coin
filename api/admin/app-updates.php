<?php
// api/admin/app-updates.php

require_once __DIR__ . '/auth.php';
requireAdminAuth();

$db = Database::getConnection();
$message = '';
$error = '';

// Handle Update Submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'save_update') {
    $latestVersion = trim($_POST['latest_version'] ?? '1.0.0');
    $minVersion = trim($_POST['min_version'] ?? '1.0.0');
    $apkUrl = trim($_POST['apk_url'] ?? '');
    $releaseNotes = trim($_POST['release_notes'] ?? '');
    $isForceUpdate = isset($_POST['is_force_update']) ? 1 : 0;
    $broadcastNotif = isset($_POST['broadcast_notification']) ? 1 : 0;

    // Handle APK File Upload if provided
    if (isset($_FILES['apk_file']) && $_FILES['apk_file']['error'] === UPLOAD_ERR_OK) {
        $fileTmp = $_FILES['apk_file']['tmp_name'];
        $fileName = $_FILES['apk_file']['name'];
        $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

        if ($ext === 'apk') {
            $uploadDir = dirname(__DIR__) . '/uploads/updates/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            $targetPath = $uploadDir . 'tapx-v' . preg_replace('/[^0-9.]/', '', $latestVersion) . '.apk';
            if (move_uploaded_file($fileTmp, $targetPath)) {
                $apkUrl = 'https://tapx.ashiik.com/api/uploads/updates/' . basename($targetPath);
            } else {
                $error = 'Failed to save uploaded APK file.';
            }
        } else {
            $error = 'Only .apk files are accepted for upload.';
        }
    }

    if (empty($error)) {
        // Upsert record
        $stmt = $db->query("SELECT id FROM app_updates ORDER BY id DESC LIMIT 1");
        $existing = $stmt->fetch();

        if ($existing) {
            $update = $db->prepare("
                UPDATE app_updates 
                SET latest_version = :latest, min_version = :min, apk_url = :url, release_notes = :notes, is_force_update = :force, updated_at = NOW()
                WHERE id = :id
            ");
            $update->execute([
                ':latest' => $latestVersion,
                ':min'    => $minVersion,
                ':url'    => $apkUrl,
                ':notes'  => $releaseNotes,
                ':force'  => $isForceUpdate,
                ':id'     => $existing['id']
            ]);
        } else {
            $insert = $db->prepare("
                INSERT INTO app_updates (latest_version, min_version, apk_url, release_notes, is_force_update)
                VALUES (:latest, :min, :url, :notes, :force)
            ");
            $insert->execute([
                ':latest' => $latestVersion,
                ':min'    => $minVersion,
                ':url'    => $apkUrl,
                ':notes'  => $releaseNotes,
                ':force'  => $isForceUpdate,
            ]);
        }

        // Broadcast notification if checked
        if ($broadcastNotif) {
            $notif = $db->prepare("
                INSERT INTO notifications (user_id, title, message, type, is_read)
                VALUES (NULL, :title, :msg, 'announcement', 0)
            ");
            $notif->execute([
                ':title' => "New Update Available (v$latestVersion)!",
                ':msg'   => "TapX v$latestVersion is now live! Update now to enjoy new features & boosts: " . substr(strip_tags($releaseNotes), 0, 120) . "..."
            ]);
        }

        $message = 'App Update parameters saved successfully!' . ($broadcastNotif ? ' Global push announcement dispatched.' : '');
    }
}

// Fetch current active config
$stmt = $db->query("SELECT * FROM app_updates ORDER BY id DESC LIMIT 1");
$current = $stmt->fetch() ?: [
    'latest_version'  => '1.0.0',
    'min_version'     => '1.0.0',
    'apk_url'         => 'https://tapx.ashiik.com/api/uploads/updates/tapx-release.apk',
    'release_notes'   => "• Performance optimizations\n• Instant bKash/Nagad withdrawals\n• Real-time Live/Today taps tracker",
    'is_force_update' => 0,
    'updated_at'      => date('Y-m-d H:i:s')
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TapX Admin Portal &bull; OTA App Updates</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        body { background: #09090B; color: #FAFAFA; min-height: 100vh; display: flex; flex-direction: column; }
        
        header { background: #121215; border-bottom: 1px solid #27272A; padding: 16px 24px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 100; }
        .logo-group { display: flex; align-items: center; gap: 12px; }
        .logo { font-size: 22px; font-weight: 900; letter-spacing: 3px; color: #FFFFFF; text-decoration: none; }
        .admin-badge { background: #27272A; color: #A1A1AA; font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 20px; letter-spacing: 1px; }
        
        .nav-links { display: flex; align-items: center; gap: 6px; }
        .nav-links a { color: #A1A1AA; text-decoration: none; font-size: 14px; font-weight: 600; padding: 8px 14px; border-radius: 10px; transition: all 0.2s; display: inline-flex; align-items: center; gap: 6px; }
        .nav-links a:hover, .nav-links a.active { color: #FFFFFF; background: #1E1E24; }
        
        .user-nav { display: flex; align-items: center; gap: 16px; font-size: 13px; color: #71717A; }
        .logout-btn { color: #EF4444; text-decoration: none; font-weight: 600; padding: 6px 12px; border-radius: 8px; border: 1px solid rgba(239, 68, 68, 0.3); }
        .logout-btn:hover { background: rgba(239, 68, 68, 0.1); }

        /* Hamburger Button */
        .hamburger { display: none; flex-direction: column; justify-content: space-around; width: 38px; height: 38px; background: #1E1E24; border: 1px solid #27272A; border-radius: 8px; cursor: pointer; padding: 9px 8px; z-index: 101; }
        .hamburger .bar { width: 100%; height: 2px; background: #FFFFFF; border-radius: 2px; transition: all 0.3s ease; }
        .hamburger.active .bar:nth-child(1) { transform: translateY(6px) rotate(45deg); }
        .hamburger.active .bar:nth-child(2) { opacity: 0; }
        .hamburger.active .bar:nth-child(3) { transform: translateY(-6px) rotate(-45deg); }

        @media (max-width: 900px) {
            .hamburger { display: flex; }
            .nav-links {
                display: none;
                position: fixed;
                top: 71px;
                left: 0;
                right: 0;
                background: #121215;
                border-bottom: 1px solid #27272A;
                flex-direction: column;
                align-items: stretch;
                padding: 16px 20px 24px;
                gap: 8px;
                box-shadow: 0 20px 30px rgba(0,0,0,0.8);
                z-index: 99;
            }
            .nav-links.open { display: flex; }
            .nav-links a { padding: 12px 16px; font-size: 15px; border-radius: 12px; }
            .user-nav { display: none; }
            .mobile-user-nav { display: block; margin-top: 12px; padding-top: 12px; border-top: 1px solid #27272A; }
            .mobile-user-nav span { display: block; margin-bottom: 8px; font-size: 13px; color: #71717A; }
            .layout-grid { grid-template-columns: 1fr !important; }
        }
        @media (min-width: 901px) {
            .mobile-user-nav { display: none; }
        }
        
        .container { max-width: 1280px; width: 100%; margin: 0 auto; padding: 32px 24px; flex: 1; }
        .layout-grid { display: grid; grid-template-columns: 1.2fr 0.8fr; gap: 28px; }

        .card { background: #121215; border: 1px solid #27272A; border-radius: 20px; padding: 28px; }
        .card-title { font-size: 18px; font-weight: 800; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
        
        .alert-success { background: rgba(34, 197, 94, 0.1); border: 1px solid rgba(34, 197, 94, 0.3); color: #22C55E; padding: 12px 16px; border-radius: 12px; font-size: 14px; margin-bottom: 20px; }
        .alert-error { background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.3); color: #EF4444; padding: 12px 16px; border-radius: 12px; font-size: 14px; margin-bottom: 20px; }

        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
        .form-group { margin-bottom: 16px; }
        label { display: block; font-size: 12px; font-weight: 600; color: #A1A1AA; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px; }
        input[type="text"], textarea { width: 100%; background: #18181B; border: 1px solid #27272A; border-radius: 10px; padding: 12px 14px; font-size: 14px; color: #FFFFFF; outline: none; transition: border-color 0.2s; }
        input:focus, textarea:focus { border-color: #FFFFFF; }
        textarea { resize: vertical; min-height: 120px; font-family: monospace; font-size: 13px; line-height: 1.5; }
        
        .checkbox-label { display: flex; align-items: center; gap: 10px; cursor: pointer; text-transform: none; color: #FFFFFF; font-size: 14px; font-weight: 500; }
        .checkbox-label input[type="checkbox"] { width: 18px; height: 18px; accent-color: #FFFFFF; cursor: pointer; }

        .btn-save { width: 100%; background: #FFFFFF; color: #000000; border: none; border-radius: 12px; padding: 14px; font-size: 15px; font-weight: 700; cursor: pointer; transition: opacity 0.2s; margin-top: 10px; }
        .btn-save:hover { opacity: 0.9; }

        /* Preview card */
        .preview-box { background: #18181B; border: 1px solid #27272A; border-radius: 16px; padding: 20px; margin-top: 16px; }
        .preview-field { margin-bottom: 12px; font-size: 13px; }
        .preview-field span { color: #71717A; display: block; font-size: 11px; text-transform: uppercase; font-weight: 600; margin-bottom: 2px; }
        .preview-field strong { color: #FFFFFF; font-size: 15px; }
    </style>
</head>
<body>
    <header>
        <div class="logo-group">
            <a href="index" class="logo">TAPX</a>
            <div class="admin-badge">Admin Hub</div>
        </div>
        
        <button class="hamburger" id="menuToggle" onclick="toggleMenu()" aria-label="Toggle Menu">
            <span class="bar"></span>
            <span class="bar"></span>
            <span class="bar"></span>
        </button>

        <nav class="nav-links" id="navLinks">
            <a href="index">Dashboard</a>
            <a href="withdrawals">Withdrawals</a>
            <a href="users">Users</a>
            <a href="notifications">Notifications</a>
            <a href="app-updates" class="active">App Updates</a>
            <div class="mobile-user-nav">
                <span>Signed in as <strong><?php echo htmlspecialchars(getAdminUser()); ?></strong></span>
                <a href="logout" class="logout-btn" style="display: inline-block; text-align: center;">Log Out</a>
            </div>
        </nav>

        <div class="user-nav">
            <span>Signed in as <strong><?php echo htmlspecialchars(getAdminUser()); ?></strong></span>
            <a href="logout" class="logout-btn">Log Out</a>
        </div>
    </header>

    <div class="container">
        <?php if (!empty($message)): ?>
            <div class="alert-success">✓ <?php echo htmlspecialchars($message); ?></div>
        <?php endif; ?>
        <?php if (!empty($error)): ?>
            <div class="alert-error">✕ <?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>

        <div class="layout-grid">
            <!-- Form Card -->
            <div class="card">
                <div class="card-title">🚀 Manage OTA App Releases</div>
                <form method="POST" action="app-updates" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="save_update">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Latest Version Code</label>
                            <input type="text" name="latest_version" value="<?php echo htmlspecialchars($current['latest_version']); ?>" placeholder="e.g. 1.0.1" required>
                        </div>
                        <div class="form-group">
                            <label>Minimum Required Version</label>
                            <input type="text" name="min_version" value="<?php echo htmlspecialchars($current['min_version']); ?>" placeholder="e.g. 1.0.0" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>APK Direct Download URL</label>
                        <input type="text" name="apk_url" value="<?php echo htmlspecialchars($current['apk_url']); ?>" placeholder="https://tapx.ashiik.com/api/uploads/updates/tapx-latest.apk" required>
                    </div>

                    <div class="form-group">
                        <label>Upload New APK File (Optional)</label>
                        <input type="file" name="apk_file" accept=".apk" style="width:100%; color:#A1A1AA;">
                        <small style="color: #71717A; display: block; margin-top: 4px; font-size: 11px;">If provided, overrides the download URL with hosted file link automatically.</small>
                    </div>

                    <div class="form-group">
                        <label>Release Notes (Changelog)</label>
                        <textarea name="release_notes" placeholder="• New feature 1&#10;• Bug fix 2&#10;• Performance improvements"><?php echo htmlspecialchars($current['release_notes']); ?></textarea>
                    </div>

                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" name="is_force_update" value="1" <?php echo $current['is_force_update'] ? 'checked' : ''; ?>>
                            <span><strong>Mandatory / Force Update</strong> (Blocks older apps until updated)</span>
                        </label>
                    </div>

                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" name="broadcast_notification" value="1" checked>
                            <span><strong>Push Global In-App Notification</strong> (Notify all active users)</span>
                        </label>
                    </div>

                    <button type="submit" class="btn-save">Publish App Update & Broadcast &rarr;</button>
                </form>
            </div>

            <!-- Current Active Status Card -->
            <div class="card">
                <div class="card-title">📱 Live OTA Configuration</div>
                <p style="color: #71717A; font-size: 13px; line-height: 1.5;">This configuration is queried by the app whenever users tap "Check for Updates" or upon application launch.</p>
                
                <div class="preview-box">
                    <div class="preview-field">
                        <span>Latest Deployed Version</span>
                        <strong>v<?php echo htmlspecialchars($current['latest_version']); ?></strong>
                    </div>
                    <div class="preview-field">
                        <span>Min Supported Version</span>
                        <strong>v<?php echo htmlspecialchars($current['min_version']); ?></strong>
                    </div>
                    <div class="preview-field">
                        <span>Update Policy</span>
                        <strong style="color: <?php echo $current['is_force_update'] ? '#EF4444' : '#22C55E'; ?>;">
                            <?php echo $current['is_force_update'] ? 'Mandatory Force Update' : 'Optional Update'; ?>
                        </strong>
                    </div>
                    <div class="preview-field">
                        <span>APK Download Link</span>
                        <a href="<?php echo htmlspecialchars($current['apk_url']); ?>" target="_blank" style="color: #60A5FA; word-break: break-all; font-size: 13px;">
                            <?php echo htmlspecialchars($current['apk_url']); ?>
                        </a>
                    </div>
                    <div class="preview-field" style="margin-bottom: 0;">
                        <span>Last Updated</span>
                        <div style="font-size: 12px; color: #A1A1AA;"><?php echo $current['updated_at']; ?></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function toggleMenu() {
            const toggle = document.getElementById('menuToggle');
            const nav = document.getElementById('navLinks');
            toggle.classList.toggle('active');
            nav.classList.toggle('open');
        }
    </script>
</body>
</html>
