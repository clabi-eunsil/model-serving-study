#!/usr/bin/env bash
set -euo pipefail

# KServe 0.18 Quickstart standard mode 설치를 돕는 스크립트다.
#
# 왜 00번인가?
# - 01_check_env.sh는 "KServe가 설치되어 있는지"를 확인한다.
# - KServe가 아직 없다면 그 전에 설치가 필요하다.
# - 그래서 실제 실습 순서상 00번으로 둔다.
#
# 왜 기본값으로 바로 설치하지 않는가?
# - KServe 설치는 cluster 전체에 CRD, controller, gateway 관련 리소스를 만든다.
# - 개인 minikube/kind에서는 괜찮지만, 회사/공유 cluster에서는 영향 범위가 크다.
# - 따라서 기본 실행은 설치 명령을 보여주기만 하고,
#   CONFIRM_INSTALL_KSERVE=true를 넣었을 때만 실제 설치한다.
#
# 공식 문서:
# - Quickstart: https://kserve.github.io/website/docs/getting-started/quickstart-guide
# - Standard mode: https://kserve.github.io/website/docs/admin-guide/kubernetes-deployment

KSERVE_VERSION="${KSERVE_VERSION:-v0.18.0}"
INSTALL_URL="https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve-standard-mode-full-install-with-manifests.sh"

echo "== KServe Quickstart standard mode 설치 준비 =="
echo "KServe version: ${KSERVE_VERSION}"
echo "Install script: ${INSTALL_URL}"
echo

echo "## 1. 현재 Kubernetes context"
kubectl config current-context
echo

echo "## 2. Kubernetes node 상태"
kubectl get nodes -o wide
echo

echo "## 3. 필요한 CLI 확인"
kubectl version --client
helm version
git --version
echo

echo "## 4. 실행될 공식 설치 명령"
echo "curl -sL \"${INSTALL_URL}\" | bash"
echo

if [[ "${CONFIRM_INSTALL_KSERVE:-false}" != "true" ]]; then
  echo "기본값은 dry-run이다. 아직 설치하지 않았다."
  echo
  echo "실제로 설치하려면 아래처럼 실행한다:"
  echo "  CONFIRM_INSTALL_KSERVE=true bash scripts/00_install_kserve_quickstart_standard.sh"
  echo
  echo "주의:"
  echo "- 개인 minikube/kind cluster인지 확인한다."
  echo "- 공유 cluster라면 관리자에게 먼저 확인한다."
  echo "- 설치 후에는 scripts/01_check_env.sh로 CRD/runtime/gateway 상태를 확인한다."
  exit 0
fi

echo "CONFIRM_INSTALL_KSERVE=true가 설정되어 있으므로 실제 설치를 진행한다."
echo "네트워크에서 공식 KServe release script를 받아 실행한다."
echo

curl -sL "${INSTALL_URL}" | bash

echo
echo "== 설치 후 확인 =="
kubectl get crd inferenceservices.serving.kserve.io
kubectl get pods -n kserve
kubectl get clusterservingruntime

echo
echo "다음 단계:"
echo "  bash scripts/01_check_env.sh"
