#!/usr/bin/env bash
set -euo pipefail

# sklearn iris InferenceService를 배포한다.
#
# 이 YAML은 "Kubernetes Deployment를 직접 만든다"가 아니라
# "KServe에게 sklearn 모델을 serving하라고 선언한다"는 점이 핵심이다.
# KServe controller는 이 선언을 보고 runtime/pod/service/route 등을 준비한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-kserve-test}"
ISVC_NAME="${ISVC_NAME:-sklearn-iris}"

current_mode="$(kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.deploymentMode}' 2>/dev/null || true)"

if [[ -n "${current_mode}" && "${current_mode}" != "Standard" ]]; then
  cat <<MSG
InferenceService/${ISVC_NAME} already exists with deploymentMode=${current_mode}.

KServe does not allow changing deploymentMode in-place.
이번 실습은 Standard mode를 사용하므로 기존 InferenceService를 삭제한 뒤 다시 만들어야 한다.

삭제 없이 멈춘다. 재생성을 원하면 아래처럼 실행한다:
  CONFIRM_RECREATE_ISVC=true bash scripts/03_apply_sklearn_iris.sh

직접 명령으로 처리하려면:
  kubectl delete inferenceservice ${ISVC_NAME} -n ${NAMESPACE}
  bash scripts/03_apply_sklearn_iris.sh
MSG
  if [[ "${CONFIRM_RECREATE_ISVC:-false}" != "true" ]]; then
    exit 1
  fi

  echo
  echo "CONFIRM_RECREATE_ISVC=true가 설정되어 기존 InferenceService를 삭제하고 다시 생성한다."
  kubectl delete inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}"
fi

kubectl apply -f "${CHAPTER_DIR}/manifests/10-sklearn-iris.yaml"

echo
kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}"
