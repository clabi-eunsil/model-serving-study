#!/usr/bin/env bash
set -euo pipefail

# NIM container를 종료한다.

CONTAINER_NAME="${CONTAINER_NAME:-nim-llm-server}"

if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  docker stop "${CONTAINER_NAME}"
  echo "stopped: ${CONTAINER_NAME}"
else
  echo "container is not running: ${CONTAINER_NAME}"
fi
