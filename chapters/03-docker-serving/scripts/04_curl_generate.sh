#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 Docker container 안에서 실행 중인 /generate endpoint를 호출한다.
# 먼저 터미널 1에서 bash scripts/03_run_container.sh 또는 docker compose up --build를 실행해야 한다.

curl -sS -X POST "http://127.0.0.1:8000/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Containerized model serving is",
    "max_new_tokens": 24,
    "temperature": 0.7
  }'
