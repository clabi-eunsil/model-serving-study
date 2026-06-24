#!/usr/bin/env bash
set -euo pipefail

# 여러 조건으로 benchmark를 반복 실행한다.
#
# 이 script는 server option을 바꾸지는 않는다.
# 먼저 scripts/02_run_vllm_tuned.sh로 server를 실행한 뒤,
# client workload 조건만 바꿔 latency/throughput 변화를 관찰한다.

MODEL="${SERVED_MODEL_NAME:-qwen3-0.6b}"
REQUESTS="${REQUESTS:-12}"
MAX_TOKENS_LIST="${MAX_TOKENS_LIST:-32 128}"
CONCURRENCY_LIST="${CONCURRENCY_LIST:-1 2 4}"
PROMPT_SIZE_LIST="${PROMPT_SIZE_LIST:-short long}"

mkdir -p results

for prompt_size in ${PROMPT_SIZE_LIST}; do
  for max_tokens in ${MAX_TOKENS_LIST}; do
    for concurrency in ${CONCURRENCY_LIST}; do
      output="results/bench_${prompt_size}_mt${max_tokens}_c${concurrency}.csv"
      echo
      echo "## benchmark prompt_size=${prompt_size} max_tokens=${max_tokens} concurrency=${concurrency}"
      python client/04_benchmark_async.py \
        --model "${MODEL}" \
        --requests "${REQUESTS}" \
        --concurrency "${concurrency}" \
        --prompt-size "${prompt_size}" \
        --max-tokens "${max_tokens}" \
        --output "${output}"
    done
  done
done
