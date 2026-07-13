#!/usr/bin/env bash
set -euo pipefail

# 외부 LoadBalancer나 DNS가 없는 local cluster에서는 ingress/gateway Service를 port-forward해서 호출한다.
#
# KServe 설치 mode에 따라 요청 입구가 다르다.
# - Quickstart standard mode: ingress-nginx-controller가 보이는 경우가 많다.
# - Knative/Istio mode: istio-ingressgateway가 보이는 경우가 많다.
#
# 이 스크립트는 사용자가 GATEWAY_NAMESPACE/GATEWAY_SERVICE를 직접 지정하지 않으면
# 흔한 service 이름을 순서대로 찾아서 port-forward한다.
# 이 명령은 foreground로 계속 실행되어야 하므로, 다른 터미널에서 07_curl_predict.sh를 실행한다.

GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
SERVICE_PORT="${SERVICE_PORT:-80}"

GATEWAY_SERVICE="${GATEWAY_SERVICE:-}"

try_gateway() {
  local namespace="$1"
  local service="$2"

  if kubectl get svc "${service}" -n "${namespace}" >/dev/null 2>&1; then
    GATEWAY_NAMESPACE="${namespace}"
    GATEWAY_SERVICE="${service}"
    return 0
  fi

  return 1
}

if [[ -z "${GATEWAY_SERVICE}" || -z "${GATEWAY_NAMESPACE}" ]]; then
  try_gateway "ingress-nginx" "ingress-nginx-controller" || true
fi

if [[ -z "${GATEWAY_SERVICE}" || -z "${GATEWAY_NAMESPACE}" ]]; then
  try_gateway "istio-system" "istio-ingressgateway" || true
fi

if [[ -z "${GATEWAY_SERVICE}" || -z "${GATEWAY_NAMESPACE}" ]]; then
  cat <<MSG
Could not find a known ingress/gateway service.

Check:
  kubectl get svc -A

Common examples:
  ingress-nginx / ingress-nginx-controller
  istio-system  / istio-ingressgateway

If your KServe installation uses a different gateway or ingress service, set both values:
  GATEWAY_NAMESPACE=<namespace> GATEWAY_SERVICE=<service> bash scripts/06_port_forward_gateway.sh
MSG
  exit 1
fi

echo "Forwarding http://127.0.0.1:${LOCAL_PORT} -> svc/${GATEWAY_SERVICE}:${SERVICE_PORT} in namespace ${GATEWAY_NAMESPACE}"
echo "Keep this terminal open, then run scripts/07_curl_predict.sh in another terminal."
kubectl port-forward -n "${GATEWAY_NAMESPACE}" "svc/${GATEWAY_SERVICE}" "${LOCAL_PORT}:${SERVICE_PORT}"
