#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
PROMPT="${PROMPT:-Kubernetes model serving in one sentence}"
MAX_NEW_TOKENS="${MAX_NEW_TOKENS:-32}"

echo "## Health"
curl -sS "${BASE_URL}/health"
echo
echo

echo "## Generate"
curl -sS -X POST "${BASE_URL}/generate" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"${PROMPT}\",\"max_new_tokens\":${MAX_NEW_TOKENS}}"
echo

