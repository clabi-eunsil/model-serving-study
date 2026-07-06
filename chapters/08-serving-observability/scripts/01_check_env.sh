#!/usr/bin/env bash
set -euo pipefail

# 챕터 8 실습 전 환경을 확인한다.
#
# 이 챕터는 두 종류의 실행 환경을 함께 사용한다.
# - FastAPI model server: chapter별 .venv에서 host process로 실행
# - Prometheus/Grafana/DCGM exporter: Docker Compose로 실행
#
# GPU가 없는 로컬 환경에서도 FastAPI + Prometheus + Grafana 실습은 가능하다.
# DCGM exporter는 NVIDIA GPU와 NVIDIA Container Toolkit이 있는 서버에서만 의미가 있다.

echo "## Working directory"
pwd

echo
echo "## Python"
if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "python3: not found"
fi

echo
echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
else
  echo "docker: not found"
fi

echo
echo "## Docker Compose"
if docker compose version >/dev/null 2>&1; then
  docker compose version
else
  echo "docker compose: not available"
fi

echo
echo "## GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found (OK for non-GPU parts of this chapter)"
fi

echo
echo "## Ports used in this chapter"
echo "FastAPI model server: http://127.0.0.1:8000"
echo "Prometheus:          http://127.0.0.1:9090"
echo "Grafana:             http://127.0.0.1:3000"
echo "DCGM exporter:       http://127.0.0.1:9400 (GPU optional)"
