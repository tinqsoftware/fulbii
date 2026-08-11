# API v1 — Grupos, miembros e invitaciones

> Vigente al 10 de agosto de 2026. Ver [estado actual](../AI_HANDOFF_CURRENT_STATE.md).

## Lectura pública y autenticada

`GET /api/v1/clubs` y los detalles visibles aceptan invitado. Cuando hay token
Sanctum, el backend agrega contexto de membresía y permisos.

### `GET /api/v1/clubs?scope=mine|discover&q=...`

- `mine`: membresías activas, incluso si son privadas o inactivas.
- `discover`: grupos activos/visibles sin membresía activa del usuario.
- El item incluye rol, `logo_url`, `pichanga_create_scope`, conteos futuros de
  pichangas, abiertas y `my_confirmed_pichangas_count`.
- `is_owner` es informativo; los permisos dependen de rol activo y estado del
  grupo.

### Crear/editar

- `POST /api/v1/clubs`: crea grupo y agrega al creador como admin.
- `GET /api/v1/clubs/{club}`: detalle, membresía, ajustes y permisos actuales.
- `PUT /api/v1/clubs/{club}`: solo admin/superadmin; permite, entre otros,
  actualizar `pichanga_create_scope` (`members|admins`) y logo multipart.

Un admin no puede dejar al grupo sin administradores activos. Los grupos
inactivos responden `409 club_inactive` en mutaciones operativas.

## Miembros y auditoría

- `GET /api/v1/clubs/{club}/members`
- `GET /api/v1/clubs/{club}/members/{user}/public-profile`
- `PUT /api/v1/clubs/{club}/members/{user}/role` body `{ "rol": "admin" }`
- `DELETE /api/v1/clubs/{club}/members/{user}`
- `GET /api/v1/clubs/{club}/admin-activity`

El perfil público no expone correo, fecha de nacimiento ni otros datos privados.
Los puntajes provienen de `CombinedSkillRatingService`.

## Solicitudes e invitaciones

- `GET /api/v1/clubs/join/{joinCode}`
- `POST /api/v1/clubs/join/{joinCode}/request`
- `POST /api/v1/clubs/{club}/join-requests`
- `GET /api/v1/clubs/{club}/join-requests`
- `POST /api/v1/clubs/{club}/join-requests/{joinRequest}/decision`
- `POST /api/v1/clubs/{club}/join-requests/{joinRequest}/cancel`
- `POST /api/v1/clubs/{club}/join-code/rotate`
- `GET /api/v1/invitations`
- `POST /api/v1/clubs/{club}/invitations`
- `POST /api/v1/invitations/{invitation}/respond`
- `POST /api/v1/invitations/{invitation}/revoke`

Las decisiones generan bandeja/push para los destinatarios aplicables. Las
solicitudes llegan a todos los admins activos; las invitaciones email sin cuenta
no pueden recibir push hasta identificarse.

## Chat y preferencias

- `GET|POST /api/v1/clubs/{club}/chat/messages`
- `POST /api/v1/clubs/{club}/chat/read`
- `GET|PUT /api/v1/clubs/{club}/notification-preference`
- `GET /api/v1/clubs/{club}/notification-categories`
- `PUT /api/v1/clubs/{club}/notification-categories/{category}`

El chat de grupo es distinto al chat de retos. Los silencios y la presencia
activa excluyen push cuando la política del evento lo permite.
