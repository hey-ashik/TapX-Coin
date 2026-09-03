<?php
// api/admin/login.php

ini_set('display_errors', 0);
error_reporting(E_ALL);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/config/env.php';

if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    header('Location: index');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if (empty($username) || empty($password)) {
        $error = 'Please enter both username and password';
    } else {
        try {
            $db = Database::getConnection();
            $stmt = $db->prepare("SELECT * FROM admins WHERE username = :user OR email = :email LIMIT 1");
            $stmt->execute([':user' => $username, ':email' => $username]);
            $admin = $stmt->fetch();

            // Default master check fallback: admin / TapX@Admin2026
            if (($admin && password_verify($password, $admin['password_hash'])) || 
                ($username === 'admin' && $password === 'TapX@Admin2026')) {
                $_SESSION['admin_logged_in'] = true;
                $_SESSION['admin_username'] = $admin ? $admin['username'] : 'admin';
                $_SESSION['admin_id'] = $admin ? $admin['id'] : 1;
                header('Location: index');
                exit;
            } else {
                $error = 'Invalid admin credentials. Please try again.';
            }
        } catch (Throwable $e) {
            // Direct master password fallback if database is still provisioning
            if ($username === 'admin' && $password === 'TapX@Admin2026') {
                $_SESSION['admin_logged_in'] = true;
                $_SESSION['admin_username'] = 'admin';
                $_SESSION['admin_id'] = 1;
                header('Location: index');
                exit;
            }
            $error = 'Database Connection Notice: ' . $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TapX Admin Portal &bull; Login</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background: #09090B; color: #FAFAFA; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
        .login-card { background: #121215; border: 1px solid #27272A; border-radius: 24px; padding: 40px 32px; width: 100%; max-width: 420px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7); }
        .brand { text-align: center; margin-bottom: 28px; }
        .logo { font-size: 32px; font-weight: 900; letter-spacing: 4px; color: #FFFFFF; }
        .badge { display: inline-block; background: #27272A; color: #A1A1AA; font-size: 11px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase; padding: 4px 12px; border-radius: 20px; margin-top: 6px; }
        .form-group { margin-bottom: 18px; }
        label { display: block; font-size: 12px; font-weight: 600; color: #A1A1AA; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }
        input { width: 100%; background: #18181B; border: 1px solid #27272A; border-radius: 12px; padding: 14px 16px; font-size: 15px; color: #FFFFFF; outline: none; transition: border-color 0.2s; }
        input:focus { border-color: #FFFFFF; }
        .btn-submit { width: 100%; background: #FFFFFF; color: #000000; border: none; border-radius: 12px; padding: 14px; font-size: 15px; font-weight: 700; cursor: pointer; margin-top: 10px; transition: opacity 0.2s; }
        .btn-submit:hover { opacity: 0.9; }
        .error-box { background: rgba(239, 68, 68, 0.1); border: 1px solid #EF4444; color: #EF4444; font-size: 13px; padding: 12px; border-radius: 10px; margin-bottom: 18px; text-align: center; }
        .hint-box { background: #18181B; border: 1px solid #27272A; border-radius: 10px; padding: 12px; margin-top: 20px; font-size: 12px; color: #71717A; text-align: center; }
        .hint-box code { color: #E4E4E7; font-weight: 600; }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="brand">
            <div class="logo">TAPX</div>
            <div class="badge">Admin Command Center</div>
        </div>

        <?php if (!empty($error)): ?>
            <div class="error-box"><?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>

        <form method="POST">
            <div class="form-group">
                <label>Admin Username</label>
                <input type="text" name="username" value="admin" required autofocus>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" placeholder="••••••••••••" required>
            </div>
            <button type="submit" class="btn-submit">Sign In to Dashboard</button>
        </form>

        <div class="hint-box">
            Default credentials:<br>
            Username: <code>admin</code> &bull; Password: <code>TapX@Admin2026</code>
        </div>
    </div>
</body>
</html>
