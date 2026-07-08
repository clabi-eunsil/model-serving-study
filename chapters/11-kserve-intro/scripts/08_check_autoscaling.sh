#!/usr/bin/env bash
set -euo pipefail

# KServe autoscaling 상태를 확인한다.
#
# Knative mode에서는 ksvc/revision과 scale-to-zero 관련 상태를 볼 수 있다.
# standard mode에서는 일반 Deployment/HPA/KPA 구성 여부에 따라 보이는 리소스가 다르다.
# 이 스크립트는 "내 cluster가 어떤 mode로 동작하는지"를 관찰하기 위한 조회용이다.

NAMESPACE="${NAMESPACE:-kserve-test}"
NAME="${NAME:-sklearn-iris}"

echo "## InferenceService"
kubectl get inferenceservice "${NAME}" -n "${NAMESPACE}" -o wide

echo
echo "## Knative resources, if installed"
kubectl get ksvc,revision,route -n "${NAMESPACE}" 2>/dev/null || true

echo
echo "## Autoscaling resources"
kubectl get hpa,kpa,podautoscaler -n "${NAMESPACE}" 2>/dev/null || true

echo
echo "## Pods"
kubectl get pods -n "${NAMESPACE}" -o wide

cat <<'MSG'

What to observe:
- Knative mode may scale pods down when there is no traffic.
- Standard mode is usually more predictable for long-running/GPU/generative workloads.
- If no autoscaling resource is shown, check how KServe was installed and which mode is enabled.
MSG
