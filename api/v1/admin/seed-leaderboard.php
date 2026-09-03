<?php
// api/v1/admin/seed-leaderboard.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';
require_once dirname(__DIR__, 2) . '/config/admin_auth.php';

requireAdminApiAuth();

$db = Database::getConnection();

$defaultUsers = [
    ['id' => 'usr_001', 'name' => 'Quantum Tapper', 'username' => 'QuantumTapper', 'email' => 'quantum@tapx.app', 'score' => 4850, 'level' => 5, 'streak_days' => 4, 'rank' => 1],
    ['id' => 'usr_002', 'name' => 'Cyber Ghost',    'username' => 'CyberGhost',    'email' => 'cyber@tapx.app',   'score' => 4200, 'level' => 4, 'streak_days' => 3, 'rank' => 2],
    ['id' => 'usr_003', 'name' => 'Nova Striker',   'username' => 'NovaStriker',   'email' => 'nova@tapx.app',    'score' => 3750, 'level' => 4, 'streak_days' => 3, 'rank' => 3],
    ['id' => 'usr_004', 'name' => 'Vortex Master',  'username' => 'VortexMaster',  'email' => 'vortex@tapx.app',  'score' => 3200, 'level' => 3, 'streak_days' => 2, 'rank' => 4],
    ['id' => 'usr_005', 'name' => 'Hyper Pulse',    'username' => 'HyperPulse',    'email' => 'hyper@tapx.app',   'score' => 2850, 'level' => 3, 'streak_days' => 2, 'rank' => 5],
    ['id' => 'usr_006', 'name' => 'Apex Predator',  'username' => 'ApexPredator',  'email' => 'apex@tapx.app',    'score' => 2400, 'level' => 2, 'streak_days' => 2, 'rank' => 6],
    ['id' => 'usr_007', 'name' => 'Shadow Tap',     'username' => 'ShadowTap',     'email' => 'shadow@tapx.app',  'score' => 1950, 'level' => 2, 'streak_days' => 1, 'rank' => 7],
    ['id' => 'usr_008', 'name' => 'Pulse Rider',    'username' => 'PulseRider',    'email' => 'pulse@tapx.app',   'score' => 1600, 'level' => 2, 'streak_days' => 1, 'rank' => 8],
    ['id' => 'usr_009', 'name' => 'Neon Flash',     'username' => 'NeonFlash',     'email' => 'neon@tapx.app',    'score' => 1300, 'level' => 1, 'streak_days' => 1, 'rank' => 9],
    ['id' => 'usr_010', 'name' => 'Chrono Trigger', 'username' => 'ChronoTrigger', 'email' => 'chrono@tapx.app',  'score' => 1050, 'level' => 1, 'streak_days' => 1, 'rank' => 10],
];

$stmt = $db->prepare("
    INSERT INTO users (id, name, username, email, password_hash, avatar_url, rank, level, score, streak_days, is_verified)
    VALUES (:id, :name, :username, :email, :pass, :avatar, :rank, :level, :score, :streak, 1)
    ON DUPLICATE KEY UPDATE 
        score = VALUES(score),
        rank = VALUES(rank),
        level = VALUES(level),
        streak_days = VALUES(streak_days)
");

$seeded = 0;
foreach ($defaultUsers as $u) {
    $avatar = 'https://ui-avatars.com/api/?name=' . urlencode($u['name']) . '&background=1A1A1E&color=FFFFFF&bold=true&size=256';
    $stmt->execute([
        ':id'       => $u['id'],
        ':name'     => $u['name'],
        ':username' => $u['username'],
        ':email'    => $u['email'],
        ':pass'     => password_hash('TapX@Starter2026', PASSWORD_BCRYPT),
        ':avatar'   => $avatar,
        ':rank'     => $u['rank'],
        ':level'    => $u['level'],
        ':score'    => $u['score'],
        ':streak'   => $u['streak_days'],
    ]);
    $seeded++;
}

jsonSuccess([
    'seeded_count' => $seeded,
    'users'        => $defaultUsers,
], 'Default leaderboard users seeded successfully');
