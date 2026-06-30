#!/usr/bin/env bash
set -euo pipefail

# NIM의 OpenAI-compatible chat completions endpoint를 호출한다.
#
# NIM_MODEL은 API payload의 model field에 들어가는 값이다.
# 어떤 값을 써야 하는지는 /v1/models 응답 또는 NIM model page를 확인한다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
NIM_MODEL="${NIM_MODEL:-meta/llama-3.1-8b-instruct}"

curl -sS "${BASE_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${NIM_MODEL}\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are a concise model serving tutor.\"
      },
      {
        \"role\": \"user\",
        \"content\": \"Explain NVIDIA NIM in one short Korean paragraph.\"
      }
    ],
    \"max_tokens\": 128,
    \"temperature\": 0.2
  }"
echo
