-- Fulbii hotfix: product_events requiere updated_at para inserciones Eloquent
-- Fecha: 2026-03-24

ALTER TABLE product_events
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Verificación
SHOW CREATE TABLE product_events;
