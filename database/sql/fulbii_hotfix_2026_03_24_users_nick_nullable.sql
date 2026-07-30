-- Fulbii hotfix: permitir login social sin nick inicial
-- Fecha: 2026-03-24
-- Motivo: el flujo social crea usuario primero y onboarding completa nick/sexo después.

ALTER TABLE users
  MODIFY COLUMN nick VARCHAR(200) NULL;

-- Verificación
SHOW CREATE TABLE users;
