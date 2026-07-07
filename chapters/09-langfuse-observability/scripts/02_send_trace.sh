#!/usr/bin/env bash
set -euo pipefail

# Langfuse trace/span/generation 구조를 전송하거나 dry-run으로 확인한다.
#
# 기본은 dry-run이다. Langfuse key 없이도 어떤 정보가 trace에 들어갈지 볼 수 있다.
# 실제 Langfuse로 보내려면:
#   DRY_RUN=false bash scripts/02_send_trace.sh
# 또는:
#   bash scripts/02_send_trace.sh --send
#   bash scripts/02_send_trace.sh false
#
# 아래 값들은 학습용 기본값이다. 운영에서는 request context에서 온 값을 넣는다.
# 예:
#   TRACE_NAME=chat-completion \
#   SESSION_ID=session-20260707-001 \
#   USER_ID=user-anonymous-42 \
#   MODEL_NAME=Qwen/Qwen3-0.6B \
#   bash scripts/02_send_trace.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAPTER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# `.env`에 Langfuse key를 넣어 두었다면 자동으로 읽는다.
# 이렇게 해두면 매번 `export LANGFUSE_PUBLIC_KEY=...`를 직접 입력하지 않아도 된다.
if [[ -f "${CHAPTER_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${CHAPTER_DIR}/.env"
  set +a
fi

DRY_RUN="${DRY_RUN:-true}"

case "${1:-}" in
  --send|false)
    DRY_RUN="false"
    ;;
  --dry-run|true|"")
    ;;
  DRY_RUN=false)
    echo "입력한 형식은 shell 환경변수로 적용되지 않는다: bash scripts/02_send_trace.sh DRY_RUN=false"
    echo "아래 둘 중 하나로 실행한다:"
    echo "  DRY_RUN=false bash scripts/02_send_trace.sh"
    echo "  bash scripts/02_send_trace.sh --send"
    exit 1
    ;;
  *)
    echo "Unknown argument: ${1}"
    echo "사용법:"
    echo "  bash scripts/02_send_trace.sh"
    echo "  DRY_RUN=false bash scripts/02_send_trace.sh"
    echo "  bash scripts/02_send_trace.sh --send"
    exit 1
    ;;
esac

cd "${CHAPTER_DIR}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ "${DRY_RUN}" == "true" ]]; then
  "${PYTHON_BIN}" client/02_send_trace.py --dry-run
else
  if ! "${PYTHON_BIN}" - <<'PY'
import importlib.util
raise SystemExit(0 if importlib.util.find_spec("langfuse") else 1)
PY
  then
    echo "langfuse package가 설치되어 있지 않다."
    echo "먼저 아래 명령으로 챕터 .venv를 준비한다:"
    echo "  python3 -m venv .venv"
    echo "  source .venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
  fi
  "${PYTHON_BIN}" client/02_send_trace.py
fi
