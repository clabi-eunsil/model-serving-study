# 5. vLLM 성능 튜닝

이 단원에서는 vLLM server를 실행한 뒤 workload를 바꿔가며 latency, throughput, TTFT, GPU memory를 관찰한다.
목표는 "어떤 옵션을 외우는 것"이 아니라, 성능 실험을 어떻게 설계하고 결과를 어떻게 읽는지 익히는 것이다.

vLLM은 release에 따라 옵션 이름, 기본값, 최적화 방식이 바뀔 수 있다.
이 문서는 2026년 6월 기준 공식 stable 문서를 바탕으로 작성했다.
핵심 공식 문서는 본문에 바로 연결해 두고, 전체 목록은 [references.md](references.md)에 모아 둔다.

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
3. [공식 문서 바로가기](#공식-문서-바로가기)에서 vLLM tuning option과 benchmark 문서 위치를 본다.
4. [scripts/01_check_env.sh](scripts/01_check_env.sh)로 Docker/GPU/client 환경을 확인한다.
5. [scripts/02_run_vllm_tuned.sh](scripts/02_run_vllm_tuned.sh)로 vLLM server를 실행한다.
6. [scripts/03_warmup.sh](scripts/03_warmup.sh)로 server 준비와 warmup을 확인한다.
7. Python `.venv`를 만들고 benchmark client dependency를 설치한다.
8. [client/04_benchmark_async.py](client/04_benchmark_async.py)를 단일 조건으로 실행한다.
9. [scripts/05_run_benchmark_matrix.sh](scripts/05_run_benchmark_matrix.sh)로 concurrency/prompt/output 조건을 바꿔 실행한다.
10. [scripts/06_benchmark_streaming.sh](scripts/06_benchmark_streaming.sh)로 TTFT를 관찰한다.
11. [scripts/07_collect_gpu_metrics.sh](scripts/07_collect_gpu_metrics.sh)로 GPU/server log를 기록한다.
12. [scripts/08_stop_server.sh](scripts/08_stop_server.sh)로 server를 종료한다.
13. 결과를 [templates/lab-notes.md](templates/lab-notes.md)와 비교한다.

## 공식 문서 바로가기

| 문서 | 바로 볼 부분 |
| --- | --- |
| [vLLM Optimization and Tuning](https://docs.vllm.ai/en/stable/configuration/optimization/) | preemption, chunked prefill, parallelism, CPU resource 등 tuning 방향 |
| [vLLM Engine Arguments](https://docs.vllm.ai/en/stable/configuration/engine_args/) | `--gpu-memory-utilization`, `--max-model-len`, `--max-num-seqs`, `--max-num-batched-tokens` |
| [vLLM Online Serving](https://docs.vllm.ai/en/stable/serving/online_serving/) | benchmark client가 호출하는 API 구조 |
| [vLLM Automatic Prefix Caching](https://docs.vllm.ai/en/stable/features/automatic_prefix_caching/) | prefix caching 개념과 관련 option |
| [vLLM benchmark scripts](https://github.com/vllm-project/vllm/tree/main/benchmarks) | 공식 benchmark script와 측정 방식 |

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

### 모델 동작과 Serving Engine 동작의 차이

여기서 헷갈리기 쉬운 지점이 있다.
`prefill`, `decode`는 모델이 한 요청을 처리할 때 거치는 inference 단계다.  
반면 `waiting`, `running`, `finished` 같은 상태를 관리하고 여러 요청을 어떤 순서로 GPU에 보낼지 결정하는 것은 vLLM serving engine의 scheduler 역할이다.

즉, 두 층을 나누어 보면 이해하기 쉽다.

| 관점 | 무엇을 설명하는가 | 예시 |
| --- | --- | --- |
| 모델 inference 과정 | 하나의 요청이 token을 처리하고 생성하는 방식 | prefill, decode, KV cache |
| vLLM serving engine 과정 | 여러 요청을 받아 GPU 작업으로 배치하고 스케줄링하는 방식 | waiting queue, running sequence, finished request, continuous batching |

하나의 요청은 대략 아래 흐름을 거친다.

```text
client request
→ waiting: scheduler가 처리 순서를 기다림
→ prefill: prompt token을 처리하고 KV cache를 만듦
→ decode: output token을 하나씩 생성함
→ finished: stop condition에 도달해 응답 완료
```

하지만 실제 server 안에서는 요청 하나만 있는 것이 아니다.
어떤 요청은 긴 prompt 때문에 prefill 중이고, 어떤 요청은 이미 첫 token 이후 decode 중이고, 어떤 요청은 queue에서 기다리고, 어떤 요청은 방금 끝난 상태일 수 있다.
vLLM의 scheduler는 이런 요청들을 계속 섞어 GPU가 가능한 한 쉬지 않게 만든다.

이것이 continuous batching의 핵심이다.
고정된 batch를 처음에 한 번 만들고 끝까지 같이 가는 것이 아니라, 실행 중인 batch에서 끝난 요청은 빠지고 새 요청은 들어온다.

`sequence`는 모델이 처리 중인 token 줄이라고 볼 수 있다.
실습에서는 보통 "요청 1개가 sequence 1개에 가깝다"고 이해하면 충분하다.
따라서 `--max-num-seqs`는 vLLM scheduler가 동시에 관리할 active sequence 수의 상한이다.
이 값을 키우면 더 많은 요청을 동시에 다룰 수 있지만, KV cache와 GPU memory 사용량도 늘 수 있다.

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

옵션 의미:

| 옵션 | 의미 | 처음 바꿔볼 값 |
| --- | --- | --- |
| `--requests` | 전체 요청 수 | `8`, `16`, `32` |
| `--concurrency` | 동시에 진행할 요청 수 | `1`, `2`, `4`, `8` |
| `--prompt-size` | 입력 prompt 길이 | `short`, `medium`, `long` |
| `--max-tokens` | 요청당 최대 output token 수 | `32`, `64`, `128` |
| `--output` | 요청별 결과를 저장할 CSV 파일 | `results/bench_조건.csv` |

처음 해볼 실험:

```bash
# baseline: 가장 가벼운 조건
python client/04_benchmark_async.py --requests 8 --concurrency 1 --prompt-size short --max-tokens 32 --output results/baseline.csv

# concurrency만 증가
python client/04_benchmark_async.py --requests 16 --concurrency 4 --prompt-size short --max-tokens 32 --output results/concurrency4.csv

# prompt 길이만 증가
python client/04_benchmark_async.py --requests 8 --concurrency 1 --prompt-size long --max-tokens 32 --output results/long_prompt.csv

# output 길이만 증가
python client/04_benchmark_async.py --requests 8 --concurrency 1 --prompt-size short --max-tokens 128 --output results/long_output.csv
```

기대되는 변화:

- `concurrency`를 올리면 어느 지점까지는 `requests_per_second`가 증가할 수 있다.
- `concurrency`가 너무 높아지면 queueing 때문에 `latency_p95`가 증가할 수 있다.
- `prompt-size`를 `short`에서 `long`으로 바꾸면 prefill 비용 때문에 latency가 증가할 수 있다.
- `max-tokens`를 키우면 decode 시간이 길어져 total latency가 증가할 수 있다.
- error가 생기면 latency 평균보다 `error` column과 server log를 먼저 본다.

### 6. matrix benchmark

```bash
bash scripts/05_run_benchmark_matrix.sh
```

기본 matrix:

- prompt size: `short`, `long`
- max tokens: `32`, `128`
- concurrency: `1`, `2`, `4`

결과 CSV는 `results/` 아래에 저장된다.

값을 직접 바꾸는 예:

```bash
# 빠르게 sanity check만 하고 싶을 때
REQUESTS=6 \
CONCURRENCY_LIST="1 2" \
MAX_TOKENS_LIST="32" \
PROMPT_SIZE_LIST="short" \
bash scripts/05_run_benchmark_matrix.sh

# concurrency 영향을 더 보고 싶을 때
REQUESTS=24 \
CONCURRENCY_LIST="1 2 4 8" \
MAX_TOKENS_LIST="64" \
PROMPT_SIZE_LIST="short" \
bash scripts/05_run_benchmark_matrix.sh

# prompt/output 길이 영향을 같이 보고 싶을 때
REQUESTS=12 \
CONCURRENCY_LIST="1 4" \
MAX_TOKENS_LIST="32 128" \
PROMPT_SIZE_LIST="short long" \
bash scripts/05_run_benchmark_matrix.sh
```

matrix 결과를 볼 때는 한 파일만 보지 말고 조건별 추세를 비교한다.

| 바꾼 조건 | 기대되는 관찰 |
| --- | --- |
| concurrency 증가 | throughput 증가 가능, p95 latency 악화 가능 |
| prompt size 증가 | prefill 비용 증가, TTFT/latency 증가 가능 |
| max tokens 증가 | decode 시간 증가, total latency 증가 가능 |
| long prompt + 높은 concurrency | KV cache/GPU memory 압박 증가 가능 |

### 7. streaming TTFT benchmark

```bash
bash scripts/06_benchmark_streaming.sh
```

확인할 것:

- `ttft_avg`
- `ttft_p50`
- `ttft_p95`
- `stream_total_seconds`

값을 직접 바꾸는 예:

```bash
# baseline streaming
CONCURRENCY=1 PROMPT_SIZE=short MAX_TOKENS=64 OUTPUT=results/stream_baseline.csv bash scripts/06_benchmark_streaming.sh

# 동시 streaming 요청 증가
CONCURRENCY=4 PROMPT_SIZE=short MAX_TOKENS=64 OUTPUT=results/stream_c4.csv bash scripts/06_benchmark_streaming.sh

# 긴 prompt가 TTFT에 주는 영향 보기
CONCURRENCY=2 PROMPT_SIZE=long MAX_TOKENS=64 OUTPUT=results/stream_long_prompt.csv bash scripts/06_benchmark_streaming.sh

# 긴 output이 전체 완료 시간에 주는 영향 보기
CONCURRENCY=2 PROMPT_SIZE=medium MAX_TOKENS=256 OUTPUT=results/stream_long_output.csv bash scripts/06_benchmark_streaming.sh
```

기대되는 변화:

- `PROMPT_SIZE=long`은 첫 token 전에 처리할 prompt가 많아져 `ttft_*`가 증가할 수 있다.
- `MAX_TOKENS` 증가는 첫 token보다 전체 완료 시간에 더 큰 영향을 줄 가능성이 높다.
- `CONCURRENCY`가 높아지면 `ttft_p95`가 평균보다 더 많이 나빠질 수 있다.

### 8. GPU/server 상태 기록

```bash
bash scripts/07_collect_gpu_metrics.sh
```

이 script는 자동으로 파일에 저장하지 않고 terminal에 출력한다.
기록으로 남기고 싶으면 직접 파일로 저장한다.

```bash
bash scripts/07_collect_gpu_metrics.sh | tee results/gpu_metrics_after_benchmark.txt
```

볼 것:

| 위치 | 확인할 것 | 해석 |
| --- | --- | --- |
| `nvidia-smi` Memory-Usage | GPU memory가 거의 꽉 찼는가 | OOM 또는 KV cache 부족 위험 |
| `nvidia-smi` GPU-Util | GPU가 충분히 바쁜가 | 낮으면 CPU/network/waiting 병목 가능 |
| `nvidia-smi` Processes | vLLM process가 GPU memory를 쓰는가 | model이 GPU에 올라갔는지 확인 |
| `docker ps` | `vllm-perf-server`가 Up 상태인가 | container가 죽었으면 benchmark 결과를 믿기 어렵다 |
| `docker logs` | OOM, preemption, worker crash, model loading error | 성능 숫자보다 error 원인 확인이 우선 |

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
