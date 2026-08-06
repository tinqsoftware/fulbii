# 09. Verificacion Firebase Push (Paso a Paso)

> Guía de verificación vigente. Complementar con los pendientes de QA físico
> en [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Objetivo: validar con evidencia tecnica que el pipeline completo funciona:
Firebase -> Laravel queue -> `push_dispatch_logs` -> dispositivo.

## Estado esperado al terminar
- Token guardado en `user_devices`.
- Notificacion creada en `push_notifications`.
- Dispatch en `push_dispatch_logs` con `status=sent` y `provider=fcm_v1`.
- Push recibido en foreground/background/terminated.
- Mute por grupo respetado.

## Estado actual
- ⏳ QA challenge chat (4 estados) pendiente hasta completar prueba en físicos.

## Paso 0: Config minima en VPS
En `.env` de cloud:
```env
QUEUE_CONNECTION=database
PUSH_DRIVER=fcm
FCM_PROJECT_ID=<FIREBASE_PROJECT_ID>
FCM_SERVICE_ACCOUNT_PATH=/etc/fulbii/firebase-service-account.json
FCM_SCOPE=https://www.googleapis.com/auth/firebase.messaging
FCM_TOKEN_URI=https://oauth2.googleapis.com/token
```

Validar archivo service account:
```bash
ls -l /etc/fulbii/firebase-service-account.json
```

Aplicar config y reiniciar workers:
```bash
php artisan config:clear
php artisan cache:clear
php artisan queue:restart
php artisan queue:work --queue=default,push --tries=3 --backoff=30,120,300
```

## Paso 1: Readiness
Endpoint admin:
- `GET https://fulbii.com/api/v1/admin/ops/release-readiness`

Debe reportar:
- `queue_connection=database`
- `push_driver=fcm`
- `fcm_v1_ready=true`

## Paso 2: Verificar registro de token
1. Inicia sesion en app iOS fisico y Android fisico.
2. Acepta permisos de notificacion.
3. Ejecuta:
```sql
SELECT id, user_id, platform, is_active, device_token, last_seen_at, created_at
FROM user_devices
ORDER BY id DESC
LIMIT 20;
```

Esperado:
- Filas nuevas.
- `is_active=1`.
- `device_token` no vacio.

## Paso 3: Disparar evento real
Usa flujo normal:
- crear pichanga, o
- renotify manual desde pichanga.

Espera 5-20 segundos con worker activo.

## Paso 4: Evidencia en BD
```sql
SELECT id, user_id, club_id, group_pichanga_id, type, title, created_at
FROM push_notifications
ORDER BY id DESC
LIMIT 20;

SELECT id, push_notification_id, user_device_id, status, provider, error_message, sent_at, created_at
FROM push_dispatch_logs
ORDER BY id DESC
LIMIT 50;
```

Esperado:
- `status=sent`
- `provider=fcm_v1`
- `error_message` null.

## Paso 5: Recepcion en app (3 estados)
En iOS y Android:
1. Foreground.
2. Background.
3. App cerrada (terminated).

Nota:
- iOS simulador no es evidencia final para push productivo.

## Paso 6: Prueba de mute por grupo
1. Cambia preferencia del grupo a `mute_24h` o `mute_forever`.
2. Dispara notificacion del mismo grupo.
3. Verifica:
- usuario muteado no recibe push.
- usuario no muteado si recibe push.

## Paso 7: Diagnostico rapido
1. `fcm_v1_ready=false`: falta `FCM_PROJECT_ID` o `FCM_SERVICE_ACCOUNT_PATH`.
2. Hay `push_notifications` pero no `push_dispatch_logs`: worker push no corre.
3. `status=failed` + `401/403`: service account incorrecto.
4. Android sin push: SHA/package incorrectos en Firebase.
5. iOS sin push en TestFlight: falta APNs produccion en Firebase.

## Comandos de ayuda (ya incluidos en repo)
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
php artisan push:verification-report --minutes=240
scripts/staging/verify_push_pipeline.sh
```

Consultas SQL listas:
- `database/sql/push_verification_queries.sql`
