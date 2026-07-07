#!/usr/bin/env bash
set -euo pipefail

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-model-serving-fastapi:chapter-10}"
NAMESPACE="${NAMESPACE:-model-serving}"

kubectl apply -f "${CHAPTER_DIR}/manifests/00-namespace.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/10-model-cache-pvc.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/20-deployment-cpu.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/30-service.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/40-ingress.yaml"

if [[ "${IMAGE}" != "model-serving-fastapi:chapter-10" ]]; then
  kubectl -n "${NAMESPACE}" set image deployment/fastapi-model-server model-server="${IMAGE}"
fi

echo
kubectl -n "${NAMESPACE}" get deploy,svc,pvc,ingress

