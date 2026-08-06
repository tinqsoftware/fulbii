#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/fulbii/current}"
PHP_BIN="${PHP_BIN:-php}"
COMPOSER_BIN="${COMPOSER_BIN:-composer}"

echo "[deploy] app_dir=${APP_DIR}"
cd "${APP_DIR}"

echo "[deploy] pulling latest changes"
git fetch --all --prune
git pull --ff-only

echo "[deploy] composer install"
"${COMPOSER_BIN}" install --no-dev --optimize-autoloader

echo "[deploy] clear/cache"
"${PHP_BIN}" artisan optimize:clear
"${PHP_BIN}" artisan config:cache
"${PHP_BIN}" artisan route:cache
"${PHP_BIN}" artisan view:cache

echo "[deploy] storage link"
"${PHP_BIN}" artisan storage:link || true

echo "[deploy] restart queue workers"
if command -v supervisorctl >/dev/null 2>&1; then
  sudo supervisorctl restart fulbii-worker:*
else
  echo "[deploy] supervisorctl not found; restart worker manually"
fi

echo "[deploy] done"
