# 14. TestFlight iPhone + Apple Watch Checklist

> Para el estado transversal del producto, usar
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Objetivo
Subir un build de `Runner` que incluya `Runner Watch App` para instalación desde TestFlight en iPhone + Apple Watch, sin depender de Xcode para uso diario.

## Preflight técnico
- [ ] Proyecto: `fulbii_app/ios/Runner.xcodeproj`
- [ ] Targets presentes: `Runner`, `Runner Watch App`
- [ ] `Runner` tiene `Embed Watch Content` con `Runner Watch App.app`
- [ ] `Runner Watch App` con `WATCHOS_DEPLOYMENT_TARGET = 8.0`
- [ ] Bundle IDs:
  - [ ] `Runner`: `com.fulbii`
  - [ ] `Runner Watch App`: `com.fulbii.watchkitapp`
- [ ] Signing automático en ambos targets con el mismo Team

## Permisos y capabilities watch
- [ ] `NSLocationWhenInUseUsageDescription`
- [ ] `NSHealthShareUsageDescription`
- [ ] `NSHealthUpdateUsageDescription`
- [ ] Capability `HealthKit`
- [ ] `Background Modes` con `workout-processing`

## Flujo funcional mínimo antes de subir
- [ ] `Iniciar partido` solo aparece en ventana válida (`-5 min` hasta fin por duración)
- [ ] `Gol`/`Asistencia` muestran banner auto-cierre (sin loop modal)
- [ ] Finalizar partido genera resumen con recorrido/eventos reales
- [ ] iPhone recibe contexto/sync por `WatchConnectivity`
- [ ] Detalle de pichanga muestra card `Mi actividad watch`
- [ ] Datos watch visibles en iPhone sin reiniciar app (distancia + eventos + heatmap)

## Archive y distribución
1. Seleccionar esquema `Runner`.
2. Seleccionar destino `Any iOS Device (arm64)`.
3. `Product > Archive`.
4. En Organizer: `Distribute App > App Store Connect > Upload`.
5. Esperar procesamiento en App Store Connect.
6. En TestFlight, validar que el build incluye Apple Watch app.
7. Instalar desde TestFlight en iPhone y confirmar instalación en Watch app del iPhone.

## Si el watch no aparece en TestFlight
1. Revisar que el archivo subido fue de `Runner` (no del target watch aislado).
2. Revisar `Embed Watch Content` y bundle IDs.
3. Revisar signing/profiles del target watch.
4. Subir nuevo build incrementando build number.

## Si aparece `Sync: Subida 0/1` en watch físico
1. Abrir logs del iPhone (Xcode) y buscar líneas:
   - `relay_store`
   - `relay_samples_batch`
   - `relay_events_batch`
   - `relay_finish`
2. Verificar que cada paso devuelva `2xx` (sin `401/404/422`).
3. Verificar que `group_pichanga_id` enviado sea válido y > 0.
4. Confirmar que iPhone y watch usan el mismo usuario/token/contexto.
5. Validar que se consulta la misma BD del backend activo (no mezclar local con producción).

## Simulador Paired (debug local)
1. En `Devices and Simulators`, dejar un solo par activo (`iPhone ... (Paired)` + `Apple Watch ... (Paired)`).
2. Correr `Runner` primero sobre el iPhone paired y hacer login.
3. Luego correr `Runner Watch App` sobre el watch paired.
4. Si en logs iPhone aparece `WCErrorCodeWatchAppNotInstalled`, es problema de pairing/instalación del companion en simulador, no de autenticación.
5. Si el pairing se rompe, reiniciar ambos simuladores del mismo par y volver a correr en el orden del punto 2-3.
