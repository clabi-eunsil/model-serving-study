#!/usr/bin/env bash
set -euo pipefail

# NIM 실습 전 host 환경을 확인한다.
#
# NIM server는 Docker container로 실행된다.
# 따라서 Docker daemon, NVIDIA GPU, NVIDIA Container Toolkit 상태가 중요하다.
# OpenAI SDK client 실습도 있으므로 python3/curl도 함께 확인한다.

echo "## Working directory"
pwd

echo
echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  docker --version
else
  echo "docker: not found"
fi

echo
echo "## Docker daemon"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "docker daemon: reachable"
else
  echo "docker daemon: not reachable"
fi

echo
echo "## NVIDIA GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
fi

echo
echo "## NGC_API_KEY"
if [[ -n "${NGC_API_KEY:-}" ]]; then
  echo "NGC_API_KEY: set"
else
  echo "NGC_API_KEY: not set"
  echo "hint: export NGC_API_KEY=... before NGC login or NIM container run"
fi

echo
echo "## Client tools"
if command -v curl >/dev/null 2>&1; then
  curl --version | head -n 1
else
  echo "curl: not found"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "python3: not found"
fi
