# API v1 - Moderation and Safety

> Contrato operativo verificado contra rutas API v1. Contexto de producto y
> estado de módulos: [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## User-side
- `GET /api/v1/reports/mine`
- `POST /api/v1/reports`
- `GET /api/v1/field-submissions/mine`
- `POST /api/v1/field-submissions`

### Create report body
```json
{
  "target_type": "user",
  "target_id": 12,
  "reason_code": "toxic_behavior",
  "description": "Insultos reiterados"
}
```

`target_type`: `user|field|field_photo|group_pichanga`

### Create field submission body
```json
{
  "nombre": "Cancha Sur 1",
  "direccion": "Av. X 123",
  "x": "-12.10",
  "y": "-77.01",
  "celular": "999123123",
  "wsp": true,
  "id_distrito": 5,
  "descripcion": "Grass sintético",
  "precio_desde": "80",
  "source_type": "gps",
  "photos": [
    "https://.../foto1.jpg",
    "https://.../foto2.jpg"
  ]
}
```

## Superadmin-side
All under `/api/v1/admin/*`

- `GET /admin/reports`
- `POST /admin/reports/{report}/resolve`
- `POST /admin/reports/bulk-resolve`
- `GET /admin/strikes`
- `POST /admin/strikes`
- `POST /admin/strikes/{strike}/revoke`
- `POST /admin/strikes/bulk-revoke`
- `POST /admin/users/{user}/suspension`
- `GET /admin/field-submissions`
- `POST /admin/field-submissions/{submission}/decision`
- `POST /admin/field-submissions/{submission}/photos/{photo}/remove`
- `POST /admin/field-submissions/bulk-decision`
- `GET /admin/metrics/growth?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /admin/ops/release-readiness`

### release-readiness response (campos clave)
- `queue_connection`
- `jobs_pending`
- `failed_jobs_count`
- `auto_reminder_command_available`
- `last_auto_wave_at`
- `product_events_enabled`
- `push_driver`
- `app_link_base_url`
- `well_known_endpoints_ok`

### Issue strike body
```json
{
  "user_id": 12,
  "report_id": 55,
  "reason_code": "harassment",
  "description": "Comportamiento agresivo",
  "expires_days": 90
}
```

### Auto policy
- 3 strikes activos => suspensión automática (`users.suspended_until`) por `MODERATION_AUTO_SUSPEND_DAYS`.
- Se aplica middleware `user.not_suspended` en rutas autenticadas (excepto logout).

### Staff policy
- `staff_admin` puede operar moderación y leer métricas/ops.
- `staff_admin` no puede suspender usuarios.
- `staff_admin` no puede revocar strikes críticos globales (sin `report_id` y `reason_code` bloqueado por config).
