#!/usr/bin/env bash
set -euo pipefail

# NIM image를 pull한다.
#
# NIM_IMAGE는 NGC catalog에서 확인한 image 이름과 tag를 넣는다.
# 아래 기본값은 실습용 예시다. 실제 실행 전 NGC catalog에서 최신 image/tag와 license를 확인한다.

NIM_IMAGE="${NIM_IMAGE:-nvcr.io/nim/meta/llama-3.1-8b-instruct:latest}"

echo "Pulling NIM image: ${NIM_IMAGE}"
docker pull "${NIM_IMAGE}"
