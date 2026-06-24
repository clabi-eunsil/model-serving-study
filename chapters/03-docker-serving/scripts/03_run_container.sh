#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 CPU 기반 Docker container로 FastAPI 모델 서버를 실행한다.
# 터미널 1에서 실행하고, 터미널 2에서 curl로 호출한다.

IMAGE_NAME="model-serving-fastapi"
IMAGE_TAG="chapter-03"
CONTAINER_NAME="model-serving-fastapi"

# --rm: container 종료 시 자동 삭제
# --name: container 이름 지정
# -p 8000:8000: host 8000 port를 container 8000 port로 연결
# -v hf-cache:/root/.cache/huggingface: model cache를 Docker volume에 저장
# -e MODEL_NAME=...: container 안의 app이 사용할 Hugging Face model 이름
docker run --rm \
  --name "${CONTAINER_NAME}" \
  -p 8000:8000 \
  -v hf-cache:/root/.cache/huggingface \
  -e MODEL_NAME=sshleifer/tiny-gpt2 \
  "${IMAGE_NAME}:${IMAGE_TAG}"
