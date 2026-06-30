#!/usr/bin/env bash
set -euo pipefail

# benchmark 전후의 GPU와 vLLM container 상태를 기록한다.
#
# 숫자만 보고 해석하면 위험하다.
# concurrency를 올렸는데 latency가 나빠졌다면 GPU memory, GPU utilization,
# server log의 preemption/OOM warning도 함께 봐야 한다.
#
# 이 script는 파일에 자동 저장하지 않고 terminal에 출력한다.
# 필요한 내용은 lab notes에 복사하거나, 원하면 아래처럼 직접 파일로 저장한다.
#
#   bash scripts/07_collect_gpu_metrics.sh | tee results/gpu_metrics_after_c4.txt
#
# nvidia-smi에서 볼 것:
# - Memory-Usage:
#   GPU memory가 얼마나 찼는지 본다. 거의 꽉 찼다면 OOM 위험이 있다.
# - GPU-Util:
#   GPU 계산 유닛이 얼마나 바쁜지 본다. 낮으면 CPU/network/waiting 병목일 수 있다.
# - Processes:
#   vLLM/python process가 GPU memory를 쓰고 있는지 본다.
#
# docker ps에서 볼 것:
# - vllm-perf-server container가 계속 Up 상태인지 확인한다.
# - 재시작되었거나 없으면 benchmark 숫자를 믿기 어렵다.
#
# docker logs에서 볼 것:
# - OutOfMemoryError, CUDA out of memory, OOM
# - preemption, recompute, cache 부족 관련 warning
# - model loading 실패
# - request error나 worker crash
#
# 이런 메시지가 보이면 benchmark 결과보다 원인 분석이 먼저다.

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
