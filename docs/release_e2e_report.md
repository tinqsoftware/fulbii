# Release E2E Report (Bloque Operación + QA)

> **Histórico / snapshot de release.** No usar como estado actual; ver
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md) y
> [STATUS_GAPS](STATUS_GAPS.md).

## Resultado de validación automatizada
- `php artisan test --testsuite=Unit`: **PASS**
- `php artisan test --testsuite=Feature`: **PASS** (incluye join flow, auto-reminders, métricas/readiness)
- `flutter test`: **PASS**
- `flutter analyze`: **PASS** (sin issues)
- `php artisan pichangas:auto-reminders --dry-run`: **PASS**

## Cobertura funcional validada en este bloque
- Join request:
  - crear por link
  - cancelar solicitud pendiente
  - aceptar por admin y alta en membresía
- Auto-reminders:
  - ejecución 24h
  - idempotencia (doble corrida no duplica batch)
  - exclusión de confirmados
  - respeto de mute por grupo
- Métricas/ops:
  - `GET /api/v1/admin/metrics/growth`
  - `GET /api/v1/admin/ops/release-readiness`
- App/Universal links:
  - `GET /.well-known/apple-app-site-association`
  - `GET /.well-known/assetlinks.json`

## Pendiente manual (QA físico)
- Demo E2E en 2 móviles (Android + iPhone):
  - deep link abierto con app cerrada
  - push foreground/background/terminated
  - confirmación visual de olas 48h/24h en detalle pichanga

## Estado de cierre
- Bloque **casi cerrado** técnicamente.
- Falta cierre operativo final con evidencia QA físico (checklist en `docs/06_release_e2e_checklist.md`).
