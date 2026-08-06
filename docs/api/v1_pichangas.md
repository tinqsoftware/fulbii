# API v1 - Pichangas

> Contrato vigente al 5 de agosto de 2026. Para la decisión de producto y
> estados Flutter, ver [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Autenticación

Las mutaciones, el board personal, calendario, actividad y gestión requieren
`auth:sanctum`. La lectura de una pichanga o agenda de club puede ser pública
únicamente si el grupo está activo/visible y la pichanga está abierta, futura y
publicada o confirmada; el resto exige membresía activa o permisos elevados.

### Clubs -> Pichangas
- `GET /api/v1/clubs/{club}/pichangas`
- `POST /api/v1/clubs/{club}/pichangas`

### Agenda, calendario y detalle
- `GET /api/v1/pichangas/available`
- `GET /api/v1/pichangas/my-board`
- `GET /api/v1/pichangas/calendar?month=YYYY-MM`
- `GET /api/v1/pichangas/{pichanga}`

### Pichanga state/actions
- `POST /api/v1/pichangas/{pichanga}/confirm`
- `POST /api/v1/pichangas/{pichanga}/withdraw`
- `POST /api/v1/pichangas/{pichanga}/status`
- `PUT /api/v1/pichangas/{pichanga}/audience`

### External requests
- `POST /api/v1/pichangas/{pichanga}/external-requests`
- `GET /api/v1/pichangas/{pichanga}/external-requests`
- `POST /api/v1/pichangas/{pichanga}/external-requests/{externalRequest}/decision`

### Re-notify
- `POST /api/v1/pichangas/{pichanga}/renotify/preview`
- `POST /api/v1/pichangas/{pichanga}/renotify/send`

## Key behavior
- Auto-confirm by capacity when `confirmation_mode=auto_by_capacity`.
- Members confirm directly.
- External users send request; admin approves/rejects.
- External request expires at pichanga start.
- Audience supports degree and filters:
  - `target_degree` 1/2/3
  - sex, age range, minimum skills
- Re-notify obeys club limits:
  - `renotify_cooldown_minutes`
  - `renotify_max_per_pichanga`
- Push mute by group is respected before send accounting.
- El detalle devuelve `court_name`, `field_name`, `address`,
  `venue_photo_url` y `venue_field_id`; la app abre el detalle de
  polideportivo con este último identificador.
- También devuelve `phase`, `status_label`, `end_at`, `confirmed_count`,
  `spots_left` y `teams`. Cada equipo expone `confirmed_count`, slots y
  `avg_rating` ya en escala de estrellas 0.0–5.0.
- `me` incluye `can_confirm`, `can_request_external`, `can_change_team` y
  `can_withdraw`, para que el CTA no infiera reglas en Flutter.
- Confirmar siempre persiste `team_code` y `team_slot`. La aceptación externa
  elige el equipo menos cargado. Para datos previos sin asignación, ejecutar:

  ```bash
  php artisan pichangas:repair-team-assignments --force
  ```

## Example create body
```json
{
  "title": "Martes 9pm",
  "description": "Pichanga semanal",
  "field_id": 9,
  "address": "Av. Primavera 123",
  "starts_at": "2026-03-24 21:00:00",
  "duration_minutes": 90,
  "capacity": 14,
  "confirmation_mode": "auto_by_capacity",
  "is_open": false,
  "notify_degree": 2,
  "allow_external_requests": true,
  "withdraw_until": "2026-03-24 15:00:00",
  "audience_sex": "M",
  "audience_age_min": 18,
  "audience_age_max": 45,
  "skill_fisico_min": 3.0,
  "skill_defensa_min": 4.0
}
```

Las habilidades y filtros admiten decimales de `0.0` a `5.0`.
