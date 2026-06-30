#!/usr/bin/env bash
set -euo pipefail

# NIM runtime 상태를 terminal에 출력한다.
#
# 자동 저장하지 않는다. 저장하려면:
#   bash scripts/09_collect_runtime_info.sh | tee results/nim_runtime_info.txt
#
# 볼 것:
# - nvidia-smi Memory-Usage: GPU memory가 거의 찼는지
# - nvidia-smi GPU-Util: GPU가 실제로 바쁜지
# - docker ps: NIM container가 Up 상태인지
# - docker logs: model loading 실패, license/auth error, OOM, worker crash

CONTAINER_NAME="${CONTAINER_NAME:-nim-llm-server}"

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
echo "## Recent NIM logs"
docker logs --tail 100 "${CONTAINER_NAME}" || true
