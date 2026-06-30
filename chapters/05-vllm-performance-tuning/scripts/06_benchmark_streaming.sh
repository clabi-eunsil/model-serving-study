#!/usr/bin/env bash
set -euo pipefail

# streaming mode에서 TTFT를 관찰한다.
#
# non-streaming benchmark는 전체 응답 시간이 중심이고,
# streaming benchmark는 첫 chunk가 언제 도착하는지가 중요하다.
#
# 여기서 바꾸는 값:
#
# REQUESTS:
#   전체 streaming 요청 수.
#
# CONCURRENCY:
#   동시에 진행할 streaming 요청 수.
#   높이면 throughput은 좋아질 수 있지만 TTFT와 p95 latency가 나빠질 수 있다.
#
# PROMPT_SIZE:
#   short, medium, long 중 하나.
#   prompt가 길수록 첫 token 전 prefill 비용이 커져 TTFT가 증가할 수 있다.
#
# MAX_TOKENS:
#   생성할 최대 token 수.
#   TTFT보다는 stream_total_seconds, total latency에 더 큰 영향을 주는 편이다.
#
# 추천 실험:
#   CONCURRENCY=1 PROMPT_SIZE=short MAX_TOKENS=64 bash scripts/06_benchmark_streaming.sh
#   CONCURRENCY=4 PROMPT_SIZE=short MAX_TOKENS=64 OUTPUT=results/stream_c4.csv bash scripts/06_benchmark_streaming.sh
#   CONCURRENCY=2 PROMPT_SIZE=long MAX_TOKENS=128 OUTPUT=results/stream_long.csv bash scripts/06_benchmark_streaming.sh
#
# 기대 변화:
# - prompt_size를 short → long으로 바꾸면 TTFT가 증가할 수 있다.
# - max_tokens를 키우면 전체 streaming 완료 시간은 증가할 수 있다.
# - concurrency를 키우면 어느 지점부터 TTFT p95가 나빠질 수 있다.

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
