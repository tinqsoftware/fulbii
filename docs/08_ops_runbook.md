# Operación Fulbii en VPS

## Worker de cola

El servicio requerido es `fulbii-queue.service`; debe escuchar ambas colas.

```ini
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/fulbii/artisan queue:work database --queue=push,default --sleep=3 --tries=3 --backoff=30 --timeout=120
```

Después de modificarlo:

```bash
sudo systemctl daemon-reload
sudo systemctl restart fulbii-queue
systemctl status fulbii-queue
journalctl -u fulbii-queue -n 100 --no-pager
```

No detener el worker manual con `Ctrl+C` como solución permanente: al hacerlo,
la bandeja seguirá creándose, pero el push no se enviará.

## Diagnóstico push

```bash
cd /var/www/fulbii
php artisan push:verification-report --minutes=30
php artisan queue:monitor push default
```

Esperado: `push_driver=fcm`, `fcm_v1_ready=true`, tokens activos y dispatches
`sent`. Si hay notificaciones en la bandeja pero no alertas nativas, revisar
primero que `fulbii-queue` está activo y luego los últimos errores de
`push_dispatch_logs`.

La cuenta de servicio debe estar fuera de Git, legible por el proceso PHP:

```bash
sudo chown www-data:www-data <ruta-configurada-en-FCM_SERVICE_ACCOUNT_PATH>
sudo chmod 640 <ruta-configurada-en-FCM_SERVICE_ACCOUNT_PATH>
```

Después de reemplazar el JSON, ejecutar `php artisan optimize:clear` y
reiniciar `fulbii-queue`. Nunca pegar `private_key` o `private_key_id` en el
chat, repo o `.env`; el JSON completo es el secreto.

## Incidentes comunes

| Síntoma | Causa probable | Acción |
| --- | --- | --- |
| Bandeja sí, push no | Worker detenido | Reiniciar `fulbii-queue`. |
| `No se pudo obtener access token de FCM v1` | JSON ilegible/incorrecto | Revisar path, dueño, permisos y JSON. |
| iOS TestFlight no recibe | APNs producción/Firebase | Revisar key APNs, bundle, capability Push y build físico. |
| Android no abre link | Asset Links o firma | Revisar package y SHA-256 release. |
| Jobs acumulados | Worker/DB | Revisar `jobs`, logs y reiniciar worker. |

## Migraciones heredadas

No usar `php artisan migrate --force` global mientras `migrate:status` muestre
las migraciones antiguas Pending pero sus tablas ya existan. Respaldar y correr
la migración nueva por `--path`; la normalización del historial es una tarea
separada y debe ensayarse antes en una copia de producción.

## Comprobaciones periódicas

- `GET /api/v1/admin/ops/release-readiness` con cuenta staff autorizada.
- Backoffice: reportes pendientes, aportes, grupos sin admin, retos y push.
- `failed_jobs`, `jobs`, `push_dispatch_logs` y tokens inactivos.
- QA físico de una alerta por release.
