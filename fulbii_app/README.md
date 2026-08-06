# Fulbii App (Flutter)

Cliente móvil principal de Fulbii (Android + iOS) conectado a `Laravel API v1`.

## Stack
- Flutter + Riverpod
- Dio (API client)
- Google Sign-In + Apple Sign-In
- Google Maps Flutter
- Firebase Messaging (push)

## Módulos implementados
- Auth social + onboarding (`nick`, `sexo`)
- Mapa de canchas + favoritos + envío de nueva cancha
- Grupos: `Mis grupos` por membresía activa, descubrir públicos, crear/editar
  con foto, solicitudes, integrantes y perfil deportivo público
- Preferencias de notificación por grupo (`always_on`, `mute_24h`, `mute_1w`, `mute_forever`)
- Pichangas: agenda, calendario mensual, detalle de recinto, equipos
  persistentes, confirmar/cambiar equipo, baja y solicitudes externas
- Re-avisos con preview + envío
- Feed y comentarios de pichanga
- Calificaciones globales y por pichanga en estrellas decimales 0.0–5.0
- Inbox de notificaciones
- Perfil + historial + edición básica

## Run
```bash
flutter pub get
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://fulbii.test/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.test \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<tu_web_client_id>
```

Config nativa requerida para producción en `docs/mobile_flutter_setup.md`.

## Internal testing builds
```bash
# Android AAB (staging)
flutter build appbundle --release \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

Para iOS/TestFlight, usar Xcode Archive con mismo entorno de staging.

## Documentación de continuidad

Antes de cambiar contratos o flujos, revisar
[`../docs/AI_HANDOFF_CURRENT_STATE.md`](../docs/AI_HANDOFF_CURRENT_STATE.md).
