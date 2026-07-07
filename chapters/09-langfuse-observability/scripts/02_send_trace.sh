#!/usr/bin/env bash
set -euo pipefail

# Langfuse trace/span/generation 구조를 전송하거나 dry-run으로 확인한다.
#
# 기본은 dry-run이다. Langfuse key 없이도 어떤 정보가 trace에 들어갈지 볼 수 있다.
# 실제 Langfuse로 보내려면:
#   DRY_RUN=false bash scripts/02_send_trace.sh

DRY_RUN="${DRY_RUN:-true}"

if [[ "${DRY_RUN}" == "true" ]]; then
  python client/02_send_trace.py --dry-run
else
  python client/02_send_trace.py
fi
