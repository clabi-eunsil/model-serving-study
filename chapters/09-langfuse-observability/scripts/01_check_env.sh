#!/usr/bin/env bash
set -euo pipefail

# 챕터 9 실습 환경을 확인한다.
#
# Langfuse는 cloud 또는 self-hosted server가 필요하고,
# Python script는 Langfuse SDK와 OpenAI SDK를 사용한다.
# 이 스크립트는 "지금 바로 trace를 보낼 준비가 됐는지"를 빠르게 점검한다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAPTER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 사용자가 `.env.example`을 복사해 `.env`에 key를 넣었다면,
# shell에 직접 export하지 않아도 이 스크립트가 먼저 읽어 온다.
# 주의: `.env`는 shell 문법 형태(KEY=value)여야 한다.
if [[ -f "${CHAPTER_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${CHAPTER_DIR}/.env"
  set +a
  echo "Loaded .env from ${CHAPTER_DIR}/.env"
else
  echo "No .env file found. Dry-run is still available."
fi

echo
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

echo "LANGFUSE_BASE_URL=${LANGFUSE_BASE_URL:-not set}"
echo "LANGFUSE_HOST=${LANGFUSE_HOST:-not set} (legacy/fallback)"

echo
echo "## OpenAI-compatible endpoint variables"
echo "OPENAI_BASE_URL=${OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}"
echo "OPENAI_MODEL=${OPENAI_MODEL:-study-model}"

echo
echo "If Langfuse keys are not set, use dry-run scripts first."
