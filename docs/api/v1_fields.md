# API v1 - Fields / Canchas / Geometría

> Contrato vigente; contexto de módulos y QA pendiente en
> [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

> Las tarjetas y el detalle de pichanga entregan `venue_field_id`; Flutter lo
> usa para navegar a `GET /api/v1/fields/{field}` y regresar al detalle de la
> pichanga con la navegación normal.

## Authentication
Todos los endpoints requieren `auth:sanctum`.

## Modelo actual (compat + transición)
- `polideportivo` = centro deportivo.
- `cancha` = cancha específica dentro de un centro deportivo.
- `group_pichangas.field_id` se mantiene por compatibilidad y apunta a `polideportivo.id`.
- `group_pichangas.cancha_id` se añade para vínculo canónico de partido con cancha.
- `field_geometries` almacena geometría reusable por cancha para proyectar ruta a plano.

## Endpoints

### GET `/api/v1/fields?q=...&limit=...`
Lista centros deportivos para mapa móvil.

### GET `/api/v1/fields/{field}`
Detalle de centro deportivo.

### PUT `/api/v1/fields/{field}/geometry`
Upsert de geometría de cancha (MVP: superadmin).

Body ejemplo:
```json
{
  "cancha_id": 12,
  "width_meters": 30,
  "length_meters": 50,
  "rotation_degrees": 15,
  "corners": [
    { "lat": -12.1, "lng": -77.0 },
    { "lat": -12.1, "lng": -77.001 },
    { "lat": -12.101, "lng": -77.001 },
    { "lat": -12.101, "lng": -77.0 }
  ]
}
```

Response ejemplo:
```json
{
  "message": "Geometría actualizada.",
  "geometry": {
    "id": 2,
    "field_id": 5,
    "cancha_id": 12,
    "width_meters": 30,
    "length_meters": 50,
    "rotation_degrees": 15,
    "corners_json": [...]
  }
}
```

## Reglas heatmap (MVP)
- Si existe geometría para la cancha: proyectar puntos GPS al plano.
- Si no existe geometría: mostrar ruta GPS cruda.
- Geometría pensada para configurar una vez y reutilizar.
