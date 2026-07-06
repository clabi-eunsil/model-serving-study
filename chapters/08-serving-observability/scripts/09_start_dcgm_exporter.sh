#!/usr/bin/env bash
set -euo pipefail

# DCGM exporter를 실행한다.
#
# 이 단계는 선택 실습이다.
# NVIDIA GPU, NVIDIA driver, NVIDIA Container Toolkit이 있는 서버에서 실행한다.
# 로컬에 GPU가 없으면 건너뛰어도 된다.

docker compose --profile gpu up -d dcgm-exporter

echo "DCGM exporter: http://127.0.0.1:9400/metrics"
echo "Prometheus target: dcgm-exporter:9400"
