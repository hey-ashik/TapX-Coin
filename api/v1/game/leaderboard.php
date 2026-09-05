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
            u.score,
            u.rank AS coins_rank,
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
        ['username' => 'QuantumTapper', 'name' => 'Quantum Tapper', 'level' => 5, 'streak_days' => 4, 'score' => 4850, 'coins_rank' => 1, 'total_reward' => 2500, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'CyberGhost',    'name' => 'Cyber Ghost',    'level' => 4, 'streak_days' => 3, 'score' => 4200, 'coins_rank' => 2, 'total_reward' => 2000, 'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'NovaStriker',   'name' => 'Nova Striker',   'level' => 4, 'streak_days' => 3, 'score' => 3750, 'coins_rank' => 3, 'total_reward' => 1750, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'VortexMaster',  'name' => 'Vortex Master',  'level' => 3, 'streak_days' => 2, 'score' => 3200, 'coins_rank' => 4, 'total_reward' => 1500, 'currency' => 'BDT', 'method' => 'Rocket'],
        ['username' => 'HyperPulse',    'name' => 'Hyper Pulse',    'level' => 3, 'streak_days' => 2, 'score' => 2850, 'coins_rank' => 5, 'total_reward' => 1200, 'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'ApexPredator',  'name' => 'Apex Predator',  'level' => 2, 'streak_days' => 2, 'score' => 2400, 'coins_rank' => 6, 'total_reward' => 1000, 'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'ShadowTap',     'name' => 'Shadow Tap',     'level' => 2, 'streak_days' => 1, 'score' => 1950, 'coins_rank' => 7, 'total_reward' => 800,  'currency' => 'BDT', 'method' => 'bKash'],
        ['username' => 'PulseRider',    'name' => 'Pulse Rider',    'level' => 2, 'streak_days' => 1, 'score' => 1600, 'coins_rank' => 8, 'total_reward' => 500,  'currency' => 'BDT', 'method' => 'Rocket'],
        ['username' => 'NeonFlash',     'name' => 'Neon Flash',     'level' => 1, 'streak_days' => 1, 'score' => 1300, 'coins_rank' => 9, 'total_reward' => 300,  'currency' => 'BDT', 'method' => 'Nagad'],
        ['username' => 'ChronoTrigger', 'name' => 'Chrono Trigger', 'level' => 1, 'streak_days' => 1, 'score' => 1050, 'coins_rank' => 10, 'total_reward' => 150,  'currency' => 'BDT', 'method' => 'bKash'],
    ];

    $entries = [];
    $seenUsernames = [];

    $currentWeekday = (int)date('N') - 1; // 0 = Mon, 6 = Sun

    foreach ($rows as $row) {
        $avatar = $row['avatar_url'];
        if (empty($avatar)) {
            $avatar = "https://ui-avatars.com/api/?name=" . urlencode($row['name'] ?: $row['username']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256";
        }
        $amount = (float)$row['total_reward'];
        $score = (int)($row['score'] ?? 0);
        $coinsRank = (int)($row['coins_rank'] ?? 1);

        $rawWeekly = [0, 0, 0, 0, 0, 0, 0];
        if ($score > 0) {
            $rawWeekly[$currentWeekday] = $score;
        }

        $entries[] = [
            'username'        => $row['username'],
            'score'           => $score,
            'coins_rank'      => $coinsRank,
            'reward_amount'   => $amount,
            'reward_currency' => strtoupper($row['currency'] ?: 'BDT'),
            'reward_method'   => $row['method'] ?: 'bKash',
            'level'           => (int)$row['level'],
            'streak_days'     => (int)$row['streak_days'],
            'avatar_url'      => $avatar,
            'raw_weekly_taps' => $rawWeekly,
            'is_reward_entry' => true,
        ];
        $seenUsernames[$row['username']] = true;
    }

    if (empty($search) && count($entries) < 10) {
        foreach ($starterRewards as $starter) {
            if (isset($seenUsernames[$starter['username']])) continue;
            $avatar = "https://ui-avatars.com/api/?name=" . urlencode($starter['name']) . "&background=1A1A1E&color=FFFFFF&bold=true&size=256";
            $score = (int)($starter['score'] ?? 0);
            $rawWeekly = [0, 0, 0, 0, 0, 0, 0];
            if ($score > 0) {
                $rawWeekly[$currentWeekday] = $score;
            }
            $entries[] = [
                'username'        => $starter['username'],
                'score'           => $score,
                'coins_rank'      => (int)($starter['coins_rank'] ?? 1),
                'reward_amount'   => (float)$starter['total_reward'],
                'reward_currency' => $starter['currency'],
                'reward_method'   => $starter['method'],
                'level'           => $starter['level'],
                'streak_days'     => $starter['streak_days'],
                'avatar_url'      => $avatar,
                'raw_weekly_taps' => $rawWeekly,
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
        $entry['rank'] = $pos;
        $entry['reward_rank'] = $pos;
        $pos++;
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
    $whereSearch = "AND (u.username LIKE :q OR u.name LIKE :q)";
    $params[':q'] = "%$search%";
}

$stmt = $db->prepare("
    SELECT 
        u.id, 
        u.name, 
        u.username, 
        u.score, 
        u.level, 
        u.streak_days, 
        u.avatar_url, 
        u.rank, 
        u.updated_at,
        COALESCE(SUM(CASE WHEN t.status IN ('completed', 'approved', 'paid') THEN t.amount ELSE 0 END), 0) AS total_reward,
        COALESCE(MAX(CASE WHEN t.status IN ('completed', 'approved', 'paid') THEN t.currency ELSE NULL END), 'BDT') AS reward_currency,
        COALESCE(MAX(CASE WHEN t.status IN ('completed', 'approved', 'paid') THEN t.method ELSE NULL END), 'bKash') AS reward_method
    FROM users u
    LEFT JOIN transactions t ON u.id = t.user_id
    WHERE (u.is_verified = 1 OR u.username IN ('QuantumTapper', 'CyberGhost', 'NovaStriker', 'VortexMaster', 'HyperPulse', 'ApexPredator', 'ShadowTap', 'PulseRider', 'NeonFlash', 'ChronoTrigger'))
    $whereSearch
    GROUP BY u.id
    ORDER BY u.score DESC
    LIMIT :limit
");
foreach ($params as $k => $v) {
    $stmt->bindValue($k, $v, $k === ':limit' ? PDO::PARAM_INT : PDO::PARAM_STR);
}
$stmt->execute();
$rows = $stmt->fetchAll();

// Starter reward lookup map for fallback demo users
$starterRewardMap = [
    'QuantumTapper' => ['total_reward' => 2500.0, 'method' => 'bKash', 'currency' => 'BDT', 'reward_rank' => 1],
    'CyberGhost'    => ['total_reward' => 2000.0, 'method' => 'Nagad', 'currency' => 'BDT', 'reward_rank' => 2],
    'NovaStriker'   => ['total_reward' => 1750.0, 'method' => 'bKash', 'currency' => 'BDT', 'reward_rank' => 3],
    'VortexMaster'  => ['total_reward' => 1500.0, 'method' => 'Rocket', 'currency' => 'BDT', 'reward_rank' => 4],
    'HyperPulse'    => ['total_reward' => 1200.0, 'method' => 'bKash', 'currency' => 'BDT', 'reward_rank' => 5],
    'ApexPredator'  => ['total_reward' => 1000.0, 'method' => 'Nagad', 'currency' => 'BDT', 'reward_rank' => 6],
    'ShadowTap'     => ['total_reward' => 800.0,  'method' => 'bKash', 'currency' => 'BDT', 'reward_rank' => 7],
    'PulseRider'    => ['total_reward' => 500.0,  'method' => 'Rocket', 'currency' => 'BDT', 'reward_rank' => 8],
    'NeonFlash'     => ['total_reward' => 300.0,  'method' => 'Nagad', 'currency' => 'BDT', 'reward_rank' => 9],
    'ChronoTrigger' => ['total_reward' => 150.0,  'method' => 'bKash', 'currency' => 'BDT', 'reward_rank' => 10],
];

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

    $rewardAmount = (float)$row['total_reward'];
    $rewardCurrency = strtoupper($row['reward_currency'] ?: 'BDT');
    $rewardMethod = $row['reward_method'] ?: 'bKash';
    $rewardRank = null;

    if ($rewardAmount <= 0 && isset($starterRewardMap[$row['username']])) {
        $starterInfo = $starterRewardMap[$row['username']];
        $rewardAmount = (float)$starterInfo['total_reward'];
        $rewardCurrency = $starterInfo['currency'];
        $rewardMethod = $starterInfo['method'];
        $rewardRank = (int)$starterInfo['reward_rank'];
    }

    $entries[] = [
        'rank'             => $pos,
        'coins_rank'       => $pos,
        'username'         => $row['username'],
        'score'            => $score,
        'level'            => (int)$row['level'],
        'streak_days'      => (int)$row['streak_days'],
        'avatar_url'       => $avatar,
        'activity_history' => $activityRates,
        'raw_weekly_taps'  => $rawWeekly,
        'reward_amount'    => $rewardAmount > 0 ? $rewardAmount : null,
        'reward_currency'  => $rewardCurrency,
        'reward_method'    => $rewardAmount > 0 ? $rewardMethod : null,
        'reward_rank'      => $rewardRank,
        'is_reward_entry'  => false,
    ];
    $pos++;
}

jsonSuccess([
    'type'    => $type,
    'entries' => $entries,
    'total'   => count($entries),
], 'Leaderboard retrieved successfully');
