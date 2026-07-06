#!/usr/bin/env bash
set -euo pipefail

# 관측할 metric을 만들기 위해 여러 요청을 보낸다.
#
# Prometheus/Grafana는 data가 쌓여야 그래프가 보인다.
# 이 script는 성공 요청과 실패 요청을 섞어서 request rate, error count,
# latency histogram 변화를 확인할 수 있게 만든다.

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
REQUESTS="${REQUESTS:-30}"

for i in $(seq 1 "${REQUESTS}"); do
  if (( i % 10 == 0 )); then
    # 10번째마다 의도적 실패를 보내 error metric을 만든다.
    curl -sS "${BASE_URL}/generate" \
      -H "Content-Type: application/json" \
      -d '{"prompt": "force one error", "max_new_tokens": 8, "fail": true}' >/dev/null || true
  else
    curl -sS "${BASE_URL}/generate" \
      -H "Content-Type: application/json" \
      -d "{
        \"prompt\": \"Request ${i}: explain model serving metrics in Korean.\",
        \"max_new_tokens\": $((16 + (i % 5) * 8))
      }" >/dev/null
  fi
  echo "sent request ${i}/${REQUESTS}"
done

echo
echo "Load generation finished."
echo "Prometheus scrapes every 5 seconds in this chapter."
echo "Wait a few seconds before running:"
echo "  bash scripts/08_query_prometheus.sh"
