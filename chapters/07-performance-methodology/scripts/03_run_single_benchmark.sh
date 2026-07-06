#!/usr/bin/env bash
set -euo pipefail

# 단일 조건 benchmark를 실행한다.
#
# 처음에는 조건을 하나만 고정해서 결과 CSV가 어떻게 생기는지 확인한다.
# 이후 04_run_benchmark_matrix.sh에서 concurrency, prompt 길이, output token 수를 바꿔본다.
#
# 기본 고정 조건:
# - requests=8: 총 8개의 요청을 보낸다.
# - concurrency=2: 동시에 최대 2개의 요청만 진행한다.
# - prompt_size=short: 짧은 prompt를 사용한다.
# - max_tokens=64: 요청당 최대 64개 token 생성을 요청한다.
# - stream=false: streaming이 아닌 일반 chat completions 응답을 측정한다.
#
# 값을 바꿔보고 싶으면 환경변수로 덮어쓴다.
# 예:
#   CONCURRENCY=4 MAX_TOKENS=128 bash scripts/03_run_single_benchmark.sh

mkdir -p results

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-qwen3-0.6b}"
REQUESTS="${REQUESTS:-8}"
CONCURRENCY="${CONCURRENCY:-2}"
PROMPT_SIZE="${PROMPT_SIZE:-short}"
MAX_TOKENS="${MAX_TOKENS:-64}"
OUTPUT="${OUTPUT:-results/single_benchmark.csv}"

echo "## Single benchmark condition"
echo "base_url=${BASE_URL}"
echo "model=${MODEL_NAME}"
echo "requests=${REQUESTS}"
echo "concurrency=${CONCURRENCY}"
echo "prompt_size=${PROMPT_SIZE}"
echo "max_tokens=${MAX_TOKENS}"
echo "stream=false"
echo "output=${OUTPUT}"

python client/03_openai_benchmark.py \
  --base-url "${BASE_URL}" \
  --model "${MODEL_NAME}" \
  --requests "${REQUESTS}" \
  --concurrency "${CONCURRENCY}" \
  --prompt-size "${PROMPT_SIZE}" \
  --max-tokens "${MAX_TOKENS}" \
  --output "${OUTPUT}"
