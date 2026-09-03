<?php
// api/v1/game/leaderboard.php

require_once dirname(__DIR__, 2) . '/config/cors.php';
require_once dirname(__DIR__, 2) . '/config/database.php';

$type = isset($_GET['type']) ? strtolower(trim($_GET['type'])) : 'global';
$search = isset($_GET['q']) ? trim($_GET['q']) : '';
$db = Database::getConnection();

// -------------------------------------------------------------
// 1. REWARDS / PAYOUTS LEADERBOARD
// -------------------------------------------------------------
if ($type === 'rewards' || $type === 'weekly') {
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $limit = max(1, min(50, $limit));

    $whereSearch = "";
    $params = [':limit' => $limit];
    if (!empty($search)) {
        $whereSearch = "AND (u.username LIKE :q OR u.name LIKE :q)";
        $params[':q'] = "%$search%";
    }

    $stmt = $db->prepare("
        SELECT 
            u.id, 
            u.name, 
            u.username, 
            u.level, 
            u.streak_days, 
            u.avatar_url,
            COALESCE(SUM(t.amount), 0) AS total_reward,
            COALESCE(MAX(t.currency), 'BDT') AS currency,
            COALESCE(MAX(t.method), 'bKash') AS method,
            COUNT(t.id) AS payout_count
        FROM users u
        INNER JOIN transactions t ON u.id = t.user_id
        WHERE t.status IN ('completed', 'approved', 'paid')
        $whereSearch
        GROUP BY u.id
        ORDER BY total_reward DESC
        LIMIT :limit
    ");
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v, $k === ':limit' ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $rows = $stmt->fetchAll();

    // Starter demo payouts with realistic top-tier payout sums
    $starterRewards = [
        ['username' => 'QuantumTapper', 'name' => 'Quantum Tapper', 'level' => 5, 'streak_days' => 4, 'total_reward' => 2500, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'CyberGhost',    'name' => 'Cyber Ghost',    'level' => 4, 'streak_days' => 3, 'total_reward' => 2000, 'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'NovaStriker',   'name' => 'Nova Striker',   'level' => 4, 'streak_days' => 3, 'total_reward' => 1750, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'VortexMaster',  'name' => 'Vortex Master',  'level' => 3, 'streak_days' => 2, 'total_reward' => 1500, 'currency' => 'BDT', 'method' => 'Rocket'],
        ['username' => 'HyperPulse',    'name' => 'Hyper Pulse',    'level' => 3, 'streak_days' => 2, 'total_reward' => 1200, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'ApexPredator',  'name' => 'Apex Predator',  'level' => 2, 'streak_days' => 2, 'total_reward' => 1000, 'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'ShadowTap',     'name' => 'Shadow Tap',     'level' => 2, 'streak_days' => 1, 'total_reward' => 800,  'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'PulseRider',    'name' => 'Pulse Rider',    'level' => 2, 'streak_days' => 1, 'total_reward' => 500,  'currency' => 'BDT', 'method' => 'Rocket'],
        ['username' => 'NeonFlash',     'name' => 'Neon Flash',     'level' => 1, 'streak_days' => 1, 'total_reward' => 300,  'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'ChronoTrigger', 'name' => 'Chrono Trigger', 'level' => 1, 'streak_days' => 1, 'total_reward' => 150,  'currency' => 'BDT', 'method' => 'bKash'],
    ];

    $entries = [];
    $seenUsernames = [];

    foreach ($rows as $row) {
        $avatar = $row['avatar_url'];
        if (empty($avatar)) {
            $avatar = "https://ui-avatars.com/api/?name=" . urlencode($row['name'] ?: $row['username']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256";
        }
        $amount = (float)$row['total_reward'];
        $entries[] = [
            'username'        => $row['username'],
            'score'           => (int)$amount,
            'reward_amount'   => $amount,
            'reward_currency' => strtoupper($row['currency'] ?: 'BDT'),
            'reward_method'   => $row['method'] ?: 'bKash',
            'level'           => (int)$row['level'],
            'streak_days'     => (int)$row['streak_days'],
            'avatar_url'      => $avatar,
            'is_reward_entry' => true,
        ];
        $seenUsernames[$row['username']] = true;
    }

    if (empty($search) && count($entries) < 10) {
        foreach ($starterRewards as $starter) {
            if (isset($seenUsernames[$starter['username']])) continue;
            $avatar = "https://ui-avatars.com/api/?name=" . urlencode($starter['name']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256";
            $entries[] = [
                'username'        => $starter['username'],
                'score'           => (int)$starter['total_reward'],
                'reward_amount'   => (float)$starter['total_reward'],
                'reward_currency' => $starter['currency'],
                'reward_method'   => $starter['method'],
                'level'           => $starter['level'],
                'streak_days'     => $starter['streak_days'],
                'avatar_url'      => $avatar,
                'is_reward_entry' => true,
            ];
            $seenUsernames[$starter['username']] = true;
            if (count($entries) >= 10) break;
        }
    }

    // Sort strictly in descending order of payout amount (highest payout first)
    usort($entries, function($a, $b) {
        if ($b['reward_amount'] == $a['reward_amount']) return 0;
        return ($b['reward_amount'] > $a['reward_amount']) ? 1 : -1;
    });

    // Re-assign accurate 1..N ranks based on descending reward amounts
    $pos = 1;
    foreach ($entries as &$entry) {
        $entry['rank'] = $pos++;
    }
    unset($entry);

    jsonSuccess([
        'type'    => 'rewards',
        'entries' => $entries,
        'total'   => count($entries),
    ], 'Rewards leaderboard retrieved successfully');
    exit;
}

// -------------------------------------------------------------
// 2. GLOBAL RANKERS LEADERBOARD
// -------------------------------------------------------------
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
$limit = max(1, min(50, $limit));

$whereSearch = "";
$params = [':limit' => $limit];
if (!empty($search)) {
    $whereSearch = "AND (username LIKE :q OR name LIKE :q)";
    $params[':q'] = "%$search%";
}

$stmt = $db->prepare("
    SELECT id, name, username, score, level, streak_days, avatar_url, rank, updated_at
    FROM users
    WHERE (is_verified = 1 OR username IN ('QuantumTapper', 'CyberGhost', 'NovaStriker', 'VortexMaster', 'HyperPulse', 'ApexPredator', 'ShadowTap', 'PulseRider', 'NeonFlash', 'ChronoTrigger'))
    $whereSearch
    ORDER BY score DESC
    LIMIT :limit
");
foreach ($params as $k => $v) {
    $stmt->bindValue($k, $v, $k === ':limit' ? PDO::PARAM_INT : PDO::PARAM_STR);
}
$stmt->execute();
$rows = $stmt->fetchAll();

$currentWeekday = (int)date('N') - 1; // 0 = Mon, 6 = Sun
$entries = [];
$pos = 1;
foreach ($rows as $row) {
    $avatar = $row['avatar_url'];
    if (empty($avatar)) {
        $avatar = "https://ui-avatars.com/api/?name=" . urlencode($row['name'] ?: $row['username']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256";
    }

    $score = (int)$row['score'];
    $rawWeekly = [0, 0, 0, 0, 0, 0, 0];
    if ($score > 0) {
        $rawWeekly[$currentWeekday] = $score;
    }

    $activityRates = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    if ($score > 0) {
        $activityRates[$currentWeekday] = 1.0;
    }

    $entries[] = [
        'rank'             => $pos,
        'username'         => $row['username'],
        'score'            => $score,
        'level'            => (int)$row['level'],
        'streak_days'      => (int)$row['streak_days'],
        'avatar_url'       => $avatar,
        'activity_history' => $activityRates,
        'raw_weekly_taps'  => $rawWeekly,
        'is_reward_entry'  => false,
    ];
    $pos++;
}

jsonSuccess([
    'type'    => $type,
    'entries' => $entries,
    'total'   => count($entries),
], 'Leaderboard retrieved successfully');
