#!/usr/bin/env bash
set -euo pipefail

# Ingress나 LoadBalancer 없이 local machine에서 cluster 내부 Service를 호출하는 방법이다.
# 이 명령은 foreground로 계속 떠 있어야 한다.
# 새 터미널을 하나 더 열고 scripts/07_curl_generate.sh를 실행한다.

NAMESPACE="${NAMESPACE:-model-serving}"
LOCAL_PORT="${LOCAL_PORT:-8000}"
SERVICE_PORT="${SERVICE_PORT:-8000}"

echo "Forwarding http://127.0.0.1:${LOCAL_PORT} -> svc/fastapi-model-server:${SERVICE_PORT}"
echo "Keep this terminal open while calling the service."
kubectl -n "${NAMESPACE}" port-forward svc/fastapi-model-server "${LOCAL_PORT}:${SERVICE_PORT}"
