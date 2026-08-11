# API v1 — Moderación, reportes y bloqueos

## Usuario autenticado

- `GET /api/v1/reports/mine`
- `POST /api/v1/reports`
- `GET /api/v1/me/blocks`
- `POST /api/v1/users/{user}/block`
- `DELETE /api/v1/users/{user}/block`
- `GET|POST /api/v1/field-submissions...`

Un reporte acepta objetivo y contexto de contenido para que staff pueda revisar
sin adivinar qué se reportó:

```json
{
  "target_type": "user",
  "target_id": 12,
  "content_type": "group_chat_message",
  "content_id": 78,
  "reason_code": "toxic_behavior",
  "description": "Insultos reiterados"
}
```

Los tipos admitidos dependen del objetivo y pueden incluir jugador, recinto,
foto, pichanga, publicación, comentario y mensajes de chat de grupo o reto.
El backend previene duplicados recientes equivalentes.

## Backoffice/API staff

Todo bajo `/api/v1/admin/*` y `/admin` web, con rol correspondiente:

- reportes: listar, resolver y resolver masivamente;
- strikes: crear, revocar y aplicar suspensión;
- aportes: listar, decidir, retirar foto y decisión masiva;
- métricas de crecimiento y readiness operativo.

El panel muestra también señales operativas: reportes pendientes, bloqueos,
push/colas, grupos sin admin, retos pendientes y pichangas que requieren
atención. `staff_admin` opera moderación; restricciones críticas siguen siendo
propiedad de superadmin.
