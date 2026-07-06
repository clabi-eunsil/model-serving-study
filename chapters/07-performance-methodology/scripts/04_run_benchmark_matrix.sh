#!/usr/bin/env bash
set -euo pipefail

# 여러 workload 조건을 순서대로 실행한다.
#
# benchmark matrix는 "한 번에 모든 것을 바꾸지 않는 것"이 중요하다.
# 아래 순서는 baseline에서 시작해 하나씩 조건을 바꾼다.
#
# 1. concurrency 증가: 같은 prompt/output 조건에서 동시 요청 수만 올린다.
# 2. prompt 길이 증가: prefill 부담이 커질 때 latency가 어떻게 변하는지 본다.
# 3. output 길이 증가: decode 시간이 길어질 때 total latency와 tokens/sec를 본다.

mkdir -p results

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-qwen3-0.6b}"
REQUESTS="${REQUESTS:-24}"

for concurrency in 1 2 4 8; do
  python client/03_openai_benchmark.py \
    --base-url "${BASE_URL}" \
    --model "${MODEL_NAME}" \
    --requests "${REQUESTS}" \
    --concurrency "${concurrency}" \
    --prompt-size short \
    --max-tokens 64 \
    --output "results/concurrency_${concurrency}.csv"
done

for prompt_size in short medium long; do
  python client/03_openai_benchmark.py \
    --base-url "${BASE_URL}" \
    --model "${MODEL_NAME}" \
    --requests 12 \
    --concurrency 2 \
    --prompt-size "${prompt_size}" \
    --max-tokens 64 \
    --output "results/prompt_${prompt_size}.csv"
done

for max_tokens in 32 64 128; do
  python client/03_openai_benchmark.py \
    --base-url "${BASE_URL}" \
    --model "${MODEL_NAME}" \
    --requests 12 \
    --concurrency 2 \
    --prompt-size short \
    --max-tokens "${max_tokens}" \
    --output "results/output_${max_tokens}.csv"
done
