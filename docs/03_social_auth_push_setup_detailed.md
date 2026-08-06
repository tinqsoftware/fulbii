# 03. Configurar Google Login + Apple Login + Firebase Push

> Guía operativa; mantener valores sensibles solo en variables de entorno.
> Ver [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Fecha: 2026-03-24

## Estado actual
- ✅ Bundle iOS real: `com.fulbii`.
- ✅ Xcode con capabilities: Sign in with Apple, Push Notifications, Associated Domains.
- ✅ Simulador iOS con sesión Apple.
- ✅ Apple login operativo en iOS simulator.
- ✅ Google Maps operativo en iOS simulator.
- ✅ OAuth Google creados (iOS/Web/Android).
- ✅ Info.plist iOS actualizado con `GIDClientID`, `GIDServerClientID`, y reversed scheme.
- ✅ Backend VPS actualizado con `GOOGLE_CLIENT_ID` y modo verificado (reportado por usuario).
- ⏳ Firebase/APNs productivo pendiente de cierre para push real.
- ✅ `google-services.json` actualizado para `com.fulbii.fulbii_app`.
- ✅ Login Google validado E2E contra `https://fulbii.com/api/v1`.
- ✅ Backend push migrado a FCM HTTP v1 (pendiente configurar secretos en VPS).

## IDs oficiales del proyecto
- iOS bundle id: `com.fulbii`
- Android package: `com.fulbii.fulbii_app`
- Dominio local: `fulbii.test`
- Dominio cloud/staging: `fulbii.com`

## A) Apple Login (cerrado en iOS simulator)

### A.1 Apple Developer > App ID
En `Certificates, Identifiers & Profiles` para `com.fulbii`:
1. `Sign in with Apple` = ON.
2. En la configuración de Sign in with Apple: elegir `Enable as a primary App ID` y guardar.
3. `Server-to-Server Notification Endpoint`: dejar vacío por ahora.

### A.2 APNs
- En la sección de Push Notifications del App ID, que aparezca `Certificates (0)` no bloquea este flujo.
- Para push productivo usar APNs Auth Key `.p8` (recomendado) en Firebase.

### A.3 Backend (requerido)
Configurar en cloud y local según corresponda:
```env
APPLE_CLIENT_ID=com.fulbii
```
Y aplicar:
```bash
php artisan config:clear
php artisan cache:clear
```

Estado:
- ✅ Login Apple devuelve `access_token`.
- ✅ Usuario se crea/actualiza en backend cloud.

## B) Google Login

### B.1 Google Cloud OAuth Clients
Crear/confirmar:
1. OAuth iOS para `com.fulbii`.
2. OAuth Android para `com.fulbii.fulbii_app` + SHA-1/SHA-256.
3. OAuth Web (server client).

Guardar:
- `IOS_CLIENT_ID`
- `IOS_REVERSED_CLIENT_ID`
- `WEB_CLIENT_ID`

Estado:
- ✅ Creados en Google Cloud.

### B.2 iOS Info.plist
Archivo: `fulbii_app/ios/Runner/Info.plist`

Reemplazar placeholders:
1. `GIDClientID` = `IOS_CLIENT_ID`
2. `GIDServerClientID` = `WEB_CLIENT_ID`
3. URL Scheme de Google = `IOS_REVERSED_CLIENT_ID`

Estado:
- ✅ Actualizado (sin placeholders `REPLACE_WITH_*`).

### B.3 Backend
```env
GOOGLE_CLIENT_ID=<WEB_CLIENT_ID>
SOCIAL_AUTH_TRUSTED_MODE=false
```

Estado:
- ✅ Aplicado en VPS (reportado por usuario).

### B.4 Flutter run de validación (iOS contra cloud)
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2/fulbii_app"
flutter clean
flutter pub get
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>
```

### B.5 Checklist de salida Google
1. `Info.plist` ya no tiene `REPLACE_WITH_*`.
2. `GOOGLE_WEB_CLIENT_ID` se pasa en `flutter run`.
3. `GOOGLE_CLIENT_ID=<WEB_CLIENT_ID>` está en `.env` del backend cloud.
4. `SOCIAL_AUTH_TRUSTED_MODE=false` en cloud.
5. Google login devuelve `access_token`.

Pendiente actual:
- ⏳ Punto 5 (validación funcional final en app).

## C) Firebase Push

### C.1 Archivos nativos
- `fulbii_app/android/app/google-services.json` (debe incluir package `com.fulbii.fulbii_app`).
- `fulbii_app/ios/Runner/GoogleService-Info.plist` (bundle `com.fulbii`).

### C.2 APNs key en Firebase
Firebase > Project Settings > Cloud Messaging:
1. Subir `.p8`
2. `Key ID`
3. `Team ID`

### C.3 Backend push
```env
PUSH_DRIVER=fcm
FCM_PROJECT_ID=<FIREBASE_PROJECT_ID>
FCM_SERVICE_ACCOUNT_PATH=/etc/fulbii/firebase-service-account.json
# opcionales
FCM_SCOPE=https://www.googleapis.com/auth/firebase.messaging
FCM_TOKEN_URI=https://oauth2.googleapis.com/token
```

### C.4 Lectura rápida de pantallas Firebase
1. `Configuración > Cuentas de servicio`:
- Botón `Generar nueva clave privada` descarga el JSON que usa el backend Laravel para FCM v1.
2. App Android con warning de SHA-1 duplicado:
- Significa que esa combinación `package + SHA-1` también existe en otro proyecto.
- Recomendación: dejar Fulbii como proyecto único para ese package/huella.
3. `Cloud Messaging` app iOS:
- Si solo aparece APNs desarrollo, falta subir APNs producción.
- APNs producción es obligatoria para que push funcione en TestFlight/App Store.

## D) Validación final de login contra cloud
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2/fulbii_app"
flutter clean
flutter pub get
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>
```

Criterio OK:
- Apple login retorna a app y backend devuelve `access_token`.
- Google login retorna a app y backend devuelve `access_token`.

## E) Troubleshooting rápido
- Apple falla instantáneo: faltó guardar `Primary App ID` o `APPLE_CLIENT_ID` no coincide.
- Google no vuelve a la app: reversed client id no configurado en URL Schemes.
- Backend responde 422: `aud` del token no coincide con `GOOGLE_CLIENT_ID` o `APPLE_CLIENT_ID`.
