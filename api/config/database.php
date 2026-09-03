<?php
// api/config/database.php

require_once __DIR__ . '/env.php';

class Database {
    private static $pdo = null;

    public static function getConnection() {
        if (self::$pdo !== null) {
            return self::$pdo;
        }

        $host = Env::get('DB_HOST', 'localhost');
        $port = Env::get('DB_PORT', '3306');
        $db   = Env::get('DB_NAME', 'u697802579_tapxdb');
        $user = Env::get('DB_USER', 'u697802579_tapxuser');
        $pass = Env::get('DB_PASS', 'Ashik@21032001');

        $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];

        try {
            self::$pdo = new PDO($dsn, $user, $pass, $options);
            self::ensureTablesExist();
            return self::$pdo;
        } catch (PDOException $e) {
            error_log("Database connection error: " . $e->getMessage());
            throw new Exception("Database connection failed: " . $e->getMessage());
        }
    }

    public static function ensureTablesExist() {
        if (self::$pdo === null) return;

        $schema = "
        CREATE TABLE IF NOT EXISTS `users` (
            `id` VARCHAR(64) PRIMARY KEY,
            `name` VARCHAR(100) NOT NULL,
            `username` VARCHAR(100) UNIQUE NOT NULL,
            `email` VARCHAR(150) UNIQUE NOT NULL,
            `password_hash` VARCHAR(255) NOT NULL,
            `avatar_url` VARCHAR(500) NULL,
            `rank` INT DEFAULT 1,
            `level` INT DEFAULT 1,
            `score` BIGINT DEFAULT 0,
            `streak_days` INT DEFAULT 1,
            `phone` VARCHAR(30) NULL,
            `twitter_handle` VARCHAR(100) NULL,
            `discord_username` VARCHAR(100) NULL,
            `is_verified` TINYINT(1) DEFAULT 0,
            `auth_token` VARCHAR(255) NULL,
            `token_expires_at` DATETIME NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS `admins` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `username` VARCHAR(100) UNIQUE NOT NULL,
            `email` VARCHAR(150) UNIQUE NOT NULL,
            `password_hash` VARCHAR(255) NOT NULL,
            `role` VARCHAR(50) DEFAULT 'superadmin',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS `otps` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `email` VARCHAR(150) NOT NULL,
            `otp_code` VARCHAR(10) NOT NULL,
            `expires_at` DATETIME NOT NULL,
            `is_used` TINYINT(1) DEFAULT 0,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX (`email`),
            INDEX (`otp_code`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS `transactions` (
            `id` VARCHAR(64) PRIMARY KEY,
            `user_id` VARCHAR(64) NOT NULL,
            `amount` DECIMAL(10, 2) NOT NULL,
            `currency` VARCHAR(10) DEFAULT 'bdt',
            `taps_deducted` BIGINT NOT NULL,
            `method` VARCHAR(50) NOT NULL,
            `account_name` VARCHAR(100) NULL,
            `destination` VARCHAR(255) NOT NULL,
            `status` VARCHAR(20) DEFAULT 'processing',
            `admin_notes` TEXT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX (`user_id`),
            FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS `notifications` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `user_id` VARCHAR(64) NULL, -- NULL means global announcement to all users
            `title` VARCHAR(255) NOT NULL,
            `message` TEXT NOT NULL,
            `type` VARCHAR(50) DEFAULT 'system', -- 'payout_completed', 'payout_rejected', 'announcement', 'bonus'
            `is_read` TINYINT(1) DEFAULT 0,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX (`user_id`),
            INDEX (`is_read`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS `app_updates` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `latest_version` VARCHAR(20) NOT NULL DEFAULT '1.0.0',
            `min_version` VARCHAR(20) NOT NULL DEFAULT '1.0.0',
            `apk_url` TEXT NOT NULL,
            `release_notes` TEXT NOT NULL,
            `is_force_update` TINYINT(1) DEFAULT 0,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ";

        try {
            self::$pdo->exec($schema);

            // Seed default master admin if none exists
            $adminCheck = self::$pdo->query("SELECT COUNT(*) FROM admins")->fetchColumn();
            if ($adminCheck == 0) {
                $masterPass = password_hash('TapX@Admin2026', PASSWORD_BCRYPT);
                $seedAdmin = self::$pdo->prepare("
                    INSERT INTO admins (username, email, password_hash, role)
                    VALUES ('admin', 'admin@tapx.ashiik.com', :pass, 'superadmin')
                ");
                $seedAdmin->execute([':pass' => $masterPass]);
            }

            // Seed default app update config if none exists
            $updateCheck = self::$pdo->query("SELECT COUNT(*) FROM app_updates")->fetchColumn();
            if ($updateCheck == 0) {
                $seedUpdate = self::$pdo->prepare("
                    INSERT INTO app_updates (latest_version, min_version, apk_url, release_notes, is_force_update)
                    VALUES ('1.0.0', '1.0.0', 'https://tapx.ashiik.com/api/uploads/updates/tapx-release.apk', '• Welcome to TapX v1.0.0!\\n• 2x Doubling 7-Day Daily Streak Bonus\\n• Instant bKash & Nagad Withdrawals\\n• Real-Time Leaderboards & Live Taps Tracker', 0)
                ");
                $seedUpdate->execute();
            }
        } catch (PDOException $e) {
            error_log("Schema auto-creation note: " . $e->getMessage());
        }
    }
}
