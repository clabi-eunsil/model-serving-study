#!/usr/bin/env bash
set -euo pipefail

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-model-serving}"

kubectl -n "${NAMESPACE}" patch deployment fastapi-model-server \
  --patch-file "${CHAPTER_DIR}/manifests/50-gpu-patch.yaml"

echo
kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m || true

echo
kubectl -n "${NAMESPACE}" get pods -o wide

echo
echo "If the Pod is Pending, inspect scheduler events:"
echo "kubectl -n ${NAMESPACE} describe pod -l app=fastapi-model-server"
