#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 Kubernetes 실습을 시작하기 전에 host에 필요한 도구와
# 현재 선택된 cluster 상태를 빠르게 확인한다.
#
# 주의할 점:
# - kubectl이 설치되어 있어도 현재 context가 엉뚱한 cluster를 가리킬 수 있다.
# - Docker Desktop/WSL/minikube 조합에서는 Docker daemon 연결 문제가 자주 난다.
# - GPU 실습은 host에서 nvidia-smi가 동작하는 것만으로 충분하지 않고,
#   cluster node 안에서도 NVIDIA device plugin이 GPU를 노출해야 한다.

echo "## kubectl"
if command -v kubectl >/dev/null 2>&1; then
  # kubectl version --client는 cluster 연결 없이도 확인할 수 있다.
  kubectl version --client
  echo
  # current-context는 "지금 kubectl 명령이 어느 cluster로 가는지"를 보여준다.
  echo "current-context: $(kubectl config current-context 2>/dev/null || true)"
  if kubectl cluster-info >/dev/null 2>&1; then
    # cluster-info가 성공하면 API server에 실제로 연결된 상태다.
    kubectl cluster-info
  else
    echo "cluster-info: unavailable. Start or select a cluster before applying manifests."
  fi
else
  echo "kubectl: not found"
  cat <<'MSG'
install guide:
  https://kubernetes.io/docs/tasks/tools/

Ubuntu/WSL example:
  sudo snap install kubectl --classic

macOS Homebrew example:
  brew install kubectl
MSG
fi

echo
echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  # 챕터 10에서는 챕터 3의 Docker image를 다시 build한다.
  # 따라서 docker CLI와 daemon 연결이 모두 필요하다.
  docker --version
else
  echo "docker: not found"
  cat <<'MSG'
install guide:
  https://docs.docker.com/engine/install/

If you use Windows + WSL2, Docker Desktop must be running and WSL integration must be enabled.
MSG
fi

echo
echo "## minikube"
if command -v minikube >/dev/null 2>&1; then
  # minikube는 이번 챕터의 기본 local Kubernetes 선택지다.
  # 이미 profile이 떠 있다면 새로 만들 필요 없이 그 profile을 재사용할 수 있다.
  minikube version
  minikube profile list 2>/dev/null || true
else
  echo "minikube: not found"
  cat <<'MSG'
install guide:
  https://minikube.sigs.k8s.io/docs/start/

Linux x86_64 example:
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64

macOS Homebrew example:
  brew install minikube
MSG
fi

echo
echo "## helm"
if command -v helm >/dev/null 2>&1; then
  # Helm은 모델 서버 manifest 배포에는 필수가 아니다.
  # 다만 NVIDIA device plugin 같은 add-on 설치 옵션을 연습할 때 사용한다.
  helm version --short
else
  echo "helm: not found"
  cat <<'MSG'
install guide:
  https://helm.sh/docs/intro/install/

Helm is optional for the CPU Deployment practice.
It is used only when you choose the Helm path for NVIDIA device plugin installation.
MSG
fi

echo
echo "## NVIDIA"
if command -v nvidia-smi >/dev/null 2>&1; then
  # GPU 서버라면 여기서 driver와 GPU가 보이는지 먼저 확인한다.
  # 이후 Kubernetes node에도 nvidia.com/gpu가 보여야 Pod가 GPU를 요청할 수 있다.
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## Cluster nodes"
if command -v kubectl >/dev/null 2>&1 && kubectl get nodes >/dev/null 2>&1; then
  # node 목록은 "cluster에 실제 실행 공간이 몇 개 있는지"를 보여준다.
  # StorageClass는 PVC가 실제 volume으로 바인딩될 수 있는지 확인할 때 중요하다.
  kubectl get nodes -o wide
  echo
  kubectl get storageclass 2>/dev/null || true
else
  echo "No reachable Kubernetes cluster."
fi
