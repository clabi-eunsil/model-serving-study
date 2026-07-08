#!/usr/bin/env bash
set -euo pipefail

# KServe 실습을 시작하기 전에 cluster와 KServe 설치 상태를 확인한다.
#
# 이 챕터는 KServe 자체를 무조건 설치하는 스크립트를 제공하지 않는다.
# KServe 설치는 Kubernetes/Knative/Istio/cert-manager 버전에 민감하고,
# cluster마다 standard mode, knative mode 선택이 달라지기 때문이다.
# 대신 여기서는 "현재 cluster가 KServe 실습을 할 준비가 되었는지"를 먼저 본다.

echo "## kubectl"
if command -v kubectl >/dev/null 2>&1; then
  kubectl version --client
  echo "current-context: $(kubectl config current-context 2>/dev/null || true)"
else
  echo "kubectl: not found"
  echo "Install guide: https://kubernetes.io/docs/tasks/tools/"
  exit 1
fi

echo
echo "## Kubernetes cluster"
if kubectl get nodes >/dev/null 2>&1; then
  kubectl get nodes -o wide
else
  echo "No reachable Kubernetes cluster. Start minikube/kind or select the right kubeconfig context."
  exit 1
fi

echo
echo "## KServe CRDs"
if kubectl get crd inferenceservices.serving.kserve.io >/dev/null 2>&1; then
  echo "InferenceService CRD: installed"
else
  echo "InferenceService CRD: not found"
  echo "Install KServe first. See references.md and the KServe Quickstart Guide."
fi

echo
echo "## KServe namespaces and controllers"
kubectl get ns kserve 2>/dev/null || true
kubectl get pods -n kserve 2>/dev/null || true

echo
echo "## Serving runtimes"
# ClusterServingRuntime은 cluster 전체에서 쓸 수 있는 runtime 정의다.
# sklearn, xgboost, triton 같은 runtime이 여기에 보이면 InferenceService가 해당 runtime을 선택할 수 있다.
kubectl get clusterservingruntime 2>/dev/null || true
kubectl get servingruntime -A 2>/dev/null || true

echo
echo "## Networking layer"
# Knative/Istio mode에서는 gateway를 통해 InferenceService를 호출하는 경우가 많다.
# standard mode에서는 설치 방식에 따라 routing object가 다르게 보일 수 있다.
kubectl get ns knative-serving 2>/dev/null || true
kubectl get ns istio-system 2>/dev/null || true
kubectl get svc -n istio-system 2>/dev/null || true

echo
echo "## StorageClass"
kubectl get storageclass 2>/dev/null || true
