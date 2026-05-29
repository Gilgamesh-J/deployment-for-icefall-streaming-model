#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_URI="${SERVER_URI:-ws://127.0.0.1:8766}"
CHUNK_MS="${CHUNK_MS:-100}"
SIMULATE_REALTIME="${SIMULATE_REALTIME:-1}"
WAV_PATH="${1:-${ROOT_DIR}/examples/sample_zh.wav}"

cd "${ROOT_DIR}"
if [[ -f .venv/bin/activate ]]; then
  source .venv/bin/activate
fi

exec python server/sherpa_streaming_client.py \
  --server-uri "${SERVER_URI}" \
  --wav "${WAV_PATH}" \
  --chunk-ms "${CHUNK_MS}" \
  --simulate-realtime "${SIMULATE_REALTIME}"
