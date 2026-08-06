# Fulbii 2 - Status & Gaps

## Estado actual
- Backend Laravel y app Flutter cubren los flujos núcleo de canchas, grupos,
  pichangas, perfil deportivo, notificaciones y wearables.
- La escala vigente de calificaciones es 0.0–5.0; los equipos de pichanga se
  asignan de forma persistente a cada confirmación.

## Qué falta
- P0:
  - Cierre de QA físico E2E para watch sync, notificaciones y deep links.
  - QA visual iPhone del detalle de pichanga (notch, tabs fijas, CTA y retorno
    desde detalle de polideportivo).
- P1:
  - Ejecutar `pichangas:repair-team-assignments --force` en staging/producción
    con respaldo y validar que total de confirmados = suma de equipos.
  - Hardening de observabilidad operativa en producción.
- P2:
  - Iteración UX/UI de detalles de sincronización y estados.

## Riesgos
- La deuda principal está en validación operativa final, no en falta de funcionalidad núcleo.
- Documentos previos que describen una escala anterior son históricos; ver
  [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).
