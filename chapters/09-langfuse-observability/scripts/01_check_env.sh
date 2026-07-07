#!/usr/bin/env bash
set -euo pipefail

# 챕터 9 실습 환경을 확인한다.
#
# Langfuse는 cloud 또는 self-hosted server가 필요하고,
# Python script는 Langfuse SDK와 OpenAI SDK를 사용한다.
# 이 스크립트는 "지금 바로 trace를 보낼 준비가 됐는지"를 빠르게 점검한다.

echo "## Python"
python3 --version

echo
echo "## Python packages"
python3 - <<'PY'
from importlib import metadata

packages = ["langfuse", "openai", "requests", "python-dotenv"]

for package in packages:
    try:
        print(f"{package}: {metadata.version(package)}")
    except metadata.PackageNotFoundError:
        print(f"{package}: not installed")
PY

echo
echo "## Langfuse environment variables"
if [[ -n "${LANGFUSE_PUBLIC_KEY:-}" ]]; then
  echo "LANGFUSE_PUBLIC_KEY: set"
else
  echo "LANGFUSE_PUBLIC_KEY: not set"
fi

if [[ -n "${LANGFUSE_SECRET_KEY:-}" ]]; then
  echo "LANGFUSE_SECRET_KEY: set"
else
  echo "LANGFUSE_SECRET_KEY: not set"
fi

echo "LANGFUSE_HOST=${LANGFUSE_HOST:-not set}"

echo
echo "## OpenAI-compatible endpoint variables"
echo "OPENAI_BASE_URL=${OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}"
echo "OPENAI_MODEL=${OPENAI_MODEL:-study-model}"

echo
echo "If Langfuse keys are not set, use dry-run scripts first."
