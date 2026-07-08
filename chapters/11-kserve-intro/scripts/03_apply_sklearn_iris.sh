#!/usr/bin/env bash
set -euo pipefail

# sklearn iris InferenceService를 배포한다.
#
# 이 YAML은 "Kubernetes Deployment를 직접 만든다"가 아니라
# "KServe에게 sklearn 모델을 serving하라고 선언한다"는 점이 핵심이다.
# KServe controller는 이 선언을 보고 runtime/pod/service/route 등을 준비한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${CHAPTER_DIR}/manifests/10-sklearn-iris.yaml"

echo
kubectl get inferenceservice sklearn-iris -n kserve-test
