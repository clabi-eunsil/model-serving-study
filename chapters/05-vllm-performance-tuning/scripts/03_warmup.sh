#!/usr/bin/env bash
set -euo pipefail

# benchmark 전에 server가 준비되었는지 확인하고, 짧은 요청을 한 번 보내 warmup한다.
#
# warmup이 필요한 이유:
# - 첫 요청은 model loading, CUDA kernel 준비, cache 초기화 때문에 느릴 수 있다.
# - benchmark는 "첫 요청 비용"과 "steady-state 성능"을 구분해서 봐야 한다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
MODEL="${SERVED_MODEL_NAME:-qwen3-0.6b}"

echo "## /v1/models"
curl -sS "${BASE_URL}/v1/models"
echo

echo
echo "## Warmup chat completion"
curl -sS "${BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL}\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"Say warmup complete in Korean.\"
      }
    ],
    \"max_tokens\": 32,
    \"temperature\": 0.0
  }"
echo
