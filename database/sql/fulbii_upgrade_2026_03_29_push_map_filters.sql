-- Fulbii upgrade 2026-03-29
-- Push E2E + map filters support (safe for repeated execution on MySQL compatibles)

-- 1) polideportivo.precio_desde_num
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'polideportivo'
     AND COLUMN_NAME = 'precio_desde_num') = 0,
  'ALTER TABLE polideportivo ADD COLUMN precio_desde_num DECIMAL(10,2) NULL AFTER precio_desde',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) cancha.tipo_superficie
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'cancha'
     AND COLUMN_NAME = 'tipo_superficie') = 0,
  "ALTER TABLE cancha ADD COLUMN tipo_superficie ENUM('losa','sintetico','artificial') NULL AFTER equiposvs",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) cancha.formato_vs
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'cancha'
     AND COLUMN_NAME = 'formato_vs') = 0,
  "ALTER TABLE cancha ADD COLUMN formato_vs ENUM('6v6','7v7','9v9') NULL AFTER tipo_superficie",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) indexes for filters
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'polideportivo'
     AND INDEX_NAME = 'idx_poli_precio_desde_num') = 0,
  'ALTER TABLE polideportivo ADD INDEX idx_poli_precio_desde_num (precio_desde_num)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'cancha'
     AND INDEX_NAME = 'idx_cancha_tipo_superficie') = 0,
  'ALTER TABLE cancha ADD INDEX idx_cancha_tipo_superficie (tipo_superficie)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'cancha'
     AND INDEX_NAME = 'idx_cancha_formato_vs') = 0,
  'ALTER TABLE cancha ADD INDEX idx_cancha_formato_vs (formato_vs)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5) backfill formato_vs from equiposvs
UPDATE cancha
SET formato_vs = CASE REPLACE(LOWER(COALESCE(equiposvs, '')), ' ', '')
  WHEN '6vs6' THEN '6v6'
  WHEN '7vs7' THEN '7v7'
  WHEN '9vs9' THEN '9v9'
  ELSE formato_vs
END
WHERE (formato_vs IS NULL OR formato_vs = '')
  AND equiposvs IS NOT NULL
  AND REPLACE(LOWER(COALESCE(equiposvs, '')), ' ', '') IN ('6vs6','7vs7','9vs9');

-- 6) optional heuristic for tipo_superficie (safe defaults)
UPDATE cancha
SET tipo_superficie = CASE
  WHEN LOWER(COALESCE(nombre, '')) LIKE '%losa%' THEN 'losa'
  WHEN LOWER(COALESCE(nombre, '')) LIKE '%sinte%' THEN 'sintetico'
  WHEN LOWER(COALESCE(nombre, '')) LIKE '%artif%' THEN 'artificial'
  ELSE tipo_superficie
END
WHERE (tipo_superficie IS NULL OR tipo_superficie = '')
  AND nombre IS NOT NULL
  AND (
    LOWER(nombre) LIKE '%losa%'
    OR LOWER(nombre) LIKE '%sinte%'
    OR LOWER(nombre) LIKE '%artif%'
  );

-- 7) backfill precio_desde_num from precio_desde (text)
UPDATE polideportivo
SET precio_desde_num = CAST(
  REPLACE(
    REPLACE(
      REPLACE(
        REPLACE(TRIM(COALESCE(precio_desde, '')), 'S/', ''),
      's/', ''),
    ' ', ''),
  ',', '.') AS DECIMAL(10,2)
)
WHERE precio_desde_num IS NULL
  AND precio_desde IS NOT NULL
  AND TRIM(precio_desde) <> ''
  AND REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(TRIM(COALESCE(precio_desde, '')), 'S/', ''),
          's/', ''),
        ' ', ''),
      ',', '.') REGEXP '^[0-9]+(\\.[0-9]+)?$';
