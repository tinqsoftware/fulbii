#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://fulbii.com}"
PHP_BIN="${PHP_BIN:-php}"

echo "[smoke] php tests"
"${PHP_BIN}" artisan test --stop-on-failure

echo "[smoke] auto reminders dry run"
"${PHP_BIN}" artisan pichangas:auto-reminders --dry-run

echo "[smoke] readiness route"
"${PHP_BIN}" artisan route:list --path=api/v1/admin/ops/release-readiness

echo "[smoke] .well-known endpoints"
curl -fsS "${BASE_URL}/.well-known/apple-app-site-association" >/dev/null
curl -fsS "${BASE_URL}/.well-known/assetlinks.json" >/dev/null

echo "[smoke] done"
