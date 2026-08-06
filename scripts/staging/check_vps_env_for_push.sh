#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

ok() { echo "[ok] $1"; }
warn() { echo "[warn] $1"; }
err() { echo "[error] $1"; }

if [[ ! -f "${ENV_FILE}" ]]; then
  err "No se encontró ${ENV_FILE}"
  exit 1
fi

required_keys=(
  "APP_ENV"
  "APP_DEBUG"
  "APP_URL"
  "APP_LINK_BASE_URL"
  "QUEUE_CONNECTION"
  "PUSH_DRIVER"
  "FCM_PROJECT_ID"
  "FCM_SERVICE_ACCOUNT_PATH"
  "GOOGLE_CLIENT_ID"
  "APPLE_CLIENT_ID"
  "APP_LINK_IOS_APP_IDS"
  "APP_LINK_ANDROID_PACKAGE_NAME"
  "APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS"
)

echo "== Verificación .env VPS para push =="
for key in "${required_keys[@]}"; do
  if ! grep -q "^${key}=" "${ENV_FILE}"; then
    err "Falta ${key}"
    continue
  fi

  value="$(grep "^${key}=" "${ENV_FILE}" | head -n1 | cut -d'=' -f2-)"
  if [[ -z "${value}" ]]; then
    warn "${key} está vacío"
  else
    ok "${key} configurado"
  fi
done

app_env="$(grep '^APP_ENV=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2- || true)"
app_debug="$(grep '^APP_DEBUG=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2- || true)"
push_driver="$(grep '^PUSH_DRIVER=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2- || true)"
queue_connection="$(grep '^QUEUE_CONNECTION=' "${ENV_FILE}" | head -n1 | cut -d'=' -f2- || true)"

[[ "${app_env}" == "production" ]] && ok "APP_ENV=production" || warn "APP_ENV debería ser production"
[[ "${app_debug}" == "false" ]] && ok "APP_DEBUG=false" || warn "APP_DEBUG debería ser false"
[[ "${push_driver}" == "fcm" ]] && ok "PUSH_DRIVER=fcm" || warn "PUSH_DRIVER debería ser fcm"
[[ "${queue_connection}" == "database" ]] && ok "QUEUE_CONNECTION=database" || warn "QUEUE_CONNECTION debería ser database"

if grep -q '^FCM_SERVER_KEY=' "${ENV_FILE}"; then
  warn "FCM_SERVER_KEY presente (legacy). No se usa en FCM v1."
fi

echo ""
echo "Siguiente paso:"
echo "1) php artisan config:clear && php artisan cache:clear && php artisan queue:restart"
echo "2) php artisan queue:work --queue=default,push --tries=3 --backoff=30,120,300"
echo "3) GET /api/v1/admin/ops/release-readiness"
