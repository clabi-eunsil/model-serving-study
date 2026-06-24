#!/usr/bin/env bash
set -euo pipefail

# benchmark 전후의 GPU와 vLLM container 상태를 기록한다.
#
# 숫자만 보고 해석하면 위험하다.
# concurrency를 올렸는데 latency가 나빠졌다면 GPU memory, GPU utilization,
# server log의 preemption/OOM warning도 함께 봐야 한다.

CONTAINER_NAME="${CONTAINER_NAME:-vllm-perf-server}"

echo "## GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## Docker container"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo
echo "## Recent vLLM logs"
docker logs --tail 80 "${CONTAINER_NAME}" || true
