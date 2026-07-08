#!/usr/bin/env bash
set -euo pipefail

# tensor parallelism과 pipeline parallelism을 언제 쓰는지 설명하고,
# 현재 GPU 개수 기준으로 vLLM 실행 옵션 예시를 보여준다.
# 이 스크립트는 실제 server를 띄우지 않는다.

GPU_COUNT="unknown"
if command -v nvidia-smi >/dev/null 2>&1; then
  GPU_COUNT="$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l | tr -d ' ')"
fi

echo "== GPU count =="
echo "${GPU_COUNT}"
echo

cat <<'TEXT'
== 선택 기준 ==

1. 모델이 GPU 1장에 들어간다
   - distributed inference가 필요하지 않을 수 있다.
   - 예: vllm serve <model>

2. 모델이 GPU 1장에는 안 들어가지만, 한 node의 여러 GPU에는 들어간다
   - tensor parallelism을 먼저 고려한다.
   - 예: vllm serve <model> --tensor-parallel-size 4

3. 모델이 한 node에도 안 들어가서 여러 node가 필요하다
   - tensor parallelism + pipeline parallelism 조합을 고려한다.
   - 예: 2 nodes x 8 GPUs
     vllm serve <model> --tensor-parallel-size 8 --pipeline-parallel-size 2

4. GPU 간 통신이 느리거나 NVLINK가 없다
   - tensor parallelism의 통신 비용이 커질 수 있다.
   - 모델 구조와 hardware에 따라 pipeline parallelism이 나을 수 있다.
TEXT

echo
echo "== 현재 환경 기준 예시 =="
if [[ "${GPU_COUNT}" =~ ^[0-9]+$ && "${GPU_COUNT}" -gt 1 ]]; then
  echo "vllm serve <model> --tensor-parallel-size ${GPU_COUNT}"
else
  echo "GPU가 1개 이하이거나 확인되지 않았다. 먼저 단일 GPU 실행부터 확인한다."
fi
