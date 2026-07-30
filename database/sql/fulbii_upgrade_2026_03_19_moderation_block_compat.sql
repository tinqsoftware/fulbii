-- Fulbii moderation block: reports + strikes + field submissions + suspension
-- Compatible script for MySQL/MariaDB

SET FOREIGN_KEY_CHECKS = 0;

-- users.suspended_until
SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'suspended_until'),
    'ALTER TABLE `users` ADD COLUMN `suspended_until` DATETIME NULL AFTER `avatar_url`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.suspension_reason
SET @sql = (
  SELECT IF(
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'suspension_reason'),
    'ALTER TABLE `users` ADD COLUMN `suspension_reason` VARCHAR(255) NULL AFTER `suspended_until`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS field_submissions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  nombre VARCHAR(250) NOT NULL,
  direccion VARCHAR(255) NULL,
  x VARCHAR(50) NULL,
  y VARCHAR(50) NULL,
  celular VARCHAR(20) NULL,
  wsp TINYINT(1) NOT NULL DEFAULT 0,
  id_distrito INT NULL,
  descripcion VARCHAR(300) NULL,
  precio_desde VARCHAR(10) NULL,
  source_type ENUM('gps','manual_map') NOT NULL DEFAULT 'gps',
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  approved_polideportivo_id INT NULL,
  resolution_note VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_fs_status_created (status, created_at),
  KEY idx_fs_user_created (user_id, created_at),
  CONSTRAINT fk_fs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS field_submission_photos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  field_submission_id BIGINT UNSIGNED NOT NULL,
  photo_url VARCHAR(500) NOT NULL,
  status ENUM('active','removed') NOT NULL DEFAULT 'active',
  removed_by_user_id BIGINT UNSIGNED NULL,
  removed_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_fsp_submission_status (field_submission_id, status),
  CONSTRAINT fk_fsp_submission FOREIGN KEY (field_submission_id) REFERENCES field_submissions(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS reports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reporter_user_id BIGINT UNSIGNED NOT NULL,
  target_type ENUM('user','field','field_photo','group_pichanga') NOT NULL,
  target_id BIGINT UNSIGNED NOT NULL,
  reason_code VARCHAR(60) NOT NULL,
  description VARCHAR(500) NULL,
  status ENUM('pending','reviewed','dismissed','actioned') NOT NULL DEFAULT 'pending',
  resolved_by_user_id BIGINT UNSIGNED NULL,
  resolved_at DATETIME NULL,
  resolution_note VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_reports_status_created (status, created_at),
  KEY idx_reports_target (target_type, target_id),
  KEY idx_reports_reporter_created (reporter_user_id, created_at),
  CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS strikes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  report_id BIGINT UNSIGNED NULL,
  assigned_by_user_id BIGINT UNSIGNED NOT NULL,
  reason_code VARCHAR(60) NOT NULL,
  description VARCHAR(500) NULL,
  status ENUM('active','revoked') NOT NULL DEFAULT 'active',
  expires_at DATETIME NULL,
  revoked_by_user_id BIGINT UNSIGNED NULL,
  revoked_at DATETIME NULL,
  revoked_note VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_strikes_user_status_created (user_id, status, created_at),
  KEY idx_strikes_report (report_id),
  CONSTRAINT fk_strikes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_strikes_assigned_by FOREIGN KEY (assigned_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 1;
