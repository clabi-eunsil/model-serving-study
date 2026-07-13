#!/usr/bin/env bash
set -euo pipefail

# KServe standard mode가 생성하는 Ingress의 class를 nginx로 맞춘다.
#
# 왜 필요한가?
# - 현재 local minikube 실습은 ingress-nginx를 networking layer로 사용한다.
# - 그런데 KServe inferenceservice-config의 기본 ingressClassName이 istio이면,
#   KServe가 Ingress를 만들더라도 ingress-nginx controller가 그 Ingress를 처리하지 않는다.
# - 이 경우 port-forward는 성공하지만 요청은 nginx 기본 404로 끝난다.
#
# 이 스크립트는 kserve namespace의 inferenceservice-config ConfigMap 중
# data.ingress 값을 학습용 nginx 설정으로 patch한다.
# cluster 전체 KServe 설정을 바꾸는 작업이므로 기본값은 dry-run이다.

CONFIGMAP_NAMESPACE="${CONFIGMAP_NAMESPACE:-kserve}"
CONFIGMAP_NAME="${CONFIGMAP_NAME:-inferenceservice-config}"
INGRESS_CLASS_NAME="${INGRESS_CLASS_NAME:-nginx}"

cat <<MSG
== KServe standard mode ingress class patch 준비 ==
ConfigMap: ${CONFIGMAP_NAMESPACE}/${CONFIGMAP_NAME}
Target ingressClassName: ${INGRESS_CLASS_NAME}

이 patch는 KServe가 standard mode에서 생성하는 Kubernetes Ingress를
ingress-nginx controller가 처리하도록 만드는 학습용 설정이다.
MSG

echo
echo "## 1. 현재 IngressClass"
kubectl get ingressclass

echo
echo "## 2. 현재 KServe ingress config"
kubectl get configmap "${CONFIGMAP_NAME}" -n "${CONFIGMAP_NAMESPACE}" \
  -o jsonpath='{.data.ingress}{"\n"}'

echo
echo "## 3. 적용될 설정"
cat <<EOF
{
  "enableGatewayApi": false,
  "kserveIngressGateway": "kserve/kserve-ingress-gateway",
  "ingressGateway": "knative-serving/knative-ingress-gateway",
  "localGateway": "knative-serving/knative-local-gateway",
  "localGatewayService": "knative-local-gateway.istio-system.svc.cluster.local",
  "ingressDomain": "example.com",
  "ingressClassName": "${INGRESS_CLASS_NAME}",
  "domainTemplate": "{{ .Name }}-{{ .Namespace }}.{{ .IngressDomain }}",
  "urlScheme": "http",
  "disableIngressCreation": false,
  "disableHTTPRouteTimeout": false,
  "disableIstioVirtualHost": true
}
EOF

if [[ "${CONFIRM_PATCH_KSERVE_INGRESS:-false}" != "true" ]]; then
  cat <<'MSG'

기본값은 dry-run이다. 아직 ConfigMap을 변경하지 않았다.

실제로 patch하려면 아래처럼 실행한다:
  CONFIRM_PATCH_KSERVE_INGRESS=true bash scripts/00_patch_kserve_standard_ingress_nginx.sh

patch 후에는 KServe controller가 새 설정을 읽도록 rollout restart를 수행하고,
기존 InferenceService를 재생성한다:
  CONFIRM_RECREATE_ISVC=true bash scripts/03_apply_sklearn_iris.sh
MSG
  exit 0
fi

echo
echo "CONFIRM_PATCH_KSERVE_INGRESS=true가 설정되어 ConfigMap을 patch한다."

kubectl patch configmap "${CONFIGMAP_NAME}" -n "${CONFIGMAP_NAMESPACE}" --type merge -p "{
  \"data\": {
    \"ingress\": \"{\\\"enableGatewayApi\\\":false,\\\"kserveIngressGateway\\\":\\\"kserve/kserve-ingress-gateway\\\",\\\"ingressGateway\\\":\\\"knative-serving/knative-ingress-gateway\\\",\\\"localGateway\\\":\\\"knative-serving/knative-local-gateway\\\",\\\"localGatewayService\\\":\\\"knative-local-gateway.istio-system.svc.cluster.local\\\",\\\"ingressDomain\\\":\\\"example.com\\\",\\\"ingressClassName\\\":\\\"${INGRESS_CLASS_NAME}\\\",\\\"domainTemplate\\\":\\\"{{ .Name }}-{{ .Namespace }}.{{ .IngressDomain }}\\\",\\\"urlScheme\\\":\\\"http\\\",\\\"disableIngressCreation\\\":false,\\\"disableHTTPRouteTimeout\\\":false,\\\"disableIstioVirtualHost\\\":true}\"
  }
}"

echo
echo "KServe controller를 재시작한다."
kubectl rollout restart deployment/kserve-controller-manager -n "${CONFIGMAP_NAMESPACE}"
kubectl rollout status deployment/kserve-controller-manager -n "${CONFIGMAP_NAMESPACE}" --timeout=5m

echo
echo "== patch 후 KServe ingress config =="
kubectl get configmap "${CONFIGMAP_NAME}" -n "${CONFIGMAP_NAMESPACE}" \
  -o jsonpath='{.data.ingress}{"\n"}'

echo
echo "다음 단계:"
echo "  CONFIRM_RECREATE_ISVC=true bash scripts/03_apply_sklearn_iris.sh"
echo "  bash scripts/04_wait_and_inspect.sh"
