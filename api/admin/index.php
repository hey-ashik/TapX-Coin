<?php
// api/admin/index.php

require_once __DIR__ . '/auth.php';
requireAdminAuth();

$db = Database::getConnection();

// 1. Fetch Stats
$totalUsers = (int)$db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalTaps = (int)$db->query("SELECT SUM(score) FROM users")->fetchColumn();
$pendingPayoutsCount = (int)$db->query("SELECT COUNT(*) FROM transactions WHERE status = 'processing'")->fetchColumn();
$pendingPayoutsAmount = (float)$db->query("SELECT SUM(amount) FROM transactions WHERE status = 'processing'")->fetchColumn();
$completedPayoutsAmount = (float)$db->query("SELECT SUM(amount) FROM transactions WHERE status = 'completed'")->fetchColumn();

// 2. Fetch Pending Withdrawals
$pendingStmt = $db->query("
    SELECT t.*, u.name, u.email, u.username
    FROM transactions t
    JOIN users u ON t.user_id = u.id
    WHERE t.status = 'processing'
    ORDER BY t.created_at ASC
    LIMIT 10
");
$pendingTxs = $pendingStmt->fetchAll();

// 3. Fetch Recent Registered Users
$usersStmt = $db->query("
    SELECT id, name, username, email, score, level, streak_days, is_verified, created_at
    FROM users
    ORDER BY created_at DESC
    LIMIT 6
");
$recentUsers = $usersStmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TapX Admin Portal &bull; Dashboard</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        body { background: #09090B; color: #FAFAFA; min-height: 100vh; display: flex; flex-direction: column; }
        
        /* Header */
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

        /* 3-Line Hamburger Button */
        .hamburger { display: none; flex-direction: column; justify-content: space-around; width: 38px; height: 38px; background: #1E1E24; border: 1px solid #27272A; border-radius: 8px; cursor: pointer; padding: 9px 8px; z-index: 101; }
        .hamburger .bar { width: 100%; height: 2px; background: #FFFFFF; border-radius: 2px; transition: all 0.3s ease; }
        .hamburger.active .bar:nth-child(1) { transform: translateY(6px) rotate(45deg); }
        .hamburger.active .bar:nth-child(2) { opacity: 0; }
        .hamburger.active .bar:nth-child(3) { transform: translateY(-6px) rotate(-45deg); }

        /* Mobile Nav Drawer */
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
        }
        @media (min-width: 901px) {
            .mobile-user-nav { display: none; }
        }

        /* Container */
        .container { max-width: 1280px; width: 100%; margin: 0 auto; padding: 32px 24px; flex: 1; }

        /* KPI Grid */
        .kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 20px; margin-bottom: 36px; }
        .kpi-card { background: #121215; border: 1px solid #27272A; border-radius: 20px; padding: 24px; }
        .kpi-label { font-size: 12px; font-weight: 600; color: #71717A; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }
        .kpi-val { font-size: 32px; font-weight: 900; color: #FFFFFF; letter-spacing: -0.5px; }
        .kpi-sub { font-size: 12px; color: #A1A1AA; margin-top: 6px; }
        .kpi-card.highlight { border-color: #FFFFFF; box-shadow: 0 0 25px rgba(255, 255, 255, 0.05); }

        /* Section Layout */
        .section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .section-title { font-size: 18px; font-weight: 700; color: #FFFFFF; display: flex; align-items: center; gap: 10px; }
        .count-pill { background: #27272A; color: #FFFFFF; font-size: 12px; padding: 2px 8px; border-radius: 12px; }

        /* Table */
        .table-card { background: #121215; border: 1px solid #27272A; border-radius: 20px; overflow-x: auto; -webkit-overflow-scrolling: touch; margin-bottom: 36px; }
        table { width: 100%; min-width: 700px; border-collapse: collapse; text-align: left; font-size: 14px; }
        th { background: #18181B; padding: 14px 20px; font-size: 12px; font-weight: 600; color: #71717A; text-transform: uppercase; letter-spacing: 1px; border-bottom: 1px solid #27272A; }
        td { padding: 16px 20px; border-bottom: 1px solid #1E1E24; color: #E4E4E7; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #16161A; }
        .badge-method { background: #27272A; border: 1px solid #3F3F46; padding: 3px 8px; border-radius: 6px; font-size: 12px; font-weight: 700; color: #FFFFFF; }
        .badge-bdt { color: #22C55E; }
        .badge-status-processing { background: rgba(234, 179, 8, 0.15); color: #EAB308; border: 1px solid rgba(234, 179, 8, 0.4); padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        
        .action-btn { background: #FFFFFF; color: #000000; border: none; border-radius: 8px; padding: 6px 14px; font-size: 13px; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-block; }
        .action-btn:hover { opacity: 0.9; }
        .reject-btn { background: transparent; color: #EF4444; border: 1px solid rgba(239, 68, 68, 0.4); border-radius: 8px; padding: 6px 14px; font-size: 13px; font-weight: 600; cursor: pointer; margin-left: 6px; }
        .reject-btn:hover { background: rgba(239, 68, 68, 0.1); }

        .empty-state { padding: 48px; text-align: center; color: #71717A; font-size: 14px; }
    </style>
</head>
<body>
    <header>
        <div class="logo-group">
            <a href="index" class="logo">TAPX</a>
            <div class="admin-badge">Admin Hub</div>
        </div>
        
        <!-- 3-Line Hamburger Button -->
        <button class="hamburger" id="menuToggle" onclick="toggleMenu()" aria-label="Toggle Menu">
            <span class="bar"></span>
            <span class="bar"></span>
            <span class="bar"></span>
        </button>

        <!-- Navigation Links -->
        <nav class="nav-links" id="navLinks">
            <a href="index" class="active">Dashboard</a>
            <a href="withdrawals">Withdrawals <?php if ($pendingPayoutsCount > 0): ?><span class="count-pill"><?php echo $pendingPayoutsCount; ?></span><?php endif; ?></a>
            <a href="users">Users</a>
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
        <!-- KPI Metrics -->
        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-label">Total Tappers</div>
                <div class="kpi-val"><?php echo number_format($totalUsers); ?></div>
                <div class="kpi-sub">Registered community members</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Total Tap Volume</div>
                <div class="kpi-val"><?php echo number_format($totalTaps); ?></div>
                <div class="kpi-sub">Lifetime taps across all accounts</div>
            </div>
            <div class="kpi-card highlight">
                <div class="kpi-label">Pending Payouts</div>
                <div class="kpi-val" style="color: #EAB308;"><?php echo $pendingPayoutsCount; ?></div>
                <div class="kpi-sub">৳<?php echo number_format($pendingPayoutsAmount, 2); ?> awaiting disbursement</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Total Disbursed</div>
                <div class="kpi-val" style="color: #22C55E;">৳<?php echo number_format($completedPayoutsAmount, 2); ?></div>
                <div class="kpi-sub">Successfully transferred to users</div>
            </div>
        </div>

        <!-- Pending Withdrawals Queue -->
        <div class="section-header">
            <div class="section-title">
                <span>Pending Withdrawal Requests</span>
                <span class="count-pill"><?php echo count($pendingTxs); ?> pending</span>
            </div>
            <a href="withdrawals" style="color: #A1A1AA; font-size: 13px; text-decoration: none;">View All Withdrawals &rarr;</a>
        </div>

        <div class="table-card">
            <?php if (empty($pendingTxs)): ?>
                <div class="empty-state">
                    ✓ All withdrawal requests have been processed! No pending queues.
                </div>
            <?php else: ?>
                <table>
                    <thead>
                        <tr>
                            <th>Tx ID</th>
                            <th>User</th>
                            <th>Amount</th>
                            <th>Method</th>
                            <th>Account / Phone</th>
                            <th>Status</th>
                            <th>Requested At</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($pendingTxs as $tx): ?>
                            <tr>
                                <td><code><?php echo htmlspecialchars($tx['id']); ?></code></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($tx['name'] ?: $tx['username']); ?></strong><br>
                                    <span style="font-size: 12px; color: #71717A;"><?php echo htmlspecialchars($tx['email']); ?></span>
                                </td>
                                <td>
                                    <strong class="badge-bdt">
                                        <?php echo strtoupper($tx['currency']) === 'BDT' ? '৳' : '$'; ?><?php echo number_format($tx['amount'], 2); ?>
                                    </strong>
                                    <div style="font-size: 11px; color: #71717A;"><?php echo number_format($tx['taps_deducted']); ?> taps</div>
                                </td>
                                <td><span class="badge-method"><?php echo htmlspecialchars($tx['method']); ?></span></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($tx['destination']); ?></strong>
                                    <?php if (!empty($tx['account_name'])): ?>
                                        <div style="font-size: 12px; color: #71717A;"><?php echo htmlspecialchars($tx['account_name']); ?></div>
                                    <?php endif; ?>
                                </td>
                                <td><span class="badge-status-processing">Processing</span></td>
                                <td style="font-size: 12px; color: #A1A1AA;"><?php echo $tx['created_at']; ?></td>
                                <td>
                                    <button class="action-btn" onclick="confirmPayout('<?php echo $tx['id']; ?>', '<?php echo htmlspecialchars($tx['name'] ?: $tx['username']); ?>', '<?php echo $tx['amount']; ?>', '<?php echo $tx['currency']; ?>', '<?php echo htmlspecialchars($tx['destination']); ?>')">Confirm & Pay</button>
                                    <button class="reject-btn" onclick="rejectPayout('<?php echo $tx['id']; ?>')">Reject</button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
        </div>

        <!-- Recent Registered Users -->
        <div class="section-header">
            <div class="section-title">Recent Registered Users</div>
            <a href="users" style="color: #A1A1AA; font-size: 13px; text-decoration: none;">View All Users &rarr;</a>
        </div>

        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Email</th>
                        <th>Level</th>
                        <th>Total Score</th>
                        <th>Streak</th>
                        <th>Verified</th>
                        <th>Joined</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($recentUsers as $u): ?>
                        <tr>
                            <td><strong><?php echo htmlspecialchars($u['name'] ?: $u['username']); ?></strong></td>
                            <td style="color: #A1A1AA;"><?php echo htmlspecialchars($u['email']); ?></td>
                            <td>Level <?php echo $u['level']; ?></td>
                            <td><strong><?php echo number_format($u['score']); ?></strong></td>
                            <td>Day <?php echo $u['streak_days']; ?> 🔥</td>
                            <td>
                                <?php if ($u['is_verified']): ?>
                                    <span style="color: #22C55E; font-weight: 700; font-size: 12px;">✓ Verified</span>
                                <?php else: ?>
                                    <span style="color: #71717A; font-size: 12px;">Unverified</span>
                                <?php endif; ?>
                            </td>
                            <td style="font-size: 12px; color: #71717A;"><?php echo $u['created_at']; ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Payout Confirm Modal Script -->
    <script>
        function toggleMenu() {
            const toggle = document.getElementById('menuToggle');
            const nav = document.getElementById('navLinks');
            toggle.classList.toggle('active');
            nav.classList.toggle('open');
        }

        async function confirmPayout(txId, name, amount, currency, phone) {
            const symbol = currency.toUpperCase() === 'BDT' ? '৳' : '$';
            if (!confirm(`Are you sure you have transferred ${symbol}${amount} to ${name} (${phone}) and want to mark this payout as COMPLETED?\n\nThis will:\n1. Update status to Completed\n2. Send confirmation email to user\n3. Push an in-app notification to the user`)) {
                return;
            }

            try {
                const res = await fetch('../v1/admin/confirm-payout.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        transaction_id: txId,
                        notes: `Manually verified & paid to ${phone}`
                    })
                });
                const data = await res.json();
                if (data.success) {
                    alert('✓ Payout confirmed! Email and in-app notification sent to the user.');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            } catch (err) {
                alert('Network error: ' + err);
            }
        }

        async function rejectPayout(txId) {
            const reason = prompt('Please enter the rejection reason (Taps will be refunded back to user):', 'Incorrect account number / unverified account');
            if (!reason) return;

            try {
                const res = await fetch('../v1/admin/reject-payout.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        transaction_id: txId,
                        reason: reason
                    })
                });
                const data = await res.json();
                if (data.success) {
                    alert('✓ Payout rejected and taps refunded to user.');
                    location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            } catch (err) {
                alert('Network error: ' + err);
            }
        }
    </script>
</body>
</html>
