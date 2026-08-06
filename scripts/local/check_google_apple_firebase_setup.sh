#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_DIR="${ROOT_DIR}/fulbii_app/ios"
ANDROID_DIR="${ROOT_DIR}/fulbii_app/android"
INFO_PLIST="${IOS_DIR}/Runner/Info.plist"
ENTITLEMENTS="${IOS_DIR}/Runner/Runner.entitlements"
PBXPROJ="${IOS_DIR}/Runner.xcodeproj/project.pbxproj"
ENV_FILE="${ROOT_DIR}/.env"

ok() { echo "[ok] $1"; }
warn() { echo "[warn] $1"; }
err() { echo "[error] $1"; }

echo "== Fulbii social/push setup check =="

if [[ ! -f "${PBXPROJ}" ]]; then
  err "No se encontró ${PBXPROJ}"
  exit 1
fi

iOS_bundle_id="$(rg -n "PRODUCT_BUNDLE_IDENTIFIER = " "${PBXPROJ}" -S | head -n1 | sed -E 's/.*PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/\1/' || true)"
android_package="$(rg -n "applicationId = " "${ANDROID_DIR}/app/build.gradle.kts" -S | head -n1 | sed -E 's/.*applicationId = "([^"]+)".*/\1/' || true)"

echo "Bundle iOS detectado: ${iOS_bundle_id:-N/A}"
echo "Package Android detectado: ${android_package:-N/A}"

if [[ -f "${ANDROID_DIR}/app/google-services.json" ]]; then
  ok "google-services.json presente"
else
  warn "Falta ${ANDROID_DIR}/app/google-services.json"
fi

if [[ -f "${IOS_DIR}/Runner/GoogleService-Info.plist" ]]; then
  ok "GoogleService-Info.plist presente"
else
  warn "Falta ${IOS_DIR}/Runner/GoogleService-Info.plist"
fi

if rg -q "<key>GIDClientID</key>" "${INFO_PLIST}"; then
  ok "Info.plist contiene GIDClientID"
else
  warn "Info.plist no contiene GIDClientID"
fi

if rg -q "<key>GIDServerClientID</key>" "${INFO_PLIST}"; then
  ok "Info.plist contiene GIDServerClientID"
else
  warn "Info.plist no contiene GIDServerClientID"
fi

if rg -q "REPLACE_WITH_IOS_CLIENT_ID|REPLACE_WITH_WEB_CLIENT_ID|REPLACE_WITH_IOS_REVERSED_CLIENT_ID" "${INFO_PLIST}"; then
  warn "Info.plist aún tiene placeholders de Google Sign-In. Reemplázalos con valores reales."
fi

if rg -q "<string>fulbii</string>" "${INFO_PLIST}"; then
  ok "Info.plist tiene URL scheme fulbii"
else
  warn "Info.plist no tiene URL scheme fulbii"
fi

if rg -q "applinks:fulbii.com" "${ENTITLEMENTS}"; then
  ok "Runner.entitlements contiene applinks:fulbii.com"
else
  warn "Runner.entitlements no contiene applinks:fulbii.com"
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  err "No se encontró ${ENV_FILE}"
  exit 1
fi

required_env_keys=(
  "GOOGLE_CLIENT_ID"
  "APPLE_CLIENT_ID"
  "PUSH_DRIVER"
  "FCM_PROJECT_ID"
  "FCM_SERVICE_ACCOUNT_PATH"
  "APP_LINK_IOS_APP_IDS"
  "APP_LINK_ANDROID_PACKAGE_NAME"
  "APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS"
)

echo ""
echo "Revisión de .env"
for key in "${required_env_keys[@]}"; do
  if ! rg -q "^${key}=" "${ENV_FILE}"; then
    warn ".env no tiene ${key}"
    continue
  fi

  value="$(rg "^${key}=" "${ENV_FILE}" -N | head -n1 | cut -d'=' -f2-)"
  if [[ -z "${value}" ]]; then
    warn "${key} está vacío"
  else
    ok "${key} configurado"
  fi
done

if rg -q "^FCM_SERVER_KEY=" "${ENV_FILE}"; then
  warn "FCM_SERVER_KEY detectado (legacy). En esta versión usar FCM v1 con service account."
fi

echo ""
echo "Siguiente acción recomendada:"
echo "1) Completar archivos Firebase (google-services.json / GoogleService-Info.plist)."
echo "2) Completar IDs OAuth y APNs según docs/03_social_auth_push_setup_detailed.md."
echo "3) Ejecutar nuevamente este script y luego probar flutter run."
