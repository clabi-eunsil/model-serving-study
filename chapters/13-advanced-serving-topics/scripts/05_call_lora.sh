#!/usr/bin/env bash
set -euo pipefail

# LoRA adapter는 OpenAI-compatible API에서 별도 model 이름처럼 호출할 수 있다.
# vLLM 문서의 핵심 포인트:
# - server 시작 시 --enable-lora를 켠다.
# - --lora-modules name=path 형태로 adapter를 등록한다.
# - 요청 JSON의 model field에 adapter name을 넣는다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-sql-lora}"
API_KEY="${API_KEY:-EMPTY}"

cat > /tmp/chapter13-lora-request.json <<JSON
{
  "model": "${MODEL_NAME}",
  "messages": [
    {
      "role": "user",
      "content": "LoRA adapter를 모델 서빙에서 쓰는 이유를 한국어로 설명해줘."
    }
  ],
  "max_tokens": 180,
  "temperature": 0.2
}
JSON

curl -sS \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  "${BASE_URL}/chat/completions" \
  -d @/tmp/chapter13-lora-request.json | python3 -m json.tool
