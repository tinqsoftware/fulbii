-- Fulbii upgrade script (compat for older MySQL/MariaDB that do not support
-- "ALTER TABLE ... ADD COLUMN IF NOT EXISTS")
-- Execute inside the target database (phpMyAdmin SQL tab or mysql client).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- users: mobile onboarding + social auth fields
-- ---------------------------------------------------------------------------
SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'nick'),
    'ALTER TABLE `users` ADD COLUMN `nick` VARCHAR(200) NULL AFTER `name`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'sexo'),
    'ALTER TABLE `users` ADD COLUMN `sexo` VARCHAR(2) NULL AFTER `nick`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'fec_nac'),
    'ALTER TABLE `users` ADD COLUMN `fec_nac` DATE NULL AFTER `email`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'altura_cm'),
    'ALTER TABLE `users` ADD COLUMN `altura_cm` SMALLINT UNSIGNED NULL AFTER `fec_nac`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'estado'),
    'ALTER TABLE `users` ADD COLUMN `estado` VARCHAR(2) NOT NULL DEFAULT ''1'' AFTER `altura_cm`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'auth_provider'),
    'ALTER TABLE `users` ADD COLUMN `auth_provider` VARCHAR(30) NULL AFTER `password`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'provider_uid'),
    'ALTER TABLE `users` ADD COLUMN `provider_uid` VARCHAR(191) NULL AFTER `auth_provider`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'avatar_url'),
    'ALTER TABLE `users` ADD COLUMN `avatar_url` VARCHAR(500) NULL AFTER `provider_uid`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- clubs: mobile behavior settings
-- ---------------------------------------------------------------------------
SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'is_visible'),
    'ALTER TABLE `clubs` ADD COLUMN `is_visible` TINYINT(1) NOT NULL DEFAULT 1 AFTER `estado`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'pichanga_create_scope'),
    'ALTER TABLE `clubs` ADD COLUMN `pichanga_create_scope` ENUM(''admins'',''members'') NOT NULL DEFAULT ''admins'' AFTER `is_visible`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'renotify_scope'),
    'ALTER TABLE `clubs` ADD COLUMN `renotify_scope` ENUM(''admins'',''members'') NOT NULL DEFAULT ''admins'' AFTER `pichanga_create_scope`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'renotify_cooldown_minutes'),
    'ALTER TABLE `clubs` ADD COLUMN `renotify_cooldown_minutes` SMALLINT UNSIGNED NOT NULL DEFAULT 30 AFTER `renotify_scope`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'renotify_max_per_pichanga'),
    'ALTER TABLE `clubs` ADD COLUMN `renotify_max_per_pichanga` SMALLINT UNSIGNED NOT NULL DEFAULT 5 AFTER `renotify_cooldown_minutes`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'clubs')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'clubs' AND column_name = 'audience_max_degree'),
    'ALTER TABLE `clubs` ADD COLUMN `audience_max_degree` TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER `renotify_max_per_pichanga`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- notification preferences table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_group_notification_prefs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  club_id BIGINT UNSIGNED NOT NULL,
  mode ENUM('always_on','mute_24h','mute_1w','mute_forever') NOT NULL DEFAULT 'always_on',
  muted_until TIMESTAMP NULL DEFAULT NULL,
  updated_by_user TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_club_notification_pref (user_id, club_id),
  KEY idx_club_mode (club_id, mode),
  KEY idx_muted_until (muted_until),
  CONSTRAINT fk_ugnp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ugnp_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;
