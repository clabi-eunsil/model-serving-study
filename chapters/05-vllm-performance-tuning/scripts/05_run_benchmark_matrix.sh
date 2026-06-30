#!/usr/bin/env bash
set -euo pipefail

# 여러 조건으로 benchmark를 반복 실행한다.
#
# 이 script는 server option을 바꾸지는 않는다.
# 먼저 scripts/02_run_vllm_tuned.sh로 server를 실행한 뒤,
# client workload 조건만 바꿔 latency/throughput 변화를 관찰한다.
#
# 여기서 바꾸는 값은 "client가 어떤 부하를 주는가"에 대한 값이다.
#
# REQUESTS:
#   전체 요청 수. 예: 12이면 총 12번 /v1/chat/completions를 호출한다.
#
# CONCURRENCY_LIST:
#   동시에 날릴 요청 수 목록.
#   예: "1 2 4"는 concurrency 1, 2, 4를 차례로 실험한다.
#   기대 변화:
#   - 처음에는 concurrency가 올라갈수록 requests/sec가 증가할 수 있다.
#   - 너무 높아지면 queueing 때문에 latency_p95가 증가할 수 있다.
#
# PROMPT_SIZE_LIST:
#   prompt 길이 종류. client/04_benchmark_async.py의 PROMPTS에서 고른다.
#   short보다 long은 prefill 비용과 KV cache 사용량이 커질 가능성이 높다.
#
# MAX_TOKENS_LIST:
#   요청별 최대 output token 수 목록.
#   값이 커지면 decode 단계가 길어져 total latency가 증가할 가능성이 높다.
#
# 추천 실험:
#   REQUESTS=12 CONCURRENCY_LIST="1 2 4" MAX_TOKENS_LIST="32 128" PROMPT_SIZE_LIST="short long" bash scripts/05_run_benchmark_matrix.sh
#
# 더 가볍게:
#   REQUESTS=6 CONCURRENCY_LIST="1 2" MAX_TOKENS_LIST="32" PROMPT_SIZE_LIST="short" bash scripts/05_run_benchmark_matrix.sh
#
# 더 무겁게:
#   REQUESTS=24 CONCURRENCY_LIST="1 4 8 16" MAX_TOKENS_LIST="64 256" PROMPT_SIZE_LIST="medium long" bash scripts/05_run_benchmark_matrix.sh
#
# 해석할 때 볼 것:
# - latency_p50: 일반적인 요청이 어느 정도 걸리는지
# - latency_p95: 느린 요청이 얼마나 나빠지는지
# - requests_per_second: 초당 요청 처리량
# - completion_tokens_per_second: 초당 생성 token 처리량
# - CSV의 error column: OOM, timeout, connection error가 있었는지

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
