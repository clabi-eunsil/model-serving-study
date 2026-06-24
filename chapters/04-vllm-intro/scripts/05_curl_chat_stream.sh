#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 streaming chat completions를 호출한다.
#
# 04_curl_chat.sh와 같은 chat request 구조를 사용하되,
# 마지막에 "stream": true를 추가해서 응답을 chunk 단위로 받는다.
# system message는 필수는 아니지만, 04번과 비교하기 쉽도록 같은 방식으로 넣어 둔다.
#
# streaming이 중요한 이유:
# - LLM은 긴 답변을 한 번에 완성한 뒤 보내기보다, token이 생성되는 대로 보낼 수 있다.
# - 사용자는 전체 답변이 끝나기 전에도 첫 token을 볼 수 있다.
# - request 시작부터 첫 chunk가 도착하기까지의 시간이 TTFT 관찰 지점이다.
#
# curl의 -N 옵션:
# - buffering을 줄여 server가 보내는 chunk를 가능한 바로 화면에 보여준다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
MODEL="${SERVED_MODEL_NAME:-qwen3-0.6b}"

curl -N -sS "${BASE_URL}/v1/chat/completions" \
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
        \"content\": \"Give me three short bullets about continuous batching.\"
      }
    ],
    \"max_tokens\": 128,
    \"temperature\": 0.2,
    \"stream\": true
  }"
echo
