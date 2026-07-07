#!/usr/bin/env bash
set -euo pipefail

# 로컬 학습용 Kubernetes cluster를 minikube로 만든다.
#
# 환경변수로 크기를 바꿀 수 있다.
#   PROFILE=my-lab CPUS=6 MEMORY=12288 DISK_SIZE=60g bash scripts/02_start_minikube.sh
#
# 이번 챕터의 기본값은 작은 FastAPI 모델 서버가 뜰 정도로 잡았다.
# 큰 LLM을 직접 올리는 실습은 이 값보다 훨씬 많은 memory/disk/GPU가 필요하다.

PROFILE="${PROFILE:-model-serving}"
DRIVER="${DRIVER:-docker}"
CPUS="${CPUS:-4}"
MEMORY="${MEMORY:-8192}"
DISK_SIZE="${DISK_SIZE:-40g}"

if ! command -v minikube >/dev/null 2>&1; then
  cat <<'MSG'
minikube is not installed, so this script cannot create the local Kubernetes cluster yet.

Install minikube first:
  https://minikube.sigs.k8s.io/docs/start/

Linux x86_64 example:
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64

After installation, check:
  minikube version

Then run this script again:
  bash scripts/02_start_minikube.sh
MSG
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  cat <<'MSG'
kubectl is not installed.

minikube can install/use a bundled kubectl via:
  minikube kubectl -- get nodes

However, this chapter uses the normal kubectl command throughout the scripts,
so install kubectl before continuing:
  https://kubernetes.io/docs/tasks/tools/
MSG
  exit 1
fi

if [[ "${DRIVER}" == "docker" ]] && ! command -v docker >/dev/null 2>&1; then
  cat <<'MSG'
Docker is not installed, but DRIVER=docker was selected.

Install Docker or choose another minikube driver.
Docker install guide:
  https://docs.docker.com/engine/install/

Available minikube drivers:
  https://minikube.sigs.k8s.io/docs/drivers/
MSG
  exit 1
fi

echo "Starting minikube profile: ${PROFILE}"
# minikube start는 내부에 단일 노드 Kubernetes cluster를 만든다.
# --driver=docker는 Docker container 안에 Kubernetes node를 띄우는 방식이다.
minikube start \
  -p "${PROFILE}" \
  --driver="${DRIVER}" \
  --cpus="${CPUS}" \
  --memory="${MEMORY}" \
  --disk-size="${DISK_SIZE}"

# kubectl이 방금 만든 minikube profile을 바라보게 한다.
kubectl config use-context "${PROFILE}"

echo
echo "Enabling ingress addon. If this fails, port-forward 실습은 계속 진행할 수 있다."
# Ingress는 선택 실습이다. addon 활성화가 실패해도 Deployment/Service/port-forward는 계속 가능하다.
minikube addons enable ingress -p "${PROFILE}" || true

echo
kubectl get nodes -o wide
