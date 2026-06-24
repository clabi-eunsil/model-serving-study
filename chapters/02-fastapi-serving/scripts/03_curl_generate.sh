#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 실행 중인 FastAPI 서버의 /generate endpoint를 호출한다.
# 먼저 다른 터미널에서 bash scripts/02_run_server.sh 로 서버를 띄워야 한다.
#
# 요청 흐름:
# 1. POST /generate 로 JSON payload를 보낸다.
# 2. FastAPI가 payload를 GenerateRequest schema로 검증한다.
# 3. app/main.py의 generator pipeline이 prompt를 받아 text를 생성한다.
# 4. 서버가 generated_text와 latency_ms를 JSON으로 돌려준다.
#
# 아래 JSON payload의 의미:
# - prompt: 생성 시작 문장
# - max_new_tokens: 새로 생성할 token 수의 상한
# - temperature: 생성 결과의 무작위성 정도
#
# -H "Content-Type: application/json" 은 서버에 JSON을 보낸다고 알려주는 header다.
curl -sS -X POST "http://127.0.0.1:8000/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Model serving is",
    "max_new_tokens": 24,
    "temperature": 0.7
  }'
