-- Fulbii upgrade: ratings 1-10 + weekly lookup index + profile clips
-- Execute once on the active database (local/cloud).

START TRANSACTION;

-- 1) Weekly free-rating lookup performance
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'calificaciones'
    AND INDEX_NAME = 'idx_calif_week_lookup'
);
SET @sql_idx := IF(
  @idx_exists = 0,
  'ALTER TABLE calificaciones ADD INDEX idx_calif_week_lookup (club_id, user_calificador_id, user_calificado_id, created_at)',
  'SELECT 1'
);
PREPARE stmt_idx FROM @sql_idx;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;

-- 2) Clips de perfil (MP4 loop canonical)
CREATE TABLE IF NOT EXISTS user_profile_clips (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(120) NULL,
  mp4_url VARCHAR(500) NOT NULL,
  duration_ms INT UNSIGNED NOT NULL DEFAULT 7000,
  width SMALLINT UNSIGNED NULL,
  height SMALLINT UNSIGNED NULL,
  file_size_bytes INT UNSIGNED NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  status ENUM('active','deleted') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_upc_user_status_order (user_id, status, sort_order, id),
  CONSTRAINT fk_upc_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3) Unified source views (free ratings + pichanga ratings)
CREATE OR REPLACE VIEW vw_skill_ratings_votes AS
SELECT
  c.club_id AS club_id,
  c.user_calificado_id AS user_id,
  c.fisico AS fisico,
  c.arquero AS arquero,
  c.delantero AS delantero,
  c.mediocampo AS mediocampo,
  c.defensa AS defensa,
  c.created_at AS created_at
FROM calificaciones c
WHERE c.deleted_at IS NULL

UNION ALL

SELECT
  gp.club_id AS club_id,
  gpr.rated_user_id AS user_id,
  gpr.fisico AS fisico,
  gpr.arquero AS arquero,
  gpr.delantero AS delantero,
  gpr.mediocampo AS mediocampo,
  gpr.defensa AS defensa,
  gpr.created_at AS created_at
FROM group_pichanga_ratings gpr
INNER JOIN group_pichangas gp ON gp.id = gpr.pichanga_id;

CREATE OR REPLACE VIEW vw_skill_ratings_avg_by_club AS
SELECT
  v.club_id,
  v.user_id,
  COUNT(*) AS votos,
  AVG(v.fisico) AS fisico_prom,
  AVG(v.arquero) AS arquero_prom,
  AVG(v.delantero) AS delantero_prom,
  AVG(v.mediocampo) AS mediocampo_prom,
  AVG(v.defensa) AS defensa_prom
FROM vw_skill_ratings_votes v
WHERE v.club_id IS NOT NULL
GROUP BY v.club_id, v.user_id;

CREATE OR REPLACE VIEW vw_skill_ratings_avg_global AS
SELECT
  v.user_id,
  COUNT(*) AS votos,
  AVG(v.fisico) AS fisico_prom,
  AVG(v.arquero) AS arquero_prom,
  AVG(v.delantero) AS delantero_prom,
  AVG(v.mediocampo) AS mediocampo_prom,
  AVG(v.defensa) AS defensa_prom
FROM vw_skill_ratings_votes v
GROUP BY v.user_id;

COMMIT;

