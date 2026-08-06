# API v1 - Watch Match Sessions

> Contrato vigente para companions; el QA físico sigue pendiente. Ver
> [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Authentication
Requiere `auth:sanctum`.

## Endpoints

### POST `/api/v1/watch/match-sessions`
Inicia una sesión de partido desde reloj.

Body ejemplo:
```json
{
  "external_session_id": "6C4A6E31-8F63-4EF6-8C8A-5E7715B6D3A8",
  "group_pichanga_id": 7,
  "field_id": 1,
  "cancha_id": 3,
  "field_geometry_id": 2,
  "start_time": "2026-04-06T18:00:00Z",
  "status": "live",
  "my_goal_side": "north",
  "device": "watchos",
  "source": "live",
  "distance_meters_raw": 320.4,
  "distance_meters_filtered": 287.2,
  "device_payload": {
    "watch_session_id": "6C4A6E31-8F63-4EF6-8C8A-5E7715B6D3A8",
    "schema_version": "1"
  }
}
```

Notas:
- `external_session_id` permite idempotencia por usuario.
- En sesiones reales (`source=live`) se exige `group_pichanga_id` válido.
- IDs inválidos (`<=0`) se normalizan a `null` y pueden causar `422` según flujo.

### GET `/api/v1/watch/match-sessions/my-active`
Retorna la sesión activa (`live|paused`) del usuario autenticado.

### POST `/api/v1/watch/match-sessions/{id}/samples/batch`
Batch de posiciones.

Body ejemplo:
```json
{
  "samples": [
    {
      "timestamp": "2026-04-06T18:00:10Z",
      "lat": -12.0464,
      "lng": -77.0428,
      "horizontalAccuracy": 8.2,
      "speed": 1.1,
      "quality_flag": "good"
    }
  ]
}
```

### POST `/api/v1/watch/match-sessions/{id}/events/batch`
Batch de eventos manuales.

Body ejemplo:
```json
{
  "events": [
    {
      "type": "goal",
      "timestamp": "2026-04-06T18:14:20Z",
      "minute": 15,
      "clockTime": "18:14"
    }
  ]
}
```

### POST `/api/v1/watch/match-sessions/{id}/finish`
Cierre de sesión.

Body ejemplo:
```json
{
  "end_time": "2026-04-06T19:32:00Z",
  "status": "finished",
  "distance_meters": 5234.4,
  "distance_meters_raw": 5360.2,
  "distance_meters_filtered": 5234.4
}
```

### GET `/api/v1/watch/pichangas/{id}/sessions/me`
Retorna historial de sesiones watch del usuario para esa pichanga con conteo de goles/asistencias.

### GET `/api/v1/watch/pichangas/{id}/heatmap/me`
Retorna datos para visualización en detalle de pichanga:
- `projection_mode=projected` con `projected_points` si existe geometría.
- `projection_mode=raw` con `raw_normalized_points` si no hay geometría.

## Errores y comportamiento esperado
- `404` en `heatmap/me`: no hay sesión watch para ese usuario+pichanga.
- Si existe sesión pero sin samples:
  - `session` presente,
  - `projected_points=[]`,
  - `raw_normalized_points=[]`.
- `422` en `store`: IDs inválidos o falta de `group_pichanga_id` para sesión real.
- `403`: sesión no pertenece al usuario autenticado (o no superadmin).
