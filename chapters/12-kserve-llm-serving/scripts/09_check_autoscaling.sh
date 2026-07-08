#!/usr/bin/env bash
set -euo pipefail

# KServe LLM 배포에서 autoscaling 관련 리소스를 확인한다.
# LLM은 model loading과 GPU memory 비용이 크기 때문에 scale-to-zero가 항상 좋은 선택은 아니다.
# 요청이 없는 동안 비용을 줄일 수는 있지만, 다시 요청이 들어오면 cold start가 길어질 수 있다.
# 이 스크립트는 "현재 cluster가 어떤 autoscaling 리소스를 만들었는지" 관찰하는 용도다.

NAMESPACE="${NAMESPACE:-kserve-llm}"
NAME="${NAME:-qwen-llm}"

echo "== InferenceService =="
kubectl -n "${NAMESPACE}" get inferenceservice "${NAME}" -o wide || true

echo
echo "== Deployments =="
kubectl -n "${NAMESPACE}" get deployments -o wide || true

echo
echo "== HPA =="
kubectl -n "${NAMESPACE}" get hpa || true

echo
echo "== Knative Serving resources, if this cluster uses Knative mode =="
kubectl -n "${NAMESPACE}" get ksvc,revision,route 2>/dev/null || true

echo
echo "== Pods and resource requests =="
kubectl -n "${NAMESPACE}" get pods -o custom-columns='NAME:.metadata.name,PHASE:.status.phase,NODE:.spec.nodeName,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,GPU_REQ:.spec.containers[*].resources.requests.nvidia\.com/gpu' || true

echo
echo "해석:"
echo "- HPA가 있으면 CPU/custom metric 기반 scaling을 볼 수 있다."
echo "- Knative resource가 있으면 request 기반 scale-to-zero/scale-from-zero 가능성이 있다."
echo "- GPU LLM은 scale-from-zero 시 model download/loading 때문에 첫 요청 latency가 커질 수 있다."
