-- TapX MySQL Database Schema
-- Database: u697802579_tapxdb
-- Host: localhost

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Users Table
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

-- 2. Admins Table
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(100) UNIQUE NOT NULL,
    `email` VARCHAR(150) UNIQUE NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` VARCHAR(50) DEFAULT 'superadmin',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. OTP Verification Codes Table
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

-- 4. Payout Transactions Table
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

-- 5. In-App Notifications & Global Broadcasts Table
CREATE TABLE IF NOT EXISTS `notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(64) NULL, -- NULL means broadcast to all users
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` VARCHAR(50) DEFAULT 'system',
    `is_read` TINYINT(1) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX (`user_id`),
    INDEX (`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Master Admin Seed (Password: TapX@Admin2026)
INSERT IGNORE INTO `admins` (`id`, `username`, `email`, `password_hash`, `role`)
VALUES
(1, 'admin', 'admin@tapx.ashiik.com', '$2y$10$wE9K2O9L017q4H45oK3BReYV42s04bM5H7ZqGjYQx7Kx7vO6Yx9Xe', 'superadmin');

-- Seed Starter Leaderboard Data (1,000 to 5,000 taps)
INSERT IGNORE INTO `users` (`id`, `name`, `username`, `email`, `password_hash`, `avatar_url`, `rank`, `level`, `score`, `streak_days`, `is_verified`)
VALUES
('usr_001', 'Quantum Tapper', 'QuantumTapper', 'quantum@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Quantum+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256', 1, 5, 4850, 4, 1),
('usr_002', 'Cyber Ghost', 'CyberGhost', 'cyber@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Cyber+Ghost&background=1A1A1E&color=FFFFFF&bold=true&size=256', 2, 4, 4200, 3, 1),
('usr_003', 'Nova Striker', 'NovaStriker', 'nova@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Nova+Striker&background=1A1A1E&color=FFFFFF&bold=true&size=256', 3, 4, 3750, 3, 1),
('usr_004', 'Vortex Master', 'VortexMaster', 'vortex@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Vortex+Master&background=1A1A1E&color=FFFFFF&bold=true&size=256', 4, 3, 3200, 2, 1),
('usr_005', 'Hyper Pulse', 'HyperPulse', 'hyper@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Hyper+Pulse&background=1A1A1E&color=FFFFFF&bold=true&size=256', 5, 3, 2850, 2, 1),
('usr_006', 'Apex Predator', 'ApexPredator', 'apex@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Apex+Predator&background=1A1A1E&color=FFFFFF&bold=true&size=256', 6, 2, 2400, 2, 1),
('usr_007', 'Shadow Tap', 'ShadowTap', 'shadow@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Shadow+Tap&background=1A1A1E&color=FFFFFF&bold=true&size=256', 7, 2, 1950, 1, 1),
('usr_008', 'Pulse Rider', 'PulseRider', 'pulse@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Pulse+Rider&background=1A1A1E&color=FFFFFF&bold=true&size=256', 8, 2, 1600, 1, 1),
('usr_009', 'Neon Flash', 'NeonFlash', 'neon@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Neon+Flash&background=1A1A1E&color=FFFFFF&bold=true&size=256', 9, 1, 1300, 1, 1),
('usr_010', 'Chrono Trigger', 'ChronoTrigger', 'chrono@tapx.app', '$2y$10$abcdefghijklmnopqrstuv', 'https://ui-avatars.com/api/?name=Chrono+Trigger&background=1A1A1E&color=FFFFFF&bold=true&size=256', 10, 1, 1050, 1, 1);

-- Initial System Notifications
INSERT IGNORE INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `is_read`)
VALUES
(1, NULL, 'Welcome to TapX!', 'Welcome to TapX! Tap continuous combos to charge energy and claim 2x daily streak bonuses.', 'announcement', 0),
(2, NULL, 'bKash & Nagad Payouts Online', 'Fast automated withdrawals to bKash and Nagad are now active with 1-24h verification.', 'system', 0);

-- App Updates Table & Seed
CREATE TABLE IF NOT EXISTS `app_updates` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `latest_version` VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    `min_version` VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    `apk_url` TEXT NOT NULL,
    `release_notes` TEXT NOT NULL,
    `is_force_update` TINYINT(1) DEFAULT 0,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `app_updates` (`id`, `latest_version`, `min_version`, `apk_url`, `release_notes`, `is_force_update`)
VALUES
(1, '1.0.0', '1.0.0', 'https://tapx.ashiik.com/api/uploads/updates/tapx-release.apk', '• Welcome to TapX v1.0.0!\n• 2x Doubling 7-Day Daily Streak Bonus\n• Instant bKash & Nagad Withdrawals\n• Real-Time Leaderboards & Live Taps Tracker', 0);

SET FOREIGN_KEY_CHECKS = 1;
