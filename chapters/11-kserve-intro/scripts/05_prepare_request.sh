#!/usr/bin/env bash
set -euo pipefail

# sklearn iris model에 보낼 입력 JSON을 눈으로 확인한다.
#
# 이 스크립트는 서버에 요청을 보내지 않는다.
# 07_curl_predict.sh가 실제 요청을 보내기 전에,
# "어떤 파일을 보낼지", "JSON 모양이 맞는지", "instances 안에 어떤 값이 들어가는지"를
# 확인하기 위한 준비 단계다.
#
# KServe v1 protocol에서 sklearn 같은 predictive model은 보통 아래 형태를 사용한다.
# {
#   "instances": [
#     [feature1, feature2, feature3, feature4]
#   ]
# }
#
# iris 예제의 feature 4개는 꽃받침 길이, 꽃받침 너비, 꽃잎 길이, 꽃잎 너비에 해당한다.
# 이 값들을 모델에 넣으면 sklearn model server가 iris 품종 class를 예측한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUEST_FILE="${REQUEST_FILE:-${CHAPTER_DIR}/data/iris-input.json}"

echo "Request file: ${REQUEST_FILE}"
cat "${REQUEST_FILE}"
echo
