#!/usr/bin/env bash
set -euo pipefail

# OpenAI Python SDK로 KServe LLM endpoint를 호출한다.
# Python package가 필요하므로 이 챕터는 별도 .venv를 만들어 실행하는 것을 권장한다.
#
# 준비:
#   python3 -m venv .venv
#   source .venv/bin/activate
#   pip install -r requirements.txt
#
# 별도 터미널에서 scripts/06_port_forward_gateway.sh가 실행 중이어야 한다.

NAMESPACE="${NAMESPACE:-kserve-llm}"
NAME="${NAME:-qwen-llm}"
INGRESS_HOST="${INGRESS_HOST:-127.0.0.1}"
INGRESS_PORT="${INGRESS_PORT:-8080}"

export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://${INGRESS_HOST}:${INGRESS_PORT}/openai/v1}"
export SERVICE_HOSTNAME="${SERVICE_HOSTNAME:-$(kubectl -n "${NAMESPACE}" get inferenceservice "${NAME}" -o jsonpath='{.status.url}' | cut -d '/' -f 3)}"
export MODEL_NAME="${MODEL_NAME:-qwen}"

if [[ -z "${SERVICE_HOSTNAME}" ]]; then
  echo "SERVICE_HOSTNAME을 찾지 못했다. InferenceService Ready 상태를 먼저 확인한다."
  exit 1
fi

echo "OPENAI_BASE_URL=${OPENAI_BASE_URL}"
echo "SERVICE_HOSTNAME=${SERVICE_HOSTNAME}"
echo "MODEL_NAME=${MODEL_NAME}"
echo

python client/08_openai_client.py
