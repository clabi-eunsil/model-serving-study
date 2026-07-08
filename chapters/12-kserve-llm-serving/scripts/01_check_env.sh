#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 챕터 12 실습을 시작하기 전에 필요한 조건을 확인한다.
# KServe LLM 실습은 일반 Kubernetes 예제보다 요구 조건이 많다.
# 최소한 아래 조건이 필요하다.
# 1. kubectl이 현재 Kubernetes cluster에 연결되어 있어야 한다.
# 2. KServe CRD와 Hugging Face runtime이 설치되어 있어야 한다.
# 3. GPU 실습을 하려면 node에 nvidia.com/gpu resource가 보여야 한다.
# 4. 외부 호출을 하려면 Istio/Knative gateway 또는 유사한 ingress 경로가 있어야 한다.

echo "== command check =="
for cmd in kubectl curl; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "OK: ${cmd} -> $(command -v "${cmd}")"
  else
    echo "MISSING: ${cmd}"
  fi
done

echo
echo "== kubectl context =="
kubectl config current-context || {
  echo "kubectl context를 확인하지 못했다. 먼저 cluster 접속 설정을 확인한다."
  exit 1
}

echo
echo "== cluster reachability =="
kubectl cluster-info

echo
echo "== KServe CRD =="
if kubectl get crd inferenceservices.serving.kserve.io >/dev/null 2>&1; then
  echo "OK: InferenceService CRD가 설치되어 있다."
else
  echo "MISSING: InferenceService CRD가 없다."
  echo "챕터 11 또는 KServe 공식 Quickstart에 따라 KServe를 먼저 설치해야 한다."
fi

echo
echo "== KServe runtimes =="
echo "Hugging Face runtime이 보이면 LLM 실습을 진행하기 좋다."
kubectl get clusterservingruntime 2>/dev/null | sed -n '1,40p' || true

echo
echo "== GPU resource on nodes =="
echo "아래 출력에 nvidia.com/gpu가 보이면 GPU scheduling 실습이 가능하다."
kubectl describe nodes | grep -E "nvidia.com/gpu|Name:|Capacity:|Allocatable:" || true

echo
echo "== gateway service candidates =="
echo "local 실습에서는 보통 gateway service를 8080:80으로 port-forward한다."
kubectl get svc -A | grep -E "istio-ingressgateway|knative-local-gateway|kourier|gateway" || true

echo
echo "환경 확인 완료. MISSING 항목이 있으면 README의 '실습 전 확인'을 먼저 본다."
