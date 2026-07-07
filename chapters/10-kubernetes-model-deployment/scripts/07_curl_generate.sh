#!/usr/bin/env bash
set -euo pipefail

# port-forward로 열린 local endpoint에 요청을 보내 모델 서버가 실제로 응답하는지 확인한다.
#
# 값을 바꿔 실험할 수 있다.
#   PROMPT="Kubernetes Service를 쉽게 설명해줘" MAX_NEW_TOKENS=64 bash scripts/07_curl_generate.sh
#
# BASE_URL은 기본적으로 port-forward 주소를 사용한다.
# Ingress나 LoadBalancer를 쓴다면 BASE_URL을 해당 주소로 바꾼다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
PROMPT="${PROMPT:-Kubernetes model serving in one sentence}"
MAX_NEW_TOKENS="${MAX_NEW_TOKENS:-32}"

echo "## Health"
# /health는 readiness/liveness probe도 사용하는 endpoint다.
curl -sS "${BASE_URL}/health"
echo
echo

echo "## Generate"
# /generate는 챕터 3 FastAPI 서버의 모델 추론 endpoint다.
curl -sS -X POST "${BASE_URL}/generate" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"${PROMPT}\",\"max_new_tokens\":${MAX_NEW_TOKENS}}"
echo
