# Watch Tracking v1.2 (especificación vigente)

> Complementar con [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md) y
> validar en dispositivo físico antes de cambios de tracking.

## Objetivo
Medir distancia útil para fútbol y construir heatmap estable en watch físico, minimizando jitter cuando el usuario está quieto.

## Entradas por muestra
- `lat`, `lng`
- `horizontal_accuracy` (m)
- `speed` (m/s) cuando venga del sensor
- `timestamp` real de `CLLocation`

## Salidas por muestra
- `quality_flag`: `good` | `weak` | `rejected`
- `delta_meters_raw`
- `delta_meters_filtered`
- `is_movement_detected`

## Parámetros actuales (en código)
- `maxAccuracyMeters = 60.0`
- `maxFootballSpeedMetersPerSecond = 11.0`
- `stationaryDistanceThreshold = 1.7`
- `stationarySpeedThreshold = 0.45`
- `movementDistanceThreshold = 1.2`
- `movementSpeedThreshold = 0.35`
- `emaAlpha = 0.35`
- `minRequiredSamplesForMovement = 1`

## Reglas principales
1. Rechazo:
   - accuracy inválida o > `maxAccuracyMeters`,
   - timestamp no creciente,
   - velocidad implícita (`distancia/dt`) imposible para fútbol.
2. Quieto:
   - distancia corta + EMA de velocidad baja => no suma filtered (`weak`).
3. Movimiento:
   - distancia + EMA superan umbral => suma filtered (`good`).
4. Distancia de producto:
   - prioriza `distance_meters_filtered`.
   - fallback a `raw` solo si filtered queda casi en 0 y raw es significativa.

## Uso en UI y backend
- UI watch/iPhone muestra la distancia final de producto (filtered con fallback controlado).
- Persistencia manda:
  - `distance_meters_raw`
  - `distance_meters_filtered`
  - `quality_flag` por sample.
- Heatmap usa puntos no `rejected` (`good` y `weak`).

## Nota de tuning
Esta versión está ajustada para pruebas físicas Series 3.  
Si se vuelve a modificar sensibilidad, actualizar este documento junto con los valores en código.
