# 01. Fulbii - Flujo General (Paso a Paso)

> **Histórico / supersedido.** Conserva el plan de una fase anterior. La escala
> 1–10 que menciona no es vigente; consultar
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

Este es el orden único recomendado para cerrar setup local, login social, nube y release.

## Estado rápido
- ✅ 1. Dominio local `https://fulbii.test` con Valet.
- ✅ 2. App iOS corre en simulador.
- ✅ 3. Bundle iOS alineado a `com.fulbii`.
- ✅ 4. Apple Login funcionando en iOS simulator contra cloud.
- ✅ 5. Google Maps funcionando en iOS simulator.
- ✅ 6. OAuth Google creados (iOS/Web/Android).
- ✅ 7. Info.plist iOS actualizado con `GIDClientID`, `GIDServerClientID` y reversed scheme.
- ✅ 8. `.env` en VPS actualizado para Google (reportado por usuario).
- ✅ 9. Validación E2E de Google Login (iOS simulator + Android emulator).
- ✅ 10. Backend push migrado a FCM HTTP v1.
- ✅ 11. Suite backend (`php artisan test`) en verde tras migración FCM v1.
- ✅ 12. Suite Flutter (`flutter analyze` y `flutter test`) en verde.
- ✅ 13. Módulo base de retos + chat implementado (backend + app).
- ✅ 14. Presencia de chat para suprimir push dentro del chat activo implementada.
- ✅ 15. SQL de retos ejecutado en BD activa.
- ⏳ 16. Cargar secretos FCM v1 + APNs producción en Firebase.
- ⏳ 17. QA físico final y publicación.
- ✅ 18. Escala de skills migrada a `1-10` (API + app pichanga + filtros).
- ✅ 19. API y UI base de clips de perfil (subir/listar/eliminar/reordenar).
- ⏳ 20. Editor de clips 7s + export GIF/sticker WhatsApp.

## Secuencia obligatoria
1. `docs/02_local_valet_ios16_simulator_guide.md`
2. `docs/03_social_auth_push_setup_detailed.md`
3. `docs/04_mobile_flutter_setup.md`
4. `docs/05_vps_native_staging_deploy.md`
5. `docs/06_release_e2e_checklist.md`
6. `docs/07_internal_release_handoff.md`
7. `docs/08_ops_runbook.md`
8. `docs/09_firebase_push_verification_step_by_step.md`
9. `docs/10_challenges_chat_setup_and_qa.md`
10. `docs/11_ratings10_profile_clips_setup.md`

## Comandos mínimos de arranque local
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/check_local_readiness.sh
scripts/local/run_queue_worker.sh
scripts/local/run_scheduler_worker.sh
```

## Comandos de pre-release local
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2"
scripts/local/check_internal_release_readiness.sh
scripts/local/print_android_fingerprints.sh
```

## Template `.env` para VPS
- `deploy/env/fulbii.com.vps.env.example`

## Comando iOS simulador apuntando a nube
```bash
cd "/Users/alfredoricciale/Sites/MisLaravel/fulbii 2/fulbii_app"
flutter run -d "iPhone 16 Plus" \
  --dart-define=APP_ENV=stg \
  --dart-define=API_BASE_URL=https://fulbii.com/api/v1 \
  --dart-define=APP_LINK_BASE_URL=https://fulbii.com
```

## Criterio de cierre de este bloque
- Apple login devuelve `access_token` contra `https://fulbii.com/api/v1`.
- Google Maps carga correctamente en iOS simulator.
- Usuario se crea/actualiza en BD cloud.
- `docs/03_social_auth_push_setup_detailed.md` queda con Apple/Maps en ✅.
