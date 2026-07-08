#!/usr/bin/env bash
set -euo pipefail

# 챕터 13 실습에서 띄운 container를 정리한다.

for name in chapter13-quantized-vllm chapter13-lora-vllm chapter13-nginx-rate-limit; do
  docker rm -f "${name}" >/dev/null 2>&1 || true
done

echo "chapter 13 containers cleanup requested."
