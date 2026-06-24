#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 챕터 4 vLLM 실습을 시작하기 전에 실행 환경을 확인한다.
#
# 챕터 4의 server는 host Python이 아니라 Docker container 안에서 실행한다.
# 그래서 server 실행에 필요한 핵심은 Docker, NVIDIA GPU, NVIDIA Container Toolkit이다.
#
# 반대로 OpenAI SDK client 실습은 host Python에서 실행한다.
# 그래서 python3와 pip도 함께 확인한다.

echo "## Working directory"
pwd

echo
echo "## Docker CLI"
if command -v docker >/dev/null 2>&1; then
  docker --version
else
  echo "docker: not found"
  echo "hint: vLLM Docker server를 실행하려면 Docker가 필요하다."
fi

echo
echo "## Docker daemon"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "docker daemon: reachable"
else
  echo "docker daemon: not reachable"
  echo "hint: Docker Desktop/Engine이 켜져 있는지, 현재 user가 Docker 권한을 갖는지 확인한다."
fi

echo
echo "## NVIDIA GPU on host"
if command -v nvidia-smi >/dev/null 2>&1; then
  # host에서 nvidia-smi가 보여야 GPU server 자체가 GPU를 인식한다고 볼 수 있다.
  nvidia-smi
else
  echo "nvidia-smi: not found"
  echo "hint: 로컬에 GPU가 없다면 원격 GPU 서버에서 이 챕터를 실행한다."
fi

echo
echo "## Docker GPU passthrough command"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "Run this manually on a GPU server before vLLM if you want a container GPU test:"
  echo "docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi"
else
  echo "skip: Docker daemon is not reachable"
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

echo
echo "## Notes"
echo "- Server runtime: Docker container vllm/vllm-openai"
echo "- Client runtime: optional chapter-local .venv for OpenAI SDK"
echo "- Default model: Qwen/Qwen3-0.6B"
echo "- Served model name: qwen3-0.6b"
