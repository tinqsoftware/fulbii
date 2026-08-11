# Fulbii — Estado actual y relevo

> Fuente de verdad operativa al **10 de agosto de 2026**. Los documentos
> históricos preservan contexto; los contratos API y este archivo definen el
> comportamiento vigente.

## Arquitectura

- **Backend:** Laravel; API en `routes/api.php`, web pública/backoffice en
  `routes/web.php`, servicios de dominio en `app/Services`.
- **Móvil:** Flutter/Riverpod en `fulbii_app/lib/src`; es el cliente de usuario
  final para iOS y Android.
- **Web:** landing, deep links y backoffice. Los flujos web heredados de
  perfiles, grupos y calificaciones se muestran como intersticial a la app y
  ya no aceptan mutaciones públicas.
- **Wearables:** `fulbii_watchos` y `fulbii_wearos` sincronizan sesiones,
  eventos y muestras por contratos API v1.

## Decisiones de producto vigentes

### Grupos

- Los grupos pueden tener múltiples administradores iguales. No se permite
  retirar/degradar al último admin activo.
- `pichanga_create_scope` define `members` o `admins`; Laravel valida el
  permiso incluso si el selector móvil lo deshabilita.
- El chat general es independiente del chat contextual de retos. Bloqueos,
  silencios y preferencias por categoría se aplican al destinatario.

### Pichangas

- `cancha_id` es el vínculo canónico de una pichanga; `field_id` se conserva
  por compatibilidad.
- Participantes confirmados tienen equipo, slot y, si se edita formación,
  coordenadas normalizadas `formation_x`/`formation_y`.
- La lista de espera es FIFO, transaccional y promueve solo si existe un cupo
  elegible. Pichangas pasadas no aparecen como abiertas.
- Calificar dentro de una pichanga requiere que ambas personas estén
  confirmadas, prohíbe autocalificación y permite un voto por par/pichanga.

### Calificaciones y ranking

- Cada habilidad se promedia globalmente entre votos válidos: físico, arquero,
  delantero, mediocampo y defensa.
- `promedio de campo = promedio(delantero, mediocampo, defensa)`.
- `promedio jugador = promedio(promedio de campo, físico)`.
- `promedio arquero = promedio(arquero, físico)`.
- `promedio principal`/`stars` es el mayor; en empate gana el perfil de campo.
  La posición de campo desempata delantero, mediocampo y defensa, en ese
  orden. La fuente única es `CombinedSkillRatingService`.
- Equipos, grupos, pichangas y rankings promedian únicamente promedios
  principales disponibles, nunca una media local de cinco campos.

### Aportes de canchas

- Una persona puede crear máximo tres solicitudes por mes calendario y solo
  una pendiente a la vez. Las decisiones notifican por bandeja y push.
- La atribución aprobada se muestra en el detalle, no en marcadores del mapa.

### Notificaciones

- La notificación se registra primero en bandeja y se despacha en cola `push`.
- FCM requiere cuenta de servicio legible, token activo y worker `fulbii-queue`
  ejecutando `queue:work database --queue=push,default`.
- iOS soporta imágenes ricas mediante `FulbiiNotificationService`; Android usa
  el payload estándar y fallback de texto.

## Migraciones y despliegue

Migraciones recientes aditivas:

- `2026_08_08_000001_add_formation_coordinates_to_group_pichanga_participants`
- `2026_08_08_000002_add_rating_lookup_indexes`
- `2026_08_10_000001_add_community_notification_tables`
- `2026_08_10_000002_add_report_context_and_pichanga_waitlist`
- `2026_08_10_000003_add_field_submission_submission_limits_indexes`

El VPS heredado tiene tablas existentes que no figuran en la tabla
`migrations`. Por eso **no** se debe ejecutar `php artisan migrate --force`
globalmente hasta reconstruir el baseline de forma controlada. Para una
migración nueva, respaldar, ejecutar solo su `--path`, verificar con
`migrate:status` y confirmar tablas/índices mediante `tinker`.

## Validación prioritaria

1. Push físico iOS y Android con app en foreground, background y cerrada.
2. Worker systemd y `php artisan push:verification-report --minutes=30`.
3. [Checklist móvil reciente](QA_MOBILE_RECENT_CHANGES.md) con dos cuentas y
   un administrador.
4. Archive iOS con versión/build nuevos. La extensión debe tener el bundle id
   `com.fulbii.FulbiiNotificationService`.

## Brechas conocidas

- La política de actualización obligatoria aún no existe; requiere configuración
  de versión mínima publicada después de cada release de tienda.
- Falta normalizar la historia de migraciones del VPS antes de adoptar el
  comando Laravel global de migración.
- Las imágenes push y APNs de producción requieren validación real por release.

## Documentos canónicos

- [Proyecto](PROJECT_OVERVIEW.md)
- [QA móvil](QA_MOBILE_RECENT_CHANGES.md)
- [Operación](08_ops_runbook.md)
- [Push](09_firebase_push_verification_step_by_step.md)
- [Brechas](STATUS_GAPS.md)
