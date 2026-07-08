#!/usr/bin/env bash
set -euo pipefail

# InferenceService가 Ready가 될 때까지 기다리고, 실패 시 볼 만한 정보를 출력한다.
# LLM serving은 image pull, model download, GPU scheduling 때문에 실패 지점이 다양하다.
# 특히 Pending이면 GPU node/resource가 부족한 경우가 많고,
# Init 상태에서 멈추면 model download/storage initializer 문제일 수 있다.

NAMESPACE="${NAMESPACE:-kserve-llm}"
NAME="${NAME:-qwen-llm}"
TIMEOUT="${TIMEOUT:-20m}"

echo "== wait for InferenceService Ready =="
kubectl -n "${NAMESPACE}" wait --for=condition=Ready "inferenceservice/${NAME}" --timeout="${TIMEOUT}" || true

echo
echo "== InferenceService =="
kubectl -n "${NAMESPACE}" get inferenceservice "${NAME}" -o wide || true

echo
echo "== status url =="
kubectl -n "${NAMESPACE}" get inferenceservice "${NAME}" -o jsonpath='{.status.url}' 2>/dev/null || true
echo

echo
echo "== pods =="
kubectl -n "${NAMESPACE}" get pods -o wide

echo
echo "== recent events =="
kubectl -n "${NAMESPACE}" get events --sort-by=.lastTimestamp | tail -n 30

echo
echo "== describe pods with qwen-llm in name =="
kubectl -n "${NAMESPACE}" get pods -o name | grep "${NAME}" | while read -r pod; do
  echo
  echo "--- ${pod} ---"
  kubectl -n "${NAMESPACE}" describe "${pod}" | sed -n '1,180p'
done

echo
echo "Ready가 False라면 위 events에서 FailedScheduling, ErrImagePull, OOMKilled, storage initializer 관련 메시지를 먼저 본다."
