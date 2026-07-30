-- Fulbii: reinicio de datos de juego/mapa y seed demo de Lima.
-- Conserva users, clubs y club_user. Ejecutar completo en phpMyAdmin.
-- Resultado: 40 polideportivos y 90 canchas (10 centros con 3, 30 con 2).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- Datos de juego, retos y Watch. Las cuentas, grupos y membresias se conservan.
DELETE FROM watch_match_events;
DELETE FROM watch_position_samples;
DELETE FROM watch_match_sessions;
DELETE FROM push_dispatch_logs;
DELETE FROM push_notifications;
DELETE FROM group_pichanga_comments;
DELETE FROM group_pichanga_ratings;
DELETE FROM group_pichanga_posts;
DELETE FROM group_pichanga_external_requests;
DELETE FROM group_pichanga_notification_batches;
DELETE FROM group_pichanga_participants;
DELETE FROM group_pichangas;
DELETE FROM user_chat_presence;
DELETE FROM club_challenge_configurations;
DELETE FROM club_challenge_messages;
DELETE FROM club_challenge_field_options;
DELETE FROM club_challenge_time_options;
DELETE FROM club_challenges;
DELETE FROM club_invitations;
DELETE FROM club_join_requests;
DELETE FROM goles;
DELETE FROM historial_calificacion;
DELETE FROM pichanga;
DELETE FROM evento_usuarios;
DELETE FROM evento;
DELETE FROM calificaciones;

-- Datos asociados a los polideportivos anteriores.
DELETE FROM user_favorite_fields;
DELETE FROM field_geometries;
DELETE FROM horario_atencion;
DELETE FROM servicio_polideportivo_detalle;
DELETE FROM field_submission_photos;
DELETE FROM field_submissions;
DELETE FROM cancha;
DELETE FROM polideportivo;

CREATE TEMPORARY TABLE tmp_seed_polideportivos (
  codigo CHAR(3) NOT NULL PRIMARY KEY,
  nombre VARCHAR(250) NOT NULL,
  direccion VARCHAR(255) NOT NULL,
  latitud DECIMAL(10,6) NOT NULL,
  longitud DECIMAL(10,6) NOT NULL,
  celular VARCHAR(10) NOT NULL,
  descripcion VARCHAR(300) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  foto VARCHAR(300) NOT NULL,
  canchas_objetivo TINYINT NOT NULL
) ENGINE=MEMORY DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

INSERT INTO tmp_seed_polideportivos
  (codigo, nombre, direccion, latitud, longitud, celular, descripcion, precio, foto, canchas_objetivo)
VALUES
  ('P01', 'Arena Norte 360', 'Av. Carlos Izaguirre 1280, Los Olivos', -11.971420, -77.074810, '987410101', 'Centro deportivo con canchas para partidos amistosos y torneos nocturnos.', 65, 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?auto=format&fit=crop&w=1200&q=80', 3),
  ('P02', 'Complejo San Martin', 'Av. Peru 2450, San Martin de Porres', -12.013950, -77.088220, '987410102', 'Complejo de barrio con opciones para futbol cinco, siete y nueve.', 55, 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=1200&q=80', 3),
  ('P03', 'Independencia Futbol Club', 'Av. Tupa Amaru 3920, Independencia', -11.991450, -77.062130, '987410103', 'Canchas de grass artificial para encuentros de grupos y empresas.', 60, 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=1200&q=80', 3),
  ('P04', 'Premier Comas', 'Av. Universitaria 7600, Comas', -11.936110, -77.059460, '987410104', 'Espacio deportivo amplio para pichangas de fin de semana.', 50, 'https://images.unsplash.com/photo-1518604666860-9ed391f76460?auto=format&fit=crop&w=1200&q=80', 3),
  ('P05', 'Puente Piedra Arena', 'Av. Puente Piedra 510, Puente Piedra', -11.867690, -77.077520, '987410105', 'Centro deportivo con canchas de distintas capacidades.', 45, 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80', 3),
  ('P06', 'Rimac Gol', 'Av. Proceres 720, Rimac', -12.033410, -77.033480, '987410106', 'Canchas urbanas para futbol rapido y partidos competitivos.', 48, 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=1200&q=80', 3),
  ('P07', 'Centro Lima Sport', 'Av. Brasil 610, Cercado de Lima', -12.055760, -77.044150, '987410107', 'Complejo deportivo ubicado cerca al centro de Lima.', 70, 'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?auto=format&fit=crop&w=1200&q=80', 3),
  ('P08', 'La Victoria Play', 'Av. Mexico 1610, La Victoria', -12.075390, -77.024970, '987410108', 'Canchas para partidos cortos, ligas y entrenamientos.', 58, 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?auto=format&fit=crop&w=1200&q=80', 3),
  ('P09', 'Cancha 28 Arena', 'Av. 28 de Julio 1460, La Victoria', -12.072010, -77.032610, '987410109', 'Centro con buena conectividad y formatos variados.', 62, 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?auto=format&fit=crop&w=1200&q=80', 3),
  ('P10', 'Barranco Futbol House', 'Av. Bolognesi 780, Barranco', -12.143640, -77.020250, '987410110', 'Canchas de futbol para grupos de amigos y empresas.', 85, 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=1200&q=80', 3),
  ('P11', 'Costa Sur Canchas', 'Av. Defensores del Morro 1780, Chorrillos', -12.172320, -77.016480, '987410111', 'Centro deportivo del sur con ambientes para futbol.', 65, 'https://images.unsplash.com/photo-1551958219-acbc608c6377?auto=format&fit=crop&w=1200&q=80', 2),
  ('P12', 'Surco Prime', 'Av. Caminos del Inca 1890, Santiago de Surco', -12.129570, -76.991550, '987410112', 'Canchas modernas para encuentros semanales.', 95, 'https://images.unsplash.com/photo-1566577739112-5180d4bf9390?auto=format&fit=crop&w=1200&q=80', 2),
  ('P13', 'Miraflores 5', 'Av. La Mar 1020, Miraflores', -12.108460, -77.053110, '987410113', 'Futbol rapido cerca a restaurantes y zonas comerciales.', 90, 'https://images.unsplash.com/photo-1580748141549-71748dbe0bdc?auto=format&fit=crop&w=1200&q=80', 2),
  ('P14', 'San Borja Arena', 'Av. Aviacion 2850, San Borja', -12.096850, -77.000180, '987410114', 'Centro para pichangas y torneos de futbol amateur.', 80, 'https://images.unsplash.com/photo-1570498839593-e565b39455fc?auto=format&fit=crop&w=1200&q=80', 2),
  ('P15', 'Lince Sport Zone', 'Av. Arequipa 2260, Lince', -12.083610, -77.033860, '987410115', 'Canchas centrales para partidos despues del trabajo.', 68, 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=1200&q=80', 2),
  ('P16', 'Jesus Maria FC', 'Av. Brasil 1250, Jesus Maria', -12.078480, -77.047470, '987410116', 'Complejo deportivo con superficies variadas.', 72, 'https://images.unsplash.com/photo-1593766827228-7c6c6e9c5f61?auto=format&fit=crop&w=1200&q=80', 2),
  ('P17', 'Pueblo Libre Gol', 'Av. Sucre 890, Pueblo Libre', -12.076870, -77.063740, '987410117', 'Canchas familiares para futbol cinco y siete.', 60, 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1200&q=80', 2),
  ('P18', 'Magdalena Arena', 'Av. Javier Prado Oeste 980, Magdalena del Mar', -12.095840, -77.072220, '987410118', 'Centro deportivo cercano a la costa.', 78, 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1200&q=80', 2),
  ('P19', 'San Miguel Canchas', 'Av. La Marina 2350, San Miguel', -12.077560, -77.089310, '987410119', 'Espacio de futbol para grupos y campeonatos internos.', 75, 'https://images.unsplash.com/photo-1600679472829-3044539ce8ed?auto=format&fit=crop&w=1200&q=80', 2),
  ('P20', 'Callao Futsal Park', 'Av. Saenz Pena 1290, Callao', -12.058310, -77.129470, '987410120', 'Canchas de acceso rapido desde el Callao.', 52, 'https://images.unsplash.com/photo-1495555961986-6d4c1ecb7be3?auto=format&fit=crop&w=1200&q=80', 2),
  ('P21', 'Bellavista Futbol', 'Av. Colonial 4200, Bellavista', -12.062860, -77.102760, '987410121', 'Centro de futbol para partidos de noche.', 57, 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=1200&q=80', 2),
  ('P22', 'La Perla Arena', 'Av. La Paz 840, La Perla', -12.071530, -77.118900, '987410122', 'Canchas de barrio con formatos para todos los grupos.', 50, 'https://images.unsplash.com/photo-1518604666860-9ed391f76460?auto=format&fit=crop&w=1200&q=80', 2),
  ('P23', 'Ate Pro Futbol', 'Carretera Central 1620, Ate', -12.038250, -76.963810, '987410123', 'Complejo deportivo del este para partidos competitivos.', 55, 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80', 2),
  ('P24', 'Santa Anita Play', 'Av. Los Ruiseñores 1180, Santa Anita', -12.042760, -76.970640, '987410124', 'Canchas para pichangas y entrenamientos.', 48, 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?auto=format&fit=crop&w=1200&q=80', 2),
  ('P25', 'El Agustino Sport', 'Av. Riva Aguero 1240, El Agustino', -12.044270, -76.998540, '987410125', 'Centro con canchas de futbol para la comunidad.', 45, 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=1200&q=80', 2),
  ('P26', 'San Juan Arena', 'Av. Wiesse 2270, San Juan de Lurigancho', -12.001980, -76.993310, '987410126', 'Complejo amplio para futbol cinco, siete y nueve.', 46, 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=1200&q=80', 2),
  ('P27', 'Villa El Salvador FC', 'Av. Revolucion 1570, Villa El Salvador', -12.212960, -76.937470, '987410127', 'Canchas de futbol para grupos del sur de Lima.', 42, 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?auto=format&fit=crop&w=1200&q=80', 2),
  ('P28', 'Villa Maria Gol', 'Av. Pachacutec 3400, Villa Maria del Triunfo', -12.165920, -76.946130, '987410128', 'Centro deportivo con canchas de grass sintetico.', 43, 'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?auto=format&fit=crop&w=1200&q=80', 2),
  ('P29', 'Lurin Futbol Park', 'Antigua Panamericana Sur Km 34, Lurin', -12.280630, -76.871860, '987410129', 'Complejo de futbol para partidos de fin de semana.', 70, 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=1200&q=80', 2),
  ('P30', 'Pachacamac Arena', 'Av. Paul Poblet 620, Pachacamac', -12.229430, -76.859770, '987410130', 'Canchas abiertas para pichangas y torneos.', 65, 'https://images.unsplash.com/photo-1551958219-acbc608c6377?auto=format&fit=crop&w=1200&q=80', 2),
  ('P31', 'Chaclacayo Futbol', 'Av. Nicolas Ayllon 650, Chaclacayo', -11.979090, -76.767490, '987410131', 'Centro deportivo con ambiente para futbol recreativo.', 58, 'https://images.unsplash.com/photo-1566577739112-5180d4bf9390?auto=format&fit=crop&w=1200&q=80', 2),
  ('P32', 'Chosica Prime', 'Av. Lima Sur 530, Lurigancho-Chosica', -11.930120, -76.696130, '987410132', 'Canchas para grupos que juegan en el este de Lima.', 55, 'https://images.unsplash.com/photo-1580748141549-71748dbe0bdc?auto=format&fit=crop&w=1200&q=80', 2),
  ('P33', 'La Molina Sports', 'Av. La Molina 3800, La Molina', -12.084510, -76.930560, '987410133', 'Centro deportivo con formatos para distintos equipos.', 100, 'https://images.unsplash.com/photo-1570498839593-e565b39455fc?auto=format&fit=crop&w=1200&q=80', 2),
  ('P34', 'Cieneguilla Canchas', 'Av. Nueva Toledo 1450, Cieneguilla', -12.118270, -76.816510, '987410134', 'Canchas amplias para encuentros de dia y noche.', 90, 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=1200&q=80', 2),
  ('P35', 'Breña Futbol Club', 'Av. Arica 620, Breña', -12.057960, -77.052950, '987410135', 'Canchas centrales para futbol rapido.', 54, 'https://images.unsplash.com/photo-1593766827228-7c6c6e9c5f61?auto=format&fit=crop&w=1200&q=80', 2),
  ('P36', 'Surquillo Arena', 'Av. Republica de Panama 4480, Surquillo', -12.116050, -77.020520, '987410136', 'Complejo urbano para pichangas de todos los niveles.', 68, 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1200&q=80', 2),
  ('P37', 'San Isidro Play', 'Av. Javier Prado Este 1400, San Isidro', -12.095570, -77.031180, '987410137', 'Centro de futbol corporativo y recreativo.', 110, 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1200&q=80', 2),
  ('P38', 'San Luis Sport', 'Av. Canada 2600, San Luis', -12.075750, -76.995570, '987410138', 'Canchas para encuentros entre amigos y equipos.', 60, 'https://images.unsplash.com/photo-1600679472829-3044539ce8ed?auto=format&fit=crop&w=1200&q=80', 2),
  ('P39', 'Zarate Futbol Center', 'Av. Gran Chimu 1050, San Juan de Lurigancho', -12.022360, -77.006440, '987410139', 'Centro para futbol siete y formatos complementarios.', 50, 'https://images.unsplash.com/photo-1495555961986-6d4c1ecb7be3?auto=format&fit=crop&w=1200&q=80', 2),
  ('P40', 'Carabayllo FC', 'Av. Universitaria 10200, Carabayllo', -11.890420, -77.044360, '987410140', 'Canchas de futbol para pichangas al norte de Lima.', 40, 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?auto=format&fit=crop&w=1200&q=80', 2);

INSERT INTO polideportivo
  (nombre, direccion, x, y, celular, wsp, id_distrito, descripcion, id_user_create, precio_desde, precio_desde_num, url_foto, created_at, updated_at)
SELECT
  nombre, direccion, CAST(latitud AS CHAR), CAST(longitud AS CHAR), celular, '1', NULL,
  descripcion, NULL, CAST(precio AS CHAR), precio, foto, NOW(), NOW()
FROM tmp_seed_polideportivos;

CREATE TEMPORARY TABLE tmp_seed_poli_ids AS
SELECT seed.codigo, seed.canchas_objetivo, polideportivo.id
FROM tmp_seed_polideportivos AS seed
JOIN polideportivo
  ON CONVERT(polideportivo.nombre USING utf8mb4) COLLATE utf8mb4_general_ci
     = CONVERT(seed.nombre USING utf8mb4) COLLATE utf8mb4_general_ci
 AND CONVERT(polideportivo.direccion USING utf8mb4) COLLATE utf8mb4_general_ci
     = CONVERT(seed.direccion USING utf8mb4) COLLATE utf8mb4_general_ci;

CREATE TEMPORARY TABLE tmp_seed_court_templates (
  orden TINYINT NOT NULL PRIMARY KEY,
  letra CHAR(1) NOT NULL
) ENGINE=MEMORY;

INSERT INTO tmp_seed_court_templates (orden, letra)
VALUES (1, 'A'), (2, 'B'), (3, 'C');

INSERT INTO cancha
  (id_polideportivo, nombre, anchom2, largom2, equiposvs, tipo_superficie, formato_vs, id_cancha_unida, url_foto, created_at, updated_at)
SELECT
  courts.id,
  CONCAT('Cancha ', courts.letra),
  CASE courts.capacidad
    WHEN '5' THEN '20' WHEN '6' THEN '25' WHEN '7' THEN '30'
    WHEN '8' THEN '34' WHEN '9' THEN '38' ELSE '45'
  END,
  CASE courts.capacidad
    WHEN '5' THEN '40' WHEN '6' THEN '45' WHEN '7' THEN '50'
    WHEN '8' THEN '55' WHEN '9' THEN '60' ELSE '75'
  END,
  courts.capacidad,
  courts.superficie,
  CASE courts.capacidad WHEN '6' THEN '6v6' WHEN '7' THEN '7v7' WHEN '9' THEN '9v9' ELSE NULL END,
  NULL,
  courts.foto_cancha,
  NOW(), NOW()
FROM (
  SELECT
    ids.id,
    ids.codigo,
    templates.orden,
    templates.letra,
    ELT(1 + MOD(CAST(SUBSTRING(ids.codigo, 2) AS UNSIGNED) + templates.orden, 6), '5', '6', '7', '8', '9', '11') AS capacidad,
    ELT(1 + MOD(CAST(SUBSTRING(ids.codigo, 2) AS UNSIGNED) + templates.orden, 3), 'sintetico', 'losa', 'artificial') AS superficie,
    ELT(1 + MOD(CAST(SUBSTRING(ids.codigo, 2) AS UNSIGNED) + templates.orden, 5),
      'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518604666860-9ed391f76460?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=800&q=80'
    ) AS foto_cancha
  FROM tmp_seed_poli_ids AS ids
  JOIN tmp_seed_court_templates AS templates
    ON templates.orden <= ids.canchas_objetivo
) AS courts;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_seed_court_templates;
DROP TEMPORARY TABLE IF EXISTS tmp_seed_poli_ids;
DROP TEMPORARY TABLE IF EXISTS tmp_seed_polideportivos;

-- Validacion esperada: 40 polideportivos y 90 canchas.
SELECT COUNT(*) AS total_polideportivos FROM polideportivo;
SELECT COUNT(*) AS total_canchas FROM cancha;

SELECT
  p.nombre AS polideportivo,
  COUNT(c.id) AS cantidad_canchas,
  GROUP_CONCAT(CONCAT(c.equiposvs, 'v', c.equiposvs) ORDER BY c.id SEPARATOR ' · ') AS capacidades,
  MIN(p.precio_desde_num) AS precio_desde
FROM polideportivo AS p
LEFT JOIN cancha AS c ON c.id_polideportivo = p.id
GROUP BY p.id, p.nombre
ORDER BY p.nombre;

SELECT
  COUNT(*) AS coordenadas_validas,
  SUM(CAST(x AS DECIMAL(10,6)) BETWEEN -12.400000 AND -11.800000
      AND CAST(y AS DECIMAL(10,6)) BETWEEN -77.200000 AND -76.600000) AS dentro_de_lima
FROM polideportivo;
