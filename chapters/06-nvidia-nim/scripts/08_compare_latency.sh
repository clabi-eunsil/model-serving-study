#!/usr/bin/env bash
set -euo pipefail

# 같은 prompt를 NIM endpoint에 여러 번 보내 간단한 latency를 본다.
#
# 목적:
# - vLLM 챕터에서 사용한 prompt와 비슷한 요청을 NIM에도 보내본다.
# - production-grade benchmark가 아니라 "비교 실험을 어떻게 시작하는지"를 보는 용도다.
#
# 결과는 terminal에 출력한다. 저장하려면:
#   bash scripts/08_compare_latency.sh | tee results/nim_latency.txt

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
NIM_MODEL="${NIM_MODEL:-meta/llama-3.1-8b-instruct}"
REQUESTS="${REQUESTS:-5}"

mkdir -p results

for i in $(seq 1 "${REQUESTS}"); do
  started_ns="$(date +%s%N)"
  curl -sS "${BASE_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${NIM_MODEL}\",
      \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"Explain model serving latency in one short Korean paragraph.\"
        }
      ],
      \"max_tokens\": 128,
      \"temperature\": 0.2
    }" >/tmp/nim_latency_response.json
  ended_ns="$(date +%s%N)"
  elapsed_ms=$(( (ended_ns - started_ns) / 1000000 ))
  echo "request=${i} elapsed_ms=${elapsed_ms}"
done

echo "last_response=/tmp/nim_latency_response.json"
