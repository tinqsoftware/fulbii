-- Fulbii Watch Tracking Hardening (idempotente)
-- Objetivo: robustecer persistencia de sesiones/samples para heatmap y distancia filtrada.

START TRANSACTION;

-- 1) watch_match_sessions: external_session_id
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_match_sessions'
    AND COLUMN_NAME = 'external_session_id'
);
SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE watch_match_sessions ADD COLUMN external_session_id VARCHAR(64) NULL AFTER user_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) watch_match_sessions: distance_meters_raw
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_match_sessions'
    AND COLUMN_NAME = 'distance_meters_raw'
);
SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE watch_match_sessions ADD COLUMN distance_meters_raw DECIMAL(10,2) NULL AFTER distance_meters',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) watch_match_sessions: distance_meters_filtered
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_match_sessions'
    AND COLUMN_NAME = 'distance_meters_filtered'
);
SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE watch_match_sessions ADD COLUMN distance_meters_filtered DECIMAL(10,2) NULL AFTER distance_meters_raw',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) watch_position_samples: quality_flag
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_position_samples'
    AND COLUMN_NAME = 'quality_flag'
);
SET @sql := IF(
  @col_exists = 0,
  "ALTER TABLE watch_position_samples ADD COLUMN quality_flag ENUM('good','weak','rejected') NULL AFTER speed",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5) Índice sessions por user + external_session_id
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_match_sessions'
    AND INDEX_NAME = 'idx_watch_session_user_ext'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX idx_watch_session_user_ext ON watch_match_sessions (user_id, external_session_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 6) Índice samples por session + quality + sampled_at
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'watch_position_samples'
    AND INDEX_NAME = 'idx_watch_samples_session_quality_time'
);
SET @sql := IF(
  @idx_exists = 0,
  'CREATE INDEX idx_watch_samples_session_quality_time ON watch_position_samples (session_id, quality_flag, sampled_at)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

COMMIT;
