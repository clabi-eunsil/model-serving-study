#!/usr/bin/env bash
set -euo pipefail

# 챕터 5는 vLLM 성능을 측정하는 실습이다.
#
# server는 Docker container에서 실행하고, benchmark client는 Python .venv에서 실행한다.
# 그래서 Docker/GPU 상태와 Python client 환경을 함께 확인한다.

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
echo "## GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi: not found"
  echo "hint: vLLM 성능 실습은 GPU 서버에서 진행하는 것을 권장한다."
fi

echo
echo "## Client tools"
if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "python3: not found"
fi

if command -v curl >/dev/null 2>&1; then
  curl --version | head -n 1
else
  echo "curl: not found"
fi

echo
echo "## Expected server endpoint"
echo "http://127.0.0.1:8000/v1"
