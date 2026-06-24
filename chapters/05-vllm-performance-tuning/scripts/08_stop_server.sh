#!/usr/bin/env bash
set -euo pipefail

# 성능 실습이 끝난 뒤 vLLM server container를 종료한다.

CONTAINER_NAME="${CONTAINER_NAME:-vllm-perf-server}"

if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  docker stop "${CONTAINER_NAME}"
  echo "stopped: ${CONTAINER_NAME}"
else
  echo "container is not running: ${CONTAINER_NAME}"
fi
