# Backoffice administrativo

Ruta web: `/admin`. Requiere sesión Laravel y perfil `superadmin` o
`staff_admin`; no forma parte de la experiencia de jugador.

## Módulos

| Ruta | Uso |
| --- | --- |
| `/admin` | Dashboard y señales operativas. |
| `/admin/reports` | Revisar/resolver reportes individuales o masivos. |
| `/admin/field-submissions` | Aprobar/rechazar aportes, fotos y lotes. |
| `/admin/strikes` | Emitir/revocar strikes y revisar suspensión. |
| `/admin/metrics/growth` | Métricas por rango. |
| `/admin/ops/readiness` | Colas, push, links y estado de release. |

## Operación

- Al resolver aportes, verificar que la notificación aprobada/rechazada se
  genera para el autor y que el enlace apunta a aporte/cancha/polideportivo.
- Priorizar reportes con contexto de mensaje, post o comentario: el panel no
  debe perder el `content_type`/`content_id` de la evidencia.
- Revisar grupos activos sin admin, retos sin coordinador, pichangas próximas,
  tokens activos/inactivos, jobs pendientes, `failed_jobs` y fallos FCM.
- Acciones masivas deben mostrar `processed`, `skipped` y `errors`; no asumir
  que todos los ítems cambiaron de estado.

## Permisos

- `superadmin`: acceso total, incluyendo suspensión manual.
- `staff_admin`: moderación, aportes, métricas y operación; sin permisos de
  suspensión ni revocación de restricciones críticas globales.

La API espejo usa `/api/v1/admin/*`. Ver
[moderación](api/v1_moderation.md) y [runbook](08_ops_runbook.md).
