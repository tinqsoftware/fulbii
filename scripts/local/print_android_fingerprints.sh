#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANDROID_DIR="${ROOT_DIR}/fulbii_app/android"
KEY_PROPERTIES_FILE="${ANDROID_DIR}/key.properties"

if ! command -v keytool >/dev/null 2>&1; then
  echo "[error] keytool no esta instalado o no esta en PATH."
  exit 1
fi

print_fingerprints() {
  local label="$1"
  shift

  echo ""
  echo "== ${label} =="
  set +e
  local output
  output="$(keytool "$@" 2>/dev/null)"
  local status=$?
  set -e
  if [[ ${status} -ne 0 ]]; then
    echo "[warn] No se pudo leer huellas para ${label}."
    return
  fi

  echo "${output}" | awk '
    /Alias name:/ {print $0}
    /SHA1:/ || /SHA-1:/ {print $0}
    /SHA256:/ || /SHA-256:/ {print $0}
  '
}

DEBUG_KEYSTORE="${HOME}/.android/debug.keystore"
if [[ -f "${DEBUG_KEYSTORE}" ]]; then
  print_fingerprints \
    "Debug keystore (${DEBUG_KEYSTORE})" \
    -list -v \
    -keystore "${DEBUG_KEYSTORE}" \
    -alias androiddebugkey \
    -storepass android \
    -keypass android
else
  echo "[warn] No existe debug keystore en ${DEBUG_KEYSTORE}"
fi

if [[ -f "${KEY_PROPERTIES_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${KEY_PROPERTIES_FILE}"

  if [[ -n "${storeFile:-}" && -n "${keyAlias:-}" && -n "${storePassword:-}" ]]; then
    RELEASE_KEYSTORE="${storeFile}"
    if [[ "${RELEASE_KEYSTORE}" != /* ]]; then
      RELEASE_KEYSTORE="${ANDROID_DIR}/${RELEASE_KEYSTORE}"
    fi

    if [[ -f "${RELEASE_KEYSTORE}" ]]; then
      if [[ -n "${keyPassword:-}" ]]; then
        print_fingerprints \
          "Release keystore (${RELEASE_KEYSTORE})" \
          -list -v \
          -keystore "${RELEASE_KEYSTORE}" \
          -alias "${keyAlias}" \
          -storepass "${storePassword}" \
          -keypass "${keyPassword}"
      else
        print_fingerprints \
          "Release keystore (${RELEASE_KEYSTORE})" \
          -list -v \
          -keystore "${RELEASE_KEYSTORE}" \
          -alias "${keyAlias}" \
          -storepass "${storePassword}"
      fi
    else
      echo "[warn] key.properties apunta a un keystore que no existe: ${RELEASE_KEYSTORE}"
    fi
  else
    echo "[warn] key.properties existe pero esta incompleto (storeFile/keyAlias/storePassword)."
  fi
else
  echo ""
  echo "[info] No existe ${KEY_PROPERTIES_FILE}. Solo se mostraron huellas debug."
fi

echo ""
echo "Siguiente paso recomendado:"
echo "1) Registrar SHA-1 y SHA-256 en Firebase app Android com.fulbii.fulbii_app."
echo "2) Registrar huellas release definitivas cuando tengas keystore final."
