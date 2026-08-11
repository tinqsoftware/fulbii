# Release E2E checklist

> Usar junto a [QA móvil](QA_MOBILE_RECENT_CHANGES.md) y
> [operación](08_ops_runbook.md). No declarar release listo sin push físico.

## 1. Antes de crear builds

- [ ] `git status` limpio salvo archivos locales excluidos.
- [ ] `php artisan test` relevante y `flutter analyze`/`flutter test` verdes.
- [ ] `git diff --check` sin salida.
- [ ] Version/build aumentados en `fulbii_app/pubspec.yaml`.
- [ ] URLs productivas configuradas: `API_BASE_URL`, `APP_LINK_BASE_URL`,
  `IOS_STORE_URL` y `ANDROID_STORE_URL` cuando estén disponibles.
- [ ] iOS: `FulbiiNotificationService` con bundle id
  `com.fulbii.FulbiiNotificationService`, firma válida y pods instalados.

## 2. Backend/VPS

- [ ] `php artisan optimize:clear` tras desplegar código.
- [ ] `sudo systemctl restart fulbii-queue` y `systemctl status fulbii-queue`.
- [ ] `php artisan push:verification-report --minutes=30` muestra FCM listo,
  tokens activos y sin fallo nuevo.
- [ ] `.env`: `QUEUE_CONNECTION=database`, `PUSH_DRIVER=fcm`,
  `FCM_PROJECT_ID` y `FCM_SERVICE_ACCOUNT_PATH` absoluto y válido.
- [ ] No se subió ninguna cuenta de servicio, `.env`, token o log al repo.

### Migraciones

El VPS actual contiene tablas heredadas no registradas en `migrations`. Por
eso no ejecutar `php artisan migrate --force` global. Para cada archivo nuevo:

```bash
php artisan migrate:status
php artisan migrate --force --path=database/migrations/AAAA_MM_DD_NNNNNN_nombre.php
php artisan migrate:status
```

Respaldar la base antes. Solo adoptar migración global después de normalizar el
baseline en staging y producción.

## 3. Smoke por plataforma

- [ ] Inicio de sesión y registro de token en iOS/Android.
- [ ] Deep links `/join`, `/club`, `/pichanga` desde navegador y notificación.
- [ ] Crear pichanga, confirmar y lista de espera con dos cuentas.
- [ ] Crear reto y enviar chat.
- [ ] Aprobar/rechazar aporte y ver notificación.
- [ ] Crear solicitud/invitación de grupo y resolverla como admin.
- [ ] Publicar y calificar con permisos válidos.
- [ ] iOS: app foreground, background y terminada; validar imagen rica si la
  notificación tiene URL de imagen.
- [ ] Android: mismo flujo de push y navegación, con fallback estándar.

## 4. Distribución

### iOS/TestFlight

1. Desde `fulbii_app/ios`, ejecutar `pod install` si cambió `Podfile.lock`.
2. Abrir `Runner.xcworkspace`, Archive y validar la app.
3. Subir con un build nuevo, esperar procesamiento y asignar testers.
4. Probar un push productivo desde TestFlight antes de ampliar audiencia.

### Android/Google Play

```bash
cd fulbii_app
flutter build appbundle --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

Subir primero a Internal Testing y probar deep links/push en un dispositivo.

## 5. Go / No-Go

Solo publicar si no hay bloqueadores en flujos de negocio, worker/push están
activos y la evidencia de ambos dispositivos queda registrada.
