#!/usr/bin/env bash
set -euo pipefail

# custom vLLM ServingRuntime을 실제로 Kubernetes에 적용해 보는 실습이다.
#
# 중요한 점:
# - ServingRuntime은 "이 modelFormat을 어떤 container image로 실행할지"를 정의하는
#   KServe runtime 리소스다.
# - ServingRuntime을 apply하는 것만으로 model server Pod가 바로 뜨지는 않는다.
#   실제 Pod는 InferenceService가 이 runtime을 참조할 때 만들어진다.
# - 따라서 이 스크립트는 비교적 안전한 첫 단계다. custom runtime 리소스를 등록하고,
#   KServe가 그 리소스를 읽을 수 있는지 확인한다.
#
# 운영 환경에서 custom runtime을 만들 때는 아래 값을 반드시 검증해야 한다.
# - image tag, CUDA version, vLLM version이 cluster GPU/driver와 맞는가?
# - readiness/liveness probe가 실제 endpoint와 맞는가?
# - CPU, memory, GPU request/limit이 모델 크기에 맞는가?
# - namespace-scoped ServingRuntime을 쓸지, cluster-scoped ClusterServingRuntime을 쓸지
#   권한과 운영 정책에 맞는가?

MANIFEST="manifests/20-vllm-custom-runtime-example.yaml"
NAMESPACE="${NAMESPACE:-kserve-llm}"
RUNTIME_NAME="${RUNTIME_NAME:-custom-vllm-runtime}"

echo "== custom vLLM ServingRuntime 적용 =="
echo "파일: ${MANIFEST}"
echo
sed -n '1,220p' "${MANIFEST}"

echo
echo "적용 전 볼 부분:"
echo "- kind: ServingRuntime"
echo "- supportedModelFormats.name: huggingface"
echo "- containers.image: 실제 vLLM image로 바꿔야 하는 자리"
echo "- args: vLLM server 실행 옵션"
echo "- resources: GPU/memory request"
echo
echo "kubectl apply 실행"
kubectl apply -f "${MANIFEST}"

echo
echo "등록된 ServingRuntime 확인"
kubectl -n "${NAMESPACE}" get servingruntime "${RUNTIME_NAME}" -o wide

echo
echo "상세 spec 확인"
kubectl -n "${NAMESPACE}" describe servingruntime "${RUNTIME_NAME}"

echo
echo "주의:"
echo "- 여기까지는 runtime 정의를 등록한 것이다."
echo "- 이 runtime으로 실제 LLM Pod를 띄우려면 InferenceService에서 runtime: ${RUNTIME_NAME}처럼 참조해야 한다."
echo "- custom runtime image와 args가 실제 환경에 맞지 않으면 InferenceService 단계에서 실패할 수 있다."
