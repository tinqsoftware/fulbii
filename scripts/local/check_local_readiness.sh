#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

echo "[local] checking required .env keys"
required_keys=(
  "APP_URL"
  "APP_LINK_BASE_URL"
  "QUEUE_CONNECTION"
  "PUSH_DRIVER"
)

for key in "${required_keys[@]}"; do
  if ! grep -q "^${key}=" .env; then
    echo "[local][error] missing ${key} in .env"
    exit 1
  fi
done

echo "[local] php tests"
php artisan test --stop-on-failure

echo "[local] auto reminders dry-run"
php artisan pichangas:auto-reminders --dry-run

echo "[local] readiness route exists"
php artisan route:list --path=api/v1/admin/ops/release-readiness

echo "[local] done"
