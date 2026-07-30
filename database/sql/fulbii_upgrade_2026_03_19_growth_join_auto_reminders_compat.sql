-- Fulbii Growth Block (Join por link + solicitudes + auto reminders 48h/24h)
-- Compatible with MySQL 5.7+ (sin ADD COLUMN IF NOT EXISTS).

SET @schema_name := DATABASE();

-- -------------------------------------------------------------------
-- 1) clubs: join_code + settings de link y auto reminders
-- -------------------------------------------------------------------

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'clubs' AND COLUMN_NAME = 'join_code'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE clubs ADD COLUMN join_code CHAR(12) NULL AFTER audience_max_degree',
  'SELECT "clubs.join_code exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'clubs' AND COLUMN_NAME = 'link_join_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE clubs ADD COLUMN link_join_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER join_code',
  'SELECT "clubs.link_join_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'clubs' AND COLUMN_NAME = 'auto_reminder_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE clubs ADD COLUMN auto_reminder_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER link_join_enabled',
  'SELECT "clubs.auto_reminder_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'clubs' AND COLUMN_NAME = 'auto_reminder_48h_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE clubs ADD COLUMN auto_reminder_48h_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER auto_reminder_enabled',
  'SELECT "clubs.auto_reminder_48h_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'clubs' AND COLUMN_NAME = 'auto_reminder_24h_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE clubs ADD COLUMN auto_reminder_24h_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER auto_reminder_48h_enabled',
  'SELECT "clubs.auto_reminder_24h_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE clubs
SET join_code = UPPER(LPAD(CONV(id, 10, 16), 12, '0'))
WHERE join_code IS NULL OR join_code = '';

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = @schema_name
    AND TABLE_NAME = 'clubs'
    AND INDEX_NAME = 'uq_clubs_join_code'
);
SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE clubs ADD UNIQUE KEY uq_clubs_join_code (join_code)',
  'SELECT "uq_clubs_join_code exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- -------------------------------------------------------------------
-- 2) club_join_requests
-- -------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS club_join_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  requester_user_id BIGINT UNSIGNED NOT NULL,
  requested_via ENUM('search','link') NOT NULL DEFAULT 'search',
  status ENUM('pending','accepted','rejected','cancelled','expired') NOT NULL DEFAULT 'pending',
  requested_at DATETIME NULL,
  decided_at DATETIME NULL,
  decided_by_user_id BIGINT UNSIGNED NULL,
  note VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cjr_club_status (club_id, status, created_at),
  KEY idx_cjr_requester_status (requester_user_id, status, created_at),
  KEY idx_cjr_club_requester_status (club_id, requester_user_id, status),
  CONSTRAINT fk_cjr_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_cjr_requester FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cjr_decider FOREIGN KEY (decided_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------------
-- 3) group_pichangas: estado de olas automáticas
-- -------------------------------------------------------------------

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'auto_reminder_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN auto_reminder_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER allow_external_requests',
  'SELECT "group_pichangas.auto_reminder_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'auto_reminder_48h_sent_at'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN auto_reminder_48h_sent_at DATETIME NULL AFTER auto_reminder_enabled',
  'SELECT "group_pichangas.auto_reminder_48h_sent_at exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'auto_reminder_24h_sent_at'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN auto_reminder_24h_sent_at DATETIME NULL AFTER auto_reminder_48h_sent_at',
  'SELECT "group_pichangas.auto_reminder_24h_sent_at exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- -------------------------------------------------------------------
-- 4) batch types: auto_48h / auto_24h
-- -------------------------------------------------------------------

SET @current_enum := (
  SELECT COLUMN_TYPE
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema_name
    AND TABLE_NAME = 'group_pichanga_notification_batches'
    AND COLUMN_NAME = 'batch_type'
  LIMIT 1
);

SET @needs_alter := IF(
  @current_enum LIKE '%''auto_48h''%' AND @current_enum LIKE '%''auto_24h''%',
  0,
  1
);

SET @sql := IF(
  @needs_alter = 1,
  'ALTER TABLE group_pichanga_notification_batches MODIFY batch_type ENUM(''initial'',''manual_renotify'',''auto_48h'',''auto_24h'') NOT NULL DEFAULT ''manual_renotify''',
  'SELECT "group_pichanga_notification_batches.batch_type already supports auto waves"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

