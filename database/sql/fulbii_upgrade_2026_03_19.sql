-- Fulbii upgrade script (manual SQL, no Laravel migrations required)
-- Target: MySQL 8+

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- 1) users alignment for mobile onboarding and social auth
-- ---------------------------------------------------------------------------
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS nick VARCHAR(200) NULL AFTER name,
  ADD COLUMN IF NOT EXISTS sexo VARCHAR(2) NULL AFTER nick,
  ADD COLUMN IF NOT EXISTS fec_nac DATE NULL AFTER email,
  ADD COLUMN IF NOT EXISTS altura_cm SMALLINT UNSIGNED NULL AFTER fec_nac,
  ADD COLUMN IF NOT EXISTS estado VARCHAR(2) NOT NULL DEFAULT '1' AFTER altura_cm,
  ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(30) NULL AFTER password,
  ADD COLUMN IF NOT EXISTS provider_uid VARCHAR(191) NULL AFTER auth_provider,
  ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500) NULL AFTER provider_uid;

-- Ensure social login can create user before onboarding assigns nick.
ALTER TABLE users
  MODIFY COLUMN nick VARCHAR(200) NULL;

-- ---------------------------------------------------------------------------
-- 2) clubs settings for mobile behavior
-- ---------------------------------------------------------------------------
ALTER TABLE clubs
  ADD COLUMN IF NOT EXISTS is_visible TINYINT(1) NOT NULL DEFAULT 1 AFTER estado,
  ADD COLUMN IF NOT EXISTS pichanga_create_scope ENUM('admins','members') NOT NULL DEFAULT 'admins' AFTER is_visible,
  ADD COLUMN IF NOT EXISTS renotify_scope ENUM('admins','members') NOT NULL DEFAULT 'admins' AFTER pichanga_create_scope,
  ADD COLUMN IF NOT EXISTS renotify_cooldown_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 30 AFTER renotify_scope,
  ADD COLUMN IF NOT EXISTS renotify_max_per_pichanga SMALLINT UNSIGNED NOT NULL DEFAULT 5 AFTER renotify_cooldown_minutes,
  ADD COLUMN IF NOT EXISTS audience_max_degree TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER renotify_max_per_pichanga;

-- ---------------------------------------------------------------------------
-- 2.1) polideportivo alignment for mobile field APIs
-- ---------------------------------------------------------------------------
ALTER TABLE polideportivo
  ADD COLUMN IF NOT EXISTS direccion VARCHAR(255) NULL AFTER nombre;

-- ---------------------------------------------------------------------------
-- 3) per-user per-group notification preferences
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

-- ---------------------------------------------------------------------------
-- 4) Optional checks and recommendations
-- ---------------------------------------------------------------------------
-- Check duplicate group names (case-insensitive). Must be 0 rows to enforce DB-level unique later.
-- SELECT LOWER(TRIM(nombre)) AS nombre_ci, COUNT(*) c
-- FROM clubs
-- GROUP BY LOWER(TRIM(nombre))
-- HAVING c > 1;

-- Check duplicate nicks (case-insensitive). Must be 0 rows to enforce DB-level unique later.
-- SELECT LOWER(TRIM(nick)) AS nick_ci, COUNT(*) c
-- FROM users
-- WHERE nick IS NOT NULL AND nick <> ''
-- GROUP BY LOWER(TRIM(nick))
-- HAVING c > 1;

SET FOREIGN_KEY_CHECKS = 1;
