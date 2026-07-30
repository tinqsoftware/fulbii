-- Fulbii - Staff Admin Backoffice enablement
-- Safe to run multiple times.

-- 1) Create staff_admin profile if missing
INSERT INTO perfil (nombre, descripcion, estado, id_user_create, created_at, updated_at)
SELECT 'staff_admin', 'Staff operativo: moderación y métricas sin privilegios críticos', '1', 1, NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM perfil WHERE LOWER(nombre) = 'staff_admin'
);

-- 2) Optional: assign profile to a user
-- Replace :USER_ID with numeric id and run this block manually.
-- INSERT INTO user_perfil (id_user, id_perfil, estado, id_user_create, created_at, updated_at)
-- SELECT :USER_ID, p.id, '1', 1, NOW(), NOW()
-- FROM perfil p
-- WHERE LOWER(p.nombre) = 'staff_admin'
--   AND NOT EXISTS (
--     SELECT 1
--     FROM user_perfil up
--     WHERE up.id_user = :USER_ID
--       AND up.id_perfil = p.id
--   );
