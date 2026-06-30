#!/usr/bin/env bash
set -euo pipefail

# NIM container를 실행한다.
#
# 이 script는 NIM image를 "모델 서버 container"로 실행한다.
# image 이름, port, cache path는 NIM model page와 공식 문서를 우선한다.
#
# 실행 전 확인:
# - docker login nvcr.io가 되어 있는가?
# - NGC_API_KEY가 설정되어 있는가?
# - NIM_IMAGE가 NGC catalog에서 확인한 실제 image/tag인가?
# - host GPU와 Docker GPU passthrough가 정상인가?

CONTAINER_NAME="${CONTAINER_NAME:-nim-llm-server}"
NIM_IMAGE="${NIM_IMAGE:-nvcr.io/nim/meta/llama-3.1-8b-instruct:latest}"
PORT="${PORT:-8000}"
NIM_CACHE_DIR="${NIM_CACHE_DIR:-${HOME}/.cache/nim}"

if [[ -z "${NGC_API_KEY:-}" ]]; then
  echo "NGC_API_KEY is not set."
  echo "Run: export NGC_API_KEY=..."
  exit 1
fi

mkdir -p "${NIM_CACHE_DIR}"

echo "## Starting NIM container"
echo "container=${CONTAINER_NAME}"
echo "image=${NIM_IMAGE}"
echo "port=${PORT}"
echo "cache=${NIM_CACHE_DIR}"

# docker run 옵션 설명:
#
# --gpus all:
#   host GPU를 container에 전달한다.
#
# -p ${PORT}:8000:
#   host ${PORT}를 container 8000 port에 연결한다.
#   많은 NIM LLM container는 8000 port로 API server를 제공한다.
#
# -e NGC_API_KEY:
#   NIM container가 필요한 model artifact 접근에 사용할 수 있도록 API key를 전달한다.
#
# -v ${NIM_CACHE_DIR}:/opt/nim/.cache:
#   NIM cache를 host directory에 보존한다.
#   정확한 cache path는 NIM image 문서를 우선한다.
#
# --shm-size=16g:
#   ML container에서 shared memory 부족 문제를 줄이기 위한 설정이다.
#   필요한 값은 model/container에 따라 달라질 수 있다.
docker run --rm \
  --gpus all \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:8000" \
  -e "NGC_API_KEY=${NGC_API_KEY}" \
  -v "${NIM_CACHE_DIR}:/opt/nim/.cache" \
  --shm-size=16g \
  "${NIM_IMAGE}"
