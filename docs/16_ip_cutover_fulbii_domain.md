# 16. Cutover por cambio de IP (manteniendo `fulbii.com`)

> **Histórico / de operación puntual.** Mantener como evidencia de cutover;
> para operación actual usar [08_ops_runbook](08_ops_runbook.md) y
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Objetivo: mover backend a un VPS nuevo sin romper iOS/Android/Watch/Widgets/Deep Links/Push.

Decisión de arquitectura: **mantener dominio** (`fulbii.com`), no usar IP directa en la app.

IP objetivo actual: `31.97.86.237`.

## 1) DNS y TLS (infra)
1. Cambia el registro `A` de `fulbii.com` a `31.97.86.237` (TTL bajo durante el corte).
2. En el VPS nuevo, usa `server_name fulbii.com` con:
   - `deploy/nginx/fulbii.com.conf`
3. Emite/instala SSL válido para `fulbii.com` (Let's Encrypt o equivalente).
4. Verifica que puertos `80/443` estén abiertos.

## 2) Backend Laravel en VPS nuevo
1. Crea `.env` productivo desde:
   - `deploy/env/fulbii.com.vps.env.example`
2. Llaves críticas:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - `APP_URL=https://fulbii.com`
   - `APP_LINK_BASE_URL=https://fulbii.com`
   - `PUSH_DRIVER=fcm`
   - `FCM_PROJECT_ID=...`
   - `FCM_SERVICE_ACCOUNT_PATH=...`
   - `GOOGLE_CLIENT_ID=...`
   - `APPLE_CLIENT_ID=...`
3. Limpia cache y reinicia colas:
```bash
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan queue:restart
```
4. Levanta worker/scheduler (incluyendo cola `push`):
```bash
php artisan queue:work --queue=default,push --tries=3 --backoff=30,120,300
```

### Notas críticas vistas en migración real
- Si `php artisan ...` falla con `vendor/autoload.php not found`, primero debes instalar dependencias (`composer install`).
- Si `composer install` falla por `ext-dom`, instala la extensión XML/DOM de tu versión PHP (ej. `php8.x-xml`) y reinicia PHP-FPM.
- Verifica que estás en la ruta correcta del release (`/var/www/fulbii` o `/var/www/fulbii/current`) antes de correr artisan.
- Si ejecutas Composer como root, define `COMPOSER_ALLOW_SUPERUSER=1` o usa usuario deploy (`www-data`) para evitar bloqueos/plugins deshabilitados.
- Si existía `fulbii-queue.service`, debes recrear/habilitar la unidad en el nuevo VPS (`systemctl enable --now fulbii-queue.service`).

## 3) App móvil/watch/widgets (sin cambio de IP)
- No cambies base URL a IP en cliente.
- Mantener:
  - API: `https://fulbii.com/api/v1`
  - App Links: `https://fulbii.com`
  - iOS Associated Domains: `applinks:fulbii.com`
  - Android intent filters host `fulbii.com`

Con esto no necesitas recompilar solo por cambio de IP si DNS + TLS están correctos.

## 4) Validación post-cutover (un comando)
Script nuevo:
```bash
scripts/staging/smoke_post_ip_cutover.sh
```

Ejemplo mínimo:
```bash
BASE_URL=https://fulbii.com EXPECTED_IP=31.97.86.237 scripts/staging/smoke_post_ip_cutover.sh
```

Con token de usuario (validar endpoints watch):
```bash
BASE_URL=https://fulbii.com \
EXPECTED_IP=31.97.86.237 \
WATCH_BEARER_TOKEN="<token_sanctum>" \
WATCH_PICHANGA_ID=20 \
scripts/staging/smoke_post_ip_cutover.sh
```

Con token admin (validar readiness):
```bash
BASE_URL=https://fulbii.com \
ADMIN_BEARER_TOKEN="<token_admin>" \
scripts/staging/smoke_post_ip_cutover.sh
```

## 5) Comandos de ejecución recomendados para Flutter (cloud)
```bash
cd fulbii_app
flutter run \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

## 6) Criterio de éxito
- `dig` resuelve `fulbii.com` al IP nuevo.
- `.well-known` responde 200.
- App iPhone/Android login OK.
- Watch sincroniza `home-feed`.
- Push FCM/APNs vuelve a enviar en entorno nuevo.
