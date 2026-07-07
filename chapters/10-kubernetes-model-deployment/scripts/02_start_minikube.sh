#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-model-serving}"
DRIVER="${DRIVER:-docker}"
CPUS="${CPUS:-4}"
MEMORY="${MEMORY:-8192}"
DISK_SIZE="${DISK_SIZE:-40g}"

echo "Starting minikube profile: ${PROFILE}"
minikube start \
  -p "${PROFILE}" \
  --driver="${DRIVER}" \
  --cpus="${CPUS}" \
  --memory="${MEMORY}" \
  --disk-size="${DISK_SIZE}"

kubectl config use-context "${PROFILE}"

echo
echo "Enabling ingress addon. If this fails, port-forward 실습은 계속 진행할 수 있다."
minikube addons enable ingress -p "${PROFILE}" || true

echo
kubectl get nodes -o wide

