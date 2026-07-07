#!/usr/bin/env bash
set -euo pipefail

# Deployment가 정상적으로 rollout되는지 기다리고,
# 문제가 생겼을 때 가장 먼저 볼 Kubernetes object를 모아 출력한다.
#
# 자주 보는 상태:
# - Running: Pod가 실행 중이다.
# - Pending: scheduler가 node를 못 찾았거나 PVC/GPU resource가 준비되지 않았다.
# - ImagePullBackOff: image를 가져오지 못했다. minikube image load 또는 registry 설정을 확인한다.
# - CrashLoopBackOff: container가 시작했다가 반복해서 죽고 있다. logs를 확인한다.

NAMESPACE="${NAMESPACE:-model-serving}"

# rollout status는 Deployment가 원하는 replica를 준비할 때까지 기다린다.
kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m

echo
echo "## Objects"
# deploy/rs/pod를 함께 보면 Deployment -> ReplicaSet -> Pod 관계가 보인다.
kubectl -n "${NAMESPACE}" get deploy,rs,pod,svc,pvc,ingress -o wide

echo
echo "## Endpoints"
# Service 뒤에 실제로 연결된 Pod IP 목록이다.
# 비어 있으면 readiness probe 실패나 label selector mismatch를 의심한다.
kubectl -n "${NAMESPACE}" get endpoints fastapi-model-server

echo
echo "## Recent events"
# scheduler, image pull, probe 실패 같은 힌트가 events에 남는다.
kubectl -n "${NAMESPACE}" get events --sort-by=.lastTimestamp | tail -20
