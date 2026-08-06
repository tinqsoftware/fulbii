#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

PHP_BIN="${PHP_BIN:-php}"
MINUTES="${MINUTES:-240}"
USER_ID_OPT="${USER_ID_OPT:-}"

echo "[push-verify] required env keys"
required_keys=(
  "QUEUE_CONNECTION"
  "PUSH_DRIVER"
  "FCM_PROJECT_ID"
  "FCM_SERVICE_ACCOUNT_PATH"
)

for key in "${required_keys[@]}"; do
  if ! grep -q "^${key}=" .env; then
    echo "[push-verify][error] missing ${key} in .env"
    exit 1
  fi
done

echo "[push-verify] readiness route exists"
"${PHP_BIN}" artisan route:list --path=api/v1/admin/ops/release-readiness >/dev/null

echo "[push-verify] command dry checks"
if [[ -n "${USER_ID_OPT}" ]]; then
  "${PHP_BIN}" artisan push:verification-report --minutes="${MINUTES}" --user_id="${USER_ID_OPT}"
else
  "${PHP_BIN}" artisan push:verification-report --minutes="${MINUTES}"
fi

echo ""
echo "[push-verify] SQL manual checks (run on DB):"
echo "  SELECT id, user_id, platform, is_active, device_token, last_seen_at, created_at FROM user_devices ORDER BY id DESC LIMIT 20;"
echo "  SELECT id, user_id, club_id, group_pichanga_id, type, title, created_at FROM push_notifications ORDER BY id DESC LIMIT 20;"
echo "  SELECT id, push_notification_id, user_device_id, status, provider, error_message, sent_at, created_at FROM push_dispatch_logs ORDER BY id DESC LIMIT 50;"
echo ""
echo "[push-verify] done"
