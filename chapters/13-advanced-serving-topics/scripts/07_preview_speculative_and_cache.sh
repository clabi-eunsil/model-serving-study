#!/usr/bin/env bash
set -euo pipefail

# speculative decoding, prefix cache, response cache 차이를 명령 예시로 정리한다.
# 실제 실행은 모델 조합과 vLLM version에 따라 달라지므로 preview 성격의 스크립트다.

cat <<'TEXT'
== Speculative decoding ==

목표:
  decode 단계에서 token을 하나씩만 만들지 말고,
  draft model 또는 n-gram 같은 proposer가 후보 token을 먼저 제안하게 한다.
  target model은 후보 token을 검증한다.

vLLM 예시:
  vllm serve <target-model> \
    --speculative-config '{
      "method": "draft_model",
      "model": "<draft-model>",
      "num_speculative_tokens": 5
    }'

가벼운 n-gram 예시:
  vllm serve <target-model> \
    --speculative-config '{
      "method": "ngram",
      "num_speculative_tokens": 4,
      "prompt_lookup_min": 2,
      "prompt_lookup_max": 5
    }'

관찰할 것:
  - TTFT보다 inter-token latency와 total generation latency가 줄어드는지
  - QPS가 높을 때도 이득이 유지되는지
  - target model과 draft model이 둘 다 올라갈 GPU memory가 있는지

== Prompt / prefix cache ==

목표:
  여러 요청이 같은 앞부분 prompt를 공유하면,
  그 prefix의 KV cache를 재사용해 prefill 계산을 줄인다.

잘 맞는 workload:
  - 긴 system prompt가 모든 요청에 반복되는 chatbot
  - RAG에서 instruction template이 길고 반복되는 경우
  - few-shot 예제가 매번 앞에 붙는 경우

안 맞는 workload:
  - 모든 prompt 앞부분이 제각각인 경우
  - cache hit가 거의 없는 traffic

== Response cache ==

목표:
  같은 입력에 대해 이미 생성된 최종 답변을 그대로 반환한다.
  prompt cache가 "중간 계산 KV cache"를 재사용한다면,
  response cache는 "완성된 응답"을 재사용한다.

주의:
  - temperature가 높거나 사용자별 문맥이 섞이면 cache key 설계가 어려워진다.
  - 권한/개인정보가 들어간 응답을 다른 사용자에게 반환하면 사고다.
TEXT
