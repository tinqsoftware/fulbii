# 10. Retos + Chat + Notificaciones (Setup y QA)

> Guía de módulo. Revalidar permisos y estados de grupo contra
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md) antes de extenderla.

## Estado actual
- ✅ Backend de retos y chat implementado.
- ✅ Endpoint de presencia para suprimir push cuando el usuario está dentro del chat.
- ✅ App Flutter con pantalla de chat de reto + heartbeat de presencia.
- ✅ Push handler abre chat de reto (`challenge_id`) y refresca inbox en foreground.
- ✅ SQL de retos ejecutado en BD activa.
- ⏳ Falta QA en 2 dispositivos físicos (iOS + Android).

## 1) SQL obligatorio (una sola vez)
Ejecuta en la BD que usa tu backend (`fulbii.com` y local si aplica):

- `/Users/alfredoricciale/Sites/MisLaravel/fulbii 2/database/sql/fulbii_upgrade_2026_03_28_challenges_chat_presence_compat.sql`

## 2) Endpoints nuevos
- `GET /api/v1/challenges`
- `GET /api/v1/clubs/{club}/challenges`
- `POST /api/v1/clubs/{club}/challenges`
- `GET /api/v1/challenges/{challenge}`
- `POST /api/v1/challenges/{challenge}/coordinate`
- `POST /api/v1/challenges/{challenge}/reject`
- `POST /api/v1/challenges/{challenge}/cancel`
- `GET /api/v1/challenges/{challenge}/messages`
- `POST /api/v1/challenges/{challenge}/messages`
- `POST /api/v1/challenges/{challenge}/field-options`
- `POST /api/v1/challenges/{challenge}/time-options`
- `GET /api/v1/challenges/{challenge}/configurations`
- `POST /api/v1/challenges/{challenge}/configurations/propose`
- `POST /api/v1/challenges/{challenge}/configurations/{configuration}/decision`
- `PUT /api/v1/me/presence/chat`

## 3) Reglas de push en chat
- Si el usuario está en el mismo chat activo (`user_chat_presence` heartbeat < 90s): no push de sistema.
- Si está fuera del chat: sí se crea `push_notifications` y sí se despacha push.
- Se respeta mute por grupo (`user_group_notification_prefs`).
- El emisor nunca recibe su propio push.

## 4) QA rápido (obligatorio)
1. Crear reto A -> B.
2. Entrar al chat y enviar mensajes desde ambos lados.
3. Verificar 4 estados del receptor:
   1. app cerrada: llega push
   2. app minimizada: llega push
   3. app abierta en otra pantalla: llega push/inbox
   4. app abierta en el chat exacto: no push sistema, sí mensaje en vivo

## 5) SQL de evidencia
```sql
SELECT id, type, user_id, club_id, group_pichanga_id, created_at
FROM push_notifications
WHERE type LIKE 'challenge_%'
ORDER BY id DESC
LIMIT 50;

SELECT id, status, provider, error_message, sent_at, created_at
FROM push_dispatch_logs
ORDER BY id DESC
LIMIT 50;

SELECT user_id, challenge_id, is_active, last_heartbeat_at, updated_at
FROM user_chat_presence
ORDER BY updated_at DESC
LIMIT 20;
```
