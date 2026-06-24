#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 현재 디렉터리의 Dockerfile로 모델 서버 image를 만든다.
# image 이름과 tag는 이후 docker run/docker compose에서 재사용한다.

IMAGE_NAME="model-serving-fastapi"
IMAGE_TAG="chapter-03"

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .

echo "Built image: ${IMAGE_NAME}:${IMAGE_TAG}"
