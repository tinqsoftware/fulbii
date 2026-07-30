-- Fulbii big block: group pichangas + audience + external requests + renotify
-- Compatible with MySQL/MariaDB (manual execution)

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS group_pichangas (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(160) NULL,
  description TEXT NULL,
  field_id INT UNSIGNED NULL,
  address VARCHAR(255) NULL,
  starts_at DATETIME NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  capacity SMALLINT UNSIGNED NOT NULL,
  status ENUM('published','confirmed','cancelled','completed') NOT NULL DEFAULT 'published',
  confirmation_mode ENUM('auto_by_capacity','manual_paid') NOT NULL DEFAULT 'auto_by_capacity',
  is_open TINYINT(1) NOT NULL DEFAULT 0,
  notify_degree TINYINT UNSIGNED NOT NULL DEFAULT 1,
  allow_external_requests TINYINT(1) NOT NULL DEFAULT 0,
  withdraw_until DATETIME NULL,
  audience_sex ENUM('M','F') NULL,
  audience_age_min TINYINT UNSIGNED NULL,
  audience_age_max TINYINT UNSIGNED NULL,
  skill_fisico_min TINYINT UNSIGNED NULL,
  skill_arquero_min TINYINT UNSIGNED NULL,
  skill_delantero_min TINYINT UNSIGNED NULL,
  skill_mediocampo_min TINYINT UNSIGNED NULL,
  skill_defensa_min TINYINT UNSIGNED NULL,
  last_renotify_at DATETIME NULL,
  renotify_sent_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_gp_club_starts (club_id, starts_at),
  KEY idx_gp_status_starts (status, starts_at),
  KEY idx_gp_open_starts (is_open, starts_at),
  CONSTRAINT fk_gp_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_gp_creator FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS group_pichanga_participants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  origin ENUM('member','external') NOT NULL DEFAULT 'member',
  status ENUM('confirmed','withdrawn','removed') NOT NULL DEFAULT 'confirmed',
  confirmed_at DATETIME NULL,
  withdrawn_at DATETIME NULL,
  removed_by_user_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_gpp_pichanga_user (pichanga_id, user_id),
  KEY idx_gpp_status (pichanga_id, status),
  CONSTRAINT fk_gpp_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gpp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS group_pichanga_external_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','accepted','rejected','expired') NOT NULL DEFAULT 'pending',
  origin_degree TINYINT UNSIGNED NULL,
  relation_user_id BIGINT UNSIGNED NULL,
  decided_by_user_id BIGINT UNSIGNED NULL,
  requested_at DATETIME NULL,
  decided_at DATETIME NULL,
  note VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_gper_pichanga_user (pichanga_id, user_id),
  KEY idx_gper_status (pichanga_id, status),
  CONSTRAINT fk_gper_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gper_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS group_pichanga_notification_batches (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  triggered_by_user_id BIGINT UNSIGNED NOT NULL,
  batch_type ENUM('initial','manual_renotify') NOT NULL DEFAULT 'manual_renotify',
  target_degree TINYINT UNSIGNED NOT NULL DEFAULT 1,
  filters_json JSON NULL,
  target_count INT UNSIGNED NOT NULL DEFAULT 0,
  muted_skipped_count INT UNSIGNED NOT NULL DEFAULT 0,
  sent_count INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_gpb_pichanga_created (pichanga_id, created_at),
  CONSTRAINT fk_gpb_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gpb_user FOREIGN KEY (triggered_by_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

SET FOREIGN_KEY_CHECKS = 1;
