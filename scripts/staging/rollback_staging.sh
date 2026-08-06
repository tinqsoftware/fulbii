#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <git_ref>"
  exit 1
fi

TARGET_REF="$1"
APP_DIR="${APP_DIR:-/var/www/fulbii/current}"
PHP_BIN="${PHP_BIN:-php}"
COMPOSER_BIN="${COMPOSER_BIN:-composer}"

echo "[rollback] app_dir=${APP_DIR} target=${TARGET_REF}"
cd "${APP_DIR}"

git fetch --all --prune
git checkout "${TARGET_REF}"

"${COMPOSER_BIN}" install --no-dev --optimize-autoloader
"${PHP_BIN}" artisan optimize:clear
"${PHP_BIN}" artisan config:cache
"${PHP_BIN}" artisan route:cache
"${PHP_BIN}" artisan view:cache

if command -v supervisorctl >/dev/null 2>&1; then
  sudo supervisorctl restart fulbii-worker:*
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl reload nginx || true
fi

echo "[rollback] done"
