# References

이 문서는 2026-07-08 기준 공식 문서를 바탕으로 작성했다.  
KServe, Hugging Face runtime, vLLM backend, GPU runtime image, autoscaling 문서는 업데이트가 잦으므로 실습 전 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| KServe LLM InferenceService tutorial | https://kserve.github.io/website/docs/getting-started/genai-first-isvc | Qwen LLM `InferenceService` 예제, `hf://` storage URI, GPU resource request, gateway port-forward, `/openai/v1/chat/completions` 호출 |
| KServe Generative Inference Runtime Overview | https://kserve.github.io/website/docs/model-serving/generative-inference/overview | Hugging Face runtime이 vLLM backend를 사용한다는 점, CUDA/CPU image 선택, supported tasks, vLLM engine args |
| KServe LLM SDK Integration | https://kserve.github.io/website/docs/model-serving/generative-inference/sdk-integration | OpenAI SDK에서 base URL과 `/openai/v1` path를 어떻게 잡는지 |
| KServe LLM Autoscaler | https://kserve.github.io/website/docs/model-serving/generative-inference/autoscaling | LLM workload에서 autoscaling을 어떻게 바라보는지, metric 기반 scaling 가능성 |
| KServe Serving Runtime | https://kserve.github.io/website/docs/concepts/resources/servingruntime | `ServingRuntime`, `ClusterServingRuntime`, custom runtime 구성 field |
| KServe Model Cache | https://kserve.github.io/website/docs/model-serving/generative-inference/modelcache/localmodel | model download 시간을 줄이기 위한 local model cache 개념 |
| KServe LLMInferenceService | https://kserve.github.io/website/docs/model-serving/generative-inference/llmisvc/llmisvc-overview | 고급 LLM serving 리소스인 `LLMInferenceService` 개념. 이번 장은 기본 `InferenceService`를 먼저 사용 |
| KServe Multi-node/Multi-GPU Inference | https://kserve.github.io/website/docs/model-serving/generative-inference/multi-node | 큰 모델에서 tensor parallelism, multi-node serving이 필요해지는 맥락 |
| Hugging Face Models | https://huggingface.co/models | 실제 model repository 이름, license, gated 여부, model card 확인 |
| vLLM OpenAI-compatible Server | https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html | vLLM이 제공하는 OpenAI-compatible API 구조. KServe runtime 내부 이해에 도움 |

## 업데이트 가능성이 큰 정보

| 항목 | 왜 바뀔 수 있나 | 확인 위치 |
| --- | --- | --- |
| KServe version | CRD schema, runtime 이름, gateway 방식이 바뀔 수 있다. | KServe docs version selector |
| Hugging Face runtime image | CUDA version, vLLM version, supported architecture가 바뀔 수 있다. | KServe Runtime Overview |
| vLLM engine args | 옵션 이름과 기본값이 바뀔 수 있다. | vLLM official docs |
| Qwen model | model card, license, file structure가 바뀔 수 있다. | Hugging Face model page |
| autoscaling behavior | KServe deployment mode와 autoscaler 구현에 따라 다르다. | KServe Autoscaler docs |
| gateway 호출 방식 | Istio, Knative, Gateway API, cluster 환경마다 다르다. | KServe networking/quickstart docs |
