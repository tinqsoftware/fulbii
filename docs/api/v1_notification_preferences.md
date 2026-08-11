# API v1 — Preferencias de notificaciones

Las preferencias son personales por miembro activo; nunca conceden permisos de
administración.

## Preferencia general del grupo

- `GET /api/v1/clubs/{club}/notification-preference`
- `PUT /api/v1/clubs/{club}/notification-preference`

Body:

```json
{ "mode": "mute_1w" }
```

Valores: `always_on`, `mute_24h`, `mute_1w`, `mute_forever`.

## Preferencias por categoría

- `GET /api/v1/clubs/{club}/notification-categories`
- `PUT /api/v1/clubs/{club}/notification-categories/{category}`

Las categorías cubren, según evento, chat/retos, pichangas y
solicitudes/invitaciones. Los eventos críticos aplican su política explícita;
no asumir que un silencio general altera permisos, bandeja o auditoría.

Las notificaciones de chat además excluyen al emisor, usuarios con grupo
silenciado y presencia activa en esa conversación cuando corresponda.
