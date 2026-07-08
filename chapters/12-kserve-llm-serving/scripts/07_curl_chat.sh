#!/usr/bin/env bash
set -euo pipefail

# KServe LLM InferenceService를 OpenAI-compatible chat completions API로 호출한다.
# KServe 예제에서 중요한 포인트는 두 가지다.
# 1. URL path는 /openai/v1/chat/completions 이다.
# 2. gateway를 통해 호출할 때는 Host header로 어떤 InferenceService인지 알려준다.

NAMESPACE="${NAMESPACE:-kserve-llm}"
NAME="${NAME:-qwen-llm}"
INGRESS_HOST="${INGRESS_HOST:-127.0.0.1}"
INGRESS_PORT="${INGRESS_PORT:-8080}"
PAYLOAD="${PAYLOAD:-data/chat-input.json}"

SERVICE_HOSTNAME="${SERVICE_HOSTNAME:-$(kubectl -n "${NAMESPACE}" get inferenceservice "${NAME}" -o jsonpath='{.status.url}' | cut -d '/' -f 3)}"

if [[ -z "${SERVICE_HOSTNAME}" ]]; then
  echo "SERVICE_HOSTNAME을 찾지 못했다. InferenceService가 Ready인지 확인한다."
  echo "확인: kubectl -n ${NAMESPACE} get inferenceservice ${NAME}"
  exit 1
fi

echo "요청 대상: http://${INGRESS_HOST}:${INGRESS_PORT}/openai/v1/chat/completions"
echo "Host header: ${SERVICE_HOSTNAME}"
echo "payload: ${PAYLOAD}"
echo

curl -sS \
  -H "Host: ${SERVICE_HOSTNAME}" \
  -H "Content-Type: application/json" \
  "http://${INGRESS_HOST}:${INGRESS_PORT}/openai/v1/chat/completions" \
  -d @"${PAYLOAD}" | python3 -m json.tool
