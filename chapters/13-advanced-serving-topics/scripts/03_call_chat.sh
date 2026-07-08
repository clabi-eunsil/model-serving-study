#!/usr/bin/env bash
set -euo pipefail

# OpenAI-compatible chat completions endpoint를 호출한다.
# quantized model, LoRA adapter, 일반 vLLM server 모두 같은 API 모양으로 호출할 수 있다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
PAYLOAD="${PAYLOAD:-data/chat-input.json}"
API_KEY="${API_KEY:-EMPTY}"
RESPONSE_FILE="${RESPONSE_FILE:-/tmp/chapter13-chat-response.txt}"
STATUS_FILE="${STATUS_FILE:-/tmp/chapter13-chat-status.txt}"

echo "BASE_URL=${BASE_URL}"
echo "PAYLOAD=${PAYLOAD}"
echo

curl -sS \
  -o "${RESPONSE_FILE}" \
  -w "%{http_code}" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  "${BASE_URL}/chat/completions" \
  -d @"${PAYLOAD}" > "${STATUS_FILE}"

echo "HTTP status: $(cat "${STATUS_FILE}")"
echo

# 정상적인 OpenAI-compatible server 응답은 JSON이다.
# 하지만 rate limit이나 auth 실패 응답은 plain text일 수 있다.
# JSON이면 pretty print하고, 아니면 원문을 그대로 보여준다.
if python3 -m json.tool "${RESPONSE_FILE}" >/tmp/chapter13-chat-response.pretty 2>/dev/null; then
  cat /tmp/chapter13-chat-response.pretty
else
  cat "${RESPONSE_FILE}"
fi
