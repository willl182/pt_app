#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PT_APP_PORT:-3838}"
LOG_FILE="${TMPDIR:-/tmp}/pt_app_capture_${PORT}.log"

cd "$ROOT_DIR"
Rscript -e "shiny::runApp('.', host='127.0.0.1', port=${PORT}, launch.browser=FALSE)" \
  >"$LOG_FILE" 2>&1 &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 90); do
  if curl --silent --fail "http://127.0.0.1:${PORT}" >/dev/null; then
    PT_APP_URL="http://127.0.0.1:${PORT}" npm run capture:evidence
    exit 0
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    cat "$LOG_FILE" >&2
    exit 1
  fi
  sleep 1
done

cat "$LOG_FILE" >&2
echo "La aplicación no quedó disponible en el puerto ${PORT}." >&2
exit 1
