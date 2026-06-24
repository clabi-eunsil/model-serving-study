#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 원격 GPU 서버에 접속한 뒤 실행하는 점검용 스크립트다.
#
# 사용 상황:
# - 로컬 노트북/PC에는 GPU가 없다.
# - SSH로 접속 가능한 별도 GPU 서버가 있다.
# - 챕터 3 디렉터리만 GPU 서버로 복사해서 Docker GPU 실습을 하고 싶다.
#
# 실행 위치:
#   GPU 서버 안의 ~/model-serving/chapters/03-docker-serving
#
# 이 스크립트가 하지 않는 것:
# - NVIDIA driver를 설치하지 않는다.
# - Docker를 설치하지 않는다.
# - NVIDIA Container Toolkit을 설치하지 않는다.
# - image build나 container 실행을 하지 않는다.
#
# 이 스크립트가 하는 것:
# - 지금 내가 어떤 서버에 접속했는지 확인한다.
# - 현재 디렉터리가 챕터 3 실습 디렉터리인지 확인한다.
# - host에서 GPU가 보이는지 nvidia-smi로 확인한다.
# - Docker CLI가 있는지 확인한다.
# - Docker daemon에 현재 user가 접근 가능한지 확인한다.
# - Docker 안에서 GPU를 확인하는 명령어를 안내한다.

echo "## Host"
# hostname:
#   SSH로 접속한 서버가 맞는지 확인한다.
#   여러 서버를 쓰는 환경에서는 의외로 중요한 확인 단계다.
hostname

echo
echo "## Working directory"
# pwd:
#   Docker build context가 되는 현재 디렉터리를 확인한다.
#   Dockerfile, app/, requirements.txt가 있는 챕터 3 디렉터리에서 실행해야 한다.
pwd

echo
echo "## NVIDIA driver / GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  # nvidia-smi:
  #   host OS에서 NVIDIA driver와 GPU가 정상적으로 보이는지 확인한다.
  #   여기서 실패하면 Docker GPU 실습 전에 host driver부터 확인해야 한다.
  nvidia-smi
else
  echo "nvidia-smi: not found"
  echo "hint: GPU driver가 설치되어 있는지 확인한다."
fi

echo
echo "## Docker"
if command -v docker >/dev/null 2>&1; then
  # docker --version:
  #   Docker CLI가 설치되어 있는지 확인한다.
  #   CLI가 있어도 daemon 접근 권한은 별도이므로 아래 docker info도 확인한다.
  docker --version
else
  echo "docker: not found"
fi

echo
echo "## Docker daemon"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  # docker info:
  #   Docker daemon과 통신이 되는지 확인한다.
  #   여기서 실패하면 Docker service가 꺼져 있거나 현재 user 권한 문제가 있을 수 있다.
  echo "docker daemon: reachable"
else
  echo "docker daemon: not reachable"
  echo "hint: 현재 user가 docker group에 없거나 Docker daemon이 실행 중이 아닐 수 있다."
fi

echo
echo "## Docker GPU passthrough test"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  # 아래 명령은 실제로 CUDA base image를 pull하고 container 안에서 nvidia-smi를 실행한다.
  # 즉, "host에서 GPU가 보이는지"가 아니라 "container 안에서도 GPU가 보이는지"를 확인한다.
  #
  # image pull이 필요할 수 있으므로 여기서는 자동 실행하지 않고 명령어만 안내한다.
  # GPU 서버에서 직접 실행해 성공하면 scripts/07_run_container_gpu.sh로 넘어간다.
  echo "Run this command manually if you want to test GPU inside Docker:"
  echo "docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi"
else
  echo "skip: Docker daemon is not reachable"
fi
