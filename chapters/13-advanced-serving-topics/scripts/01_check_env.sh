#!/usr/bin/env bash
set -euo pipefail

# 챕터 13은 GPU 서버에서 실행해야 의미 있는 실습이 많다.
# 이 스크립트는 "지금 이 환경에서 어떤 실습까지 가능한지"를 빠르게 확인한다.
# Docker, GPU, nvidia-smi, curl, jq가 있는지 보고, 없으면 어떤 부분이 제한되는지 알려준다.

echo "== command check =="
for cmd in docker curl python3; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "OK: ${cmd} -> $(command -v "${cmd}")"
  else
    echo "MISSING: ${cmd}"
  fi
done

if command -v jq >/dev/null 2>&1; then
  echo "OK: jq -> $(command -v jq)"
else
  echo "OPTIONAL: jq가 없다. JSON pretty print는 python3 -m json.tool로 대체한다."
fi

echo
echo "== docker =="
if command -v docker >/dev/null 2>&1; then
  docker version --format 'Client={{.Client.Version}} Server={{.Server.Version}}' || true
else
  echo "Docker가 없으면 vLLM container 실습은 실행할 수 없다."
fi

echo
echo "== GPU =="
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
else
  echo "nvidia-smi가 없다. GPU 실습은 원격 GPU 서버에서 진행하는 것을 권장한다."
fi

echo
echo "== current containers =="
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' 2>/dev/null || true

echo
echo "환경 확인 완료."
