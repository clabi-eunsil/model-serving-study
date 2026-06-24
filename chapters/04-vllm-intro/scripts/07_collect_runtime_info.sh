#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 vLLM server를 실행한 뒤 runtime 정보를 기록하기 위한 도구다.
#
# 실습이 "요청이 성공했다"에서 끝나면 나중에 비교할 자산이 남지 않는다.
# 그래서 어떤 image, model, container, GPU memory 상태에서 실행했는지 함께 남긴다.

CONTAINER_NAME="${CONTAINER_NAME:-vllm-intro-server}"

echo "## Docker container"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo
echo "## Docker image"
docker images vllm/vllm-openai --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"

echo
echo "## GPU memory"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## Recent vLLM logs"
# docker logs --tail:
#   server 시작 옵션, model loading, error 등을 빠르게 확인한다.
#   전체 log가 길 수 있으므로 최근 80줄만 본다.
docker logs --tail 80 "${CONTAINER_NAME}" || true
