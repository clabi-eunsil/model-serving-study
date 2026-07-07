#!/usr/bin/env bash
set -euo pipefail

# self-host Langfuse stack을 중지한다.
#
# 기본은 container만 내리고 volume은 보존한다.
# 데이터까지 지우려면 REMOVE_VOLUMES=true로 실행한다.

SELF_HOST_DIR="${SELF_HOST_DIR:-self-host/langfuse-official}"
ENV_FILE="${SELF_HOST_DIR}/.env"
REMOVE_VOLUMES="${REMOVE_VOLUMES:-false}"

if [[ ! -f "${SELF_HOST_DIR}/docker-compose.yml" ]]; then
  echo "Missing ${SELF_HOST_DIR}/docker-compose.yml"
  exit 1
fi

if [[ -f "${ENV_FILE}" ]]; then
  COMPOSE_CMD=(docker compose --env-file "${ENV_FILE}" -f "${SELF_HOST_DIR}/docker-compose.yml")
else
  COMPOSE_CMD=(docker compose -f "${SELF_HOST_DIR}/docker-compose.yml")
fi

if [[ "${REMOVE_VOLUMES}" == "true" ]]; then
  "${COMPOSE_CMD[@]}" down -v
else
  "${COMPOSE_CMD[@]}" down
fi
