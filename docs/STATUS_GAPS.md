# Fulbii — Brechas, riesgos y próximos pasos

> Actualizado: 10 de agosto de 2026. Ver estado funcional en
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## P0 — Antes de ampliar producción

- **Push físico por release:** probar dos cuentas reales en iOS y Android con
  permisos aceptados, app abierta, en segundo plano y cerrada. Confirmar tanto
  la bandeja como la alerta nativa y el deep link.
- **Worker de cola:** `fulbii-queue.service` debe permanecer activo y consumir
  `push,default`. Revisar `push:verification-report`, `failed_jobs` y logs FCM
  después de eventos reales.
- **Historial de migraciones VPS:** las tablas heredadas existen pero muchas
  migraciones figuran Pending. No correr migración global hasta crear y probar
  una estrategia de baseline/registro consistente sobre una copia de la base.
- **Publicación móvil:** archive iOS con bundle id válido de la extensión de
  notificaciones y build creciente; Android requiere prueba de canal Play
  interno antes de distribución amplia.

## P1 — Producto y operación

- Diseñar y publicar una política de actualización obligatoria: versión mínima
  remota, mensaje de mantenimiento y enlaces configurables por tienda. No está
  implementada todavía.
- Revisión periódica de usuarios sin tokens activos, grupos sin admin,
  pichangas con coordinación pendiente, reportes abiertos y errores push.
- Medir adopción de la landing: origen, clic en abrir/descargar, instalación y
  retorno desde deep links.
- Definir copy, screenshots reales, privacidad, términos y soporte antes del
  lanzamiento público de la landing.

## P2 — Evolución

- Sustituir los emojis temporales de la landing por ilustraciones/capturas
  aprobadas y activos de marca finales.
- Añadir observabilidad centralizada de entregas FCM/APNs y alertas ante cola
  detenida o tasa alta de fallo.
- Validar Watch en dispositivos físicos y definir la comunicación comercial de
  la integración wearable.

## Lo que ya no es una brecha funcional

Las siguientes capacidades están desarrolladas y requieren QA, no un nuevo
diseño: lista de espera, chat de grupo, admins múltiples, reportes/bloqueos,
preferencias de notificaciones, aportes limitados, rankings, fórmulas de
calificación centralizadas, formaciones arrastrables y mapa por viewport.
