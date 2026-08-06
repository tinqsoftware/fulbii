# 13. Fulbii Watch MVP (Estado actual)

> Estado de módulo wearable; el estado transversal más reciente está en
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Arquitectura activa
- Watch app integrada en `fulbii_app/ios`:
  - iPhone target: `Runner`
  - watch companion target: `Runner Watch App`
- Sincronización iPhone↔Watch por `WatchConnectivity`:
  - contexto de sesión (usuario/token/base URL/matches),
  - envío de payload de sesión watch (`watch_session_sync`),
  - relay iPhone al backend cuando aplique.
- Backend Laravel v1 con tablas watch:
  - `watch_match_sessions`
  - `watch_position_samples`
  - `watch_match_events`

## Flujo funcional watch (productivo)
1. Home con 3 tabs:
   - `Confirmados` (vigentes),
   - `Pendientes` (vigentes),
   - `Terminados` (local-first, sesiones finalizadas en watch, límite 7).
2. Inicio de partido:
   - habilitado desde `start_at - 5 min` hasta `end_at`.
3. Partido en vivo:
   - captura GPS,
   - goles/asistencias/pausa/reanudar,
   - cronómetro y distancia.
4. Finalización:
   - resumen con minutos, distancia, goles, asistencias y recorrido.
   - sesión encolada para sync (`queueSessionForSync`).

## Reglas de listas (watch)
- `Confirmados` y `Pendientes` solo muestran pichangas vigentes: `now <= endAt`.
- Si expira por tiempo, deja de mostrarse en esas listas.
- Al finalizar desde watch:
  - sale de `Confirmados`,
  - entra a `Terminados` local.
- Orden:
  - `Confirmados/Pendientes`: ascendente por `startAt`.
  - `Terminados`: más reciente primero.

## Estado de integración iPhone (detalle pichanga)
- Card `Mi actividad watch`:
  - consume `sessions/me` y `heatmap/me` por `pichangaId`,
  - muestra distancia, goles/asistencias, sesiones terminadas y heatmap.
- Estado transitorio soportado:
  - si hay sesión sin puntos todavía: `Sesión recibida, sincronizando recorrido…`.
- El botón de simulación ya no es parte del flujo de usuario final en iPhone.

## Riesgo abierto principal (físico)
- En algunas pruebas físicas el watch muestra resumen local, pero backend no refleja `samples/events` recientes y aparece `Sync: Subida 0/1`.
- Este es el foco actual de QA E2E:
  - `watch -> backend -> card Mi actividad watch`.

## Checklist de smoke E2E recomendado
- [ ] Iniciar partido en watch físico desde pichanga válida.
- [ ] Registrar al menos 1 gol/asistencia y desplazamiento real.
- [ ] Finalizar y verificar subida completa de sesión/samples/events/finish.
- [ ] Abrir detalle de esa misma pichanga en iPhone sin reiniciar app.
- [ ] Ver distancia + eventos + heatmap.
