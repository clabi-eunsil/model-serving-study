# Chapter 12 Lab Notes

## 기준 문서

- 작성/확인일: 2026-07-08
- KServe 기준 문서: https://kserve.github.io/website/docs/getting-started/genai-first-isvc
- Runtime 기준 문서: https://kserve.github.io/website/docs/model-serving/generative-inference/overview

## 실행 환경

환경 확인:

```bash
bash scripts/01_check_env.sh | tee results/check-env.txt
```

기록할 것:

| 항목 | 값 |
| --- | --- |
| Kubernetes context |  |
| KServe version |  |
| deployment mode | Standard / Knative / 모름 |
| GPU node 여부 | 있음 / 없음 |
| `nvidia.com/gpu` 표시 여부 | 있음 / 없음 |
| gateway service |  |

## 배포 기록

namespace:

```bash
bash scripts/02_prepare_namespace.sh
```

Hugging Face token:

```bash
export HF_TOKEN=...
bash scripts/03_create_hf_secret.sh
```

InferenceService:

```bash
bash scripts/04_apply_qwen_llm.sh
bash scripts/05_wait_and_inspect.sh | tee results/inspect.txt
```

기록할 것:

| 항목 | 값 |
| --- | --- |
| InferenceService name | qwen-llm |
| namespace | kserve-llm |
| model URI | hf://Qwen/Qwen2.5-0.5B-Instruct |
| served model name | qwen |
| GPU request | 1 |
| Ready 상태 | True / False |
| status URL |  |

## 호출 기록

gateway port-forward:

```bash
bash scripts/06_port_forward_gateway.sh
```

curl:

```bash
bash scripts/07_curl_chat.sh | tee results/curl-chat.json
```

OpenAI SDK:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/08_openai_client.sh | tee results/openai-client.txt
deactivate
```

확인할 값:

| 항목 | 의미 | 관찰 |
| --- | --- | --- |
| `choices[0].message.content` | 모델이 생성한 답변 |  |
| `usage.prompt_tokens` | prompt 입력 token 수 |  |
| `usage.completion_tokens` | 생성된 token 수 |  |
| `usage.total_tokens` | 입력 + 출력 token 수 |  |
| latency 체감 | 첫 요청과 이후 요청 차이 |  |

## autoscaling 관찰

```bash
bash scripts/09_check_autoscaling.sh | tee results/autoscaling.txt
```

관찰할 것:

| 항목 | 볼 이유 | 기록 |
| --- | --- | --- |
| Deployment replica 수 | 실제 predictor Pod 수 확인 |  |
| HPA 존재 여부 | metric 기반 scaling 사용 여부 |  |
| Knative resource 존재 여부 | scale-to-zero 가능성 확인 |  |
| GPU request | replica마다 필요한 GPU 수 계산 |  |

## custom runtime 구조 확인

```bash
bash scripts/10_preview_custom_runtime.sh | tee results/custom-runtime-example.txt
```

기록할 것:

| 항목 | 의미 | 기록 |
| --- | --- | --- |
| `ServingRuntime` vs `ClusterServingRuntime` | namespace 범위 runtime인지 cluster 전체 runtime인지 |  |
| `supportedModelFormats` | 어떤 model format을 이 runtime에 연결할지 |  |
| `containers.image` | 실제 vLLM image를 어디서 가져올지 |  |
| `containers.args` | vLLM server 실행 옵션 |  |

## 문제 해결 메모

| 증상 | 확인한 명령어 | 원인 추정 | 조치 |
| --- | --- | --- | --- |
| Pending | `kubectl -n kserve-llm get events` | GPU 부족 가능성 |  |
| ImagePullBackOff | `kubectl describe pod` | image pull 문제 |  |
| storage initializer 실패 | pod event/log | token 또는 네트워크 문제 |  |
| OOMKilled | pod status | memory limit 부족 |  |
| 404/route 실패 | Host header, gateway port-forward | hostname/path 문제 |  |

## 정리

정리 명령:

```bash
bash scripts/11_cleanup.sh
deactivate
```

이번 장에서 이해한 것:

- KServe에서 LLM은 `InferenceService`로 배포할 수 있지만 GPU, model download, cold start를 반드시 고려해야 한다.
- `modelFormat: huggingface`는 KServe Hugging Face runtime을 사용하겠다는 뜻이고, runtime 내부에서 vLLM backend가 text generation을 처리한다.
- KServe의 OpenAI-compatible endpoint는 `/openai/v1/...` 경로를 사용한다.
- local gateway 호출에서는 Host header가 매우 중요하다.
