#!/usr/bin/env bash
set -euo pipefail

# nginx를 local reverse proxy로 띄워 rate limiting과 demo API key check를 실험한다.
# 전제:
# - model server가 host의 8000 port에서 실행 중이어야 한다.
# - nginx container는 8080 port로 열린다.
#
# 호출 예:
#   BASE_URL=http://127.0.0.1:8080/v1 API_KEY=chapter13-demo-key bash scripts/03_call_chat.sh

CONTAINER_NAME="${CONTAINER_NAME:-chapter13-nginx-rate-limit}"
CONFIG_PATH="$(pwd)/config/nginx-rate-limit.conf"
PORT="${PORT:-8080}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run --rm -d \
  --name "${CONTAINER_NAME}" \
  --add-host=host.docker.internal:host-gateway \
  -p "${PORT}:8080" \
  -v "${CONFIG_PATH}:/etc/nginx/nginx.conf:ro" \
  nginx:1.27-alpine

echo "nginx rate limit proxy started: ${CONTAINER_NAME}"
echo
echo "정상 호출:"
echo "  BASE_URL=http://127.0.0.1:${PORT}/v1 API_KEY=chapter13-demo-key bash scripts/03_call_chat.sh"
echo
echo "인증 실패 확인:"
echo "  BASE_URL=http://127.0.0.1:${PORT}/v1 API_KEY=wrong bash scripts/03_call_chat.sh"
echo
echo "rate limit 확인:"
echo "  for i in {1..10}; do BASE_URL=http://127.0.0.1:${PORT}/v1 API_KEY=chapter13-demo-key bash scripts/03_call_chat.sh; done"
