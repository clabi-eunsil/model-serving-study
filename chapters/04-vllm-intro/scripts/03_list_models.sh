#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 vLLM OpenAI-compatible server가 준비되었는지 확인한다.
#
# /v1/models는 server가 현재 어떤 model 이름을 API에 노출하는지 보여준다.
# scripts/02_run_vllm_docker.sh에서 --served-model-name qwen3-0.6b로 실행했다면,
# 응답 안에 qwen3-0.6b가 보여야 한다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

echo "## GET ${BASE_URL}/v1/models"
curl -sS "${BASE_URL}/v1/models"
echo
