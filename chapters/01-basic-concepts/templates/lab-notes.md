# Chapter 01 Lab Notes

## Sources

- vLLM documentation: https://docs.vllm.ai/
- NVIDIA NIM for LLMs: https://docs.nvidia.com/nim/large-language-models/latest/introduction.html
- KServe documentation: https://kserve.github.io/website/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/
- Hugging Face Transformers pipelines: https://huggingface.co/docs/transformers/en/main_classes/pipelines

## Commands

```bash
cd ~/study/model-serving/chapters/01-basic-concepts
bash scripts/01_collect_env.sh
cat env-summary.txt
```

## Environment

현재 기록은 [env-summary.txt](../env-summary.txt)에 저장되어 있다.

- OS: Ubuntu 24.04.1 LTS
- Python: Python 3.12.3
- CUDA: 현재 `nvidia-smi`가 보이지 않아 확인되지 않음
- NVIDIA driver: 현재 `nvidia-smi`가 보이지 않아 확인되지 않음
- GPU: 현재 WSL 환경에서 확인되지 않음
- Docker: 현재 WSL distro 안에서는 Docker command가 보이지 않음
- Kubernetes: `kubectl` not found

## Models

- 사용한 모델: 없음
- 모델 revision/version: 없음

## Notes

### Model Server

모델 서버는 모델을 메모리에 올려두고 외부 요청을 받아 inference 결과를 반환하는 서버다.
단순 API 서버와 달리 model loading, GPU memory, request scheduling, token streaming, metrics가 중요하다.

### API Types

- REST API: HTTP/JSON 기반이라 사람이 읽고 `curl`로 테스트하기 쉽다.
- gRPC: 다른 서버의 함수를 호출하듯 통신하는 RPC 방식이며, protobuf와 HTTP/2를 기반으로 한다.
- OpenAI-compatible API: OpenAI API와 비슷한 request/response 형태를 제공해 client 교체 비용을 줄인다.

### Online vs Batch Inference

- Online inference: 사용자가 기다리는 요청에 바로 응답한다. latency가 중요하다.
- Batch inference: 많은 데이터를 모아 한 번에 처리한다. throughput과 비용 효율이 중요하다.

### Latency / Throughput / Concurrency

- Latency: 요청 하나가 끝날 때까지 걸린 시간.
- Throughput: 단위 시간당 처리량. LLM에서는 requests/sec와 tokens/sec를 같이 본다.
- Concurrency: 동시에 들어와 있거나 처리 중인 요청 수.
- concurrency를 높이면 throughput은 증가할 수 있지만 queueing 때문에 p95/p99 latency가 나빠질 수 있다.

### TTFT / TTFB / TTFP / TPS / QPS

- TTFB: HTTP 응답의 첫 byte가 도착하기까지의 시간.
- TTFT: LLM streaming에서 첫 token이 도착하기까지의 시간.
- TTFP: 첫 예측까지 걸린 시간. 도구마다 정의가 다를 수 있어 사용할 때 정의를 명시해야 한다.
- TPS/tokens/sec: 초당 생성 또는 처리 token 수.
- QPS: 초당 요청 수.

### GPU Memory / KV Cache

- LLM serving에서 GPU memory는 모델 weight뿐 아니라 KV cache에도 많이 쓰인다.
- prompt 길이, output 길이, 동시 요청 수가 늘어나면 KV cache가 커진다.
- vLLM의 PagedAttention은 이 KV cache memory를 더 효율적으로 관리하려는 배경에서 나온다.

## Questions

- TTFP는 정의가 도구마다 다를 수 있으므로 benchmark 문서마다 확인해야 한다.
- 현재 WSL 환경에서 Docker, kubectl, nvidia-smi가 보이지 않는다. 이후 Docker/GPU/Kubernetes 실습 전에 환경 연결을 다시 확인해야 한다.

## Results

- `env-summary.txt` 생성 완료.