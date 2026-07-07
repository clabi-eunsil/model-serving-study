#!/usr/bin/env bash
set -euo pipefail

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
    helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
    helm repo update
    helm upgrade -i nvdp nvdp/nvidia-device-plugin \
      --version "${PLUGIN_VERSION}" \
      --namespace nvidia-device-plugin \
      --create-namespace
    ;;
  kubectl)
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

