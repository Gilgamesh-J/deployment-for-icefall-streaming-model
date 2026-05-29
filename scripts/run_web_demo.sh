#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_PORT="${WEB_PORT:-7860}"

cd "${ROOT_DIR}/web"
echo "Open http://127.0.0.1:${WEB_PORT}"
exec python3 -m http.server "${WEB_PORT}" --bind 127.0.0.1
