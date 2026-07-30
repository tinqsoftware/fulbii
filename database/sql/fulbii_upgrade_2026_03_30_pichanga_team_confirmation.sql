-- Fulbii
-- Pichangas por equipos (versus/triangular/cuadrangular)
-- Ejecutar una sola vez en la BD activa.

-- 1) group_pichangas: formato y tamaño por equipo
ALTER TABLE group_pichangas
  ADD COLUMN match_format ENUM('versus','triangular','cuadrangular') NOT NULL DEFAULT 'versus' AFTER confirmation_mode,
  ADD COLUMN team_count TINYINT UNSIGNED NOT NULL DEFAULT 2 AFTER match_format,
  ADD COLUMN players_per_team TINYINT UNSIGNED NOT NULL DEFAULT 7 AFTER team_count;

-- 2) group_pichanga_participants: asignación de equipo/slot
ALTER TABLE group_pichanga_participants
  ADD COLUMN team_code CHAR(1) NULL AFTER status,
  ADD COLUMN team_slot SMALLINT UNSIGNED NULL AFTER team_code,
  ADD KEY idx_gpp_team_board (pichanga_id, status, team_code, team_slot);

-- 3) Backfill de pichangas existentes
UPDATE group_pichangas
SET team_count = CASE match_format
  WHEN 'triangular' THEN 3
  WHEN 'cuadrangular' THEN 4
  ELSE 2
END;

UPDATE group_pichangas
SET players_per_team = LEAST(
  11,
  GREATEST(5, CEIL(capacity / NULLIF(team_count, 0)))
);

-- 4) Backfill de participantes confirmados (A/B/C/D secuencial)
SET @prev_pichanga := 0;
SET @seq := 0;

UPDATE group_pichanga_participants p
JOIN (
  SELECT
    q.id,
    q.pichanga_id,
    @seq := IF(@prev_pichanga = q.pichanga_id, @seq + 1, 1) AS seq,
    @prev_pichanga := q.pichanga_id AS __set_prev
  FROM (
    SELECT id, pichanga_id, COALESCE(confirmed_at, created_at) AS order_at
    FROM group_pichanga_participants
    WHERE status = 'confirmed'
    ORDER BY pichanga_id, order_at, id
  ) q
) s ON s.id = p.id
JOIN group_pichangas gp ON gp.id = p.pichanga_id
SET p.team_code = CHAR(64 + (((s.seq - 1) MOD gp.team_count) + 1)),
    p.team_slot = FLOOR((s.seq - 1) / gp.team_count) + 1
WHERE p.status = 'confirmed';

-- 5) No confirmados sin equipo
UPDATE group_pichanga_participants
SET team_code = NULL,
    team_slot = NULL
WHERE status <> 'confirmed';

-- 6) Unicidad de slot por equipo dentro de pichanga
ALTER TABLE group_pichanga_participants
  ADD UNIQUE KEY uq_gpp_team_slot (pichanga_id, team_code, team_slot);
