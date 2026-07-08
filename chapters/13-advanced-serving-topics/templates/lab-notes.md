# Chapter 13 Lab Notes

## 기준 문서

- 작성/확인일: 2026-07-08
- vLLM Quantization: https://docs.vllm.ai/en/latest/features/quantization/
- vLLM LoRA: https://docs.vllm.ai/en/latest/features/lora/
- vLLM Speculative Decoding: https://docs.vllm.ai/en/latest/features/speculative_decoding/
- NGINX Rate Limiting: https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-proxied-http/

## 실행 환경

```bash
bash scripts/01_check_env.sh | tee results/check-env.txt
```

| 항목 | 값 |
| --- | --- |
| GPU model |  |
| GPU memory |  |
| NVIDIA driver |  |
| Docker version |  |
| vLLM image |  |
| HF_TOKEN 필요 여부 |  |

## Quantized model serving

실행:

```bash
MODEL=... QUANTIZATION=... bash scripts/02_run_quantized_vllm.sh
bash scripts/03_call_chat.sh | tee results/quantized-response.json
```

기록:

| 항목 | 값 |
| --- | --- |
| model repo |  |
| quantization 방식 | AWQ / GPTQ / bitsandbytes / 기타 |
| model loading 성공 여부 |  |
| GPU memory 사용량 |  |
| 첫 요청 latency |  |
| 두 번째 요청 latency |  |
| 품질 특이사항 |  |

## LoRA adapter serving

실행:

```bash
BASE_MODEL=... LORA_MODULES='adapter=repo_or_path' bash scripts/04_run_lora_vllm.sh
MODEL_NAME=adapter bash scripts/05_call_lora.sh | tee results/lora-response.json
```

기록:

| 항목 | 값 |
| --- | --- |
| base model |  |
| adapter name |  |
| adapter repo/path |  |
| `/v1/models`에 adapter 표시 여부 |  |
| adapter 호출 성공 여부 |  |
| base model 대비 latency 차이 |  |

## Parallelism 판단

```bash
bash scripts/06_preview_parallelism.sh | tee results/parallelism-preview.txt
```

정리:

| 질문 | 답 |
| --- | --- |
| 모델이 GPU 1장에 들어가는가? |  |
| 한 node 안 여러 GPU로 충분한가? |  |
| 여러 node가 필요한가? |  |
| tensor parallelism 후보 값 |  |
| pipeline parallelism 후보 값 |  |

## Speculative decoding과 cache

```bash
bash scripts/07_preview_speculative_and_cache.sh | tee results/spec-cache-preview.txt
```

정리:

| 항목 | 내 이해 |
| --- | --- |
| speculative decoding이 줄이는 병목 |  |
| draft model이 필요한 경우 |  |
| n-gram speculation이 유리한 경우 |  |
| prompt/prefix cache가 잘 맞는 workload |  |
| response cache를 조심해야 하는 이유 |  |

## Rate limiting

설정 확인:

```bash
bash scripts/08_preview_rate_limit_config.sh | tee results/rate-limit-config.txt
```

실행:

```bash
bash scripts/09_run_nginx_rate_limit.sh
BASE_URL=http://127.0.0.1:8080/v1 API_KEY=chapter13-demo-key bash scripts/03_call_chat.sh
```

기록:

| 항목 | 값 |
| --- | --- |
| 정상 API key 호출 결과 |  |
| 잘못된 API key 호출 결과 |  |
| 반복 호출 시 rate limit 발생 여부 |  |
| 실제 운영에서 key 기준으로 바꾸려면 필요한 것 |  |

## 정리

```bash
bash scripts/10_cleanup.sh
deactivate
```

이번 장에서 기억할 것:

- quantization은 memory를 줄이지만 품질과 hardware support를 확인해야 한다.
- tensor parallelism은 한 node 여러 GPU에, pipeline parallelism은 layer/stage 분할에 가깝다.
- LoRA는 adapter별 task specialization을 제공하지만 base model 호환성이 중요하다.
- speculative decoding은 token decode latency를 줄일 수 있지만 traffic과 모델 조합을 탄다.
- prompt cache는 중간 계산 재사용, response cache는 최종 응답 재사용이다.
- rate limiting과 API key는 model server 앞단에서 traffic을 보호하는 기본 장치다.
