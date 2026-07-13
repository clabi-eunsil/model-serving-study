#!/usr/bin/env bash
set -euo pipefail

# KServe autoscaling 상태를 확인한다.
#
# Knative mode에서는 ksvc/revision과 scale-to-zero 관련 상태를 볼 수 있다.
# standard mode에서는 일반 Deployment/HPA/KPA 구성 여부에 따라 보이는 리소스가 다르다.
# 이 스크립트는 "내 cluster가 어떤 mode로 동작하는지"를 관찰하기 위한 조회용이다.

NAMESPACE="${NAMESPACE:-kserve-test}"
ISVC_NAME="${ISVC_NAME:-sklearn-iris}"

echo "## InferenceService"
kubectl get inferenceservice "${ISVC_NAME}" -n "${NAMESPACE}" -o wide

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

해석:
- Knative resources가 비어 있으면 현재 InferenceService는 Knative mode로 동작하지 않는 것이다.
- Autoscaling resources가 비어 있으면 현재 실습에서는 별도 HPA/KPA 기반 autoscaling을 확인하지 않는 상태다.
- Pods에 sklearn-iris-predictor Pod가 계속 Running으로 보이면 standard mode에서 predictor가 1개 Pod로 유지되고 있다는 뜻이다.

이번 챕터의 표준 실습 해석:
- 우리는 standard mode로 sklearn iris를 배포했다.
- 따라서 ksvc/revision/route 같은 Knative 리소스가 없어도 이상하지 않다.
- traffic이 없어도 Pod가 0개로 줄어드는 scale-to-zero를 기대하지 않는다.
- scale-to-zero를 보려면 Knative mode로 KServe를 설치하고 별도 실습으로 확인해야 한다.
- HPA 기반 autoscaling을 보려면 metrics-server와 HPA 설정이 필요하다. 현재 실습의 핵심은 autoscaling 동작이 아니라 mode별로 보이는 리소스 차이를 이해하는 것이다.
MSG
