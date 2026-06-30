#!/usr/bin/env bash
set -euo pipefail

# NIM server가 OpenAI-compatible model list endpoint를 제공하는지 확인한다.
# server가 아직 loading 중이면 connection refused 또는 503 계열 응답이 날 수 있다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

curl -sS "${BASE_URL}/v1/models"
echo
