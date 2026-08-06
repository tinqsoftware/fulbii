# Hardening Final Backend (Seguridad + Rate-Limit + Auditoría)

> Auditoría de referencia; mantener las reglas de seguridad alineadas con las
> rutas vigentes y no incluir secretos. Ver
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Fecha de cierre técnico: 2026-03-20

## 1) Matriz de permisos admin

| Acción | `superadmin` | `staff_admin` |
|---|---:|---:|
| Ver panel `/admin/*` | ✅ | ✅ |
| Resolver reportes (single/bulk) | ✅ | ✅ |
| Decidir field submissions (single/bulk) | ✅ | ✅ |
| Emitir strike | ✅ | ✅ (con bloqueo a usuarios backoffice) |
| Revocar strike | ✅ | ✅ (bloqueado en strikes críticos/globales) |
| Suspensión manual de usuario | ✅ | ❌ |
| Auto-acción peligrosa (self strike/self suspension) | ❌ | ❌ |

Reglas críticas aplicadas:
- `staff_admin` no puede afectar cuentas backoffice en acciones sensibles.
- No se permite auto-acción en endpoints críticos (`422`).
- Las operaciones bulk deduplican `ids[]` y revalidan estado por ítem.

## 2) Rate-limit activo por endpoint

| Limiter | Umbral | Uso principal |
|---|---:|---|
| `social-auth-login` | `20/min` por `ip+provider` | `POST /api/v1/auth/social/login` |
| `report-create` | `12/min` por actor | creación de reportes |
| `field-submission-create` | `8/min` por actor | creación de solicitudes de cancha |
| `pichanga-sensitive` | `20/min` por actor | renotify/send, audience update, decisiones sensibles |
| `admin-mutations` | `30/min` por actor | mutaciones admin API |
| `admin-web-mutations` | `60/min` por actor | mutaciones admin web |

Respuesta estándar `429` (API JSON):

```json
{
  "message": "Límite alcanzado ...",
  "error": "rate_limited",
  "status": 429
}
```

## 3) Auditoría operativa en `product_events`

Se registra trazabilidad en acciones críticas de:
- Moderación admin single y bulk.
- Bloqueos de permisos (`admin_action_blocked` / `admin_web_action_blocked`).
- Suspensiones manuales.
- Eventos de auth social y mutaciones pichanga sensibles.

Campos mínimos de metadata:
- `actor_user_id` (como `user_id` del evento),
- `action`,
- conteos (`processed`, `skipped`, `errors`) cuando aplique,
- identificadores objetivo (`report_id`, `strike_id`, `submission_id`, `target_user_id`),
- `happened_at`.

## 4) Contrato bulk estandarizado

Para endpoints bulk API:

```json
{
  "processed": 10,
  "skipped": 3,
  "errors": 1,
  "skipped_items": [{"id": 25, "reason": "already_resolved"}],
  "error_items": [{"id": 30, "reason": "not_found"}]
}
```

## 5) Validación recomendada

```bash
php artisan test --stop-on-failure
php artisan route:list --path=admin
php artisan route:list --path=api/v1/admin
```

Pruebas de referencia:
- `tests/Feature/Api/AdminModerationBulkActionsTest.php`
- `tests/Feature/Api/RateLimitHardeningTest.php`

## 6) Troubleshooting rápido

- `403` inesperado en admin:
  - revisar perfil (`superadmin`/`staff_admin`) en `user_perfil`.
  - validar regla de bloqueo crítica (staff vs target backoffice/strike crítico).
- `429` frecuente:
  - verificar picos de operación por actor.
  - ajustar operativa del panel (lotes más pequeños).
- Falta de auditoría:
  - confirmar existencia de tabla `product_events`.
  - revisar `APP_ENV`, logs y excepciones silenciosas.
