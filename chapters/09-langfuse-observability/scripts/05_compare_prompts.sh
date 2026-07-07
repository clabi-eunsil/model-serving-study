#!/usr/bin/env bash
set -euo pipefail

# prompt별 latency/token usage 비교 CSV를 만든다.
#
# Langfuse Prompt Management를 실제로 쓰기 전,
# "prompt version을 비교하려면 어떤 값이 필요할까?"를 작은 CSV로 먼저 본다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAPTER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cd "${CHAPTER_DIR}"
"${PYTHON_BIN}" client/06_compare_prompts.py
