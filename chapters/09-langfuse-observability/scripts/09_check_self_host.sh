#!/usr/bin/env bash
set -euo pipefail

# self-host Langfuse container 상태와 UI 접근 가능 여부를 확인한다.

SELF_HOST_DIR="${SELF_HOST_DIR:-self-host/langfuse-official}"
LANGFUSE_URL="${LANGFUSE_URL:-http://localhost:3000}"

if [[ ! -f "${SELF_HOST_DIR}/docker-compose.yml" ]]; then
  echo "Missing ${SELF_HOST_DIR}/docker-compose.yml"
  exit 1
fi

echo "## docker compose ps"
docker compose -f "${SELF_HOST_DIR}/docker-compose.yml" ps

echo
echo "## Langfuse web HTTP check"
if curl -fsS -I "${LANGFUSE_URL}" >/dev/null; then
  echo "Langfuse web is reachable: ${LANGFUSE_URL}"
else
  echo "Langfuse web is not reachable yet: ${LANGFUSE_URL}"
  echo "첫 실행은 migration과 dependency 준비 때문에 시간이 걸릴 수 있다."
  echo "logs 확인:"
  echo "  docker compose -f ${SELF_HOST_DIR}/docker-compose.yml logs --tail=100 langfuse-web"
fi
