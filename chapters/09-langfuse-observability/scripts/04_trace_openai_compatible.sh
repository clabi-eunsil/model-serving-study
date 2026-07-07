#!/usr/bin/env bash
set -euo pipefail

# vLLM/NIM 같은 OpenAI-compatible endpoint 호출 결과를 Langfuse generation으로 기록한다.
#
# 기본은 dry-run이다. endpoint 없이도 messages, usage, latency 형태를 확인할 수 있다.
# 실제 endpoint와 Langfuse로 보내려면:
#   DRY_RUN=false bash scripts/04_trace_openai_compatible.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAPTER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${CHAPTER_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${CHAPTER_DIR}/.env"
  set +a
fi

DRY_RUN="${DRY_RUN:-true}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cd "${CHAPTER_DIR}"

if [[ "${DRY_RUN}" == "true" ]]; then
  "${PYTHON_BIN}" client/04_trace_openai_compatible.py --dry-run
else
  "${PYTHON_BIN}" client/04_trace_openai_compatible.py
fi
