#!/usr/bin/env bash
set -euo pipefail

echo "## kubectl"
if command -v kubectl >/dev/null 2>&1; then
  kubectl version --client
  echo
  echo "current-context: $(kubectl config current-context 2>/dev/null || true)"
  if kubectl cluster-info >/dev/null 2>&1; then
    kubectl cluster-info
  else
    echo "cluster-info: unavailable. Start or select a cluster before applying manifests."
  fi
else
  echo "kubectl: not found"
fi

echo
echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
else
  echo "docker: not found"
fi

echo
echo "## minikube"
if command -v minikube >/dev/null 2>&1; then
  minikube version
  minikube profile list 2>/dev/null || true
else
  echo "minikube: not found"
fi

echo
echo "## helm"
if command -v helm >/dev/null 2>&1; then
  helm version --short
else
  echo "helm: not found"
fi

echo
echo "## NVIDIA"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## Cluster nodes"
if command -v kubectl >/dev/null 2>&1 && kubectl get nodes >/dev/null 2>&1; then
  kubectl get nodes -o wide
  echo
  kubectl get storageclass 2>/dev/null || true
else
  echo "No reachable Kubernetes cluster."
fi

