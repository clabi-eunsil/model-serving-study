#!/usr/bin/env bash
set -euo pipefail

# KServe default ServingRuntime 목록을 cluster에 등록한다.
#
# 왜 이 스크립트가 필요한가?
# - KServe control plane 설치가 끝나도 ClusterServingRuntime이 비어 있는 경우가 있다.
# - InferenceService는 modelFormat.name, 예를 들어 sklearn을 보고 runtime을 고른다.
# - cluster에 sklearn을 지원하는 ClusterServingRuntime이 없으면 sklearn iris 예제가 Ready가 되지 않는다.
#
# 이 스크립트는 KServe 공식 release tag의 config/runtimes kustomize manifest를 적용한다.
# 적용 후에는 kserve-sklearnserver, kserve-xgbserver, kserve-tritonserver,
# kserve-huggingfaceserver 같은 ClusterServingRuntime이 보여야 한다.
#
# 공식 문서:
# - ServingRuntime: https://kserve.github.io/website/docs/concepts/resources/servingruntime
# - Predictive runtimes overview:
#   https://kserve.github.io/website/docs/model-serving/predictive-inference/frameworks/overview

KSERVE_VERSION="${KSERVE_VERSION:-v0.18.0}"
RUNTIME_MANIFEST="github.com/kserve/kserve/config/runtimes?ref=${KSERVE_VERSION}"

echo "== KServe default ServingRuntime 적용 준비 =="
echo "KServe version: ${KSERVE_VERSION}"
echo "Runtime manifest: ${RUNTIME_MANIFEST}"
echo

echo "## 1. 현재 Kubernetes context"
kubectl config current-context
echo

echo "## 2. InferenceService CRD 확인"
if ! kubectl get crd inferenceservices.serving.kserve.io >/dev/null 2>&1; then
  echo "ERROR: KServe InferenceService CRD가 없다."
  echo "먼저 KServe control plane을 설치한다:"
  echo "  bash scripts/00_install_kserve_quickstart_standard.sh"
  exit 1
fi
echo "InferenceService CRD: installed"
echo

echo "## 3. 현재 runtime 목록"
kubectl get clusterservingruntime || true
echo

echo "## 4. 실행될 공식 runtime 적용 명령"
echo "kubectl apply -k \"${RUNTIME_MANIFEST}\""
echo

if [[ "${CONFIRM_APPLY_RUNTIMES:-false}" != "true" ]]; then
  echo "기본값은 dry-run이다. 아직 runtime을 적용하지 않았다."
  echo
  echo "실제로 적용하려면 아래처럼 실행한다:"
  echo "  CONFIRM_APPLY_RUNTIMES=true bash scripts/00_apply_kserve_default_runtimes.sh"
  echo
  echo "적용 후 확인:"
  echo "  kubectl get clusterservingruntime"
  echo "  bash scripts/01_check_env.sh"
  exit 0
fi

echo "CONFIRM_APPLY_RUNTIMES=true가 설정되어 있으므로 runtime manifest를 적용한다."
echo

kubectl apply -k "${RUNTIME_MANIFEST}"

echo
echo "== 적용 후 runtime 목록 =="
kubectl get clusterservingruntime

echo
echo "다음 단계:"
echo "  bash scripts/01_check_env.sh"
