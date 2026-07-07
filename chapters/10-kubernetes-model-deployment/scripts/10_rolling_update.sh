#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-model-serving}"
NEW_MODEL_NAME="${NEW_MODEL_NAME:-sshleifer/tiny-gpt2}"

kubectl -n "${NAMESPACE}" set env deployment/fastapi-model-server \
  ROLLING_UPDATE_MARK="$(date +%Y%m%d%H%M%S)" \
  MODEL_NAME="${NEW_MODEL_NAME}"

kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m

echo
kubectl -n "${NAMESPACE}" rollout history deployment/fastapi-model-server

echo
kubectl -n "${NAMESPACE}" get deploy,rs,pod -o wide

