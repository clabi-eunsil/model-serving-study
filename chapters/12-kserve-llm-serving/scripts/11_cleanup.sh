#!/usr/bin/env bash
set -euo pipefail

# 챕터 12에서 만든 리소스를 정리한다.
# namespace를 지우면 그 안의 InferenceService, pod, secret도 함께 정리된다.
# 단, ClusterStorageContainer처럼 cluster scope로 만든 리소스는 별도 정리가 필요하다.

NAMESPACE="${NAMESPACE:-kserve-llm}"

echo "삭제 대상 namespace: ${NAMESPACE}"
kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true

echo
echo "정리 요청 완료."
echo "남은 리소스 확인: kubectl get namespace ${NAMESPACE}"
