# References

vLLM 성능 튜닝은 release마다 옵션과 기본값이 바뀔 수 있다.
실습 전 공식 stable 문서를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| vLLM Optimization and Tuning | https://docs.vllm.ai/en/stable/configuration/optimization/ | preemption, chunked prefill, parallelism, CPU resource 등 성능 튜닝 방향 |
| vLLM Engine Arguments | https://docs.vllm.ai/en/stable/configuration/engine_args/ | `--gpu-memory-utilization`, `--max-model-len`, `--max-num-seqs`, `--max-num-batched-tokens` |
| vLLM Online Serving | https://docs.vllm.ai/en/stable/serving/online_serving/ | benchmark client가 호출하는 `/v1/chat/completions` API |
| vLLM Automatic Prefix Caching | https://docs.vllm.ai/en/stable/features/automatic_prefix_caching/ | prefix caching 개념과 관련 옵션 |
| vLLM benchmark scripts | https://github.com/vllm-project/vllm/tree/main/benchmarks | 공식 repository의 benchmark script와 측정 방식 |
| PagedAttention paper | https://arxiv.org/abs/2309.06180 | KV cache memory 관리가 성능에 중요한 이유 |

## 업데이트 가능성이 큰 정보

- prefix caching 옵션 이름과 기본값
- chunked prefill 관련 option과 default
- quantization backend와 지원 model
- vLLM Docker image tag
- GPU/CUDA/PyTorch compatibility
- 공식 benchmark script 경로와 사용법
