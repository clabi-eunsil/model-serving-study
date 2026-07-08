#!/usr/bin/env bash
set -euo pipefail

# 챕터 11에서 만든 실습 리소스를 정리한다.
# namespace 삭제는 그 안의 InferenceService와 관련 object를 함께 지운다.

NAMESPACE="${NAMESPACE:-kserve-test}"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true

echo "Deleted namespace '${NAMESPACE}'."
