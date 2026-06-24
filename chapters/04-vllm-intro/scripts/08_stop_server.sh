#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 챕터 4 실습이 끝난 뒤 vLLM server container를 종료한다.
#
# scripts/02_run_vllm_docker.sh는 foreground로 container를 실행한다.
# 그 터미널에서 Ctrl + C를 눌러도 종료할 수 있다.
# 다른 터미널에서 정리하고 싶을 때는 이 스크립트를 사용한다.

CONTAINER_NAME="${CONTAINER_NAME:-vllm-intro-server}"

if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  docker stop "${CONTAINER_NAME}"
  echo "stopped: ${CONTAINER_NAME}"
else
  echo "container is not running: ${CONTAINER_NAME}"
fi
