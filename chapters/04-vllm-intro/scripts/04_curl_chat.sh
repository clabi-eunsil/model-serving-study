#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 curl로 vLLM의 /v1/chat/completions endpoint를 호출한다.
#
# OpenAI-compatible chat request의 핵심:
# - model: server가 노출한 model alias. 여기서는 --served-model-name 값과 맞춘다.
# - messages: role/content로 구성된 대화 입력이다.
# - max_tokens: 새로 생성할 token 수의 상한이다.
# - temperature: 생성의 무작위성 정도다.
#
# 이 요청은 stream=false, 즉 응답 JSON이 완성된 뒤 한 번에 돌아오는 방식이다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
MODEL="${SERVED_MODEL_NAME:-qwen3-0.6b}"

curl -sS "${BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL}\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are a concise model serving tutor.\"
      },
      {
        \"role\": \"user\",
        \"content\": \"Explain vLLM in one short Korean paragraph.\"
      }
    ],
    \"max_tokens\": 128,
    \"temperature\": 0.2
  }"
echo
