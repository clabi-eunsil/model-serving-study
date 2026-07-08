#!/usr/bin/env bash
set -euo pipefail

# Qwen 0.5B instruct model을 KServe InferenceService로 배포한다.
# 이 YAML은 "Hugging Face model을 KServe Hugging Face runtime으로 실행해줘"라는 선언이다.
# 실제 container image 선택, model download, predictor Pod 생성은 KServe controller가 처리한다.

kubectl apply -f manifests/10-qwen-llm-inferenceservice.yaml

echo
echo "InferenceService 적용 완료. 상태 확인:"
kubectl -n kserve-llm get inferenceservice qwen-llm

echo
echo "처음 배포하면 model download와 container startup 때문에 시간이 걸릴 수 있다."
echo "다음 단계: bash scripts/05_wait_and_inspect.sh"
