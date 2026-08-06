# 07. Handoff de Release Interno (Actualizado)

> **Histórico / supersedido.** Este handoff corresponde a una fase previa de
> release. El relevo operativo vigente es
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Estado general del proyecto
- ✅ API Laravel v1 operativa para auth social, pichangas, notificaciones, social, moderación y watch.
- ✅ App iOS/Android Flutter operativa con módulo `Pichangas` en 3 pestañas (`Confirmados`, `Pendientes`, `Terminados`).
- ✅ Apple Watch integrado como companion en `fulbii_app/ios` (`Runner` + `Runner Watch App`).
- ✅ Sincronización iPhone↔Watch por `WatchConnectivity` con contexto (`auth_token`, usuario, matches).
- ✅ Backend watch con endpoints de sesión/samples/events/finish y lectura de heatmap/sesiones.
- ⚠️ Pendiente crítico en producción: validar E2E físico completo `watch -> backend -> card Mi actividad watch` sin estados `Sync: Subida 0/1`.
- ⚠️ Migración de servidor en curso: asegurar dependencias PHP/Composer, cola y scheduler persistentes.

## Entregables ya en código
1. Watch sync y relay iPhone:
   - iPhone `AppDelegate` procesa `watch_session_sync` y sube al backend (`relay_store`, `relay_samples_batch`, `relay_events_batch`, `relay_finish`).
   - Watch guarda cola local y reintenta subida con token/base URL del contexto.
2. Board unificado de pichangas:
   - Endpoint `GET /api/v1/pichangas/my-board`.
   - Clasificación por vigencia temporal y estado participante.
3. Watch activity en detalle de pichanga:
   - Card `Mi actividad watch` con distancia, goles/asistencias, sesiones terminadas y heatmap.
4. Tracking:
   - Distancia `filtered/raw` y `quality_flag` por muestra.

## Riesgos actuales antes de Go/No-Go
1. **Watch físico sin subida completa**:
   - Síntoma: resumen en watch con datos, pero DB/API sin `samples/events` recientes o card iPhone vacía.
2. **Confusión de entornos**:
   - App iPhone por defecto usa `https://fulbii.com/api/v1`.
   - No comparar resultados de app contra DB local si backend activo es cloud.
3. **Infra de colas tras migración**:
   - Verificar unidad de systemd para workers (`fulbii-queue.service` o equivalente) y `queue:work` activo.

## Qué debe quedar validado en esta fase
1. Login Apple/Google en iPhone físico contra backend final.
2. Push APNs/FCM en físico.
3. E2E Watch real:
   - iniciar partido,
   - registrar goles/asistencias,
   - finalizar,
   - ver sesión/heatmap en iPhone sin reiniciar app.
4. Archive/TestFlight de `Runner` incluyendo watch companion.

## Referencias
- `docs/13_fulbii_watch_mvp.md`
- `docs/14_testflight_watch_release_checklist.md`
- `docs/15_watch_tracking_spec.md`
- `docs/api/v1_watch_match_sessions.md`
- `docs/16_ip_cutover_fulbii_domain.md`
