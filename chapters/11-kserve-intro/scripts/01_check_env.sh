#!/usr/bin/env bash
set -euo pipefail

# KServe 실습을 시작하기 전에 cluster와 KServe 설치 상태를 확인한다.
#
# KServe가 아직 없다면 README의 "KServe 설치 방법"을 먼저 보고,
# 학습용 standard mode 설치는 scripts/00_install_kserve_quickstart_standard.sh로 진행한다.
# 이 스크립트는 설치 후 상태를 확인하거나, 이미 설치된 cluster가 실습 가능한지 점검한다.

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
  echo "KServe가 아직 설치되지 않았다."
  echo "학습용 standard mode 설치 안내:"
  echo "  bash scripts/00_install_kserve_quickstart_standard.sh"
  echo "공식 Quickstart:"
  echo "  https://kserve.github.io/website/docs/getting-started/quickstart-guide"
fi

echo
echo "## KServe namespaces and controllers"
kubectl get ns kserve 2>/dev/null || true
kubectl get pods -n kserve 2>/dev/null || true

echo
echo "## Serving runtimes"
# ClusterServingRuntime은 cluster 전체에서 쓸 수 있는 runtime 정의다.
# sklearn, xgboost, triton 같은 runtime이 여기에 보이면 InferenceService가 해당 runtime을 선택할 수 있다.
cluster_runtime_count="$(kubectl get clusterservingruntime --no-headers 2>/dev/null | wc -l | tr -d ' ')"
namespace_runtime_count="$(kubectl get servingruntime -A --no-headers 2>/dev/null | wc -l | tr -d ' ')"

kubectl get clusterservingruntime 2>/dev/null || true
kubectl get servingruntime -A 2>/dev/null || true

if [[ "${cluster_runtime_count}" == "0" && "${namespace_runtime_count}" == "0" ]]; then
  echo
  echo "WARN: ServingRuntime이 하나도 보이지 않는다."
  echo "- KServe CRD와 controller는 설치되어 있지만, modelFormat을 실행할 runtime이 아직 등록되지 않은 상태다."
  echo "- 이 상태에서는 sklearn iris InferenceService가 어떤 model server image를 써야 할지 고르지 못할 수 있다."
  echo "- default runtime을 적용하려면 아래 스크립트를 실행한다:"
  echo "  CONFIRM_APPLY_RUNTIMES=true bash scripts/00_apply_kserve_default_runtimes.sh"
fi

echo
echo "## Networking layer"
# KServe의 요청 입구는 설치 mode에 따라 다르게 보인다.
# - Quickstart standard mode에서는 ingress-nginx가 보일 수 있다.
# - Knative mode에서는 knative-serving, istio-system이 보일 수 있다.
# 여기서는 흔한 namespace/service를 모두 확인해서 "어떤 입구를 써야 하는지"를 판단한다.
networking_found="false"

if kubectl get ns ingress-nginx >/dev/null 2>&1; then
  networking_found="true"
  echo "ingress-nginx namespace: installed"
  kubectl get svc -n ingress-nginx 2>/dev/null || true
fi

if kubectl get ns istio-system >/dev/null 2>&1; then
  networking_found="true"
  echo
  echo "istio-system namespace: installed"
  kubectl get svc -n istio-system 2>/dev/null || true
fi

if kubectl get ns knative-serving >/dev/null 2>&1; then
  networking_found="true"
  echo
  echo "knative-serving namespace: installed"
  kubectl get svc -n knative-serving 2>/dev/null || true
fi

if kubectl api-resources 2>/dev/null | grep -q '^gateways[[:space:]]'; then
  echo
  echo "Gateway API resources:"
  kubectl get gateway -A 2>/dev/null || true
fi

if [[ "${networking_found}" != "true" ]]; then
  echo "WARN: ingress-nginx, istio-system, knative-serving namespace가 보이지 않는다."
  echo "- InferenceService가 Ready가 되더라도 외부에서 호출할 gateway/ingress가 없을 수 있다."
  echo "- KServe 설치 mode와 networking addon 설치 상태를 확인한다."
fi

echo
echo "## StorageClass"
kubectl get storageclass 2>/dev/null || true
