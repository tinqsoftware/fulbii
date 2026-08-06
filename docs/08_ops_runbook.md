# 08. Ops Runbook

> Complementar esta guía con [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Estado
- ✅ Readiness endpoint disponible.
- ✅ Runbook para cola/scheduler/push/links.
- ⏳ Falta completar monitoreo externo (opcional).

## 1) Cola acumulada
Verificación:
```sql
SELECT queue, COUNT(*) total FROM jobs GROUP BY queue;
```
Acción:
```bash
php artisan queue:restart
php artisan queue:work --queue=default,push --tries=3 --backoff=30,120,300
```

## 2) Fallos push
Verificación:
```sql
SELECT provider, status, COUNT(*) total
FROM push_dispatch_logs
GROUP BY provider, status;
```
Acción:
```bash
php artisan queue:retry all
```
Reporte rapido:
```bash
php artisan push:verification-report --minutes=240
```
Checklist de configuración:
- `PUSH_DRIVER=fcm`
- `FCM_PROJECT_ID` cargado
- `FCM_SERVICE_ACCOUNT_PATH` apunta a JSON legible por `www-data`
- Archivo service-account fuera del repo (ej: `/etc/fulbii/firebase-service-account.json`)
- `GET /api/v1/admin/ops/release-readiness` debe reportar `fcm_v1_ready=true`
- Script de verificación rápida: `scripts/staging/check_vps_env_for_push.sh`

## 3) Olas auto no disparan
Verificación:
```bash
php artisan pichangas:auto-reminders --dry-run
```

### Reparación de equipos históricos

Solo después de un respaldo verificable de la base destino:

```bash
php artisan pichangas:repair-team-assignments --force
```

Es idempotente y asigna equipo/slot únicamente a participaciones confirmadas
que no los tengan. Validar después que cada pichanga cumpla: confirmados = suma
de jugadores en sus equipos.
Acción:
- Confirmar cron de scheduler cada minuto.
- Confirmar `auto_reminder_*` en club/pichanga.

## 4) Links join no abren
Verificación:
- `GET /.well-known/apple-app-site-association`
- `GET /.well-known/assetlinks.json`

Acción:
- Revisar `APP_LINK_BASE_URL`
- Revisar `APP_LINK_IOS_APP_IDS`
- Revisar `APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS`

## 5) Orden de recuperación
1. Levantar worker.
2. Confirmar scheduler.
3. Validar readiness.
4. Hacer smoke de join/push/pichanga.
5. Ejecutar `scripts/staging/verify_push_pipeline.sh`.
