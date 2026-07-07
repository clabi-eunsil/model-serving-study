#!/usr/bin/env bash
set -euo pipefail

# 공식 Langfuse docker-compose.yml로 self-host Langfuse를 실행한다.
#
# 실행 전 확인:
# - docker compose가 동작해야 한다.
# - docker-compose.yml의 # CHANGEME secret을 바꿨는지 확인한다.
# - local/VM low-scale 실습용이며, HA/backup/scale-out 용도는 아니다.

SELF_HOST_DIR="${SELF_HOST_DIR:-self-host/langfuse-official}"

if [[ ! -f "${SELF_HOST_DIR}/docker-compose.yml" ]]; then
  echo "Missing ${SELF_HOST_DIR}/docker-compose.yml"
  echo "Run: bash scripts/06_prepare_self_host_official.sh"
  exit 1
fi

echo "## Starting Langfuse self-host stack"
echo "compose_dir=${SELF_HOST_DIR}"

docker compose -f "${SELF_HOST_DIR}/docker-compose.yml" up -d

cat <<EOF

Langfuse UI:
  http://localhost:3000

공식 문서 기준으로 첫 실행은 준비까지 2-3분 정도 걸릴 수 있다.
상태 확인:
  bash scripts/09_check_self_host.sh
EOF
