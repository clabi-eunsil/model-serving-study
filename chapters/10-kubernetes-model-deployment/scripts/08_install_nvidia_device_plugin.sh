#!/usr/bin/env bash
set -euo pipefail

# NVIDIA device plugin은 Kubernetes가 GPU를 Pod에 할당할 수 있게 해 주는 add-on이다.
# 설치가 끝나면 GPU node의 allocatable resource에 nvidia.com/gpu가 보인다.
#
# 이 스크립트는 일부러 INSTALL_METHOD를 기본값으로 두지 않는다.
# cluster마다 이미 GPU Operator/device plugin이 설치되어 있을 수 있고,
# 중복 설치하면 오히려 문제를 만들 수 있기 때문이다.

INSTALL_METHOD="${INSTALL_METHOD:-}"
PLUGIN_VERSION="${PLUGIN_VERSION:-0.17.1}"

if [[ -z "${INSTALL_METHOD}" ]]; then
  cat <<'MSG'
Set INSTALL_METHOD explicitly:

  INSTALL_METHOD=helm bash scripts/08_install_nvidia_device_plugin.sh
  INSTALL_METHOD=kubectl bash scripts/08_install_nvidia_device_plugin.sh

Use this only on a GPU cluster that has NVIDIA driver/container runtime configured.
If GPU Operator or device plugin is already installed, do not install a duplicate plugin.
MSG
  exit 1
fi

case "${INSTALL_METHOD}" in
  helm)
    # Helm 방식은 chart 버전과 values로 설치 상태를 관리하기 쉬워 production 문서에서 자주 권장된다.
    helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
    helm repo update
    helm upgrade -i nvdp nvdp/nvidia-device-plugin \
      --version "${PLUGIN_VERSION}" \
      --namespace nvidia-device-plugin \
      --create-namespace
    ;;
  kubectl)
    # Static manifest 방식은 구조를 보기 쉽지만, upgrade/values 관리는 Helm보다 직접적이다.
    # 아래 URL은 network 접근이 필요하다.
    kubectl create namespace nvidia-device-plugin --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v${PLUGIN_VERSION}/deployments/static/nvidia-device-plugin.yml"
    ;;
  *)
    echo "Unknown INSTALL_METHOD: ${INSTALL_METHOD}"
    echo "Expected: helm or kubectl"
    exit 1
    ;;
esac

echo
kubectl get pods -A | grep -E "nvidia-device-plugin|NAMESPACE" || true
