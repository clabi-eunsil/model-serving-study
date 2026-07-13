#!/usr/bin/env bash
set -euo pipefail

# KServe InferenceService에 prediction 요청을 보낸다.
#
# Knative/Istio gateway를 port-forward한 경우:
# - 실제 TCP 연결은 http://127.0.0.1:8080 으로 간다.
# - 어떤 InferenceService로 routing할지는 Host header가 결정한다.
# - SERVICE_HOSTNAME은 InferenceService status.url에서 가져온 hostname이다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-kserve-test}"
ISVC_NAME="${ISVC_NAME:-sklearn-iris}"
INGRESS_HOST="${INGRESS_HOST:-127.0.0.1}"
INGRESS_PORT="${INGRESS_PORT:-8080}"
REQUEST_FILE="${REQUEST_FILE:-${CHAPTER_DIR}/data/iris-input.json}"

SERVICE_HOSTNAME="${SERVICE_HOSTNAME:-}"
if [[ -z "${SERVICE_HOSTNAME}" ]]; then
  SERVICE_HOSTNAME="$(kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.url}' | cut -d '/' -f 3)"
fi

if [[ -z "${SERVICE_HOSTNAME}" ]]; then
  echo "Could not determine SERVICE_HOSTNAME from InferenceService status.url."
  echo "Check: kubectl get inferenceservice ${ISVC_NAME} -n ${NAMESPACE}"
  exit 1
fi

echo "SERVICE_HOSTNAME=${SERVICE_HOSTNAME}"
echo "POST http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/${ISVC_NAME}:predict"

curl -sS -v \
  -H "Host: ${SERVICE_HOSTNAME}" \
  -H "Content-Type: application/json" \
  "http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/${ISVC_NAME}:predict" \
  -d @"${REQUEST_FILE}"
echo
