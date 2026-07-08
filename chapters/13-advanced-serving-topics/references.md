# References

이 문서는 2026-07-08 기준 공식 문서를 바탕으로 작성했다.  
vLLM의 quantization, LoRA, speculative decoding, parallelism 옵션은 빠르게 바뀌므로 실습 전 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| vLLM Quantization | https://docs.vllm.ai/en/latest/features/quantization/ | quantization이 memory footprint를 줄이는 trade-off라는 설명, 지원 format, hardware compatibility 표 |
| vLLM LoRA Adapters | https://docs.vllm.ai/en/latest/features/lora/ | `--enable-lora`, `--lora-modules`, adapter를 request의 `model` field로 호출하는 방식, dynamic LoRA 보안 경고 |
| vLLM Speculative Decoding | https://docs.vllm.ai/en/latest/features/speculative_decoding/ | draft/verify 구조, `--speculative-config`, n-gram/draft model/EAGLE/MTP 등 방법별 차이 |
| vLLM Automatic Prefix Caching | https://docs.vllm.ai/en/latest/features/automatic_prefix_caching/ | 같은 prefix를 공유할 때 KV cache를 재사용해 shared prefix 계산을 건너뛰는 원리 |
| vLLM Parallelism and Scaling | https://docs.vllm.ai/en/latest/serving/parallelism_scaling/ | 단일 GPU, tensor parallelism, pipeline parallelism, multi-node 선택 기준 |
| vLLM Online Serving | https://docs.vllm.ai/en/latest/serving/online_serving/ | OpenAI-compatible serving 구조와 endpoint 호출 방식 |
| NGINX Limiting Access to Proxied HTTP Resources | https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-proxied-http/ | connection/request rate limiting 개념, `limit_req_zone`, `limit_req` |

## 업데이트 가능성이 큰 정보

- quantization 지원 표는 GPU architecture와 kernel 지원 변화에 따라 달라질 수 있다.
- AWQ, GPTQ, bitsandbytes loader와 CLI option 이름은 vLLM release와 model card에 따라 바뀔 수 있다.
- LoRA dynamic loading은 보안 정책과 endpoint 지원 방식이 바뀔 수 있으므로 production 적용 전 공식 문서를 다시 확인한다.
- speculative decoding method는 EAGLE, MTP, n-gram, suffix 등 구현과 옵션이 빠르게 바뀐다.
- prefix caching 기본 활성화 여부와 option 이름은 vLLM version에 따라 다를 수 있다.
- NGINX rate limit 설정과 실제 동작은 Ingress controller, proxy, cloud gateway마다 달라질 수 있다.
