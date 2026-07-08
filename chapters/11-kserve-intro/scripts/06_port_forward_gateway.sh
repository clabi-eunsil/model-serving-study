#!/usr/bin/env bash
set -euo pipefail

# 외부 LoadBalancer나 DNS가 없는 local cluster에서는 gateway Service를 port-forward해서 호출한다.
#
# KServe quickstart의 Knative/Istio 구성에서는 istio-ingressgateway를 통해
# InferenceService route에 접근하는 경우가 많다.
# 이 명령은 foreground로 계속 실행되어야 하므로, 다른 터미널에서 07_curl_predict.sh를 실행한다.

GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-istio-system}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
SERVICE_PORT="${SERVICE_PORT:-80}"

GATEWAY_SERVICE="${GATEWAY_SERVICE:-}"
if [[ -z "${GATEWAY_SERVICE}" ]]; then
  GATEWAY_SERVICE="$(kubectl get svc -n "${GATEWAY_NAMESPACE}" \
    --selector=app=istio-ingressgateway \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
fi

if [[ -z "${GATEWAY_SERVICE}" ]]; then
  cat <<MSG
Could not find an Istio ingress gateway service in namespace '${GATEWAY_NAMESPACE}'.

Check:
  kubectl get svc -n ${GATEWAY_NAMESPACE}

If your KServe installation uses a different gateway, set GATEWAY_NAMESPACE and GATEWAY_SERVICE:
  GATEWAY_NAMESPACE=<namespace> GATEWAY_SERVICE=<service> bash scripts/06_port_forward_gateway.sh
MSG
  exit 1
fi

echo "Forwarding http://127.0.0.1:${LOCAL_PORT} -> svc/${GATEWAY_SERVICE}:${SERVICE_PORT} in namespace ${GATEWAY_NAMESPACE}"
kubectl port-forward -n "${GATEWAY_NAMESPACE}" "svc/${GATEWAY_SERVICE}" "${LOCAL_PORT}:${SERVICE_PORT}"
