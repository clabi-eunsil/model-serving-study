#!/usr/bin/env bash
set -euo pipefail

# Deployment의 Pod template을 바꿔 rolling update를 관찰한다.
#
# Kubernetes Deployment는 Pod template이 바뀌면 새 ReplicaSet을 만들고,
# readiness가 통과한 새 Pod로 traffic을 옮기며 기존 Pod를 줄인다.
# 여기서는 MODEL_NAME과 ROLLING_UPDATE_MARK 환경변수를 바꿔 update를 유도한다.

NAMESPACE="${NAMESPACE:-model-serving}"
NEW_MODEL_NAME="${NEW_MODEL_NAME:-sshleifer/tiny-gpt2}"

# date 값은 매번 달라지므로 "내용이 바뀌었다"는 신호가 되어 rollout이 발생한다.
kubectl -n "${NAMESPACE}" set env deployment/fastapi-model-server \
  ROLLING_UPDATE_MARK="$(date +%Y%m%d%H%M%S)" \
  MODEL_NAME="${NEW_MODEL_NAME}"

# 새 Pod가 ready 상태가 될 때까지 기다린다.
kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m

echo
# history를 보면 revision이 쌓이는 것을 확인할 수 있다.
kubectl -n "${NAMESPACE}" rollout history deployment/fastapi-model-server

echo
kubectl -n "${NAMESPACE}" get deploy,rs,pod -o wide
