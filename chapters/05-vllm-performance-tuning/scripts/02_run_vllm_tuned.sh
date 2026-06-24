#!/usr/bin/env bash
set -euo pipefail

# vLLM server를 성능 실험용 옵션으로 실행한다.
#
# 챕터 4의 02_run_vllm_docker.sh와 비슷하지만, 챕터 5에서는 tuning option을
# 환경변수로 바꿔가며 실험할 수 있게 열어 둔다.
#
# 중요한 구분:
# - Docker option: --gpus all, -p, -v, --ipc=host 처럼 container 실행을 제어한다.
# - vLLM option: --model, --max-model-len 처럼 vLLM engine/server 동작을 제어한다.

CONTAINER_NAME="${CONTAINER_NAME:-vllm-perf-server}"
IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:latest}"
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen3-0.6B}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen3-0.6b}"
PORT="${PORT:-8000}"

# GPU memory 관련 기본 tuning option.
# 값이 크다고 항상 좋은 것은 아니다. OOM, preemption, tail latency 악화가 생길 수 있다.
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.80}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"

# Scheduler/batching 관련 option.
# - max-num-seqs: 동시에 처리할 sequence 수의 상한
# - max-num-batched-tokens: 한 iteration에서 batch로 묶을 token 수의 상한
MAX_NUM_SEQS="${MAX_NUM_SEQS:-16}"
MAX_NUM_BATCHED_TOKENS="${MAX_NUM_BATCHED_TOKENS:-4096}"

# vLLM은 release마다 option 이름이나 기본값이 바뀔 수 있다.
# prefix caching, chunked prefill, quantization 같은 실험은 공식 문서를 확인한 뒤
# VLLM_EXTRA_ARGS로 추가한다.
#
# 예:
#   VLLM_EXTRA_ARGS="--enable-prefix-caching" bash scripts/02_run_vllm_tuned.sh
#   VLLM_EXTRA_ARGS="--quantization awq" MODEL_NAME=... bash scripts/02_run_vllm_tuned.sh
VLLM_EXTRA_ARGS="${VLLM_EXTRA_ARGS:-}"

DOCKER_ENV_ARGS=()
if [[ -n "${HF_TOKEN:-}" ]]; then
  DOCKER_ENV_ARGS+=(--env "HF_TOKEN=${HF_TOKEN}")
fi

echo "## Starting vLLM performance server"
echo "container=${CONTAINER_NAME}"
echo "image=${IMAGE}"
echo "model=${MODEL_NAME}"
echo "served_model_name=${SERVED_MODEL_NAME}"
echo "gpu_memory_utilization=${GPU_MEMORY_UTILIZATION}"
echo "max_model_len=${MAX_MODEL_LEN}"
echo "max_num_seqs=${MAX_NUM_SEQS}"
echo "max_num_batched_tokens=${MAX_NUM_BATCHED_TOKENS}"
echo "extra_args=${VLLM_EXTRA_ARGS}"

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
  --max-model-len "${MAX_MODEL_LEN}" \
  --max-num-seqs "${MAX_NUM_SEQS}" \
  --max-num-batched-tokens "${MAX_NUM_BATCHED_TOKENS}" \
  ${VLLM_EXTRA_ARGS}
