#!/usr/bin/env bash
set -euo pipefail

# 기존 CPU Deployment에 GPU scheduling 조건을 추가한다.
#
# 먼저 확인할 것:
# - GPU node에 NVIDIA driver/container runtime이 준비되어 있는가?
# - NVIDIA device plugin이 설치되어 node에 nvidia.com/gpu가 보이는가?
# - GPU node에 accelerator=nvidia label을 붙였는가?
# - GPU node에 nvidia.com/gpu taint를 걸었다면 toleration이 필요한가?

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-model-serving}"

# patch-file은 완전한 Deployment YAML이 아니라, 기존 Deployment에 덧붙일 조각이다.
kubectl -n "${NAMESPACE}" patch deployment fastapi-model-server \
  --patch-file "${CHAPTER_DIR}/manifests/50-gpu-patch.yaml"

echo
kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m || true

echo
# Pending이어도 바로 실패로 보지 않는다. scheduler event를 보면 어떤 조건이 부족한지 배울 수 있다.
kubectl -n "${NAMESPACE}" get pods -o wide

echo
echo "If the Pod is Pending, inspect scheduler events:"
echo "kubectl -n ${NAMESPACE} describe pod -l app=fastapi-model-server"
