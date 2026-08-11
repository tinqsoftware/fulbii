# API v1 — Bandeja y push

## Dispositivos y bandeja

- `GET /api/v1/me/devices`
- `POST /api/v1/me/devices/register`
- `POST /api/v1/me/devices/{device}/deactivate`
- `GET /api/v1/me/notifications`
- `POST /api/v1/me/notifications/read-all`
- `POST /api/v1/me/notifications/{notification}/read`

El registro guarda plataforma, token, nombre de dispositivo y versión real de
la app. La bandeja es persistente y el push se procesa de forma asíncrona.

## Payload y navegación

Cada evento puede incluir `target_type`, `target_id`, actor, grupo, pichanga o
reto relacionado, `image_url` e indicador visual. Flutter abre el destino desde
la bandeja/push: grupos, solicitudes, invitaciones, pichangas, retos, perfiles,
aportes y contenido contextual.

Tipos relevantes: solicitudes/invitaciones de grupo, creación/cambio/cancelación
de pichanga, cupos/espera, reto/propuestas/chat, calificación recibida,
aprobación/rechazo de aporte, reportes y eventos operativos.

Pichangas pueden superponer balón sobre foto de cancha; retos usan las fotos de
ambos grupos cuando existen. Si una imagen falla, título, cuerpo y navegación
deben seguir funcionando.

## Entrega

- `PUSH_DRIVER=log`: solo diagnóstico local.
- `PUSH_DRIVER=fcm`: FCM HTTP v1 con `FCM_PROJECT_ID` y
  `FCM_SERVICE_ACCOUNT_PATH`.
- El worker debe consumir `push,default`; consultar
  `push_dispatch_logs` para evidencia de envío.

La extensión iOS descarga imágenes de alertas nativas. Android y cualquier
fallo de imagen conservan el payload de texto. Ver
[verificación paso a paso](../09_firebase_push_verification_step_by_step.md).
