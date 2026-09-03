<?php
// api/admin/users.php

require_once __DIR__ . '/auth.php';
requireAdminAuth();

$db = Database::getConnection();

$search = isset($_GET['q']) ? trim($_GET['q']) : '';

// Handle manual balance adjustment
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'adjust_score') {
    $userId = trim($_POST['user_id'] ?? '');
    $newScore = (int)($_POST['score'] ?? 0);
    if (!empty($userId)) {
        $update = $db->prepare("UPDATE users SET score = :score, updated_at = NOW() WHERE id = :id");
        $update->execute([':score' => $newScore, ':id' => $userId]);
        header('Location: users?q=' . urlencode($search) . '&msg=Score+updated');
        exit;
    }
}

$whereSql = "";
$params = [];

if (!empty($search)) {
    $whereSql = "WHERE (name LIKE :s OR username LIKE :s OR email LIKE :s OR phone LIKE :s)";
    $params[':s'] = "%$search%";
}

$stmt = $db->prepare("
    SELECT id, name, username, email, avatar_url, rank, level, score, streak_days, phone, is_verified, created_at
    FROM users
    $whereSql
    ORDER BY score DESC
    LIMIT 50
");
$stmt->execute($params);
$users = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TapX Admin Portal &bull; Users</title>
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
            .toolbar { flex-direction: column; align-items: stretch !important; }
            .search-input { width: 100% !important; }
        }
        @media (min-width: 901px) {
            .mobile-user-nav { display: none; }
        }
        
        .container { max-width: 1280px; width: 100%; margin: 0 auto; padding: 32px 24px; flex: 1; }

        .toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 24px; }
        .search-input { background: #121215; border: 1px solid #27272A; border-radius: 10px; padding: 10px 18px; font-size: 14px; color: #FFFFFF; outline: none; width: 340px; }
        .search-input:focus { border-color: #FFFFFF; }

        .table-card { background: #121215; border: 1px solid #27272A; border-radius: 20px; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; min-width: 750px; border-collapse: collapse; text-align: left; font-size: 14px; }
        th { background: #18181B; padding: 14px 20px; font-size: 12px; font-weight: 600; color: #71717A; text-transform: uppercase; letter-spacing: 1px; border-bottom: 1px solid #27272A; }
        td { padding: 16px 20px; border-bottom: 1px solid #1E1E24; color: #E4E4E7; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #16161A; }
        
        .avatar { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; border: 1px solid #3F3F46; }
        .user-cell { display: flex; align-items: center; gap: 12px; }
        
        .action-btn { background: #18181B; border: 1px solid #27272A; color: #FFFFFF; border-radius: 8px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; }
        .action-btn:hover { background: #27272A; }
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
            <a href="users" class="active">Users</a>
            <a href="notifications">Notifications</a>
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
        <div class="toolbar">
            <h2 style="font-size: 20px; font-weight: 700;">Community Directory (<?php echo count($users); ?>)</h2>
            <form method="GET" action="users" style="display: flex; gap: 8px; width: 100%; max-width: 380px;">
                <input type="text" name="q" class="search-input" placeholder="Search by name, email, username..." value="<?php echo htmlspecialchars($search); ?>">
                <button type="submit" style="background: #27272A; border: 1px solid #3F3F46; color: #FFFFFF; border-radius: 10px; padding: 0 16px; font-weight: 600; cursor: pointer;">Search</button>
            </form>
        </div>

        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Email / Contact</th>
                        <th>Level</th>
                        <th>Total Score</th>
                        <th>Streak</th>
                        <th>Status</th>
                        <th>Registered</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($users as $u): ?>
                        <tr>
                            <td>
                                <div class="user-cell">
                                    <img src="<?php echo !empty($u['avatar_url']) ? htmlspecialchars($u['avatar_url']) : 'https://ui-avatars.com/api/?name=' . urlencode($u['name'] ?: $u['username']) . '&background=27272A&color=FFFFFF'; ?>" class="avatar" alt="Avatar">
                                    <div>
                                        <strong><?php echo htmlspecialchars($u['name'] ?: $u['username']); ?></strong>
                                        <div style="font-size: 12px; color: #71717A;">@<?php echo htmlspecialchars($u['username']); ?></div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div><?php echo htmlspecialchars($u['email']); ?></div>
                                <?php if (!empty($u['phone'])): ?>
                                    <div style="font-size: 12px; color: #71717A;"><?php echo htmlspecialchars($u['phone']); ?></div>
                                <?php endif; ?>
                            </td>
                            <td>Level <?php echo $u['level']; ?></td>
                            <td><strong style="color: #FFFFFF; font-size: 15px;"><?php echo number_format($u['score']); ?></strong></td>
                            <td>Day <?php echo $u['streak_days']; ?> 🔥</td>
                            <td>
                                <?php if ($u['is_verified']): ?>
                                    <span style="color: #22C55E; font-weight: 700; font-size: 12px;">✓ Verified</span>
                                <?php else: ?>
                                    <span style="color: #71717A; font-size: 12px;">Unverified</span>
                                <?php endif; ?>
                            </td>
                            <td style="font-size: 12px; color: #71717A;"><?php echo $u['created_at']; ?></td>
                            <td>
                                <button class="action-btn" onclick="adjustScore('<?php echo $u['id']; ?>', '<?php echo htmlspecialchars($u['name'] ?: $u['username']); ?>', '<?php echo $u['score']; ?>')">Adjust Score</button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Hidden Form for Score Adjustment -->
    <form id="adjustScoreForm" method="POST" action="users" style="display: none;">
        <input type="hidden" name="action" value="adjust_score">
        <input type="hidden" name="user_id" id="adjUserId">
        <input type="hidden" name="score" id="adjScore">
    </form>

    <script>
        function toggleMenu() {
            const toggle = document.getElementById('menuToggle');
            const nav = document.getElementById('navLinks');
            toggle.classList.toggle('active');
            nav.classList.toggle('open');
        }

        function adjustScore(userId, name, currentScore) {
            const newScore = prompt(`Adjust tap score for ${name} (Current: ${currentScore}):`, currentScore);
            if (newScore !== null && !isNaN(parseInt(newScore))) {
                document.getElementById('adjUserId').value = userId;
                document.getElementById('adjScore').value = parseInt(newScore);
                document.getElementById('adjustScoreForm').submit();
            }
        }
    </script>
</body>
</html>
