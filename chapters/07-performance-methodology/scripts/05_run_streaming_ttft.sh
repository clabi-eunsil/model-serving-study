#!/usr/bin/env bash
set -euo pipefail

# streaming benchmark를 실행한다.
#
# non-streaming 요청은 응답이 끝난 뒤 total latency만 보기 쉽다.
# streaming 요청은 첫 chunk가 도착하는 시점도 볼 수 있어 TTFT에 가깝게 측정할 수 있다.
#
# 주의:
# 이 script의 ttft_ms는 "첫 streaming data chunk가 도착한 시간"이다.
# server나 protocol에 따라 첫 chunk가 실제 첫 token이 아닐 수도 있으므로,
# 결과를 해석할 때는 사용하는 server의 streaming 형식을 함께 확인한다.

mkdir -p results

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-qwen3-0.6b}"

python client/03_openai_benchmark.py \
  --base-url "${BASE_URL}" \
  --model "${MODEL_NAME}" \
  --requests "${REQUESTS:-8}" \
  --concurrency "${CONCURRENCY:-2}" \
  --prompt-size "${PROMPT_SIZE:-short}" \
  --max-tokens "${MAX_TOKENS:-128}" \
  --stream \
  --output "${OUTPUT:-results/streaming_ttft.csv}"
