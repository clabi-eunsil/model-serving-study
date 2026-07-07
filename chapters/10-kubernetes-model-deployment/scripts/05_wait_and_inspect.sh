#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-model-serving}"

kubectl -n "${NAMESPACE}" rollout status deployment/fastapi-model-server --timeout=10m

echo
echo "## Objects"
kubectl -n "${NAMESPACE}" get deploy,rs,pod,svc,pvc,ingress -o wide

echo
echo "## Endpoints"
kubectl -n "${NAMESPACE}" get endpoints fastapi-model-server

echo
echo "## Recent events"
kubectl -n "${NAMESPACE}" get events --sort-by=.lastTimestamp | tail -20

