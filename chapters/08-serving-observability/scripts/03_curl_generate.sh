#!/usr/bin/env bash
set -euo pipefail

# /generate endpoint를 한 번 호출한다.
#
# 이 요청이 성공하면 아래 metric들이 증가한다.
# - model_server_requests_total{status="success"}
# - model_server_request_latency_seconds_bucket
# - model_server_prompt_tokens_bucket
# - model_server_completion_tokens_bucket
# - model_server_generated_tokens_total

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

curl -sS "${BASE_URL}/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain why metrics are useful for model serving.",
    "max_new_tokens": 32
  }'
echo
