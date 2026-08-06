# 05. Deploy VPS Nativo (Nginx + PHP-FPM + MySQL + Supervisor)

> Para cambios de datos de pichangas, revisar primero
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Post-deploy de equipos históricos

Después de respaldo y smoke de API, si existen confirmaciones antiguas sin
equipo, ejecutar una vez:

```bash
php artisan pichangas:repair-team-assignments --force
```

No ejecutar `ratings:reset --force` como parte del deploy normal.

Objetivo: levantar backend cloud en `https://fulbii.com`.

## Estado
- ✅ Plantillas de Nginx/Supervisor/cron/systemd disponibles en `deploy/`.
- ✅ Template de `.env` productivo agregado en `deploy/env/fulbii.com.vps.env.example`.
- ⏳ Pendiente completar secretos reales en `.env` del VPS.
- ⏳ Pendiente smoke final cloud + readiness estable.

## 1) Stack
- Ubuntu 22.04+
- Nginx
- PHP 8.2 + extensiones Laravel
- MySQL
- Supervisor
- Certbot

## 2) `.env` productivo (cloud)
1. Copia el template:
```bash
cp deploy/env/fulbii.com.vps.env.example .env
```
2. Completa solo los valores reales:
- `APP_KEY`
- `DB_USERNAME`
- `DB_PASSWORD`
- `GOOGLE_CLIENT_ID`
- `APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS`
3. Verifica llaves críticas:
- `APP_ENV=production`
- `APP_DEBUG=false`
- `PUSH_DRIVER=fcm`
- `FCM_PROJECT_ID=fulbii`
- `FCM_SERVICE_ACCOUNT_PATH=/etc/fulbii/firebase-service-account.json`
- `APPLE_CLIENT_ID=com.fulbii`

## 3) Operación
- Worker: `php artisan queue:work --queue=default,push --tries=3 --backoff=30,120,300`
- Scheduler: `php artisan schedule:run` cada minuto por cron.
- Verificación de `.env` VPS: `scripts/staging/check_vps_env_for_push.sh`

## 3.1) Service account FCM v1 (obligatorio)
1. En Firebase > Configuración del proyecto > Cuentas de servicio > `Generar nueva clave privada`.
2. Subir el JSON al VPS en `/etc/fulbii/firebase-service-account.json`.
3. Permisos seguros:
```bash
sudo chown www-data:www-data /etc/fulbii/firebase-service-account.json
sudo chmod 600 /etc/fulbii/firebase-service-account.json
```

## 3.2) APNs producción para TestFlight/App Store (obligatorio)
En Firebase > Cloud Messaging > app iOS `com.fulbii`:
- Mantener APNs de desarrollo.
- Subir también APNs de producción.
Sin APNs de producción, push no llegará en TestFlight.

## 4) Endpoints a validar
- `GET /api/v1/admin/ops/release-readiness`
- `GET /.well-known/apple-app-site-association`
- `GET /.well-known/assetlinks.json`

## 5) Referencias
- `deploy/nginx/fulbii.com.conf`
- `deploy/supervisor/fulbii-worker.conf`
- `deploy/cron/fulbii-scheduler.cron`
- `deploy/env/fulbii.com.vps.env.example`
- `docs/16_ip_cutover_fulbii_domain.md`
- `docs/06_release_e2e_checklist.md`
- `docs/08_ops_runbook.md`
