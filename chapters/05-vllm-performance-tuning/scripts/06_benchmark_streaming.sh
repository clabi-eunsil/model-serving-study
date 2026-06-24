#!/usr/bin/env bash
set -euo pipefail

# streaming mode에서 TTFT를 관찰한다.
#
# non-streaming benchmark는 전체 응답 시간이 중심이고,
# streaming benchmark는 첫 chunk가 언제 도착하는지가 중요하다.

MODEL="${SERVED_MODEL_NAME:-qwen3-0.6b}"
REQUESTS="${REQUESTS:-8}"
CONCURRENCY="${CONCURRENCY:-2}"
PROMPT_SIZE="${PROMPT_SIZE:-medium}"
MAX_TOKENS="${MAX_TOKENS:-128}"
OUTPUT="${OUTPUT:-results/bench_streaming.csv}"

python client/04_benchmark_async.py \
  --model "${MODEL}" \
  --requests "${REQUESTS}" \
  --concurrency "${CONCURRENCY}" \
  --prompt-size "${PROMPT_SIZE}" \
  --max-tokens "${MAX_TOKENS}" \
  --stream \
  --output "${OUTPUT}"
