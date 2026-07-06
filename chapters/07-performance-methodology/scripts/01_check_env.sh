#!/usr/bin/env bash
set -euo pipefail

# 챕터 7 실습 전 client 환경을 확인한다.
#
# 이 챕터는 server를 새로 띄우는 챕터가 아니다.
# vLLM 또는 NIM처럼 OpenAI-compatible endpoint가 이미 떠 있다고 가정하고,
# client 쪽에서 요청을 보내 latency/throughput/TTFT를 측정한다.
#
# 따라서 확인할 것은:
# - python3: benchmark client 실행에 필요
# - curl: endpoint 준비 상태와 model list 확인에 필요
# - 선택 도구: k6, locust, hey, wrk
# - BASE_URL/MODEL_NAME: 어떤 server를 칠지 결정하는 환경변수
#
# k6, locust, hey, wrk는 이 챕터의 필수 도구가 아니다.
# 처음 실습하는 환경에 설치되어 있지 않은 것이 정상이다.
# 이 챕터의 기본 실습은 client/03_openai_benchmark.py만 사용한다.
# 아래 optional tool check는 "나중에 일반 HTTP 부하 도구도 비교할 수 있다"는 안내용이다.

echo "## Working directory"
pwd

echo
echo "## Python"
if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "python3: not found"
fi

echo
echo "## curl"
if command -v curl >/dev/null 2>&1; then
  curl --version | head -n 1
else
  echo "curl: not found"
fi

echo
echo "## Optional load testing tools"
echo "These tools are optional. It is OK if they are not installed yet."
for tool in k6 locust hey wrk; do
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "${tool}: installed"
  else
    echo "${tool}: not found (optional)"
  fi
done

echo
echo "## Target endpoint"
echo "BASE_URL=${BASE_URL:-http://127.0.0.1:8000/v1}"
echo "MODEL_NAME=${MODEL_NAME:-qwen3-0.6b}"

echo
echo "## Endpoint quick check"
echo "If a server is running, this should return a model list or an HTTP error from that server."
curl -sS "${BASE_URL:-http://127.0.0.1:8000/v1}/models" || true
echo
