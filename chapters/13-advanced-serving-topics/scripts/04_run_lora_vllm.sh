#!/usr/bin/env bash
set -euo pipefail

# LoRA adapter serving 실습용 vLLM server 실행 예시다.
# LoRA는 base model 전체를 새로 띄우지 않고, 작은 adapter weight를 얹어
# task별 동작을 바꾸는 방식이다.
#
# 이 스크립트는 의도적으로 BASE_MODEL과 LORA_MODULES 기본값을 강제하지 않는다.
# 이유:
# - LoRA adapter는 base model과 호환되어야 한다.
# - 많은 base model은 gated license라 HF_TOKEN과 접근 승인이 필요하다.
# - 아무 모델이나 조합하면 시작은 되지 않거나 품질이 이상할 수 있다.
#
# 사용 예:
#   BASE_MODEL=meta-llama/Llama-3.2-3B-Instruct \
#   LORA_MODULES='sql-lora=jeeejeee/llama32-3b-text2sql-spider' \
#   HF_TOKEN=hf_xxx \
#   bash scripts/04_run_lora_vllm.sh

if [[ -z "${BASE_MODEL:-}" || -z "${LORA_MODULES:-}" ]]; then
  echo "BASE_MODEL과 LORA_MODULES를 지정해야 한다."
  echo
  echo "예시:"
  echo "  BASE_MODEL=meta-llama/Llama-3.2-3B-Instruct \\"
  echo "  LORA_MODULES='sql-lora=jeeejeee/llama32-3b-text2sql-spider' \\"
  echo "  HF_TOKEN=hf_xxx \\"
  echo "  bash scripts/04_run_lora_vllm.sh"
  echo
  echo "LoRA adapter는 base model과 맞아야 하므로 model card를 먼저 확인한다."
  exit 1
fi

CONTAINER_NAME="${CONTAINER_NAME:-chapter13-lora-vllm}"
PORT="${PORT:-8000}"
HF_CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"
VLLM_IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:latest}"

mkdir -p "${HF_CACHE}"
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run --rm -d \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --ipc=host \
  -p "${PORT}:8000" \
  -v "${HF_CACHE}:/root/.cache/huggingface" \
  -e HF_TOKEN="${HF_TOKEN:-}" \
  "${VLLM_IMAGE}" \
  --model "${BASE_MODEL}" \
  --enable-lora \
  --lora-modules ${LORA_MODULES} \
  --host 0.0.0.0 \
  --port 8000

echo
echo "LoRA server started: ${CONTAINER_NAME}"
echo "models 확인: curl http://127.0.0.1:${PORT}/v1/models | python3 -m json.tool"
echo "adapter 호출: MODEL_NAME=<lora-name> bash scripts/05_call_lora.sh"
