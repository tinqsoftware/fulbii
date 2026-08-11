# API v1 — Polideportivos, canchas y aportes

## Descubrimiento

- `GET /api/v1/fields?q=&limit=&south=&west=&north=&east=`
- `GET /api/v1/fields/nearby`
- `GET /api/v1/fields/{field}`

La lista admite bounds opcionales para el mapa. Flutter consulta el viewport
más un margen de precarga y conserva caché por zona/filtros. `polideportivo` es
el recinto y `cancha` la cancha concreta; `cancha_id` es la referencia canónica
de una pichanga.

El detalle devuelve sus canchas, fotos, datos de contacto y pichangas abiertas
futuras. Una cancha usa la ubicación de su polideportivo hasta que exista
geometría individual.

## Aportes de recintos

- `GET /api/v1/field-submissions/mine`
- `POST /api/v1/field-submissions`

La respuesta de `mine` incluye uso mensual, límite, solicitud pendiente y si
se puede crear. El POST es autenticado, transaccional y aplica estas reglas:

- máximo **tres** solicitudes creadas por usuario/mes calendario;
- máximo **una** solicitud `pending` simultánea;
- el límite mensual cuenta aprobadas y rechazadas.

Un aporte puede incluir fotos, ubicación, dirección, celular/WhatsApp y datos
de polideportivo/cancha. Tras decisión, la persona recibe `field_submission_approved`
o `field_submission_rejected`; la aprobada puede enlazar al contenido creado.

## Geometría

`PUT /api/v1/fields/{field}/geometry` es para superadmin y guarda la geometría
reutilizable de una cancha para heatmaps. Si no existe, la app muestra la ruta
GPS cruda.
