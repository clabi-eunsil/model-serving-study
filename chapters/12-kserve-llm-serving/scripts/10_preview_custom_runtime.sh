#!/usr/bin/env bash
set -euo pipefail

# custom vLLM ServingRuntime 예시를 화면에 출력한다.
# 이 파일은 바로 kubectl apply 하지 않는다.
# 이유:
# - image tag, CUDA version, vLLM version을 cluster GPU/driver와 맞춰야 한다.
# - readiness/liveness probe와 resource limit을 실제 모델에 맞게 조정해야 한다.
# - 운영 cluster에서는 namespace-scoped ServingRuntime을 쓸지,
#   cluster-scoped ClusterServingRuntime을 쓸지도 권한/운영 정책에 따라 달라진다.

MANIFEST="manifests/20-vllm-custom-runtime-example.yaml"

echo "== custom vLLM ServingRuntime example =="
echo "파일: ${MANIFEST}"
echo
sed -n '1,220p' "${MANIFEST}"

echo
echo "읽을 때 볼 부분:"
echo "- kind: ServingRuntime"
echo "- supportedModelFormats.name: huggingface"
echo "- containers.image: 실제 vLLM image로 바꿔야 하는 자리"
echo "- args: vLLM server 실행 옵션"
echo "- resources: GPU/memory request"
echo
echo "실제로 적용하려면 manifest를 환경에 맞게 수정한 뒤 직접 kubectl apply를 사용한다."
