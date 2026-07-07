#!/usr/bin/env bash
set -euo pipefail

# CPU 기반 모델 서버 manifest를 cluster에 적용한다.
#
# 적용 순서:
# 1. namespace를 만든다.
# 2. Pod가 사용할 PVC를 만든다.
# 3. Deployment로 모델 서버 Pod를 만든다.
# 4. Service로 Pod 앞에 고정 endpoint를 만든다.
# 5. Ingress object를 만든다. controller가 없으면 사용하지 않아도 된다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-model-serving-fastapi:chapter-10}"
NAMESPACE="${NAMESPACE:-model-serving}"

kubectl apply -f "${CHAPTER_DIR}/manifests/00-namespace.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/10-model-cache-pvc.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/20-deployment-cpu.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/30-service.yaml"
kubectl apply -f "${CHAPTER_DIR}/manifests/40-ingress.yaml"

if [[ "${IMAGE}" != "model-serving-fastapi:chapter-10" ]]; then
  # 원격 cluster에서는 local image를 쓸 수 없으므로 registry image로 바꿔야 한다.
  # 예: IMAGE=ghcr.io/my-org/model-serving-fastapi:chapter-10 bash scripts/04_apply_cpu_manifests.sh
  kubectl -n "${NAMESPACE}" set image deployment/fastapi-model-server model-server="${IMAGE}"
fi

echo
kubectl -n "${NAMESPACE}" get deploy,svc,pvc,ingress
