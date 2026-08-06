# 17. AI Handoff (Estado actual + pendientes de imágenes/UI)

> **Histórico / supersedido.** El handoff transversal vigente está en
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Objetivo de este handoff
Entregar contexto completo a otra IA para continuar trabajo en:
1. UX/UI visual (imágenes, assets, microcopys, pulido visual),
2. Watch E2E (subida real a backend),
3. visualización inmediata en iPhone (`Mi actividad watch`).

Este documento está orientado a continuidad técnica, no marketing.

## Estado técnico actual (resumen)
- Backend Laravel API v1 activo.
- App Flutter (`fulbii_app`) con módulo `Pichangas` en 3 tabs:
  - `Confirmados`,
  - `Pendientes`,
  - `Terminados`.
- Apple Watch integrado como companion dentro de `fulbii_app/ios`.
- Watch tiene flujo completo (iniciar, eventos, finalizar, resumen, terminados local).
- Card iPhone `Mi actividad watch` ya consume:
  - `GET /watch/pichangas/{id}/sessions/me`
  - `GET /watch/pichangas/{id}/heatmap/me`

## Problema abierto principal
En pruebas físicas, hay casos donde:
- watch muestra resumen local correcto,
- pero backend no refleja todas las filas (`samples/events`),
- y en iPhone aparece vacío o parcial.

Síntoma frecuente en watch: `Sync: Subida 0/1`.

## Flujo de datos esperado (fuente de verdad)
1. Watch crea payload de sesión al finalizar:
   - `sessionId`, `groupPichangaId`, `samples`, `events`, distancias `raw/filtered`.
2. Watch intenta subida directa:
   - `POST /watch/match-sessions`
   - `POST /watch/match-sessions/{id}/samples/batch`
   - `POST /watch/match-sessions/{id}/events/batch`
   - `POST /watch/match-sessions/{id}/finish`
3. En paralelo, iPhone recibe `watch_session_sync` por `WatchConnectivity` y actúa como relay de respaldo.
4. iPhone detalle pichanga consulta backend por `pichangaId` y renderiza card watch.

## Archivos clave para continuar
- Watch sync/upload:
  - `fulbii_app/ios/RunnerWatch/Services/WatchSyncManager.swift`
- Watch estado y tracking:
  - `fulbii_app/ios/RunnerWatch/ViewModels/MatchSessionManager.swift`
  - `fulbii_app/ios/RunnerWatch/Managers/LocationCaptureManager.swift`
- iPhone relay + bridge:
  - `fulbii_app/ios/Runner/AppDelegate.swift`
- iPhone UI detalle:
  - `fulbii_app/lib/src/features/pichangas/presentation/pichanga_detail_screen.dart`
- Board de pichangas:
  - `app/Http/Controllers/Api/V1/GroupPichangaController.php`

## SQL de diagnóstico rápido (backend activo)
```sql
-- 1) Sesiones watch recientes por usuario
SELECT id, user_id, group_pichanga_id, status, external_session_id,
       distance_meters, distance_meters_raw, distance_meters_filtered,
       start_time, end_time, created_at, updated_at
FROM watch_match_sessions
WHERE user_id = 1
ORDER BY id DESC
LIMIT 20;

-- 2) Muestras por sesión
SELECT s.id AS session_id, s.group_pichanga_id, COUNT(ps.id) AS samples_count
FROM watch_match_sessions s
LEFT JOIN watch_position_samples ps ON ps.session_id = s.id
WHERE s.user_id = 1
GROUP BY s.id, s.group_pichanga_id
ORDER BY s.id DESC
LIMIT 20;

-- 3) Eventos por sesión
SELECT s.id AS session_id, s.group_pichanga_id,
       SUM(CASE WHEN e.event_type = 'goal' THEN 1 ELSE 0 END) AS goals_count,
       SUM(CASE WHEN e.event_type = 'assist' THEN 1 ELSE 0 END) AS assists_count
FROM watch_match_sessions s
LEFT JOIN watch_match_events e ON e.session_id = s.id
WHERE s.user_id = 1
GROUP BY s.id, s.group_pichanga_id
ORDER BY s.id DESC
LIMIT 20;
```

## Logs mínimos que hay que capturar al probar físico
En logs del iPhone (Xcode) deben aparecer pasos del relay:
- `relay_store ...`
- `relay_samples_batch ...`
- `relay_events_batch ...`
- `relay_finish ...`

Si alguno falla con `401/404/422`, esa es la causa directa de no ver actividad watch en iPhone.

## Entorno y consistencia (muy importante)
- No mezclar DB local y backend producción al validar resultados.
- La app iPhone por defecto usa `https://fulbii.com/api/v1` salvo `--dart-define` explícito.
- Validar siempre con el mismo `user_id` y la misma `group_pichanga_id`.

## Pendientes para IA de imágenes/UI
1. Pulir visual del heatmap en iPhone:
   - escala de color,
   - densidad,
   - contraste para canchas oscuras/claras.
2. Pulir mini mapa de recorrido en watch (legibilidad en pantalla pequeña).
3. Proponer assets visuales para cards watch/iPhone:
   - iconografía consistente (`Watch`, `En proceso`, `Terminados`),
   - mejoras tipográficas sin romper jerarquía actual.
4. Mantener consistencia de marca `Fulbii` en watch e iPhone.

## Criterio de cierre funcional
Prueba física completa exitosa cuando:
1. usuario inicia y finaliza partido desde watch,
2. backend guarda sesión + samples + events,
3. iPhone muestra la sesión en `Mi actividad watch` del detalle correcto,
4. heatmap visible sin reiniciar app.
