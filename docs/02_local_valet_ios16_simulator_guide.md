# 02. Configurar Local `.test` + Simulador iPhone 16

> Guía operativa local. Para decisiones de funcionalidad, consultar
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Estado
- ✅ Valet y SSL local configurables para `fulbii.test`.
- ✅ Simulador iOS operativo con sesión Apple iniciada.
- ✅ iOS deployment target en 15.0.

## 1) Dominio local con Valet
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
valet link fulbii
valet secure fulbii
```

Validar en navegador:
- `https://fulbii.test`

## 2) `.env` local mínimo
```env
APP_ENV=local
APP_DEBUG=true
APP_URL=https://fulbii.test
APP_LINK_BASE_URL=https://fulbii.test

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=fulbii
DB_USERNAME=root
DB_PASSWORD=

QUEUE_CONNECTION=database
PUSH_DRIVER=log

SOCIAL_AUTH_TRUSTED_MODE=true
APPLE_CLIENT_ID=com.fulbii
```

Nota:
- Para validar tokens reales localmente, usa `SOCIAL_AUTH_TRUSTED_MODE=false` y completa `GOOGLE_CLIENT_ID`.

## 3) Procesos backend para pruebas
Terminal 1:
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/run_queue_worker.sh
```

Terminal 2:
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/run_scheduler_worker.sh
```

## 4) Ejecutar app en iOS simulator (local backend)
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2/fulbii_app"
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=https://fulbii.test/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.test
```

## 5) Deep links (smoke)
```bash
xcrun simctl openurl booted "fulbii://join/ABC123DEF456"
xcrun simctl openurl booted "https://fulbii.test/join/ABC123DEF456"
```

## 6) Checks de salud
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/check_local_readiness.sh
scripts/local/check_google_apple_firebase_setup.sh
```
