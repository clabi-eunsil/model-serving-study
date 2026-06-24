#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 GPU를 container에 전달해서 모델 서버를 실행하는 실습이다.
#
# CPU container와 다른 점:
# - docker run에 --gpus all 옵션이 추가된다.
# - host에 NVIDIA driver가 설치되어 있어야 한다.
# - Docker가 GPU를 container로 넘길 수 있도록 NVIDIA Container Toolkit이 설정되어 있어야 한다.
#
# 먼저 확인할 것:
# - host에서 nvidia-smi가 실행되는가?
# - docker run --rm --gpus all nvidia/cuda:... nvidia-smi 가 실행되는가?
# - scripts/02_build_image.sh로 model-serving-fastapi:chapter-03 image를 build했는가?
#
# GPU가 보이지 않는 환경에서는 이 파일 대신 scripts/03_run_container.sh를 사용한다.
#
# 이 스크립트는 docker login을 수행하지 않는다.
# 현재 실습 image는 로컬에서 build한 image이므로 기본적으로 registry login이 필요 없다.
# NGC/NIM image나 private image를 pull할 때는 README의 registry login 안내를 먼저 따른다.

IMAGE_NAME="model-serving-fastapi"
IMAGE_TAG="chapter-03"
CONTAINER_NAME="model-serving-fastapi-gpu"

# docker run 옵션 설명:
#
# --rm:
#   container가 종료되면 container 기록을 자동 삭제한다.
#   실습 중 같은 이름의 container가 남아 충돌하는 일을 줄인다.
#
# --gpus all:
#   host에서 사용 가능한 GPU를 container에 전달한다.
#   이 옵션이 동작하려면 NVIDIA Container Toolkit이 필요하다.
#
# --name:
#   container 이름을 지정한다. 나중에 docker stop으로 종료할 때 편하다.
#
# -p 8000:8000:
#   host의 8000 port를 container의 8000 port에 연결한다.
#   그래서 host나 SSH port forwarding을 통해 http://127.0.0.1:8000으로 접근할 수 있다.
#
# -v hf-cache:/root/.cache/huggingface:
#   Hugging Face model cache를 named volume에 저장한다.
#   container를 다시 실행해도 모델 다운로드 결과를 재사용하기 위해서다.
#
# -e MODEL_NAME=...:
#   app/main.py가 os.getenv("MODEL_NAME", ...)으로 읽는 모델 이름을 설정한다.
docker run --rm \
  --gpus all \
  --name "${CONTAINER_NAME}" \
  -p 8000:8000 \
  -v hf-cache:/root/.cache/huggingface \
  -e MODEL_NAME=sshleifer/tiny-gpt2 \
  "${IMAGE_NAME}:${IMAGE_TAG}"
