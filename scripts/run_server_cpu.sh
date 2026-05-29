#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8766}"
NUM_THREADS="${NUM_THREADS:-1}"
REQUESTED_MODEL_ID="${MODEL_ID:-${MODEL:-}}"
USER_TEXT_FORMAT="${TEXT_FORMAT:-}"
USER_DECODING_METHOD="${DECODING_METHOD:-}"
if [[ -n "${PYTHON:-}" ]]; then
  PYTHON_BIN="${PYTHON}"
elif [[ -x "${ROOT_DIR}/.venv/bin/python" ]]; then
  PYTHON_BIN="${ROOT_DIR}/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  PYTHON_BIN="python"
fi

cd "${ROOT_DIR}"
if [[ -f .venv/bin/activate ]]; then
  source .venv/bin/activate
fi

eval "$("${PYTHON_BIN}" scripts/model_admin.py resolve --model-id "${REQUESTED_MODEL_ID}" --format shell)"

TEXT_FORMAT="${USER_TEXT_FORMAT:-${TEXT_FORMAT}}"
DECODING_METHOD="${USER_DECODING_METHOD:-${DECODING_METHOD}}"

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-${NUM_THREADS}}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-${NUM_THREADS}}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-${NUM_THREADS}}"
export NUMEXPR_NUM_THREADS="${NUMEXPR_NUM_THREADS:-${NUM_THREADS}}"
export ORT_INTRA_OP_NUM_THREADS="${ORT_INTRA_OP_NUM_THREADS:-${NUM_THREADS}}"
export ORT_INTER_OP_NUM_THREADS="${ORT_INTER_OP_NUM_THREADS:-1}"

echo "Starting model: ${MODEL_ID} (${LABEL})"
echo "Model dir: ${MODEL_DIR}"
echo "WebSocket: ws://${HOST}:${PORT}"
echo "CPU threads: ${NUM_THREADS}"

cmd=(
  "${PYTHON_BIN}" server/sherpa_streaming_server.py
  --host "${HOST}"
  --port "${PORT}"
  --tokens "${TOKENS}"
  --encoder "${ENCODER}"
  --decoder "${DECODER}"
  --joiner "${JOINER}"
  --provider cpu
  --sample-rate "${SAMPLE_RATE}"
  --feature-dim "${FEATURE_DIM}"
  --num-threads "${NUM_THREADS}"
  --decoding-method "${DECODING_METHOD}"
  --model-type "${MODEL_TYPE}"
  --enable-endpoint-detection 0
  --text-format "${TEXT_FORMAT}"
)

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  printf 'Command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  exit 0
fi

exec "${cmd[@]}"
