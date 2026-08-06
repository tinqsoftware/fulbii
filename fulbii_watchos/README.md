# Fulbii Watch (watchOS SwiftUI MVP)

> Estado y contratos compartidos con móvil/backend:
> [`../docs/AI_HANDOFF_CURRENT_STATE.md`](../docs/AI_HANDOFF_CURRENT_STATE.md)
> y [`../docs/api/v1_watch_match_sessions.md`](../docs/api/v1_watch_match_sessions.md).

Este módulo contiene el MVP funcional de Fulbii Watch con:
- `PreMatchView`
- `LiveMatchView`
- `EventConfirmationView`
- `MatchSummaryView`
- `SettingsDebugView`

También incluye managers de:
- sesión de partido,
- captura de ubicación (`CoreLocation`),
- workout (`HealthKit`),
- sync stub (`WatchConnectivity`),
- persistencia local (`UserDefaults` JSON).

## Crear proyecto en Xcode (rápido)
1. Abrir Xcode y crear `watchOS App` llamada `FulbiiWatchApp`.
2. Reemplazar los archivos generados por el contenido de `FulbiiWatchApp/`.
3. En `Signing & Capabilities` activar:
   - `HealthKit`
   - `Background Modes` (Workout Processing)
4. En `Info.plist` agregar permisos:
   - `NSLocationWhenInUseUsageDescription`
   - `NSHealthShareUsageDescription`
   - `NSHealthUpdateUsageDescription`
5. Seleccionar un Apple Watch físico o simulador y ejecutar.

## Flujo MVP
1. `Iniciar partido`
2. Captura periódica GPS + eventos manuales (`Gol`, `Asistencia`, `Pausa/Reanudar`)
3. `Finalizar`
4. Ver resumen con minutos, distancia, goles y mini recorrido
5. Botón `Simular partido de 10 min` para prueba inmediata
