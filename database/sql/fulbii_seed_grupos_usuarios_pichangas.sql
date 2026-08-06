-- Fulbii: seed local de usuarios, grupos y pichangas de prueba.
-- Ejecutar dentro de la base de datos local fulbii desde phpMyAdmin.
--
-- IMPORTANTE:
-- 1. Reemplaza @owner_email por el email del usuario con el que entras en el
--    simulador. Ese usuario se conserva y sera creador/admin de los datos demo.
-- 2. El script necesita que existan usuarios, clubs, club_user, cancha,
--    group_pichangas y group_pichanga_participants.
-- 3. No elimina cuentas, grupos ni polideportivos. Solo borra pichangas cuyo
--    titulo comienza con [DEMO Fulbii] para que el script sea re-ejecutable.
-- 4. El grupo "Comunidad Abierta" se crea sin tu usuario como miembro para
--    probar la pestana Descubrir grupos.

SET NAMES utf8mb4;
SET @owner_email :=
'apple_001323.f2155a07260f46629151d700eb2d1350.1835@fulbii.local';

START TRANSACTION;

-- Usuario real de la app: no se modifica, solo se toma su id.
SET @owner_id := (
  SELECT id
  FROM users
  WHERE LOWER(email) = LOWER(@owner_email)
  LIMIT 1
);

-- Si no existe, detiene el seed en esta consulta antes de insertar relaciones.
SELECT CASE
  WHEN @owner_id IS NULL THEN 'ERROR: reemplaza @owner_email por el email existente del simulador.'
  ELSE CONCAT('Usuario creador seleccionado: id ', @owner_id)
END AS resultado_usuario;

-- Usuarios demo para poblar miembros y confirmados.
INSERT INTO users
  (name, email, password, nick, estado, auth_provider, provider_uid, avatar_url, created_at, updated_at)
VALUES
  ('Marco Demo', 'demo.fulbii.marco@local.test', '$2y$12$IBR.YRc00Dsgl3EH1prZV.DKxrlDzkyZGm29S9MNNGv9pEwT0uyg.', 'marcodemo', '1', 'demo', 'demo-marco', NULL, NOW(), NOW()),
  ('Lucia Demo', 'demo.fulbii.lucia@local.test', '$2y$12$IBR.YRc00Dsgl3EH1prZV.DKxrlDzkyZGm29S9MNNGv9pEwT0uyg.', 'luciademo', '1', 'demo', 'demo-lucia', NULL, NOW(), NOW()),
  ('Diego Demo', 'demo.fulbii.diego@local.test', '$2y$12$IBR.YRc00Dsgl3EH1prZV.DKxrlDzkyZGm29S9MNNGv9pEwT0uyg.', 'diegodemo', '1', 'demo', 'demo-diego', NULL, NOW(), NOW()),
  ('Sofia Demo', 'demo.fulbii.sofia@local.test', '$2y$12$IBR.YRc00Dsgl3EH1prZV.DKxrlDzkyZGm29S9MNNGv9pEwT0uyg.', 'sofiademo', '1', 'demo', 'demo-sofia', NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  nick = VALUES(nick),
  estado = VALUES(estado),
  updated_at = NOW();

DROP TEMPORARY TABLE IF EXISTS tmp_seed_users;
CREATE TEMPORARY TABLE tmp_seed_users AS
SELECT id, email
FROM users
WHERE email IN (
  'demo.fulbii.marco@local.test',
  'demo.fulbii.lucia@local.test',
  'demo.fulbii.diego@local.test',
  'demo.fulbii.sofia@local.test'
);

SET @u_marco := (SELECT id FROM tmp_seed_users WHERE email = 'demo.fulbii.marco@local.test');
SET @u_lucia := (SELECT id FROM tmp_seed_users WHERE email = 'demo.fulbii.lucia@local.test');
SET @u_diego := (SELECT id FROM tmp_seed_users WHERE email = 'demo.fulbii.diego@local.test');
SET @u_sofia := (SELECT id FROM tmp_seed_users WHERE email = 'demo.fulbii.sofia@local.test');

-- Grupos demo. Se usa nombre/slug estable para no duplicarlos al re-ejecutar.
INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, created_at, updated_at)
VALUES ('[DEMO Fulbii] Los del Mapa', 'demo-fulbii-los-del-mapa', 'Grupo demo para probar pichangas y confirmaciones.', 1, @owner_id, NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion), updated_at = NOW();

INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, created_at, updated_at)
VALUES ('[DEMO Fulbii] Futbol Lima', 'demo-fulbii-futbol-lima', 'Grupo demo con pichangas en canchas de Lima.', 1, @owner_id, NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion), updated_at = NOW();

INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, created_at, updated_at)
VALUES ('[DEMO Fulbii] Amigos del Barrio', 'demo-fulbii-amigos-del-barrio', 'Grupo demo para probar lista, detalle e invitaciones.', 1, @owner_id, NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion), updated_at = NOW();

INSERT INTO clubs
  (nombre, slug, descripcion, estado, created_by, logo_url, created_at, updated_at)
VALUES ('[DEMO Fulbii] Comunidad Abierta', 'demo-fulbii-comunidad-abierta', 'Grupo demo visible para descubrir sin pertenecer al grupo.', 1, @u_marco, NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  descripcion = VALUES(descripcion),
  updated_at = NOW();

DROP TEMPORARY TABLE IF EXISTS tmp_seed_clubs;
CREATE TEMPORARY TABLE tmp_seed_clubs AS
SELECT id, nombre
FROM clubs
WHERE slug IN (
  'demo-fulbii-los-del-mapa',
  'demo-fulbii-futbol-lima',
  'demo-fulbii-amigos-del-barrio',
  'demo-fulbii-comunidad-abierta'
);

SET @club_mapa := (SELECT id FROM tmp_seed_clubs WHERE nombre = '[DEMO Fulbii] Los del Mapa');
SET @club_lima := (SELECT id FROM tmp_seed_clubs WHERE nombre = '[DEMO Fulbii] Futbol Lima');
SET @club_barrio := (SELECT id FROM tmp_seed_clubs WHERE nombre = '[DEMO Fulbii] Amigos del Barrio');
SET @club_abierta := (SELECT id FROM tmp_seed_clubs WHERE nombre = '[DEMO Fulbii] Comunidad Abierta');

-- Garantiza que el grupo abierto no aparezca tambien en "Mis grupos" si una
-- ejecucion anterior lo habia asociado accidentalmente al usuario actual.
DELETE FROM club_user
WHERE club_id = @club_abierta
  AND user_id = @owner_id;

-- El usuario actual administra los tres grupos; los usuarios demo son miembros.
INSERT IGNORE INTO club_user (club_id, user_id, rol, estado, created_at, updated_at)
VALUES
  (@club_mapa, @owner_id, 'admin', 1, NOW(), NOW()),
  (@club_lima, @owner_id, 'admin', 1, NOW(), NOW()),
  (@club_barrio, @owner_id, 'admin', 1, NOW(), NOW()),
  (@club_mapa, @u_marco, 'member', 1, NOW(), NOW()),
  (@club_mapa, @u_lucia, 'member', 1, NOW(), NOW()),
  (@club_mapa, @u_diego, 'member', 1, NOW(), NOW()),
  (@club_lima, @u_lucia, 'member', 1, NOW(), NOW()),
  (@club_lima, @u_diego, 'member', 1, NOW(), NOW()),
  (@club_lima, @u_sofia, 'member', 1, NOW(), NOW()),
  (@club_barrio, @u_marco, 'member', 1, NOW(), NOW()),
  (@club_barrio, @u_sofia, 'member', 1, NOW(), NOW()),
  (@club_abierta, @u_marco, 'admin', 1, NOW(), NOW()),
  (@club_abierta, @u_lucia, 'member', 1, NOW(), NOW()),
  (@club_abierta, @u_diego, 'member', 1, NOW(), NOW()),
  (@club_abierta, @u_sofia, 'member', 1, NOW(), NOW());

-- Canchas reales ya cargadas en la base local. Se requieren cuatro para las
-- pichangas demo; si hay menos, la consulta de validacion lo mostrara.
DROP TEMPORARY TABLE IF EXISTS tmp_seed_courts;
CREATE TEMPORARY TABLE tmp_seed_courts AS
SELECT c.id AS cancha_id, c.id_polideportivo AS field_id
FROM cancha c
ORDER BY c.id
LIMIT 4;

SET @court_1 := (SELECT cancha_id FROM tmp_seed_courts ORDER BY cancha_id LIMIT 0, 1);
SET @court_2 := (SELECT cancha_id FROM tmp_seed_courts ORDER BY cancha_id LIMIT 1, 1);
SET @court_3 := (SELECT cancha_id FROM tmp_seed_courts ORDER BY cancha_id LIMIT 2, 1);
SET @court_4 := (SELECT cancha_id FROM tmp_seed_courts ORDER BY cancha_id LIMIT 3, 1);
SET @field_1 := (SELECT field_id FROM tmp_seed_courts WHERE cancha_id = @court_1);
SET @field_2 := (SELECT field_id FROM tmp_seed_courts WHERE cancha_id = @court_2);
SET @field_3 := (SELECT field_id FROM tmp_seed_courts WHERE cancha_id = @court_3);
SET @field_4 := (SELECT field_id FROM tmp_seed_courts WHERE cancha_id = @court_4);

-- Solo se limpian datos creados por este mismo script. Las FK eliminan sus
-- participantes asociados antes de insertar la nueva tanda.
DELETE FROM group_pichangas
WHERE title LIKE '[DEMO Fulbii]%';

INSERT INTO group_pichangas
  (club_id, created_by_user_id, title, description, field_id, cancha_id, address,
   starts_at, duration_minutes, capacity, status, confirmation_mode, match_format,
   team_count, players_per_team, is_open, notify_degree, allow_external_requests,
   withdraw_until, created_at, updated_at)
VALUES
  (@club_mapa, @owner_id, '[DEMO Fulbii] Pichanga de prueba hoy',
   'Pichanga demo para validar el detalle y los confirmados.', @field_1, @court_1,
   'Dirección demo de la cancha 1', DATE_ADD(NOW(), INTERVAL 1 DAY), 90, 14,
   'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1,
   DATE_ADD(NOW(), INTERVAL 18 HOUR), NOW(), NOW()),
  (@club_mapa, @owner_id, '[DEMO Fulbii] Pichanga abierta de prueba',
   'Pichanga demo abierta para probar el mapa y solicitudes.', @field_2, @court_2,
   'Dirección demo de la cancha 2', DATE_ADD(NOW(), INTERVAL 3 DAY), 60, 18,
   'published', 'auto_by_capacity', 'triangular', 3, 6, 1, 1, 1,
   DATE_ADD(NOW(), INTERVAL 60 HOUR), NOW(), NOW()),
  (@club_lima, @owner_id, '[DEMO Fulbii] Pichanga Futbol Lima',
   'Pichanga demo del grupo Futbol Lima.', @field_3, @court_3,
   'Dirección demo de la cancha 3', DATE_ADD(NOW(), INTERVAL 5 DAY), 90, 14,
   'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 0,
   DATE_ADD(NOW(), INTERVAL 100 HOUR), NOW(), NOW()),
  (@club_abierta, @u_marco, '[DEMO Fulbii] Pichanga Comunidad Abierta',
   'Pichanga demo para validar varias pichangas en grupos distintos.', @field_4, @court_4,
   'Dirección demo de la cancha 4', DATE_ADD(NOW(), INTERVAL 7 DAY), 60, 14,
   'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 0,
   DATE_ADD(NOW(), INTERVAL 140 HOUR), NOW(), NOW());

DROP TEMPORARY TABLE IF EXISTS tmp_seed_pichangas;
CREATE TEMPORARY TABLE tmp_seed_pichangas AS
SELECT id, title, club_id
FROM group_pichangas
WHERE title LIKE '[DEMO Fulbii]%';

-- Confirmados demo: el usuario real y dos usuarios demo por pichanga.
INSERT IGNORE INTO group_pichanga_participants
  (pichanga_id, user_id, origin, status, confirmed_at, created_at, updated_at)
SELECT p.id, u.user_id, 'member', 'confirmed', NOW(), NOW(), NOW()
FROM tmp_seed_pichangas p
JOIN (
  SELECT @owner_id AS user_id, 0 AS position
  UNION ALL SELECT @u_marco, 1
  UNION ALL SELECT @u_lucia, 2
  UNION ALL SELECT @u_diego, 3
) u
WHERE NOT (p.club_id = @club_abierta AND u.user_id = @owner_id);

-- Verificaciones finales.
SELECT 'usuarios_demo' AS dato, COUNT(*) AS cantidad
FROM users
WHERE email LIKE 'demo.fulbii.%@local.test';

SELECT c.id, c.nombre, COUNT(cu.user_id) AS miembros
FROM clubs c
LEFT JOIN club_user cu ON cu.club_id = c.id AND cu.estado = 1
WHERE c.slug IN ('demo-fulbii-los-del-mapa', 'demo-fulbii-futbol-lima', 'demo-fulbii-amigos-del-barrio', 'demo-fulbii-comunidad-abierta')
GROUP BY c.id, c.nombre
ORDER BY c.id;

SELECT gp.id, gp.title, gp.club_id, gp.field_id, gp.cancha_id,
       gp.starts_at, gp.capacity, COUNT(gpp.id) AS confirmados
FROM group_pichangas gp
LEFT JOIN group_pichanga_participants gpp
  ON gpp.pichanga_id = gp.id AND gpp.status = 'confirmed'
WHERE gp.title LIKE '[DEMO Fulbii]%'
GROUP BY gp.id, gp.title, gp.club_id, gp.field_id, gp.cancha_id,
         gp.starts_at, gp.capacity
ORDER BY gp.starts_at;

COMMIT;

-- Para consultar el usuario actual y reemplazar @owner_email:
-- SELECT id, name, email, auth_provider FROM users ORDER BY id;
