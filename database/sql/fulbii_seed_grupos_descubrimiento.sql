-- Grupos demo para probar "Descubrir grupos".
-- Ejecutar completo en la base local fulbii desde phpMyAdmin.
-- No borra grupos ni pichangas existentes.

SET NAMES utf8mb4;
SET @owner_email := 'apple_001323.f2155a07260f46629151d700eb2d1350.1835@fulbii.local';
SET @owner_id := (
  SELECT id FROM users
  WHERE LOWER(email) = LOWER(@owner_email)
  LIMIT 1
);

-- Verifica que el email usado por el simulador exista antes de continuar.
SELECT CASE
  WHEN @owner_id IS NULL THEN 'ERROR: no existe el usuario; revisa el email.'
  ELSE CONCAT('Usuario actual: id ', @owner_id)
END AS resultado;

START TRANSACTION;

INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, is_visible, created_at, updated_at)
VALUES
  (
    '[DEMO Fulbii] Canchas de Lima Norte',
    'demo-fulbii-canchas-lima-norte',
    'Grupo público demo para probar Descubrir grupos.',
    1,
    @owner_id,
    'https://images.unsplash.com/photo-1579952363873-27f3b846e9f7?auto=format&fit=crop&w=600&q=80',
    1,
    NOW(),
    NOW()
  )
ON DUPLICATE KEY UPDATE
  descripcion = VALUES(descripcion),
  logo_url = VALUES(logo_url),
  is_visible = 1,
  updated_at = NOW();

INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, is_visible, created_at, updated_at)
VALUES
  (
    '[DEMO Fulbii] Pichangas del Fin de Semana',
    'demo-fulbii-pichangas-fin-de-semana',
    'Grupo público demo no asociado al usuario actual.',
    1,
    @owner_id,
    'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?auto=format&fit=crop&w=600&q=80',
    1,
    NOW(),
    NOW()
  )
ON DUPLICATE KEY UPDATE
  descripcion = VALUES(descripcion),
  logo_url = VALUES(logo_url),
  is_visible = 1,
  updated_at = NOW();

SET @club_norte := (
  SELECT id FROM clubs WHERE slug = 'demo-fulbii-canchas-lima-norte' LIMIT 1
);
SET @club_fin := (
  SELECT id FROM clubs WHERE slug = 'demo-fulbii-pichangas-fin-de-semana' LIMIT 1
);

-- La cuenta del simulador no pertenece a estos grupos.
DELETE FROM club_user
WHERE user_id = @owner_id
  AND club_id IN (@club_norte, @club_fin);

-- Si los usuarios demo ya fueron creados por el seed anterior, se agregan como
-- miembros. Si no existen, los grupos igual quedan visibles para descubrirlos.
INSERT IGNORE INTO club_user (club_id, user_id, rol, estado, created_at, updated_at)
SELECT @club_norte, id, 'member', 1, NOW(), NOW()
FROM users
WHERE email IN ('demo.fulbii.marco@local.test', 'demo.fulbii.lucia@local.test');

INSERT IGNORE INTO club_user (club_id, user_id, rol, estado, created_at, updated_at)
SELECT @club_fin, id, 'member', 1, NOW(), NOW()
FROM users
WHERE email IN ('demo.fulbii.diego@local.test', 'demo.fulbii.sofia@local.test');

COMMIT;

-- Verificación: estos grupos deben aparecer en scope=discover para el usuario.
SELECT
  c.id,
  c.nombre,
  c.slug,
  c.is_visible,
  COUNT(cu.user_id) AS miembros,
  MAX(CASE WHEN cu.user_id = @owner_id THEN 1 ELSE 0 END) AS pertenece_usuario_actual
FROM clubs c
LEFT JOIN club_user cu ON cu.club_id = c.id
WHERE c.slug IN (
  'demo-fulbii-canchas-lima-norte',
  'demo-fulbii-pichangas-fin-de-semana'
)
GROUP BY c.id, c.nombre, c.slug, c.is_visible
ORDER BY c.id;
