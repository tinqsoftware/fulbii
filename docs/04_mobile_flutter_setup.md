# 04. Setup Flutter (Android + iOS)

> Guía de entorno. El alcance funcional vigente está en
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Ruta app: `fulbii_app/`

## Estado
- ✅ Estructura Flutter y módulos principales disponibles.
- ✅ iOS simulator compila.
- ✅ Apple login iOS simulator operativo.
- ✅ Google Maps iOS simulator operativo.
- ✅ IDs OAuth Google definidos y Info.plist actualizado.
- ✅ Google login validado E2E contra cloud.
- ⏳ Push real pendiente de FCM/APNs completos.

## Referencias
- `docs/02_local_valet_ios16_simulator_guide.md`
- `docs/03_social_auth_push_setup_detailed.md`
- `docs/06_release_e2e_checklist.md`
- `docs/07_internal_release_handoff.md`

## 1) Dependencias
```bash
cd fulbii_app
flutter pub get
```

## 2) Run local (`fulbii.test`)
```bash
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=https://fulbii.test/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.test
```

## 3) Run cloud (`fulbii.com`)
```bash
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>
```

## 4) Configs nativas críticas
### iOS
- `Info.plist`: `GIDClientID`, `GIDServerClientID`, URL scheme reversed de Google.
- Capabilities: Sign in with Apple, Push Notifications, Associated Domains.

### Android
- `google-services.json` con package `com.fulbii.fulbii_app`.
- SHA-1/SHA-256 registrados en Google/Firebase.

## 5) Deep links
- `fulbii://join/{JOIN_CODE}`
- `https://fulbii.test/join/{JOIN_CODE}`
- `https://fulbii.com/join/{JOIN_CODE}`

## 6) Build interno
### Android
```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

### iOS
- Xcode -> Archive -> Distribute App -> TestFlight.

## 7) Android mapas (evitar pantalla vacia)
Si Android muestra mapa beige o sin tiles:
1. Verifica que el emulador sea `Google Play` image (no AOSP).
2. Verifica que `GOOGLE_MAPS_API_KEY` exista en `fulbii_app/android/local.properties`.
3. En Google Cloud, la key Android debe estar restringida a:
   - package: `com.fulbii.fulbii_app`
   - SHA-1 correcto del keystore activo (debug/release).
4. Si cambiaste huellas, vuelve a descargar `google-services.json` y reemplaza.

Para imprimir huellas actuales:
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/print_android_fingerprints.sh
```

## 8) Fulbii Watch MVP (nativo)

### watchOS (SwiftUI)
- Código fuente: `fulbii_watchos/`.
- Guía rápida: `fulbii_watchos/README.md`.

### Wear OS (Kotlin + Compose)
- Código fuente: `fulbii_wearos/`.
- Guía rápida: `fulbii_wearos/README.md`.
