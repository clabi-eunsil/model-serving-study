#!/usr/bin/env bash
set -euo pipefail

# benchmark 전에 endpoint를 한 번 호출해 warmup한다.
#
# 첫 요청은 model loading, CUDA kernel 준비, cache 초기화 때문에 느릴 수 있다.
# 실제 성능 비교에서는 cold start와 steady state를 구분해야 하므로,
# 여기서는 "steady state에 가까운 상태"를 보기 위해 짧은 요청을 먼저 보낸다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-qwen3-0.6b}"

curl -sS "${BASE_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL_NAME}\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"Say warmup in one word.\"
      }
    ],
    \"max_tokens\": 8,
    \"temperature\": 0.0
  }"
echo
