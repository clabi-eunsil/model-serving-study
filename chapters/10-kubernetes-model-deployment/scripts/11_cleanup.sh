#!/usr/bin/env bash
set -euo pipefail

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-model-serving}"

kubectl delete -f "${CHAPTER_DIR}/manifests/40-ingress.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/30-service.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/20-deployment-cpu.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/10-model-cache-pvc.yaml" --ignore-not-found=true
kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true

echo "Deleted chapter 10 resources from namespace '${NAMESPACE}'."
