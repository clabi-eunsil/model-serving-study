#!/usr/bin/env bash
set -euo pipefail

# results directory의 CSV 파일을 요약한다.
#
# benchmark는 raw result를 남기는 것이 중요하다.
# 하지만 raw CSV만 보면 실험 간 비교가 어렵기 때문에,
# 이 script는 각 CSV 파일에서 request 수, error 수, latency p50/p95,
# throughput을 한 줄 요약으로 정리한다.

python client/06_summarize_results.py "${RESULT_DIR:-results}"
