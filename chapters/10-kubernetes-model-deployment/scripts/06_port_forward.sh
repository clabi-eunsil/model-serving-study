#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-model-serving}"
LOCAL_PORT="${LOCAL_PORT:-8000}"
SERVICE_PORT="${SERVICE_PORT:-8000}"

echo "Forwarding http://127.0.0.1:${LOCAL_PORT} -> svc/fastapi-model-server:${SERVICE_PORT}"
echo "Keep this terminal open while calling the service."
kubectl -n "${NAMESPACE}" port-forward svc/fastapi-model-server "${LOCAL_PORT}:${SERVICE_PORT}"

