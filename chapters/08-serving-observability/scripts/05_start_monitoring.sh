#!/usr/bin/env bash
set -euo pipefail

# Prometheus와 Grafana를 Docker Compose로 실행한다.
#
# Prometheus:
# - monitoring/prometheus/prometheus.yml 설정을 읽는다.
# - host의 FastAPI /metrics endpoint를 scrape한다.
#
# Grafana:
# - monitoring/grafana/provisioning 아래 datasource/dashboard 설정을 자동 로딩한다.
# - http://127.0.0.1:3000 에서 admin/admin으로 접속한다.
#
# image pull 단계에서 아래 에러가 나오면 Docker credential helper 문제일 수 있다.
#   error getting credentials - ... docker-credential-desktop.exe: exec format error
#
# 이 챕터의 Prometheus/Grafana image는 public image라 login이 꼭 필요하지 않다.
# WSL의 ~/.docker/config.json에서 깨진 credsStore 설정을 제거하면 해결되는 경우가 많다.
# 자세한 내용은 README의 troubleshooting을 본다.

docker compose up -d prometheus grafana

echo "Prometheus: http://127.0.0.1:9090"
echo "Grafana:    http://127.0.0.1:3000  (admin/admin)"
