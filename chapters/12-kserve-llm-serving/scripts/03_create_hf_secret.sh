#!/usr/bin/env bash
set -euo pipefail

# Hugging Face Hub의 public model은 token 없이도 받을 수 있는 경우가 많다.
# 하지만 gated/private model은 HF_TOKEN이 필요하다.
#
# 사용 예:
#   export HF_TOKEN=hf_xxx
#   bash scripts/03_create_hf_secret.sh
#
# 이 스크립트는 HF_TOKEN이 있을 때만 Kubernetes Secret을 만든다.
# token이 없으면 public model 실습으로 계속 진행할 수 있게 안내만 출력한다.

NAMESPACE="${NAMESPACE:-kserve-llm}"

if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "HF_TOKEN 환경변수가 없다."
  echo "public model만 사용할 예정이면 이 단계는 건너뛰어도 된다."
  echo "gated/private model을 쓸 때는 'export HF_TOKEN=...' 후 다시 실행한다."
  exit 0
fi

kubectl -n "${NAMESPACE}" create secret generic hf-secret \
  --from-literal=HF_TOKEN="${HF_TOKEN}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo
echo "hf-secret 생성/갱신 완료."
kubectl -n "${NAMESPACE}" get secret hf-secret
