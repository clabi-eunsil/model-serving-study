#!/usr/bin/env bash
set -euo pipefail

# Prometheus에 PromQL query를 보내 주요 metric을 확인한다.
#
# Grafana dashboard를 보기 전에 Prometheus가 값을 실제로 저장하고 있는지
# terminal에서 빠르게 확인하는 용도다.
#
# Prometheus HTTP API의 instant query 결과는 보통 아래 형태다.
#   "value": [1783330203.128, "0"]
#
# 첫 번째 값은 Unix timestamp, 두 번째 값은 query 결과 숫자다.
# 즉 "0"이나 "NaN"이 실제로 해석해야 하는 값이다.
#
# 이 script의 rate query는 최근 1분 window를 본다.
# 그래서 scripts/07_generate_load.sh를 실행하지 않았거나, 실행한 지 오래 지났거나,
# Prometheus가 아직 scrape하기 전이면 0 또는 NaN이 나올 수 있다.
#
# 권장 순서:
#   bash scripts/07_generate_load.sh
#   sleep 6
#   bash scripts/08_query_prometheus.sh

PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"

query() {
  local title="$1"
  local description="$2"
  local expr="$3"
  echo
  echo "## ${title}"
  echo "${description}"
  echo "query: ${expr}"
  curl -sS --get "${PROMETHEUS_URL}/api/v1/query" \
    --data-urlencode "query=${expr}" | python3 -m json.tool
}

query \
  "Request rate" \
  "최근 1분 기준 초당 /generate 요청 수를 본다. traffic이 들어오는지 확인할 때 쓴다." \
  'sum(rate(model_server_requests_total[1m]))'

query \
  "Error rate" \
  "최근 1분 기준 초당 실패 요청 수를 본다. load script는 10번째마다 의도적 실패를 보내 이 값을 관찰할 수 있게 한다." \
  'sum(rate(model_server_requests_total{status="error"}[1m]))'

query \
  "Generated tokens/sec" \
  "최근 1분 기준 초당 생성 token 수를 본다. LLM workload 크기를 request 수보다 더 잘 보여준다." \
  'sum(rate(model_server_generated_tokens_total[1m]))'

query \
  "p95 request latency" \
  "최근 1분 latency histogram으로 p95 latency를 추정한다. 느린 쪽 5% 요청이 어느 정도 걸리는지 본다." \
  'histogram_quantile(0.95, sum(rate(model_server_request_latency_seconds_bucket[1m])) by (le))'

query \
  "In-flight requests" \
  "지금 이 순간 처리 중인 요청 수를 본다. 값이 계속 높으면 요청이 밀리거나 처리 시간이 길다는 신호일 수 있다." \
  'sum(model_server_in_flight_requests)'
