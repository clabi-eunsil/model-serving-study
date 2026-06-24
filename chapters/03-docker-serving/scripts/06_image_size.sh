#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 Docker image size를 확인하고, 어떤 layer가 큰지 살펴보는 실습이다.
#
# 모델 서빙 image는 일반 web app image보다 커지기 쉽다.
# 이유는 torch, transformers 같은 ML dependency가 크고, 모델 weight까지 image 안에 넣으면
# image build와 pull/push가 매우 느려질 수 있기 때문이다.
#
# 이 챕터의 Dockerfile은 모델 weight를 image에 넣지 않는다.
# 대신 container 실행 시 hf-cache volume을 /root/.cache/huggingface에 붙여서
# 다운로드된 model cache를 재사용한다.
#
# 이 스크립트에서 확인할 것:
# - 최종 image가 얼마나 큰가?
# - docker history에서 어떤 layer가 큰가?
# - pip install layer가 큰가?
# - Dockerfile이나 requirements.txt에서 줄일 수 있는 부분이 있는가?

IMAGE_NAME="model-serving-fastapi"
IMAGE_TAG="chapter-03"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "## Image size"
# docker images:
#   local Docker에 저장된 image 목록을 보여준다.
# --format:
#   repository, tag, size만 보이도록 출력 형식을 줄인다.
docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo
echo "## Image inspect size in bytes"
# docker image inspect:
#   image metadata를 JSON 형태로 보여준다.
# --format='{{.Size}} bytes':
#   전체 metadata 중 Size 값만 뽑는다.
#   bytes 단위라서 docker images의 MB/GB 출력보다 정확한 비교에 유용하다.
docker image inspect "${IMAGE}" --format='{{.Size}} bytes'

echo
echo "## Largest layers"
# docker history:
#   Dockerfile의 각 instruction이 만든 layer를 보여준다.
# --human:
#   size를 사람이 읽기 쉬운 단위로 출력한다.
# --no-trunc:
#   command가 잘리지 않게 출력한다.
# head -n 15:
#   너무 긴 출력을 피하고 상위 일부만 확인한다.
#
# 여기서 큰 layer가 보이면 Dockerfile에서 어떤 instruction이 image size를 키웠는지
# 추적할 수 있다. 예를 들어 RUN pip install layer가 크다면 requirements.txt를 본다.
docker history --human --no-trunc "${IMAGE}" | head -n 15

echo
echo "## Things to check when reducing image size"
echo "- .dockerignore excludes .venv, __pycache__, cache files"
echo "- pip install uses --no-cache-dir"
echo "- requirements.txt does not include unused packages"
echo "- large ML packages such as torch dominate the image size"
echo "- model weights are kept in a volume instead of baked into the image"
