# Verificación Firebase Push

## Condiciones mínimas

```env
QUEUE_CONNECTION=database
PUSH_DRIVER=fcm
FCM_PROJECT_ID=<firebase-project-id>
FCM_SERVICE_ACCOUNT_PATH=/ruta/absoluta/firebase-service-account.json
```

El JSON debe ser válido, corresponder al mismo proyecto Firebase que la app y
ser legible por `www-data`. No es suficiente que `fcm_v1_ready=true`: también
debe existir worker y token de dispositivo activo.

## Prueba completa

1. En dos dispositivos físicos, iniciar sesión y aceptar notificaciones.
2. Revisar tokens:
   ```sql
   SELECT user_id, platform, is_active, last_seen_at
   FROM user_devices ORDER BY id DESC LIMIT 20;
   ```
3. Crear una pichanga desde la Cuenta A o enviar un mensaje de reto/grupo.
4. Conservar el worker activo; esperar hasta 20 segundos.
5. Ejecutar:
   ```bash
   php artisan push:verification-report --minutes=30
   ```
6. Confirmar bandeja, alerta nativa y deep link en Cuenta B.
7. Repetir con app abierta, background y cerrada en iOS/Android.

## Evidencia de base

```sql
SELECT id, user_id, type, title, created_at
FROM push_notifications ORDER BY id DESC LIMIT 20;

SELECT id, push_notification_id, user_device_id, provider, status, error_message, sent_at
FROM push_dispatch_logs ORDER BY id DESC LIMIT 50;
```

El resultado sano usa `provider=fcm_v1`, `status=sent` y `error_message` nulo.
Una fila de bandeja sin dispatch normalmente indica que la cola `push` no está
siendo consumida.

## iOS

- El simulador no prueba push productivo.
- Firebase debe tener APNs de producción configurado para TestFlight.
- La extensión `FulbiiNotificationService` descarga la imagen cuando el payload
  la incluye; si falla, la alerta de texto debe llegar igualmente.

## Android

- Validar `google-services.json`, package `com.fulbii.fulbii_app` y firma SHA
  de la build distribuida.
- Confirmar permiso de notificaciones en Android 13+.
- Las imágenes ricas iOS no son requisito para que el payload estándar llegue.

## Recuperación

```bash
php artisan optimize:clear
sudo systemctl restart fulbii-queue
systemctl status fulbii-queue
php artisan push:verification-report --minutes=30
```

Si el error indica cuenta de servicio ilegible, corregir archivo/propietario y
reiniciar el worker; no regenerar tokens de usuarios como primera medida.
