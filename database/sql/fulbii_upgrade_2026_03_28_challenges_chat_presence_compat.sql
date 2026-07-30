-- Fulbii Challenges + Chat Presence (2026-03-28)
-- Compatible con MySQL 5.7+ (sin ADD COLUMN IF NOT EXISTS directo).

SET @schema_name := DATABASE();
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------
-- 1) club_challenges
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS club_challenges (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  challenger_club_id BIGINT UNSIGNED NOT NULL,
  challenged_club_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  coordinator_challenger_user_id BIGINT UNSIGNED NULL,
  coordinator_challenged_user_id BIGINT UNSIGNED NULL,
  team_size TINYINT UNSIGNED NOT NULL DEFAULT 6,
  challenge_window ENUM('next_week','next_fortnight','next_month') NOT NULL DEFAULT 'next_week',
  status ENUM('pending','negotiating','configuring','confirmed','rejected','cancelled','expired') NOT NULL DEFAULT 'pending',
  requested_note VARCHAR(500) NULL,
  rejected_by_user_id BIGINT UNSIGNED NULL,
  rejected_reason VARCHAR(255) NULL,
  cancelled_by_user_id BIGINT UNSIGNED NULL,
  cancelled_reason VARCHAR(255) NULL,
  expires_at DATETIME NOT NULL,
  confirmed_at DATETIME NULL,
  confirmed_pichanga_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cc_status_expires (status, expires_at),
  KEY idx_cc_challenger_status (challenger_club_id, status, created_at),
  KEY idx_cc_challenged_status (challenged_club_id, status, created_at),
  KEY idx_cc_confirmed_pichanga (confirmed_pichanga_id),
  CONSTRAINT fk_cc_challenger_club FOREIGN KEY (challenger_club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_cc_challenged_club FOREIGN KEY (challenged_club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_cc_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cc_coord_challenger FOREIGN KEY (coordinator_challenger_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_cc_coord_challenged FOREIGN KEY (coordinator_challenged_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_cc_rejected_by FOREIGN KEY (rejected_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_cc_cancelled_by FOREIGN KEY (cancelled_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ;

-- -------------------------------------------------------------------
-- 2) club_challenge_messages
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS club_challenge_messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  challenge_id BIGINT UNSIGNED NOT NULL,
  sender_user_id BIGINT UNSIGNED NOT NULL,
  message_type ENUM('text','system') NOT NULL DEFAULT 'text',
  content VARCHAR(1200) NOT NULL,
  metadata_json LONGTEXT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ccm_challenge_id (challenge_id, id),
  KEY idx_ccm_sender_id (sender_user_id, id),
  CONSTRAINT fk_ccm_challenge FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE CASCADE,
  CONSTRAINT fk_ccm_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

-- -------------------------------------------------------------------
-- 3) club_challenge_field_options
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS club_challenge_field_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  challenge_id BIGINT UNSIGNED NOT NULL,
  proposed_by_user_id BIGINT UNSIGNED NOT NULL,
  polideportivo_id INT UNSIGNED NULL,
  field_name VARCHAR(255) NULL,
  field_address VARCHAR(255) NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  status ENUM('proposed','accepted','rejected') NOT NULL DEFAULT 'proposed',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ccfo_challenge_status (challenge_id, status, id),
  CONSTRAINT fk_ccfo_challenge FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE CASCADE,
  CONSTRAINT fk_ccfo_proposed_by FOREIGN KEY (proposed_by_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

-- -------------------------------------------------------------------
-- 4) club_challenge_time_options
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS club_challenge_time_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  challenge_id BIGINT UNSIGNED NOT NULL,
  proposed_by_user_id BIGINT UNSIGNED NOT NULL,
  starts_at DATETIME NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 90,
  status ENUM('proposed','accepted','rejected') NOT NULL DEFAULT 'proposed',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ccto_challenge_status (challenge_id, status, starts_at),
  CONSTRAINT fk_ccto_challenge FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE CASCADE,
  CONSTRAINT fk_ccto_proposed_by FOREIGN KEY (proposed_by_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

-- -------------------------------------------------------------------
-- 5) club_challenge_configurations (requiere doble aceptación)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS club_challenge_configurations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  challenge_id BIGINT UNSIGNED NOT NULL,
  proposed_by_user_id BIGINT UNSIGNED NOT NULL,
  field_option_id BIGINT UNSIGNED NOT NULL,
  time_option_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','accepted','rejected','cancelled') NOT NULL DEFAULT 'pending',
  accepted_by_challenger_at DATETIME NULL,
  accepted_by_challenged_at DATETIME NULL,
  rejected_by_user_id BIGINT UNSIGNED NULL,
  rejected_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cccfg_challenge_status (challenge_id, status, id),
  CONSTRAINT fk_cccfg_challenge FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE CASCADE,
  CONSTRAINT fk_cccfg_proposed_by FOREIGN KEY (proposed_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cccfg_field_option FOREIGN KEY (field_option_id) REFERENCES club_challenge_field_options(id) ON DELETE CASCADE,
  CONSTRAINT fk_cccfg_time_option FOREIGN KEY (time_option_id) REFERENCES club_challenge_time_options(id) ON DELETE CASCADE,
  CONSTRAINT fk_cccfg_rejected_by FOREIGN KEY (rejected_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ;

-- -------------------------------------------------------------------
-- 6) presencia de chat
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_chat_presence (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  challenge_id BIGINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 0,
  last_heartbeat_at DATETIME NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ucp_user (user_id),
  KEY idx_ucp_challenge_active (challenge_id, is_active, last_heartbeat_at),
  CONSTRAINT fk_ucp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ucp_challenge FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE CASCADE
) ;

-- -------------------------------------------------------------------
-- 7) Extensión de group_pichangas para retos
-- -------------------------------------------------------------------
SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'match_context'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN match_context ENUM(''regular'',''club_challenge'') NOT NULL DEFAULT ''regular'' AFTER club_id',
  'SELECT "group_pichangas.match_context exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'rival_club_id'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN rival_club_id BIGINT UNSIGNED NULL AFTER club_id',
  'SELECT "group_pichangas.rival_club_id exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'challenge_id'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN challenge_id BIGINT UNSIGNED NULL AFTER rival_club_id',
  'SELECT "group_pichangas.challenge_id exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'invited_link_enabled'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN invited_link_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER allow_external_requests',
  'SELECT "group_pichangas.invited_link_enabled exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name AND TABLE_NAME = 'group_pichangas' AND COLUMN_NAME = 'invited_link_code'
);
SET @sql := IF(
  @exists = 0,
  'ALTER TABLE group_pichangas ADD COLUMN invited_link_code CHAR(16) NULL AFTER invited_link_enabled',
  'SELECT "group_pichangas.invited_link_code exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name
    AND TABLE_NAME = 'group_pichangas'
    AND INDEX_NAME = 'idx_gp_challenge_id'
);
SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE group_pichangas ADD KEY idx_gp_challenge_id (challenge_id)',
  'SELECT "idx_gp_challenge_id exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name
    AND TABLE_NAME = 'group_pichangas'
    AND INDEX_NAME = 'idx_gp_rival_club_id'
);
SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE group_pichangas ADD KEY idx_gp_rival_club_id (rival_club_id)',
  'SELECT "idx_gp_rival_club_id exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Llena invited_link_code para filas nuevas de retos que aún no lo tengan.
UPDATE group_pichangas
SET invited_link_code = UPPER(SUBSTRING(REPLACE(UUID(), '-', ''), 1, 16))
WHERE match_context = 'club_challenge'
  AND (invited_link_enabled = 1)
  AND (invited_link_code IS NULL OR invited_link_code = '');

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE BINARY TABLE_SCHEMA = BINARY @schema_name
    AND TABLE_NAME = 'group_pichangas'
    AND INDEX_NAME = 'uq_gp_invited_link_code'
);
SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE group_pichangas ADD UNIQUE KEY uq_gp_invited_link_code (invited_link_code)',
  'SELECT "uq_gp_invited_link_code exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- FK challenge_id (si no existe)
SET @fk_exists := (
  SELECT COUNT(*)
  FROM information_schema.REFERENTIAL_CONSTRAINTS
  WHERE BINARY CONSTRAINT_SCHEMA = BINARY @schema_name
    AND CONSTRAINT_NAME = 'fk_gp_challenge_id'
    AND TABLE_NAME = 'group_pichangas'
);
SET @sql := IF(
  @fk_exists = 0,
  'ALTER TABLE group_pichangas ADD CONSTRAINT fk_gp_challenge_id FOREIGN KEY (challenge_id) REFERENCES club_challenges(id) ON DELETE SET NULL',
  'SELECT "fk_gp_challenge_id exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------------
-- 8) Verificación rápida
-- -------------------------------------------------------------------
SHOW TABLES LIKE 'club_challenges';
SHOW TABLES LIKE 'club_challenge_messages';
SHOW TABLES LIKE 'club_challenge_field_options';
SHOW TABLES LIKE 'club_challenge_time_options';
SHOW TABLES LIKE 'club_challenge_configurations';
SHOW TABLES LIKE 'user_chat_presence';

SHOW COLUMNS FROM group_pichangas LIKE 'match_context';
SHOW COLUMNS FROM group_pichangas LIKE 'rival_club_id';
SHOW COLUMNS FROM group_pichangas LIKE 'challenge_id';
SHOW COLUMNS FROM group_pichangas LIKE 'invited_link_enabled';
SHOW COLUMNS FROM group_pichangas LIKE 'invited_link_code';
