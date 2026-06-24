#!/usr/bin/env bash
set -uo pipefail

# 이 스크립트는 Docker 기반 실습 전에 현재 환경을 확인한다.
# Docker command가 보이지 않으면 image build와 container run을 진행할 수 없다.

echo "## Docker"
if command -v docker >/dev/null 2>&1 && docker --version; then
  :
elif command -v docker >/dev/null 2>&1; then
  echo "docker command exists, but it is not usable in this shell."
  echo "hint: Docker Desktop WSL integration 또는 Docker Engine 설치 상태를 확인한다."
else
  echo "docker: not found"
  echo "hint: Docker Desktop WSL integration 또는 Docker Engine 설치 상태를 확인한다."
fi

echo
echo "## Docker Compose"
if command -v docker >/dev/null 2>&1 && docker compose version; then
  :
else
  echo "docker compose: not available"
fi

echo
echo "## Docker daemon"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "docker daemon: reachable"
else
  echo "docker daemon: not reachable"
fi

echo
echo "## NVIDIA GPU from host"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## NVIDIA GPU from Docker"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "To test GPU container support, run:"
  echo "docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi"
else
  echo "skip: Docker daemon is not reachable"
fi
