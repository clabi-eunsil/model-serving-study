#!/usr/bin/env bash
set -euo pipefail

# KServe LLM 실습용 namespace를 만든다.
# namespace를 따로 쓰면 나중에 cleanup할 때 실습 리소스만 지우기 쉽다.
# control-plane namespace에는 InferenceService를 만들지 않는 것이 중요하다.

kubectl apply -f manifests/00-namespace.yaml

echo
echo "namespace label 확인:"
kubectl get namespace kserve-llm --show-labels

echo
echo "kserve-llm namespace 준비 완료."
