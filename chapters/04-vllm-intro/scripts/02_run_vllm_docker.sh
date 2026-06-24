#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 official vLLM Docker image로 OpenAI-compatible server를 실행한다.
#
# 실행 위치:
#   GPU가 있는 서버의 chapters/04-vllm-intro directory
#
# 중요한 점:
# - 이 파일은 vLLM을 pip install하지 않는다.
# - vLLM server는 Docker image 안에 이미 들어 있는 실행 환경을 사용한다.
# - model weight는 이 Docker image 안에 미리 들어 있지 않다.
# - 처음 실행하면 Docker image pull과 Hugging Face model download 때문에 오래 걸릴 수 있다.
# - 두 번째 실행부터는 mount한 Hugging Face cache를 재사용할 수 있다.
#
# 공식 Docker 문서의 핵심 흐름:
#   docker run --gpus all -v ~/.cache/huggingface:/root/.cache/huggingface -p 8000:8000 --ipc=host vllm/vllm-openai ...

CONTAINER_NAME="${CONTAINER_NAME:-vllm-intro-server}"
IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:latest}"

# MODEL_NAME은 Hugging Face Hub의 model repository id다.
# 예를 들어 아래 값은 https://huggingface.co/Qwen/Qwen3-0.6B 를 의미한다.
#
# 다른 모델로 바꾸고 싶다면:
#   MODEL_NAME=Qwen/Qwen3-1.7B bash scripts/02_run_vllm_docker.sh
#
# 단, 아무 이름이나 되는 것은 아니다.
# - Hugging Face repo가 실제로 존재해야 한다.
# - vLLM이 해당 model architecture를 지원해야 한다.
# - GPU memory에 들어갈 크기여야 한다.
# - gated/private model이면 HF_TOKEN이 필요하다.
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen3-0.6B}"

# SERVED_MODEL_NAME은 API client가 request payload의 "model" field에 넣는 이름이다.
# 실제 Hugging Face repo id와 같아도 되고, qwen3-0.6b처럼 짧은 alias로 둬도 된다.
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen3-0.6b}"
PORT="${PORT:-8000}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.80}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"

# HF_TOKEN은 public model만 쓸 때는 없어도 된다.
# gated/private model을 사용할 때는 host에서 export HF_TOKEN=... 후 실행한다.
DOCKER_ENV_ARGS=()
if [[ -n "${HF_TOKEN:-}" ]]; then
  DOCKER_ENV_ARGS+=(--env "HF_TOKEN=${HF_TOKEN}")
fi

echo "## Starting vLLM server"
echo "container: ${CONTAINER_NAME}"
echo "image: ${IMAGE}"
echo "model: ${MODEL_NAME}"
echo "served model name: ${SERVED_MODEL_NAME}"
echo "port: ${PORT}"

# docker run 옵션 설명:
#
# --rm:
#   container 종료 시 container 기록을 자동 삭제한다.
#
# --gpus all:
#   host GPU를 container 안으로 전달한다.
#   NVIDIA driver와 NVIDIA Container Toolkit이 준비되어 있어야 한다.
#
# --name:
#   container 이름을 고정해 stop/log 확인을 쉽게 한다.
#
# -p ${PORT}:8000:
#   host의 PORT를 container의 8000 port와 연결한다.
#   vLLM server는 container 안에서 8000 port로 뜬다.
#
# -v ~/.cache/huggingface:/root/.cache/huggingface:
#   Hugging Face model cache를 host directory와 공유한다.
#   image 안에 model weight를 굽지 않고, 다운로드 cache를 재사용하기 위해서다.
#
# --ipc=host:
#   PyTorch/vLLM이 shared memory를 충분히 사용할 수 있게 한다.
#   vLLM 공식 Docker 예시에도 포함되는 설정이다.
#
# ${IMAGE} 뒤의 값들은 Docker 옵션이 아니라 vLLM server 옵션이다.
# --model:
#   실제 로딩할 Hugging Face model 이름이다.
# --served-model-name:
#   OpenAI-compatible API에서 client가 사용할 model alias다.
# --gpu-memory-utilization:
#   vLLM이 GPU memory 중 어느 정도를 사용할지 정한다. 너무 높으면 OOM이 날 수 있다.
# --max-model-len:
#   prompt + generated tokens를 포함한 최대 sequence length다. 길수록 KV cache 요구량이 커진다.
docker run --rm \
  --gpus all \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:8000" \
  -v "${HOME}/.cache/huggingface:/root/.cache/huggingface" \
  --ipc=host \
  "${DOCKER_ENV_ARGS[@]}" \
  "${IMAGE}" \
  --model "${MODEL_NAME}" \
  --served-model-name "${SERVED_MODEL_NAME}" \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
  --max-model-len "${MAX_MODEL_LEN}"
