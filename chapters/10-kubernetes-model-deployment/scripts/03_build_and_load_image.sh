#!/usr/bin/env bash
set -euo pipefail

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${CHAPTER_DIR}/../.." && pwd)"
IMAGE="${IMAGE:-model-serving-fastapi:chapter-10}"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-model-serving}"

echo "Building image: ${IMAGE}"
docker build -t "${IMAGE}" "${REPO_ROOT}/chapters/03-docker-serving"

if command -v minikube >/dev/null 2>&1 && minikube status -p "${MINIKUBE_PROFILE}" >/dev/null 2>&1; then
  echo
  echo "Loading image into minikube profile: ${MINIKUBE_PROFILE}"
  minikube image load "${IMAGE}" -p "${MINIKUBE_PROFILE}"
else
  echo
  echo "minikube profile '${MINIKUBE_PROFILE}' is not running."
  echo "If you use k3s/managed/kubeadm, push '${IMAGE}' to a registry and set IMAGE when applying manifests."
fi

