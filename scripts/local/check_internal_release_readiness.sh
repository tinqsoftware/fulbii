#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/fulbii_app"

echo "== Fulbii internal release readiness (local checks) =="
echo ""

cd "${ROOT_DIR}"
if [[ -x "scripts/local/check_local_readiness.sh" ]]; then
  echo "[step] check_local_readiness.sh"
  scripts/local/check_local_readiness.sh
fi

if [[ -x "scripts/local/check_google_apple_firebase_setup.sh" ]]; then
  echo ""
  echo "[step] check_google_apple_firebase_setup.sh"
  scripts/local/check_google_apple_firebase_setup.sh
fi

echo ""
echo "[step] backend tests (Unit + Feature)"
php artisan test --testsuite=Unit,Feature

echo ""
echo "[step] flutter analyze"
cd "${APP_DIR}"
flutter analyze

echo ""
echo "[step] flutter test"
flutter test

echo ""
echo "✅ Checks locales completados."
echo "Siguiente paso manual:"
echo "1) Probar login Apple/Google en iOS + Android apuntando a https://fulbii.com/api/v1."
echo "2) Verificar push real en dispositivo fisico (foreground/background/terminated)."
echo "3) Generar AAB/TestFlight para internal testing."
