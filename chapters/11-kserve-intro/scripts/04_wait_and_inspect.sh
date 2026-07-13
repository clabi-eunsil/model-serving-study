#!/usr/bin/env bash
set -euo pipefail

# InferenceService가 Ready 상태가 되는지 기다리고, 관련 리소스를 조회한다.
#
# KServe 설치 mode에 따라 생성되는 하위 리소스 이름은 다를 수 있다.
# Knative mode에서는 ksvc/revision/pod가 보이고,
# standard mode에서는 Deployment/Service 중심으로 보일 수 있다.

NAMESPACE="${NAMESPACE:-kserve-test}"
ISVC_NAME="${ISVC_NAME:-sklearn-iris}"

echo "Waiting for InferenceService/${ISVC_NAME} to become Ready..."
kubectl wait --for=condition=Ready "inferenceservice/${ISVC_NAME}" -n "${NAMESPACE}" --timeout=10m

echo
echo "## InferenceService"
kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}" -o wide

echo
echo "## URL"
kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.url}{"\n"}'

echo
echo "## Related Kubernetes resources"
kubectl get deploy,svc,pod -n "${NAMESPACE}" -o wide 2>/dev/null || true
kubectl get ksvc,revision,route -n "${NAMESPACE}" 2>/dev/null || true

echo
echo "## Recent events"
kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp | tail -30
