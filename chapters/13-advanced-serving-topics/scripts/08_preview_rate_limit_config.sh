#!/usr/bin/env bash
set -euo pipefail

# rate limiting과 demo API key check를 담은 nginx 설정을 읽어보는 스크립트다.
# 실제 실행 전 "어떤 줄이 무슨 역할인지"를 먼저 이해하기 위한 단계다.

CONFIG="${CONFIG:-config/nginx-rate-limit.conf}"

echo "== ${CONFIG} =="
sed -n '1,220p' "${CONFIG}"

echo
echo "볼 부분:"
echo "- limit_req_zone: 요청 횟수를 어떤 key 기준으로 셀지 정한다."
echo "- limit_req: 특정 location에 rate limit을 적용한다."
echo "- Authorization header check: 학습용으로만 둔 단순 API key 확인이다."
echo "- proxy_pass: 실제 model server로 요청을 넘긴다."
