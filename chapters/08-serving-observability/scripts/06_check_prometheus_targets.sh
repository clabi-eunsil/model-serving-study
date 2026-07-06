#!/usr/bin/env bash
set -euo pipefail

# Prometheus가 model-server target을 scrape하고 있는지 확인한다.
#
# Prometheus UI에서는 Status > Targets 화면에서 볼 수 있다.
# 이 script는 Prometheus HTTP API를 사용해 terminal에서 target 상태를 확인한다.
#
# 읽는 법:
# - job="model-server"가 health="up"이면 FastAPI /metrics/ scrape가 성공한 것이다.
# - job="dcgm-exporter"는 GPU 선택 실습을 아직 실행하지 않았다면 down이어도 괜찮다.
#   GPU 서버에서 scripts/09_start_dcgm_exporter.sh를 실행한 뒤 up으로 바뀌는지 확인한다.

PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"

echo "## Prometheus targets"
echo "- model-server should be up."
echo "- dcgm-exporter can be down until the optional GPU exporter lab is started."
echo

curl -sS "${PROMETHEUS_URL}/api/v1/targets" | python3 -m json.tool
