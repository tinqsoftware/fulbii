#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://fulbii.com}"
EXPECTED_IP="${EXPECTED_IP:-}"
WATCH_BEARER_TOKEN="${WATCH_BEARER_TOKEN:-}"
WATCH_PICHANGA_ID="${WATCH_PICHANGA_ID:-}"
ADMIN_BEARER_TOKEN="${ADMIN_BEARER_TOKEN:-}"

ok() { echo "[ok] $1"; }
warn() { echo "[warn] $1"; }
err() { echo "[error] $1"; }

DOMAIN="$(echo "${BASE_URL}" | sed -E 's#^https?://##' | cut -d/ -f1)"
if [[ -z "${DOMAIN}" ]]; then
  err "No se pudo resolver DOMAIN desde BASE_URL=${BASE_URL}"
  exit 1
fi

echo "== smoke_post_ip_cutover =="
echo "BASE_URL=${BASE_URL}"
echo "DOMAIN=${DOMAIN}"

echo ""
echo "[step] DNS resolution"
RESOLVED_IPS=""
if command -v dig >/dev/null 2>&1; then
  RESOLVED_IPS="$(dig +short "${DOMAIN}" A | tr '\n' ' ' | xargs)"
elif command -v nslookup >/dev/null 2>&1; then
  RESOLVED_IPS="$(nslookup "${DOMAIN}" | awk '/^Address: /{print $2}' | tr '\n' ' ' | xargs)"
else
  warn "No hay dig/nslookup para validar DNS"
fi

if [[ -n "${RESOLVED_IPS}" ]]; then
  ok "IPs resueltas: ${RESOLVED_IPS}"
fi

if [[ -n "${EXPECTED_IP}" && -n "${RESOLVED_IPS}" ]]; then
  if echo "${RESOLVED_IPS}" | tr ' ' '\n' | grep -Fxq "${EXPECTED_IP}"; then
    ok "DOMAIN incluye EXPECTED_IP=${EXPECTED_IP}"
  else
    warn "DOMAIN no incluye EXPECTED_IP=${EXPECTED_IP} (puede haber proxy/CDN)"
  fi
fi

echo ""
echo "[step] Public web/app-link endpoints"
curl -fsS "${BASE_URL}/.well-known/apple-app-site-association" >/dev/null
ok "apple-app-site-association 200"
curl -fsS "${BASE_URL}/.well-known/assetlinks.json" >/dev/null
ok "assetlinks.json 200"
curl -fsS "${BASE_URL}/join/CUTOVERTEST" >/dev/null
ok "join deep link landing 200"
curl -fsS "${BASE_URL}/api/v1/users/1/profile-clips" >/dev/null
ok "api pública /api/v1/users/1/profile-clips 200"

echo ""
echo "[step] Admin readiness (optional)"
if [[ -n "${ADMIN_BEARER_TOKEN}" ]]; then
  curl -fsS \
    -H "Authorization: Bearer ${ADMIN_BEARER_TOKEN}" \
    -H "Accept: application/json" \
    "${BASE_URL}/api/v1/admin/ops/release-readiness" >/dev/null
  ok "admin/ops/release-readiness 200 con ADMIN_BEARER_TOKEN"
else
  warn "ADMIN_BEARER_TOKEN vacío, se omite readiness autenticado"
fi

echo ""
echo "[step] Watch endpoints (optional)"
if [[ -n "${WATCH_BEARER_TOKEN}" ]]; then
  curl -fsS \
    -H "Authorization: Bearer ${WATCH_BEARER_TOKEN}" \
    -H "Accept: application/json" \
    "${BASE_URL}/api/v1/watch/pichangas/home-feed?days=7" >/dev/null
  ok "watch home-feed 200 con WATCH_BEARER_TOKEN"

  if [[ -n "${WATCH_PICHANGA_ID}" ]]; then
    curl -fsS \
      -H "Authorization: Bearer ${WATCH_BEARER_TOKEN}" \
      -H "Accept: application/json" \
      "${BASE_URL}/api/v1/watch/pichangas/${WATCH_PICHANGA_ID}/sessions/me" >/dev/null
    ok "watch sessions/me 200 para pichanga ${WATCH_PICHANGA_ID}"

    curl -fsS \
      -H "Authorization: Bearer ${WATCH_BEARER_TOKEN}" \
      -H "Accept: application/json" \
      "${BASE_URL}/api/v1/watch/pichangas/${WATCH_PICHANGA_ID}/heatmap/me" >/dev/null
    ok "watch heatmap/me 200 para pichanga ${WATCH_PICHANGA_ID}"
  else
    warn "WATCH_PICHANGA_ID vacío, se omiten sessions/me y heatmap/me"
  fi
else
  warn "WATCH_BEARER_TOKEN vacío, se omiten validaciones watch autenticadas"
fi

echo ""
ok "smoke post-cutover completado"
