# 06. Release E2E Checklist

> Checklist vigente complementario al relevo:
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Pichangas y grupos (añadir al smoke)

- [ ] Mis grupos y Descubrir grupos no tienen clubes superpuestos.
- [ ] La pichanga muestra cancha/polideportivo correctos y abre su detalle.
- [ ] Confirmados globales coinciden con la suma de equipos.
- [ ] En iPhone: hero colapsa, tabs quedan visibles bajo el notch y volver
  retorna a la pantalla previa.

## Estado
- ✅ Feature/Unit tests backend en verde (18 tests, 133 asserts).
- ✅ Flujo de join/pichanga/olas implementado.
- ✅ Apple login cloud OK (iOS simulator).
- ✅ Setup Google OAuth + Info.plist completado.
- ✅ Google login cloud OK (iOS/Android).
- ✅ Backend push migrado a FCM HTTP v1.
- ✅ `flutter analyze` sin issues.
- ✅ `flutter test` en verde.
- ⏳ Falta QA físico final (Android + iPhone).

## Referencias
- `docs/02_local_valet_ios16_simulator_guide.md`
- `docs/05_vps_native_staging_deploy.md`
- `docs/07_internal_release_handoff.md`
- `docs/09_firebase_push_verification_step_by_step.md`

## 1) Precondiciones
- `QUEUE_CONNECTION=database`
- `PUSH_DRIVER=fcm`
- `FCM_PROJECT_ID=<FIREBASE_PROJECT_ID>`
- `FCM_SERVICE_ACCOUNT_PATH=/etc/fulbii/firebase-service-account.json`
- `SOCIAL_AUTH_TRUSTED_MODE=false` (staging)
- `APP_LINK_BASE_URL=https://fulbii.com`
- `APP_LINK_IOS_APP_IDS=<TEAM_ID>.com.fulbii`
- `APP_LINK_ANDROID_PACKAGE_NAME=com.fulbii.fulbii_app`
- `APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS=<SHA256_RELEASE>`

Chequeo local recomendado antes de subir builds:
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/check_internal_release_readiness.sh
scripts/staging/check_vps_env_for_push.sh
```

## 2) Smoke backend
```bash
php artisan pichangas:auto-reminders --dry-run
php artisan route:list --path=api/v1/admin/ops/release-readiness
```

Validar:
- `GET /api/v1/admin/ops/release-readiness`
- `GET /.well-known/apple-app-site-association`
- `GET /.well-known/assetlinks.json`

Si el mapa movil muestra `0/0 con coordenadas validas`, ejecutar seed de QA:
```bash
mysql -u <USER> -p <DB_NAME> < database/sql/fulbii_seed_demo_fields.sql
```

## 3) QA móvil E2E
1. Deep link join abre app.
2. Login social completo.
3. Join request + aprobación admin.
4. Push foreground/background/terminated.
5. Olas auto 48h/24h visibles y auditadas.
6. Push verificado con evidencia DB (`push_notifications` + `push_dispatch_logs`).

## 4) Build interno
### Android
```bash
cd fulbii_app
flutter build appbundle --release \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

### iOS
- Xcode -> Archive -> Distribute App -> TestFlight Internal Testing.

## 5) Go/No-Go
Go solo si:
- login social cloud OK,
- readiness OK,
- push OK en 2 físicos,
- sin errores críticos en flujo de negocio principal.
