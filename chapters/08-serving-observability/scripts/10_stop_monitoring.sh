#!/usr/bin/env bash
set -euo pipefail

# Prometheus, Grafana, DCGM exporter container를 종료한다.
#
# FastAPI model server는 터미널에서 Ctrl+C로 종료한다.

docker compose --profile gpu down
