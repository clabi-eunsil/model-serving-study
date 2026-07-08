#!/usr/bin/env bash
set -euo pipefail

# InferenceService를 배포할 namespace를 만든다.
# control plane namespace가 아니라 별도 namespace를 사용하는 습관을 들인다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${CHAPTER_DIR}/manifests/00-namespace.yaml"

echo
kubectl get namespace kserve-test
