#!/usr/bin/env bash
set -euo pipefail

# FastAPI model server를 실행한다.
#
# 이 server는 app/main.py의 fake model을 사용한다.
# 핵심은 모델 품질이 아니라 /metrics endpoint가 Prometheus 형식으로
# request count, latency histogram, token count를 노출하는 구조를 보는 것이다.
#
# 실행 전:
#   python3 -m venv .venv
#   source .venv/bin/activate
#   pip install -r requirements.txt
#
# 종료:
#   Ctrl+C

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"

echo "## Starting observable FastAPI model server"
echo "url=http://127.0.0.1:${PORT}"
echo "metrics=http://127.0.0.1:${PORT}/metrics/"

uvicorn app.main:app --host "${HOST}" --port "${PORT}"
