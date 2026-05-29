#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-${ROOT_DIR%/}.tar.gz}"

cd "$(dirname "${ROOT_DIR}")"
tar \
  --exclude '.git' \
  --exclude '.venv' \
  --exclude '__pycache__' \
  --exclude '.DS_Store' \
  --exclude 'model/*.onnx' \
  --exclude 'model/tokens.txt' \
  --exclude 'models/*' \
  -czf "${OUT}" "$(basename "${ROOT_DIR}")"
echo "${OUT}"
