# Fulbii Watch (Wear OS MVP)

> Estado y contratos compartidos con móvil/backend:
> [`../docs/AI_HANDOFF_CURRENT_STATE.md`](../docs/AI_HANDOFF_CURRENT_STATE.md)
> y [`../docs/api/v1_watch_match_sessions.md`](../docs/api/v1_watch_match_sessions.md).

Base nativa en Kotlin + Compose for Wear OS con:
- prepartido,
- partido en vivo,
- eventos (`gol`, `asistencia`, `pausa/reanudar`),
- finalización y resumen,
- modo debug con `Simular 10 min`.

Incluye:
- `Room` para persistencia local,
- `FusedLocationProviderClient` para tracking,
- `SyncManager` stub para Data Layer/backend.

## Ejecutar
1. Abrir `fulbii_wearos/` en Android Studio.
2. Sincronizar Gradle.
3. Conectar reloj físico Wear OS con `adb` o usar emulador.
4. Ejecutar app module `app`.
