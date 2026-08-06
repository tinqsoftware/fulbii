# Backoffice Admin Panel (Web)

> Referencia de operación administrativa. Estado transversal y brechas:
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Ruta base: `/admin` (requiere sesión Laravel + perfil `superadmin` o `staff_admin`).

## Módulos
- `/admin` dashboard operativo.
- `/admin/reports` moderación de reportes + resolución masiva.
- `/admin/field-submissions` aprobación/rechazo de canchas + acción masiva.
- `/admin/strikes` gestión de strikes + revocación masiva.
- `/admin/metrics/growth` reporte growth por rango.
- `/admin/ops/readiness` estado operativo (colas, olas, links, push).

## Permisos
- `superadmin`: acceso total.
- `staff_admin`: moderación + métricas + ops.
- Solo `superadmin` puede usar suspensión manual de usuarios.

## Acciones masivas (API)
- `POST /api/v1/admin/reports/bulk-resolve`
- `POST /api/v1/admin/field-submissions/bulk-decision`
- `POST /api/v1/admin/strikes/bulk-revoke`

Respuesta estándar bulk:
- `processed`: total procesado.
- `skipped`: items omitidos por estado/regla.
- `errors`: items con error o no encontrados.
