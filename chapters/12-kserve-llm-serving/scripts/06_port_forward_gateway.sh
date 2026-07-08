#!/usr/bin/env bash
set -euo pipefail

# local cluster에서는 외부 LoadBalancer IP가 없을 수 있다.
# 이럴 때 gateway service를 localhost:8080으로 port-forward해서 호출한다.
#
# 이 스크립트는 계속 실행된 채로 있어야 한다.
# 다른 터미널에서 07_curl_chat.sh 또는 08_openai_client.sh를 실행한다.

GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-istio-system}"
GATEWAY_SELECTOR="${GATEWAY_SELECTOR:-app=istio-ingressgateway}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
REMOTE_PORT="${REMOTE_PORT:-80}"

GATEWAY_SERVICE="$(kubectl get svc \
  --namespace "${GATEWAY_NAMESPACE}" \
  --selector="${GATEWAY_SELECTOR}" \
  --output jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [[ -z "${GATEWAY_SERVICE}" ]]; then
  echo "gateway service를 찾지 못했다."
  echo "현재 후보:"
  kubectl get svc -A | grep -E "istio-ingressgateway|knative-local-gateway|kourier|gateway" || true
  echo
  echo "환경에 맞게 GATEWAY_NAMESPACE와 GATEWAY_SELECTOR를 지정한 뒤 다시 실행한다."
  echo "예: GATEWAY_NAMESPACE=knative-serving GATEWAY_SELECTOR='app=net-kourier' bash scripts/06_port_forward_gateway.sh"
  exit 1
fi

echo "Port-forward 시작: ${GATEWAY_NAMESPACE}/svc/${GATEWAY_SERVICE} localhost:${LOCAL_PORT} -> ${REMOTE_PORT}"
echo "이 터미널은 열어둔다. 중지하려면 Ctrl+C를 누른다."
kubectl port-forward --namespace "${GATEWAY_NAMESPACE}" "svc/${GATEWAY_SERVICE}" "${LOCAL_PORT}:${REMOTE_PORT}"
