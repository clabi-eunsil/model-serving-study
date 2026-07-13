# References

최신 버전, 지원 모델, 설치 방법, 라이선스, vendor 정책은 업데이트될 수 있다. 실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 문서 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| vLLM documentation | https://docs.vllm.ai/ | vLLM이 제공하는 serving, deployment, observability, benchmarking 문서의 전체 위치를 파악한다. |
| vLLM Online Serving | https://docs.vllm.ai/en/latest/serving/online_serving/ | `/v1/chat/completions` 같은 endpoint, server 실행 옵션, OpenAI SDK 호환 방식을 본다. |
| vLLM benchmarking | https://docs.vllm.ai/en/latest/benchmarking/ | latency, throughput, serving benchmark를 어떤 식으로 측정하는지 본다. |
| vLLM production metrics | https://docs.vllm.ai/en/latest/usage/metrics/ | 실제 운영에서 어떤 metrics를 노출하고 Prometheus로 어떻게 볼 수 있는지 확인한다. |
| NVIDIA NIM for LLMs | https://docs.nvidia.com/nim/large-language-models/latest/introduction.html | NIM이 어떤 형태의 inference microservice인지, OpenAI-compatible endpoint와 container 운영 방식을 본다. |
| KServe documentation | https://kserve.github.io/website/ | KServe가 Kubernetes 위에서 model serving을 어떻게 추상화하는지, `InferenceService`와 LLM serving 예시를 본다. |
| Kubeflow Architecture | https://www.kubeflow.org/docs/started/architecture/ | Kubeflow가 ML lifecycle과 pipeline, serving을 전체 플랫폼 관점에서 어떻게 위치시키는지 본다. |
| Kubeflow Pipelines introduction | https://www.kubeflow.org/docs/components/pipelines/ | Kubeflow Pipelines가 model serving engine이 아니라 ML workflow/pipeline 계층이라는 점을 확인한다. |
| TensorFlow Serving | https://www.tensorflow.org/tfx/guide/serving | TensorFlow 모델을 production serving에 올리는 범용 serving framework의 예시로 본다. |
| TorchServe | https://pytorch.org/serve/ | PyTorch 모델 serving framework의 구조와 handler 개념을 확인한다. |
| NVIDIA Triton Inference Server | https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/ | 여러 backend를 지원하는 inference server가 vLLM 같은 LLM 전용 engine과 어떻게 다른지 비교할 때 본다. |
| Kubernetes Deployments | https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ | 모델 서버를 Pod replica로 운영할 때 Deployment가 어떤 역할을 하는지 본다. |
| Kubernetes Services | https://kubernetes.io/docs/concepts/services-networking/service/ | Pod 뒤의 안정적인 endpoint를 제공하는 Service 개념을 본다. |
| Kubernetes Ingress | https://kubernetes.io/docs/concepts/services-networking/ingress/ | cluster 밖에서 HTTP endpoint로 접근시키는 방법을 본다. |
| Hugging Face Transformers pipelines | https://huggingface.co/docs/transformers/en/main_classes/pipelines | 모델 호출을 task 단위로 감싸는 pipeline 구조와 간단한 inference 흐름을 본다. |
| Prometheus metric types | https://prometheus.io/docs/concepts/metric_types/ | counter, gauge, histogram 같은 metric type을 이해한다. latency 측정에는 histogram이 중요하다. |
| NVIDIA DCGM Exporter | https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html | GPU utilization, memory 같은 GPU metrics를 Prometheus로 수집하는 방법을 본다. |
| Langfuse documentation | https://langfuse.com/docs | LLM trace, prompt, generation, token usage, latency 관측 방식을 본다. |

## 논문과 배경 자료

| 문서 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| Attention Is All You Need | https://arxiv.org/abs/1706.03762 | Transformer 구조의 출발점이다. 지금은 전체 수식보다 self-attention, decoder, autoregressive generation(자기회귀 생성)의 배경만 본다. |
| Efficient Memory Management for Large Language Model Serving with PagedAttention | https://arxiv.org/abs/2309.06180 | vLLM의 핵심 배경이다. KV cache가 왜 메모리 병목이 되는지, PagedAttention이 무엇을 개선하려는지 본다. |
| Orca: A Distributed Serving System for Transformer-Based Generative Models | https://www.usenix.org/conference/osdi22/presentation/yu | LLM serving에서 batching과 scheduling이 왜 중요한지 배경으로 본다. |

## 확인 필요 항목

- vLLM의 CLI 옵션과 지원 모델 목록은 버전에 따라 바뀔 수 있다.
- NIM은 지원 모델, container tag, 라이선스, registry 접근 방식이 바뀔 수 있다.
- KServe 설치 방식은 Kubernetes, Knative, Istio, Gateway API 버전에 영향을 받는다.
- TTFP는 도구마다 의미가 다를 수 있으므로 benchmark 문서마다 정의를 확인한다.
