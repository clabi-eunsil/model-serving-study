#!/usr/bin/env bash
set -euo pipefail

# sklearn iris model에 보낼 입력 JSON을 확인한다.
# KServe v1 protocol에서 predictive model은 보통 {"instances": [...]} 형태를 사용한다.

CHAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUEST_FILE="${REQUEST_FILE:-${CHAPTER_DIR}/data/iris-input.json}"

echo "Request file: ${REQUEST_FILE}"
cat "${REQUEST_FILE}"
echo
