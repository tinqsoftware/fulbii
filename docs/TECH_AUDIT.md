# Fulbii 2 - Technical Audit

## Arquitectura
- Monorepo con backend Laravel + frontend móvil Flutter + módulos wearable.
- Contratos API v1 bien documentados por dominio.

## Stack y BD
- Backend: Laravel 10, PHP 8.1, Sanctum, Vite 5.
- Mobile: Flutter SDK 3.10.x.
- Wearables: integración watchOS/Wear OS.
- BD MySQL/MariaDB con tablas específicas de tracking y pichangas.

## Integraciones
- Push notifications.
- Deep links/universal links.
- Sync watch hacia backend (batch endpoints).

## Hallazgos
- Fortaleza: documentación operativa extensa y técnica madura.
- Fortaleza: cobertura funcional integral en app y backend.
- Fortaleza: contratos de grupos y pichangas separan estados públicos,
  membresía activa, permisos y datos de presentación calculados.
- Fortaleza: asignación transaccional de equipo/slot evita que el contador de
  confirmados diverja del tablero de equipos.
- Deuda: pendiente cierre de QA físico E2E para flujo watch completo.

## Riesgos técnicos
- Sin validación física completa de watch sync, pueden persistir inconsistencias de sesión/eventos.
- La documentación histórica usa una escala anterior; la escala técnica vigente
  es 0.0–5.0. Ver [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).
