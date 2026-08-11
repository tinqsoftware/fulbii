# API v1 — Pichangas, equipos y lista de espera

## Rutas principales

- `GET|POST /api/v1/clubs/{club}/pichangas`
- `GET /api/v1/clubs/{club}/pichangas/calendar`
- `GET /api/v1/pichangas/available`
- `GET /api/v1/pichangas/my-board`
- `GET /api/v1/pichangas/calendar?month=YYYY-MM`
- `GET /api/v1/pichangas/{pichanga}`

Crear requiere membresía activa y respeta `pichanga_create_scope`. El cliente
envía `cancha_id` real; `field_id` permanece como compatibilidad. Valores
habituales incluyen formato, jugadores por equipo, `duration_minutes`,
`starts_at`, audiencia, `is_open` y `allow_external_requests`.

## Acciones de asistencia y agenda

- `POST /api/v1/pichangas/{pichanga}/confirm`
- `POST /api/v1/pichangas/{pichanga}/withdraw`
- `GET|POST|DELETE /api/v1/pichangas/{pichanga}/waitlist`
- `POST /api/v1/pichangas/{pichanga}/status`
- `PUT /api/v1/pichangas/{pichanga}/schedule`
- `PUT /api/v1/pichangas/{pichanga}/audience`

Confirmar persiste `team_code` y `team_slot`; al retirar se libera el cupo. La
espera es FIFO y una promoción se realiza transaccionalmente. El detalle expone
estado propio, cupos, fase, recinto, fotos, equipos y permisos para que Flutter
no infiera reglas.

## Equipos y formación

- `GET /api/v1/pichangas/{pichanga}/teams/{teamCode}/formation-suggestion`
- `PUT /api/v1/pichangas/{pichanga}/teams/{teamCode}/formation`
- `PUT /api/v1/pichangas/{pichanga}/participants/{user}/team`

Una formación guarda roles, orden y posiciones normalizadas `formation_x` /
`formation_y` entre 0 y 1. Admin edita equipos; jugador confirmado edita el
suyo mientras la pichanga permita cambios.

## Operación y solicitudes externas

- `POST|GET /api/v1/pichangas/{pichanga}/external-requests`
- `POST /api/v1/pichangas/{pichanga}/external-requests/{externalRequest}/decision`
- `POST /api/v1/pichangas/{pichanga}/renotify/preview`
- `POST /api/v1/pichangas/{pichanga}/renotify/send`

Cambios de fecha/cancha, cancelación, cupos y decisiones generan eventos de
notificación respetando permisos y silencios aplicables.
