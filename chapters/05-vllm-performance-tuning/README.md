# 5. vLLM 성능 튜닝

이 단원에서는 vLLM server를 실행한 뒤 workload를 바꿔가며 latency, throughput, TTFT, GPU memory를 관찰한다.
목표는 "어떤 옵션을 외우는 것"이 아니라, 성능 실험을 어떻게 설계하고 결과를 어떻게 읽는지 익히는 것이다.

vLLM은 release에 따라 옵션 이름, 기본값, 최적화 방식이 바뀔 수 있다.
이 문서는 2026-06-24 기준 공식 stable 문서를 바탕으로 작성했다.
실습 전 [references.md](references.md)의 공식 문서를 다시 확인한다.

## 학습 목표

- concurrency를 올릴 때 latency와 throughput이 어떻게 달라지는지 설명할 수 있다.
- prompt length, output token length, KV cache, GPU memory의 관계를 이해한다.
- `--gpu-memory-utilization`, `--max-model-len`, `--max-num-seqs`, `--max-num-batched-tokens`의 역할을 안다.
- streaming benchmark에서 TTFT와 total latency를 나누어 본다.
- prefix caching, chunked prefill, quantization, tensor parallelism이 어떤 문제를 다루는지 개념적으로 정리한다.
- benchmark 결과를 CSV로 남기고 다음 실험과 비교할 수 있다.

## 추천 진행 순서

1. [../../GLOSSARY.md](../../GLOSSARY.md)에서 performance, vLLM, GPU 관련 용어를 확인한다.
2. 아래 핵심 개념 요약을 읽는다.
3. [scripts/01_check_env.sh](scripts/01_check_env.sh)로 Docker/GPU/client 환경을 확인한다.
4. [scripts/02_run_vllm_tuned.sh](scripts/02_run_vllm_tuned.sh)로 vLLM server를 실행한다.
5. [scripts/03_warmup.sh](scripts/03_warmup.sh)로 server 준비와 warmup을 확인한다.
6. Python `.venv`를 만들고 benchmark client dependency를 설치한다.
7. [client/04_benchmark_async.py](client/04_benchmark_async.py)를 단일 조건으로 실행한다.
8. [scripts/05_run_benchmark_matrix.sh](scripts/05_run_benchmark_matrix.sh)로 concurrency/prompt/output 조건을 바꿔 실행한다.
9. [scripts/06_benchmark_streaming.sh](scripts/06_benchmark_streaming.sh)로 TTFT를 관찰한다.
10. [scripts/07_collect_gpu_metrics.sh](scripts/07_collect_gpu_metrics.sh)로 GPU/server log를 기록한다.
11. [scripts/08_stop_server.sh](scripts/08_stop_server.sh)로 server를 종료한다.
12. 결과를 [templates/lab-notes.md](templates/lab-notes.md)와 비교한다.

## 실행 환경 기준

server는 Docker container 안에서 실행한다.
client benchmark는 Python `.venv`에서 실행한다.

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

실습 후:

```bash
deactivate
```

## 챕터 4와의 차이

챕터 4는 vLLM server를 실행하고 API를 호출하는 것이 목표였다.
챕터 5는 같은 vLLM server에 여러 요청을 보내면서 성능 변화를 관찰한다.

| 구분 | 챕터 4 | 챕터 5 |
| --- | --- | --- |
| 질문 | vLLM server를 어떻게 실행하고 호출하는가? | workload와 option이 성능에 어떤 영향을 주는가? |
| client | curl, OpenAI SDK 단일 요청 | async benchmark client |
| 주요 관찰 | `/v1/models`, chat completions, streaming | latency, p50/p95, requests/sec, TTFT, GPU memory |
| 결과물 | response 확인 | CSV benchmark 결과 |

## 핵심 개념 요약

### Concurrency

concurrency는 동시에 진행 중인 요청 수다.
concurrency를 올리면 GPU를 더 바쁘게 만들 수 있어 throughput이 좋아질 수 있다.
하지만 너무 많이 올리면 queueing이 생기고 p95/p99 latency가 나빠질 수 있다.

### Throughput

throughput은 단위 시간당 처리량이다.
LLM serving에서는 requests/sec와 tokens/sec를 함께 본다.
요청 수는 많아도 output token이 짧으면 tokens/sec는 낮을 수 있다.

### Latency

latency는 요청 하나가 끝날 때까지 걸린 시간이다.
평균만 보면 느린 요청을 놓치기 쉬우므로 p50, p95 같은 percentile을 같이 본다.

### TTFT

TTFT는 Time To First Token이다.
streaming 응답에서 request를 보낸 뒤 첫 chunk가 도착할 때까지 걸린 시간으로 관찰한다.
사용자가 체감하는 "답변이 시작되기까지의 시간"과 가깝다.

### Prompt Length와 Output Length

prompt가 길면 prefill 단계가 길어진다.
output token이 많으면 decode 단계가 길어진다.
동시 요청이 늘어나면 각 요청의 KV cache가 GPU memory를 더 많이 사용한다.

### vLLM Tuning Options

| 옵션 | 의미 | 주의 |
| --- | --- | --- |
| `--gpu-memory-utilization` | vLLM이 GPU memory 중 어느 정도까지 사용할지 정한다 | 너무 높으면 OOM이나 불안정성이 생길 수 있다 |
| `--max-model-len` | prompt + output 최대 sequence length | 크게 잡을수록 KV cache 여유가 필요하다 |
| `--max-num-seqs` | 동시에 처리할 sequence 수 상한 | throughput과 memory 사용량에 영향을 준다 |
| `--max-num-batched-tokens` | 한 scheduler iteration에서 묶을 token 수 상한 | prefill/decode batching 효율에 영향을 준다 |

### Advanced Topics

| 주제 | 이 챕터에서의 위치 |
| --- | --- |
| Prefix caching | 같은 prefix를 공유하는 요청에서 prefill 계산을 줄이는 개념. 옵션 이름과 기본값은 vLLM 버전에 따라 확인한다. |
| Chunked prefill | 긴 prompt prefill을 쪼개 decode와 섞어 scheduling하는 최적화. latency/throughput trade-off와 관련 있다. |
| Quantization | weight precision을 낮춰 memory와 compute 비용을 줄일 수 있지만 품질/지원 모델/성능 trade-off가 있다. |
| Tensor parallelism | 큰 모델을 여러 GPU에 나누어 올리는 방식. 단일 GPU 실습 이후 다룬다. |

## 학습 포인트와 파일 안내

| 파일 | 볼 부분 | 이유 |
| --- | --- | --- |
| [scripts/02_run_vllm_tuned.sh](scripts/02_run_vllm_tuned.sh) | server tuning option | vLLM engine option과 Docker option 구분 |
| [client/04_benchmark_async.py](client/04_benchmark_async.py) | concurrency, latency, TTFT 측정 | benchmark client의 기본 구조 이해 |
| [scripts/05_run_benchmark_matrix.sh](scripts/05_run_benchmark_matrix.sh) | prompt/max_tokens/concurrency 반복 | 실험 matrix를 어떻게 구성하는지 확인 |
| [scripts/06_benchmark_streaming.sh](scripts/06_benchmark_streaming.sh) | `--stream` benchmark | TTFT 측정 흐름 확인 |
| [scripts/07_collect_gpu_metrics.sh](scripts/07_collect_gpu_metrics.sh) | `nvidia-smi`, server logs | 숫자와 GPU/server 상태를 함께 해석 |

## 실습

### 1. 환경 확인

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/01_check_env.sh
```

로컬에 GPU가 없다면 챕터 4와 같이 이 챕터 폴더만 GPU 서버로 복사해서 진행한다.

```bash
rsync -av ~/study/model-serving/chapters/05-vllm-performance-tuning/ user@gpu-server:~/vllm-performance-tuning/
ssh user@gpu-server
cd ~/vllm-performance-tuning
```

### 2. vLLM server 실행

터미널 1에서 실행한다.

```bash
bash scripts/02_run_vllm_tuned.sh
```

옵션을 바꿔보고 싶으면 환경변수로 준다.

```bash
MAX_NUM_SEQS=32 \
MAX_NUM_BATCHED_TOKENS=8192 \
GPU_MEMORY_UTILIZATION=0.85 \
bash scripts/02_run_vllm_tuned.sh
```

advanced option은 공식 문서를 확인한 뒤 `VLLM_EXTRA_ARGS`로 추가한다.

```bash
VLLM_EXTRA_ARGS="--enable-prefix-caching" bash scripts/02_run_vllm_tuned.sh
```

### 3. warmup

터미널 2에서 실행한다.

```bash
bash scripts/03_warmup.sh
```

첫 요청은 느릴 수 있다.
benchmark 전에 warmup을 한 번 실행하고, server가 준비되었는지 확인한다.

### 4. client 환경 준비

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 5. 단일 조건 benchmark

```bash
python client/04_benchmark_async.py \
  --requests 8 \
  --concurrency 2 \
  --prompt-size short \
  --max-tokens 64 \
  --output results/bench_single.csv
```

확인할 것:

- `latency_avg`, `latency_p50`, `latency_p95`
- `requests_per_second`
- `completion_tokens_per_second`
- error가 있는지

### 6. matrix benchmark

```bash
bash scripts/05_run_benchmark_matrix.sh
```

기본 matrix:

- prompt size: `short`, `long`
- max tokens: `32`, `128`
- concurrency: `1`, `2`, `4`

결과 CSV는 `results/` 아래에 저장된다.

### 7. streaming TTFT benchmark

```bash
bash scripts/06_benchmark_streaming.sh
```

확인할 것:

- `ttft_avg`
- `ttft_p50`
- `ttft_p95`
- `stream_total_seconds`

### 8. GPU/server 상태 기록

```bash
bash scripts/07_collect_gpu_metrics.sh
```

benchmark 숫자만 보지 말고 `nvidia-smi`, GPU memory, server log를 함께 본다.

### 9. 실습 마무리

server 종료:

```bash
bash scripts/08_stop_server.sh
```

client `.venv` 종료:

```bash
deactivate
```

결과 확인:

```bash
ls -lh results/
```

## 확인 질문

| 질문 | 정리 |
| --- | --- |
| concurrency를 올리면 항상 좋은가? | 아니다. throughput은 좋아질 수 있지만 queueing으로 tail latency가 나빠질 수 있다. |
| prompt가 길어지면 무엇이 느려지는가? | prefill 비용과 KV cache memory 사용량이 늘어난다. |
| output token 수가 늘어나면 무엇이 늘어나는가? | decode 시간이 늘어나고 total latency가 길어진다. |
| streaming에서 TTFT는 왜 중요한가? | 전체 답변이 끝나기 전 사용자가 첫 반응을 보는 시간과 관련 있다. |
| benchmark 결과를 볼 때 latency만 보면 되는가? | 아니다. throughput, error, GPU memory, server log를 함께 봐야 한다. |

## 다음 챕터에서 이어질 내용

다음 챕터에서는 NVIDIA NIM을 다룬다.
직접 vLLM server를 운영하는 방식과 vendor-provided inference microservice를 사용하는 방식을 비교한다.
