#!/usr/bin/env bash
set -euo pipefail

# vLLM/NIM 같은 OpenAI-compatible endpoint 호출 결과를 Langfuse generation으로 기록한다.
#
# 기본은 dry-run이다. endpoint 없이도 messages, usage, latency 형태를 확인할 수 있다.
# 실제 endpoint와 Langfuse로 보내려면:
#   DRY_RUN=false bash scripts/04_trace_openai_compatible.sh

DRY_RUN="${DRY_RUN:-true}"

if [[ "${DRY_RUN}" == "true" ]]; then
  python client/04_trace_openai_compatible.py --dry-run
else
  python client/04_trace_openai_compatible.py
fi
