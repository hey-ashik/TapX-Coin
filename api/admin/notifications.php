<?php
// api/admin/notifications.php

require_once __DIR__ . '/auth.php';
requireAdminAuth();

$db = Database::getConnection();

$notifsStmt = $db->query("
    SELECT n.*, u.name as user_name, u.email as user_email
    FROM notifications n
    LEFT JOIN users u ON n.user_id = u.id
    ORDER BY n.created_at DESC
    LIMIT 40
");
$notifications = $notifsStmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TapX Admin Portal &bull; Notifications Broadcast</title>
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

        .layout-grid { display: grid; grid-template-columns: 380px 1fr; gap: 28px; }
        
        /* Composer Form */
        .composer-card { background: #121215; border: 1px solid #27272A; border-radius: 20px; padding: 24px; height: fit-content; }
        .composer-title { font-size: 18px; font-weight: 800; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; }
        .form-group { margin-bottom: 16px; }
        label { display: block; font-size: 12px; font-weight: 600; color: #A1A1AA; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px; }
        input, select, textarea { width: 100%; background: #18181B; border: 1px solid #27272A; border-radius: 10px; padding: 12px 14px; font-size: 14px; color: #FFFFFF; outline: none; transition: border-color 0.2s; }
        input:focus, select:focus, textarea:focus { border-color: #FFFFFF; }
        textarea { resize: vertical; min-height: 100px; }
        .btn-broadcast { width: 100%; background: #FFFFFF; color: #000000; border: none; border-radius: 12px; padding: 14px; font-size: 14px; font-weight: 700; cursor: pointer; transition: opacity 0.2s; }
        .btn-broadcast:hover { opacity: 0.9; }

        /* History Table */
        .history-card { background: #121215; border: 1px solid #27272A; border-radius: 20px; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; min-width: 600px; border-collapse: collapse; text-align: left; font-size: 14px; }
        th { background: #18181B; padding: 14px 20px; font-size: 12px; font-weight: 600; color: #71717A; text-transform: uppercase; letter-spacing: 1px; border-bottom: 1px solid #27272A; }
        td { padding: 16px 20px; border-bottom: 1px solid #1E1E24; color: #E4E4E7; vertical-align: top; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #16161A; }
        
        .type-badge { background: #27272A; color: #A1A1AA; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; text-transform: uppercase; display: inline-block; }
        .type-payout { background: rgba(34, 197, 94, 0.15); color: #22C55E; }
        .type-announcement { background: rgba(59, 130, 246, 0.15); color: #60A5FA; }
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
            <a href="notifications" class="active">Notifications</a>
            <a href="app-updates">App Updates</a>
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
        <div class="layout-grid">
            <!-- Composer -->
            <div class="composer-card">
                <div class="composer-title">📢 Push Announcement</div>
                <form id="broadcastForm">
                    <div class="form-group">
                        <label>Target Audience</label>
                        <select id="targetType" onchange="toggleUserSelect()">
                            <option value="all">Global (All Registered Users)</option>
                            <option value="specific">Specific User ID</option>
                        </select>
                    </div>
                    <div class="form-group" id="userIdGroup" style="display: none;">
                        <label>User ID</label>
                        <input type="text" id="targetUserId" placeholder="e.g. usr_001">
                    </div>
                    <div class="form-group">
                        <label>Title</label>
                        <input type="text" id="notifTitle" placeholder="e.g. ⚡ Double Multiplier Weekend!" required>
                    </div>
                    <div class="form-group">
                        <label>Message Content</label>
                        <textarea id="notifMessage" placeholder="Type your broadcast message to users..." required></textarea>
                    </div>
                    <div class="form-group">
                        <label>Notification Type</label>
                        <select id="notifType">
                            <option value="announcement">Announcement (Blue Badge)</option>
                            <option value="reward">Bonus / Reward (Gold Badge)</option>
                            <option value="system">System Notice (Grey Badge)</option>
                        </select>
                    </div>
                    <button type="submit" class="btn-broadcast" id="submitBtn">Send Notification Broadcast &rarr;</button>
                </form>
            </div>

            <!-- Sent History -->
            <div class="history-card">
                <table>
                    <thead>
                        <tr>
                            <th>Recipient</th>
                            <th>Notification</th>
                            <th>Type</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($notifications)): ?>
                            <tr>
                                <td colspan="4" style="text-align: center; color: #71717A; padding: 32px;">No notification history yet.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($notifications as $n): ?>
                                <tr>
                                    <td>
                                        <?php if ($n['user_id'] === null): ?>
                                            <strong style="color: #60A5FA;">📢 Global (All)</strong>
                                        <?php else: ?>
                                            <strong><?php echo htmlspecialchars($n['user_name'] ?: 'User'); ?></strong><br>
                                            <span style="font-size: 11px; color: #71717A;"><?php echo htmlspecialchars($n['user_email'] ?? $n['user_id']); ?></span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <div style="font-weight: 700; color: #FFFFFF; margin-bottom: 4px;"><?php echo htmlspecialchars($n['title']); ?></div>
                                        <div style="font-size: 13px; color: #A1A1AA; line-height: 1.4;"><?php echo htmlspecialchars($n['message']); ?></div>
                                    </td>
                                    <td>
                                        <span class="type-badge type-<?php echo $n['type']; ?>"><?php echo htmlspecialchars($n['type']); ?></span>
                                    </td>
                                    <td style="font-size: 12px; color: #71717A; white-space: nowrap;"><?php echo $n['created_at']; ?></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
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

        function toggleUserSelect() {
            const type = document.getElementById('targetType').value;
            document.getElementById('userIdGroup').style.display = type === 'specific' ? 'block' : 'none';
        }

        document.getElementById('broadcastForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            const btn = document.getElementById('submitBtn');
            btn.disabled = true;
            btn.innerText = 'Broadcasting...';

            const payload = {
                title: document.getElementById('notifTitle').value.trim(),
                message: document.getElementById('notifMessage').value.trim(),
                type: document.getElementById('notifType').value,
                user_id: document.getElementById('targetType').value === 'specific' ? document.getElementById('targetUserId').value.trim() : null
            };

            try {
                const res = await fetch('../v1/admin/broadcast-notification.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (data.success) {
                    alert('✓ ' + data.message);
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            } catch (err) {
                alert('Network error: ' + err);
            } finally {
                btn.disabled = false;
                btn.innerText = 'Send Notification Broadcast →';
            }
        });
    </script>
</body>
</html>
