#!/usr/bin/env bash
set -euo pipefail

# Kubernetes는 "container image"를 실행한다.
# 그래서 챕터 3에서 만든 FastAPI Dockerfile을 다시 build하고,
# minikube node가 그 image를 찾을 수 있도록 image를 minikube 안으로 load한다.
#
# managed Kubernetes/k3s/kubeadm에서는 보통 local image load가 아니라
# Docker Hub, GHCR, 사내 registry 같은 곳에 push한 image를 사용한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${CHAPTER_DIR}/../.." && pwd)"
IMAGE="${IMAGE:-model-serving-fastapi:chapter-10}"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-model-serving}"

echo "Building image: ${IMAGE}"
# build context는 챕터 3 디렉터리다. app/main.py와 Dockerfile, requirements.txt가 여기 있다.
docker build -t "${IMAGE}" "${REPO_ROOT}/chapters/03-docker-serving"

if command -v minikube >/dev/null 2>&1 && minikube status -p "${MINIKUBE_PROFILE}" >/dev/null 2>&1; then
  echo
  echo "Loading image into minikube profile: ${MINIKUBE_PROFILE}"
  # minikube image load는 host Docker image를 minikube node 내부 image store로 복사한다.
  # 이 작업을 하지 않으면 Pod가 ImagePullBackOff 상태가 될 수 있다.
  minikube image load "${IMAGE}" -p "${MINIKUBE_PROFILE}"
else
  echo
  echo "minikube profile '${MINIKUBE_PROFILE}' is not running."
  echo "If you use k3s/managed/kubeadm, push '${IMAGE}' to a registry and set IMAGE when applying manifests."
fi
