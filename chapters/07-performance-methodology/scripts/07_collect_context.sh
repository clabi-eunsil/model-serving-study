#!/usr/bin/env bash
set -euo pipefail

# benchmark 결과를 해석할 때 같이 봐야 하는 최소 context를 모은다.
#
# 이 script는 Prometheus/Grafana 같은 정식 observability 구성이 아니다.
# 그런 내용은 다음 챕터에서 더 자세히 다룬다.
#
# 여기서는 "latency 숫자만 보고 끝내지 않기" 위해 아래 정보를 한 번에 확인한다.
# - benchmark target: BASE_URL, MODEL_NAME
# - endpoint 상태: /v1/models 응답
# - GPU 상태: nvidia-smi
# - Docker container 상태: docker ps
# - server log 일부: docker logs --tail
#
# 사용 예:
#   CONTAINER_NAME=vllm-intro-server bash scripts/07_collect_context.sh | tee results/context_vllm_intro.txt
#   CONTAINER_NAME=vllm-performance-server bash scripts/07_collect_context.sh | tee results/context_vllm_tuned.txt
#   CONTAINER_NAME=nim-llm-server bash scripts/07_collect_context.sh | tee results/context_nim.txt

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/v1}"
MODEL_NAME="${MODEL_NAME:-qwen3-0.6b}"
CONTAINER_NAME="${CONTAINER_NAME:-}"

mkdir -p results

echo "## Benchmark target"
echo "timestamp=$(date -Is)"
echo "BASE_URL=${BASE_URL}"
echo "MODEL_NAME=${MODEL_NAME}"
echo "CONTAINER_NAME=${CONTAINER_NAME:-not set}"

echo
echo "## Endpoint /models"
curl -sS "${BASE_URL}/models" || true
echo

echo
echo "## GPU snapshot"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## Docker containers"
if command -v docker >/dev/null 2>&1; then
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
else
  echo "docker: not found"
fi

echo
echo "## Recent server logs"
if [[ -n "${CONTAINER_NAME}" ]] && command -v docker >/dev/null 2>&1; then
  docker logs --tail "${LOG_TAIL:-120}" "${CONTAINER_NAME}" || true
else
  echo "Set CONTAINER_NAME to collect logs."
  echo "Examples: vllm-intro-server, vllm-performance-server, nim-llm-server"
fi
