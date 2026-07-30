-- Fulbii push block: devices + in-app notifications + dispatch logs
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS user_devices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  platform ENUM('ios','android','web') NOT NULL,
  device_token VARCHAR(255) NOT NULL,
  device_name VARCHAR(100) NULL,
  app_version VARCHAR(40) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ud_platform_token (platform, device_token),
  KEY idx_ud_user_active (user_id, is_active),
  CONSTRAINT fk_ud_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS push_notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  club_id BIGINT UNSIGNED NULL,
  group_pichanga_id BIGINT UNSIGNED NULL,
  type VARCHAR(80) NOT NULL,
  title VARCHAR(140) NOT NULL,
  body VARCHAR(500) NOT NULL,
  data_json JSON NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  read_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pn_user_read_created (user_id, is_read, created_at),
  KEY idx_pn_club_created (club_id, created_at),
  KEY idx_pn_pichanga_created (group_pichanga_id, created_at),
  CONSTRAINT fk_pn_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS push_dispatch_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  push_notification_id BIGINT UNSIGNED NOT NULL,
  user_device_id BIGINT UNSIGNED NULL,
  status ENUM('queued','sent','failed') NOT NULL DEFAULT 'queued',
  provider VARCHAR(30) NOT NULL DEFAULT 'log',
  provider_response TEXT NULL,
  error_message VARCHAR(255) NULL,
  sent_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pdl_notification_status (push_notification_id, status),
  CONSTRAINT fk_pdl_notification FOREIGN KEY (push_notification_id) REFERENCES push_notifications(id) ON DELETE CASCADE
) ;

SET FOREIGN_KEY_CHECKS = 1;
