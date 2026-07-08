#!/usr/bin/env bash
set -euo pipefail

# Quantized model을 vLLM OpenAI-compatible server로 실행하는 예시다.
# 실제 model repository와 quantization 방식은 GPU 종류와 vLLM version에 따라 달라질 수 있다.
#
# 기본값은 "이런 식으로 실행한다"를 보여주기 위한 예시다.
# 실습 전 Hugging Face model card와 vLLM quantization 문서에서
# 모델 repo, license, hardware support를 확인한다.
#
# 사용 예:
#   MODEL=Qwen/Qwen2.5-7B-Instruct-AWQ QUANTIZATION=awq bash scripts/02_run_quantized_vllm.sh

CONTAINER_NAME="${CONTAINER_NAME:-chapter13-quantized-vllm}"
MODEL="${MODEL:-Qwen/Qwen2.5-7B-Instruct-AWQ}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-advanced-model}"
QUANTIZATION="${QUANTIZATION:-awq}"
PORT="${PORT:-8000}"
HF_CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"
VLLM_IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:latest}"

mkdir -p "${HF_CACHE}"

echo "Quantized vLLM server 실행 준비"
echo "MODEL=${MODEL}"
echo "QUANTIZATION=${QUANTIZATION}"
echo "SERVED_MODEL_NAME=${SERVED_MODEL_NAME}"
echo "PORT=${PORT}"
echo
echo "주의: model repo가 존재하지 않거나 GPU가 지원하지 않는 quantization이면 시작에 실패할 수 있다."
echo "실패하면 README의 quantization 표와 references.md를 보고 모델/옵션을 바꾼다."
echo

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run --rm -d \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --ipc=host \
  -p "${PORT}:8000" \
  -v "${HF_CACHE}:/root/.cache/huggingface" \
  -e HF_TOKEN="${HF_TOKEN:-}" \
  "${VLLM_IMAGE}" \
  --model "${MODEL}" \
  --served-model-name "${SERVED_MODEL_NAME}" \
  --quantization "${QUANTIZATION}" \
  --host 0.0.0.0 \
  --port 8000

echo
echo "container started: ${CONTAINER_NAME}"
echo "logs 확인: docker logs -f ${CONTAINER_NAME}"
echo "모델 준비 후 호출: bash scripts/03_call_chat.sh"
