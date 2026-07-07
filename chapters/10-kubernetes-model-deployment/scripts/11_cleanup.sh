#!/usr/bin/env bash
set -euo pipefail

# 챕터 10에서 만든 Kubernetes object를 정리한다.
# namespace까지 삭제하므로 그 안의 Deployment, Service, PVC, Ingress가 함께 사라진다.
#
# 주의:
# - PVC를 지우면 model cache도 함께 사라질 수 있다.
# - minikube cluster 자체를 지우려면 README의 minikube delete 명령을 별도로 실행한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-model-serving}"

# 개별 manifest 삭제를 먼저 시도해 어떤 object가 정리되는지 보여준다.
kubectl delete -f "${CHAPTER_DIR}/manifests/40-ingress.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/30-service.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/20-deployment-cpu.yaml" --ignore-not-found=true
kubectl delete -f "${CHAPTER_DIR}/manifests/10-model-cache-pvc.yaml" --ignore-not-found=true
kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true

echo "Deleted chapter 10 resources from namespace '${NAMESPACE}'."
