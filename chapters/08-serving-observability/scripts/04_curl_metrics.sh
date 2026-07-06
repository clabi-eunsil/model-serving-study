#!/usr/bin/env bash
set -euo pipefail

# /metrics endpoint를 직접 확인한다.
#
# Prometheus도 결국 이 endpoint를 주기적으로 HTTP GET 한다.
# 사람이 먼저 curl로 확인하면 "우리 앱이 metric을 잘 노출하는지"를 빠르게 볼 수 있다.
#
# FastAPI에서 prometheus_client ASGI app을 app.mount("/metrics", ...)로 붙이면
# /metrics 요청이 /metrics/로 307 redirect될 수 있다.
# 그래서 이 script는 redirect를 보지 않도록 처음부터 /metrics/를 호출한다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

curl -sS "${BASE_URL}/metrics/" | grep -E "model_server_|^# HELP model_server_|^# TYPE model_server_" || true
