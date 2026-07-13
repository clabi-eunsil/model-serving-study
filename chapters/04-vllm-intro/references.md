# References

이 단원은 vLLM 공식 문서와 PagedAttention 논문을 기준으로 정리한다.
vLLM은 release와 Docker image가 자주 바뀌므로, 실습 전 공식 문서의 stable 버전을 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| vLLM stable docs | https://docs.vllm.ai/en/stable/ | 현재 stable 문서인지 확인. 최신 developer preview와 stable 문서가 다를 수 있다. |
| Installation | https://docs.vllm.ai/en/stable/getting_started/installation/ | GPU/CPU 설치 경로, Python/PyTorch/CUDA 요구사항 |
| Using Docker | https://docs.vllm.ai/en/stable/deployment/docker/ | `vllm/vllm-openai` image, `docker run --gpus all`, cache mount, `--ipc=host` |
| Online Serving | https://docs.vllm.ai/en/stable/serving/online_serving/ | `/v1/models`, `/v1/chat/completions`, OpenAI SDK와의 연결 방식 |
| Engine Arguments | https://docs.vllm.ai/en/stable/configuration/engine_args/ | `--model`, `--served-model-name`, `--gpu-memory-utilization`, `--max-model-len` |
| Server Arguments | https://docs.vllm.ai/en/stable/configuration/server_args/ | `--host`, `--port`, server 실행 관련 옵션 |
| Model Resolution | https://docs.vllm.ai/en/stable/configuration/model_resolution/ | vLLM이 Hugging Face model repo의 `config.json`과 architecture 정보를 어떻게 해석하는지 |
| Supported Models | https://docs.vllm.ai/en/stable/models/supported_models/ | 사용할 model이 vLLM에서 지원되는지 확인 |
| Hugging Face Model Hub | https://huggingface.co/docs/hub/en/models-the-hub | model repository id, model card, files, license 확인 |
| Qwen/Qwen3-0.6B model page | https://huggingface.co/Qwen/Qwen3-0.6B | 이 챕터에서 사용하는 실제 model repo id, license, model card, vLLM 사용 예시 |

## 논문과 설계 배경

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| PagedAttention paper | https://arxiv.org/abs/2309.06180 | KV cache memory 낭비 문제, PagedAttention 아이디어, throughput 개선 배경 |
| vLLM GitHub | https://github.com/vllm-project/vllm | release, issue, Dockerfile, 예제 코드 |

## 업데이트 가능성이 큰 정보

- Docker image tag: `vllm/vllm-openai:latest`는 시간이 지나면 내용이 바뀔 수 있다. 재현성이 필요하면 특정 version tag를 고정한다.
- default model: 공식 문서 예시는 바뀔 수 있다. 이 챕터는 `Qwen/Qwen3-0.6B`를 사용한다.
- option name/default: vLLM engine/server argument는 release에 따라 추가/변경될 수 있다.
- GPU/CUDA/PyTorch compatibility: 서버 환경마다 다르므로 실습 전 `nvidia-smi`, Docker GPU passthrough, vLLM release note를 확인한다.
- model support: Hugging Face에 model이 있다고 해서 vLLM에서 항상 바로 실행되는 것은 아니다. vLLM supported models와 model card를 함께 확인한다.
- model access: public model은 token 없이 받을 수 있지만, gated/private model은 `HF_TOKEN`이 필요할 수 있다.
