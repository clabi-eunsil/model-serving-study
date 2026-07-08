# Chapter 13 Lab Notes

## 기준 문서

- 작성/확인일: 2026-07-08
- vLLM Quantization: https://docs.vllm.ai/en/latest/features/quantization/
- vLLM LoRA: https://docs.vllm.ai/en/latest/features/lora/
- vLLM Speculative Decoding: https://docs.vllm.ai/en/latest/features/speculative_decoding/
- vLLM Parallelism and Scaling: https://docs.vllm.ai/en/latest/serving/parallelism_scaling/
- NGINX Rate Limiting: https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-proxied-http/

## 실행 환경

```bash
cd ~/study/model-serving/chapters/13-advanced-serving-topics
bash scripts/01_check_env.sh
```

예상 관찰:

| 항목 | 의미 | 정상/주의 기준 |
| --- | --- | --- |
| `docker` | vLLM, NGINX container 실습에 필요 | Docker server version이 보여야 container 실습 가능 |
| `nvidia-smi` | GPU 실습 가능 여부 확인 | GPU 이름, memory, driver version이 보이면 quantization/LoRA 실습 가능 |
| `curl` | OpenAI-compatible endpoint 호출 | 반드시 필요 |
| `python3` | JSON pretty print와 간단한 확인에 사용 | 반드시 필요 |
| `jq` | JSON 확인 보조 도구 | 없어도 `python3 -m json.tool`로 대체 가능 |

로컬 PC에 GPU가 없으면 이 장의 핵심 실습은 원격 GPU 서버에서 진행하는 것이 자연스럽다.

그래도 `06_preview_parallelism.sh`, `07_preview_speculative_and_cache.sh`, `08_preview_rate_limit_config.sh`는 개념 확인용으로 로컬에서도 읽어볼 수 있다.

## Quantized model serving

실행:

```bash
MODEL=Qwen/Qwen2.5-7B-Instruct-AWQ \
QUANTIZATION=awq \
bash scripts/02_run_quantized_vllm.sh
```

로그 확인:

```bash
docker logs -f chapter13-quantized-vllm
```

호출:

```bash
bash scripts/03_call_chat.sh
```

예상 관찰:

| 볼 것 | 의미 | 해석 |
| --- | --- | --- |
| model loading log | quantized weight를 정상적으로 읽었는지 | loader/format mismatch가 있으면 여기서 실패한다. |
| GPU memory | quantization 후 실제 GPU memory 사용량 | weight는 줄어도 KV cache 때문에 memory가 계속 중요하다. |
| 첫 요청 latency | warmup 영향 확인 | 첫 요청은 CUDA/context/kernel/tokenizer 준비 때문에 느릴 수 있다. |
| 두 번째 요청 latency | warmup 이후 체감 latency | 첫 요청보다 안정적이면 warmup 효과를 확인한 것이다. |
| 답변 품질 | quantization 품질 저하 확인 | 속도/메모리 숫자가 좋아도 답변 품질이 너무 떨어지면 운영에 부적합하다. |

정리 예:

- AWQ/GPTQ/bitsandbytes는 모두 "작게 만들기" 계열이지만 format과 hardware 지원이 다르다.
- quantization은 model weight memory를 줄이는 데 도움을 주지만, 긴 prompt와 많은 동시 요청에서 커지는 KV cache 문제를 없애지는 않는다.
- 실패하면 먼저 model card, vLLM quantization 지원 표, GPU architecture를 확인한다.

내가 선택한 quantization 방식:

| 항목 | 기록 |
| --- | --- |
| 선택한 model repo |  |
| 선택한 quantization | AWQ / GPTQ / bitsandbytes / 기타 |
| 이 방식을 고른 이유 |  |
| GPU architecture |  |
| vLLM 지원 문서에서 확인한 내용 |  |
| 원본 모델과 비교해야 할 품질 기준 |  |

## LoRA adapter serving

LoRA adapter는 base model과 호환되어야 한다.

그래서 이 실습은 기본값으로 아무 모델이나 강제 실행하지 않고, 직접 model card를 확인한 뒤 환경변수를 넣게 되어 있다.

실행 예:

```bash
BASE_MODEL=meta-llama/Llama-3.2-3B-Instruct \
LORA_MODULES='sql-lora=jeeejeee/llama32-3b-text2sql-spider' \
HF_TOKEN=hf_xxx \
bash scripts/04_run_lora_vllm.sh
```

모델 목록 확인:

```bash
curl http://127.0.0.1:8000/v1/models | python3 -m json.tool
```

adapter 호출:

```bash
MODEL_NAME=sql-lora bash scripts/05_call_lora.sh
```

예상 관찰:

| 볼 것 | 의미 | 해석 |
| --- | --- | --- |
| `/v1/models`의 base model | base model이 정상 등록되었는지 | base model만 보이면 LoRA 등록이 빠졌을 수 있다. |
| `/v1/models`의 adapter name | LoRA adapter가 model처럼 노출되는지 | 요청 JSON의 `model` 값으로 adapter 이름을 쓴다. |
| adapter 호출 응답 | adapter가 실제로 적용되어 호출되는지 | base model과 답변 스타일/능력이 달라질 수 있다. |
| latency 차이 | adapter overhead 확인 | adapter가 많아질수록 loading, scheduling, memory 정책을 봐야 한다. |

정리 예:

- multi-LoRA serving은 base model 하나에 여러 task adapter를 얹는 방식이다.
- adapter마다 base model을 새로 띄우는 것보다 memory를 아낄 수 있다.
- 대신 adapter별 권한, 품질, latency, token usage를 따로 추적해야 한다.
- runtime LoRA loading은 편하지만, 운영에서는 보안 위험 때문에 신뢰된 환경에서만 조심해서 사용한다.

LoRA 조합 확인:

| 항목 | 기록 |
| --- | --- |
| base model |  |
| adapter repo/path |  |
| adapter가 요구하는 base model |  |
| gated/private 여부 |  |
| HF token 필요 여부 |  |
| adapter가 해결하려는 task |  |

## Parallelism 판단

```bash
bash scripts/06_preview_parallelism.sh
```

예상 관찰:

| 출력 | 의미 | 다음 판단 |
| --- | --- | --- |
| GPU count가 1 | 단일 GPU 기준으로 먼저 model이 올라가는지 본다. | quantization이나 작은 model부터 검토 |
| GPU count가 2 이상 | tensor parallelism 후보가 생긴다. | `--tensor-parallel-size <GPU 수>`를 검토 |
| GPU가 확인되지 않음 | 현재 환경에서는 distributed serving 실습이 어렵다. | 원격 GPU 서버에서 다시 확인 |

정리 예:

- 모델이 GPU 1장에 들어가면 distributed inference부터 고민하지 않아도 된다.
- 한 node의 여러 GPU에 나누면 tensor parallelism을 먼저 떠올린다.
- 여러 node가 필요하면 tensor parallelism과 pipeline parallelism을 조합한다.
- GPU 간 통신이 느리면 tensor parallelism의 이득이 줄어들 수 있다.

내 환경에서의 판단:

| 질문 | 답 |
| --- | --- |
| 모델이 GPU 1장에 들어가는가? |  |
| 한 node에 GPU가 몇 장 있는가? |  |
| GPU 사이 통신이 빠른 편인가? |  |
| tensor parallelism을 먼저 검토할 상황인가? |  |
| pipeline parallelism까지 필요한 상황인가? |  |

## Speculative decoding과 cache

```bash
bash scripts/07_preview_speculative_and_cache.sh
```

예상 관찰:

| 주제 | 핵심 | 볼 지표 |
| --- | --- | --- |
| speculative decoding | 작은 proposer가 후보 token을 만들고 target model이 검증한다. | inter-token latency, total latency, acceptance rate |
| n-gram speculation | 별도 draft model 없이 prompt 반복 패턴을 활용한다. | 반복 문맥이 있는 workload에서 이득이 있는지 |
| prompt/prefix cache | 같은 앞부분 prompt의 KV cache를 재사용한다. | prefill latency, cache hit 가능성 |
| response cache | 완성된 최종 응답을 재사용한다. | cache hit, tenant/권한 안전성 |

정리 예:

- speculative decoding은 TTFT보다 token이 이어서 나오는 속도, 즉 inter-token latency에 더 직접적으로 영향을 줄 수 있다.
- prompt cache는 "중간 계산 재사용"이고 response cache는 "최종 답변 재사용"이다.
- response cache는 빠르지만 tenant나 개인정보가 섞이면 위험하다.

적용 판단:

| 질문 | 기록 |
| --- | --- |
| 현재 병목은 TTFT인가, inter-token latency인가? |  |
| draft model을 올릴 GPU memory 여유가 있는가? |  |
| 반복되는 prefix가 많은 workload인가? |  |
| response cache를 써도 개인정보/권한 문제가 없는가? |  |

## Rate limiting

설정 확인:

```bash
bash scripts/08_preview_rate_limit_config.sh
```

볼 설정:

| 설정 | 의미 | 이번 실습의 값 |
| --- | --- | --- |
| `limit_req_zone` | 요청 수를 어떤 기준으로 셀지 정의 | client IP 기준 |
| `rate=5r/m` | 분당 허용 요청 속도 | 분당 5개 요청 |
| `burst=2` | 짧은 순간 초과 요청 허용량 | 2개 |
| `Authorization` check | demo API key 확인 | `Bearer chapter13-demo-key` |
| `proxy_pass` | 실제 model server 위치 | `host.docker.internal:8000` |

실행:

```bash
bash scripts/09_run_nginx_rate_limit.sh
```

정상 호출:

```bash
BASE_URL=http://127.0.0.1:8080/v1 \
API_KEY=chapter13-demo-key \
bash scripts/03_call_chat.sh
```

인증 실패 확인:

```bash
BASE_URL=http://127.0.0.1:8080/v1 \
API_KEY=wrong \
bash scripts/03_call_chat.sh
```

반복 호출:

```bash
for i in {1..10}; do
  BASE_URL=http://127.0.0.1:8080/v1 \
  API_KEY=chapter13-demo-key \
  bash scripts/03_call_chat.sh
done
```

예상 관찰:

| 상황 | 기대 결과 | 의미 |
| --- | --- | --- |
| 올바른 API key | model server까지 proxy됨 | 인증을 통과했다. |
| 잘못된 API key | `401` | model server로 보내기 전에 proxy가 차단했다. |
| 너무 많은 반복 호출 | `503` 또는 rate limit 응답 | proxy가 과도한 요청을 막았다. |

정리 예:

- rate limiting은 model server 내부보다 gateway/proxy/ingress에 두는 경우가 많다.
- IP 기준 제한은 NAT나 shared proxy 환경에서 부정확할 수 있다.
- 운영에서는 API key, user id, org id, tenant id 같은 식별자를 기준으로 quota와 rate limit을 나누는 편이 낫다.

rate limit/auth/quota 구분:

| 항목 | 이번 실습에서 확인한 것 | 운영에서 추가로 필요한 것 |
| --- | --- | --- |
| authentication | demo API key 확인 | key 발급, 회전, 폐기 절차 |
| authorization | 없음 | key별 model/adapter 권한 |
| rate limit | request 수 제한 | token 기준 제한, tenant별 제한 |
| quota | 없음 | 일/월 단위 총 token 또는 비용 제한 |
| audit log | 없음 | 누가 어떤 model을 얼마나 썼는지 기록 |

## 정리

```bash
bash scripts/10_cleanup.sh
```

가상환경을 켰다면 종료:

```bash
deactivate
```

최종 정리:

- quantization은 memory 절약과 품질/호환성 사이의 trade-off다.
- parallelism은 큰 모델을 올리기 위한 분산 전략이고, GPU 간 통신이 중요하다.
- LoRA는 base model을 공유하면서 task별 adapter를 얹는 방식이다.
- speculative decoding은 decode latency를 줄이려는 기법이지만 workload와 모델 조합을 탄다.
- cache는 무엇을 재사용하는지에 따라 prompt cache와 response cache를 구분해야 한다.
- rate limiting과 API key는 GPU server를 보호하고 tenant별 사용량을 관리하는 출발점이다.
