-- Fulbii hotfix (2026-03-24): alineacion minima de esquema para app movil
-- Objetivo: evitar errores SQL de columnas faltantes en login social y mapa.

SET FOREIGN_KEY_CHECKS = 0;

-- 1) users.nick debe permitir NULL para onboarding post-login social.
SET @sql = (
  SELECT IF(
    EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'nick'
    ),
    'ALTER TABLE `users` MODIFY COLUMN `nick` VARCHAR(200) NULL',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) product_events.updated_at requerido por Eloquent timestamps.
SET @sql = (
  SELECT IF(
    EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_name = 'product_events'
    )
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'product_events' AND column_name = 'updated_at'
    ),
    'ALTER TABLE `product_events` ADD COLUMN `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) polideportivo.direccion requerido por API de mapa/canchas.
SET @sql = (
  SELECT IF(
    EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_name = 'polideportivo'
    )
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'polideportivo' AND column_name = 'direccion'
    ),
    'ALTER TABLE `polideportivo` ADD COLUMN `direccion` VARCHAR(255) NULL AFTER `nombre`',
    'SELECT 1'
  )
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- Verificaciones
SHOW COLUMNS FROM users LIKE 'nick';
SHOW COLUMNS FROM product_events LIKE 'updated_at';
SHOW COLUMNS FROM polideportivo LIKE 'direccion';
