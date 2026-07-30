-- Seed minimo de canchas para QA de mapa.
-- Ejecutar solo en entorno de pruebas (staging/local), no en produccion final.

SELECT COUNT(*) AS total_polideportivos FROM polideportivo;

INSERT INTO polideportivo
(
  nombre,
  direccion,
  x,
  y,
  celular,
  wsp,
  id_distrito,
  descripcion,
  id_user_create,
  precio_desde,
  url_foto,
  created_at,
  updated_at
)
SELECT *
FROM (
  SELECT
    'Fulbii Demo Centro' AS nombre,
    'Av. Nicolas de Pierola 123, Lima' AS direccion,
    '-12.0464' AS x,
    '-77.0428' AS y,
    '999111222' AS celular,
    '1' AS wsp,
    NULL AS id_distrito,
    'Cancha demo para validar mapa y flujo de pichangas.' AS descripcion,
    1 AS id_user_create,
    '50' AS precio_desde,
    NULL AS url_foto,
    NOW() AS created_at,
    NOW() AS updated_at
  UNION ALL
  SELECT
    'Fulbii Demo Sur',
    'Av. Angamos 456, Surquillo',
    '-12.1111',
    '-77.0215',
    '999222333',
    '1',
    NULL,
    'Cancha demo 2 para QA movil.',
    1,
    '45',
    NULL,
    NOW(),
    NOW()
  UNION ALL
  SELECT
    'Fulbii Demo Norte',
    'Av. Universitaria 789, Los Olivos',
    '-11.9960',
    '-77.0700',
    '999333444',
    '1',
    NULL,
    'Cancha demo 3 para QA movil.',
    1,
    '40',
    NULL,
    NOW(),
    NOW()
) demo_rows
WHERE NOT EXISTS (
  SELECT 1 FROM polideportivo LIMIT 1
);

SELECT
  COUNT(*) AS total_polideportivos,
  SUM(
    CASE
      WHEN x IS NOT NULL AND y IS NOT NULL
           AND x <> '' AND y <> '' THEN 1
      ELSE 0
    END
  ) AS con_coordenadas
FROM polideportivo;
