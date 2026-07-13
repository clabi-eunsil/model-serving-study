# 7. 성능 테스트 방법론

이 단원에서는 모델 서버의 성능을 어떤 기준으로 측정하고 해석할지 정리한다.  
챕터 5가 vLLM option을 바꿔보는 실습이었다면, 챕터 7은 vLLM, NIM, FastAPI model server처럼 여러 backend에 공통으로 적용할 수 있는 benchmark 방법론을 다룬다.

성능 테스트 도구와 vLLM benchmark script는 업데이트될 수 있다.  
이 문서는 2026년 6월 기준 공식 문서를 바탕으로 작성했다.  
핵심 공식 문서는 본문에 바로 연결해 두고, 전체 목록은 [references.md](references.md)에 모아 둔다.

## 학습 목표

- TTFT, TTFB, TTFP의 차이를 구분한다.
- end-to-end latency와 inter-token latency를 나누어 해석한다.
- p50, p90, p95, p99 latency가 무엇을 의미하는지 설명한다.
- requests/sec와 tokens/sec가 왜 다르게 보일 수 있는지 이해한다.
- throughput과 latency trade-off를 benchmark 결과로 읽는다.
- `wrk`, `hey`, `k6`, `locust` 같은 일반 HTTP 부하 도구와 LLM 전용 benchmark의 차이를 안다.
- OpenAI-compatible endpoint에 custom Python async benchmark를 실행한다.
- benchmark 결과 CSV를 요약하고 다음 실험과 비교한다.

## 추천 진행 순서

1. [../../GLOSSARY.md](../../GLOSSARY.md)에서 performance 관련 용어를 확인한다.
2. 아래 핵심 개념 요약을 읽는다.
3. [공식 문서 바로가기](#공식-문서-바로가기)에서 benchmark 도구별 확인 지점을 본다.
4. benchmark 대상 server를 다시 실행한다. 예: 챕터 4/5의 vLLM 또는 챕터 6의 NIM.
5. [scripts/01_check_env.sh](scripts/01_check_env.sh)로 client 환경과 endpoint를 확인한다.
6. Python `.venv`를 만들고 dependency를 설치한다.
7. [scripts/02_warmup_endpoint.sh](scripts/02_warmup_endpoint.sh)로 warmup 요청을 보낸다.
8. [scripts/03_run_single_benchmark.sh](scripts/03_run_single_benchmark.sh)로 단일 조건 benchmark를 실행한다.
9. [scripts/04_run_benchmark_matrix.sh](scripts/04_run_benchmark_matrix.sh)로 concurrency, prompt 길이, output 길이를 바꿔본다.
10. [scripts/05_run_streaming_ttft.sh](scripts/05_run_streaming_ttft.sh)로 streaming TTFT를 관찰한다.
11. [scripts/06_summarize_results.sh](scripts/06_summarize_results.sh)로 CSV 결과를 요약한다.
12. [scripts/07_collect_context.sh](scripts/07_collect_context.sh)로 server log, GPU 상태, endpoint 정보를 함께 기록한다.
13. [scripts/08_cleanup.sh](scripts/08_cleanup.sh)와 [templates/lab-notes.md](templates/lab-notes.md)를 보며 실습을 마무리한다.

## 공식 문서 바로가기

| 문서 | 바로 볼 부분 |
| --- | --- |
| [vLLM Benchmarking](https://docs.vllm.ai/en/latest/benchmarking/) | vLLM benchmark script 종류와 serving benchmark 관점 |
| [vLLM Production Metrics](https://docs.vllm.ai/en/latest/usage/metrics/) | latency, throughput, scheduler, cache metric |
| [OpenAI Chat Completions API](https://platform.openai.com/docs/api-reference/chat/create) | OpenAI-compatible request/response 구조 비교 |
| [k6 HTTP metrics](https://grafana.com/docs/k6/latest/using-k6/metrics/reference/) | HTTP load test 기본 latency, request rate, failure metric |
| [Locust documentation](https://docs.locust.io/) | Python으로 user behavior 기반 load test 작성 |
| [hey](https://github.com/rakyll/hey) | 단순 HTTP endpoint 부하 CLI |
| [wrk](https://github.com/wg/wrk) | thread/connection/duration 기반 HTTP benchmark |

## 실행 환경 기준

이 챕터는 benchmark client를 만드는 챕터다.  
모델 서버 자체는 챕터 4, 5, 6에서 만든 vLLM 또는 NIM server를 다시 실행해서 benchmark target으로 사용한다.

우리는 매 챕터 실습 마무리에서 server/container를 종료하고 `.venv`에서 나오기로 했다.
따라서 챕터 7을 시작할 때는 이전 server가 계속 떠 있다고 가정하지 않는다.
먼저 benchmark 대상 server를 하나 다시 띄운 뒤, 챕터 7의 `.venv`를 새로 만든다.

예:

```bash
# vLLM 챕터에서 띄운 server
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="qwen3-0.6b"

# NIM 챕터에서 띄운 server라면 model 이름을 /v1/models 응답에 맞춘다.
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="meta/llama-3.1-8b-instruct"
```

benchmark client는 Python `.venv`에서 실행한다.

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

실습 후:

```bash
deactivate
```

## Benchmark Target 다시 띄우기

챕터 7은 "어떤 server를 테스트할지"를 먼저 정해야 한다.
아래 중 하나만 선택해서 실행한다.

### 선택 A. 챕터 4 vLLM server

가장 단순한 선택이다.
챕터 4에서 사용한 vLLM Online Serving를 다시 실행한다.

터미널 1:

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/02_run_vllm_docker.sh
```

터미널 2:

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="qwen3-0.6b"
```

끝낼 때:

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/08_stop_server.sh
```

### 선택 B. 챕터 5 tuned vLLM server

성능 option을 바꿔가며 비교하고 싶을 때 선택한다.

터미널 1:

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/02_run_vllm_tuned.sh
```

터미널 2:

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="qwen3-0.6b"
```

끝낼 때:

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/08_stop_server.sh
```

### 선택 C. 챕터 6 NIM server

NIM과 vLLM을 같은 benchmark client로 비교하고 싶을 때 선택한다.
이 방법은 NGC 계정, `NGC_API_KEY`, GPU 서버, NIM image 권한이 필요하다.

터미널 1:

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
export NGC_API_KEY=...
export NIM_IMAGE="NGC catalog에서 확인한 image/tag"
bash scripts/04_run_nim_container.sh
```

터미널 2:

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="NIM의 /v1/models 응답에 나온 model id"
```

끝낼 때:

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
bash scripts/10_stop_container.sh
```

target server가 준비되었는지는 아래 명령으로 확인한다.

```bash
curl "${BASE_URL}/models"
```

## 챕터 5와의 차이

| 구분 | 챕터 5 | 챕터 7 |
| --- | --- | --- |
| 중심 질문 | vLLM option과 workload가 성능에 어떤 영향을 주는가? | 어떤 server든 공통으로 성능을 어떻게 측정하고 해석할 것인가? |
| 대상 | vLLM server | OpenAI-compatible endpoint 전체 |
| 주요 파일 | vLLM tuned run script, async benchmark | generic OpenAI-compatible async benchmark |
| 결과 해석 | vLLM scheduler, KV cache, GPU memory 중심 | latency percentile, TTFT, throughput, 실험 조건 통제 중심 |

## 핵심 개념 요약

### End-to-End Latency

end-to-end latency는 client가 요청을 보내기 시작한 시점부터 응답 전체를 받을 때까지 걸린 시간이다.
network, queueing, model inference, response serialization이 모두 포함된다.

LLM non-streaming 요청에서는 사용자가 전체 답변을 받기까지의 시간으로 볼 수 있다.

조금 더 풀어서 보면, 요청 하나는 대략 아래 구간을 지난다.

```text
client
  -> network
  -> server queue
  -> model inference
  -> response serialization
  -> network
  -> client
```

각 구간의 의미는 다음과 같다.

| 구간 | 의미 | 느려질 수 있는 상황 |
| --- | --- | --- |
| client overhead | benchmark client가 request payload를 만들고 HTTP 요청을 준비하는 시간 | client machine CPU가 부족하거나, benchmark client 자체가 너무 많은 concurrency를 만들 때 |
| network | client와 server 사이에서 요청/응답이 이동하는 시간 | 원격 GPU 서버, VPN, SSH port forwarding, cloud region 차이 |
| queueing | server가 이미 바빠서 요청이 바로 GPU 작업에 들어가지 못하고 기다리는 시간 | concurrency가 높거나, `max-num-seqs`/scheduler 한계에 걸리거나, 이전 요청들이 길게 실행 중일 때 |
| model inference | 모델이 prompt를 처리하고 token을 생성하는 시간 | prompt가 길거나, output token 수가 많거나, GPU가 느리거나, KV cache memory 압박이 있을 때 |
| response serialization | server가 모델 출력을 JSON/SSE 같은 HTTP 응답 형식으로 바꾸는 시간 | 응답이 매우 크거나, streaming chunk를 많이 만들거나, server CPU가 바쁠 때 |

그래서 latency가 높게 나왔다고 해서 바로 "모델 자체가 느리다"고 보면 안 된다.
예를 들어 전체 latency가 `1200ms`라면 내부적으로는 아래처럼 쪼개질 수 있다.

```text
network: 40ms
queueing: 300ms
model inference: 820ms
response serialization: 40ms
total: 1200ms
```

benchmark 결과를 해석할 때는 아래처럼 의심 지점을 나누어 본다.

| 관찰 | 먼저 의심할 것 | 같이 볼 것 |
| --- | --- | --- |
| concurrency를 올렸더니 p95 latency가 급증 | queueing 증가 | server log, GPU utilization, requests/sec 정체 여부 |
| 원격 GPU 서버에서만 느림 | network 또는 SSH tunneling 영향 | local/remote 비교, ping, 같은 server 안에서 client 실행 |
| output token 수를 늘렸더니 total latency 증가 | decode 시간이 증가 | max_tokens, completion length, tokens/sec |
| prompt를 길게 했더니 첫 응답이 늦음 | prefill 비용 증가 | prompt token 수, TTFT, GPU memory |
| 첫 요청만 유독 느림 | cold start, model loading, CUDA warmup, cache 준비 | warmup 전후 latency 비교, server log |
| latency가 높고 GPU 사용률이 낮음 | client/network 병목 또는 server queue 설정 문제 | client CPU, network, server log, request error |

이 챕터의 custom benchmark가 측정하는 `latency_ms`는 이런 구간을 모두 합친 값이다.
따라서 더 깊게 원인을 찾으려면 benchmark 숫자와 함께 server log, GPU metric, network 위치, prompt/output 조건을 같이 기록해야 한다.

챕터 8에서는 Prometheus, Grafana, DCGM exporter처럼 지속적으로 metric을 수집하는 방법을 다룬다.
하지만 챕터 7에서도 간단한 원인 확인은 할 수 있다.
[scripts/07_collect_context.sh](scripts/07_collect_context.sh)는 benchmark 직후 아래 정보를 한 번에 출력한다.

- `BASE_URL`, `MODEL_NAME`, `CONTAINER_NAME`
- `/v1/models` 응답
- `nvidia-smi` GPU snapshot
- `docker ps` container 상태
- `docker logs --tail` server log 일부

예:

```bash
# 챕터 4 vLLM server를 benchmark한 경우
CONTAINER_NAME=vllm-intro-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_intro.txt

# 챕터 5 tuned vLLM server를 benchmark한 경우
CONTAINER_NAME=vllm-performance-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_tuned.txt

# 챕터 6 NIM server를 benchmark한 경우
CONTAINER_NAME=nim-llm-server \
bash scripts/07_collect_context.sh | tee results/context_nim.txt
```

### TTFT, TTFB, TTFP

| 지표 | 의미 | 주의 |
| --- | --- | --- |
| TTFB | Time To First Byte. HTTP 응답의 첫 byte까지 걸린 시간 | LLM token 생성과 1:1로 같지 않을 수 있다. |
| TTFT | Time To First Token. 첫 token 또는 첫 streaming chunk까지 걸린 시간 | streaming 형식에 따라 첫 chunk가 실제 token인지 확인해야 한다. |
| TTFP | Time To First Prediction. 첫 예측까지 걸린 시간 | 도구/조직마다 정의가 달라서 반드시 정의를 적어야 한다. |

이 챕터의 streaming benchmark에서 `ttft_ms`는 **첫 streaming data chunk가 도착한 시간**이다.
대부분의 LLM serving 실습에서는 TTFT에 가깝게 해석할 수 있지만, server가 첫 chunk에 metadata를 먼저 보낼 수도 있으므로 문서에 정의를 남긴다.

### Inter-Token Latency

inter-token latency는 streaming 중 token 또는 chunk 사이의 간격이다.
첫 token이 빨리 와도 이후 token 간격이 길면 답변이 끊기는 것처럼 느껴질 수 있다.

이 챕터의 custom client는 TTFT와 total latency를 우선 다룬다.
inter-token latency는 다음 단계에서 streaming chunk timestamp를 모두 저장하도록 확장할 수 있다.

### Percentile Latency

평균 latency만 보면 느린 요청을 놓치기 쉽다.
p50, p90, p95, p99는 latency를 낮은 순서로 정렬했을 때 특정 위치의 값을 의미한다.

예:

```text
p50: 절반의 요청은 이 시간 이하로 끝났다.
p95: 95%의 요청은 이 시간 이하로 끝났고, 나머지 5%는 더 느렸다.
p99: 가장 느린 1%에 가까운 tail latency를 본다.
```

운영에서는 평균보다 p95/p99가 더 중요할 때가 많다.
사용자는 평균 사용자가 아니라 느린 요청을 경험한 사용자일 수 있기 때문이다.

### Requests/sec vs Tokens/sec

requests/sec는 초당 완료한 요청 수다.
tokens/sec는 초당 생성 또는 처리한 token 수다.

LLM에서는 requests/sec만 보면 부족하다.
요청 1개가 16 token을 생성하는 경우와 512 token을 생성하는 경우는 같은 1 request라도 부하가 완전히 다르다.

### Throughput과 Latency Trade-off

concurrency를 올리면 GPU가 더 바빠져 throughput이 올라갈 수 있다.
하지만 처리 한계를 넘으면 queueing이 생겨 p95/p99 latency가 급격히 나빠질 수 있다.

benchmark에서는 아래 모양을 찾는다.

```text
낮은 concurrency: latency 낮음, throughput 낮음
적절한 concurrency: latency 조금 증가, throughput 증가
과한 concurrency: throughput 정체, tail latency 급증, error/OOM 가능
```

### 일반 HTTP 부하 도구와 LLM Benchmark

`wrk`, `hey`, `k6`, `locust`는 이 챕터의 필수 설치 도구가 아니다.
처음 실습 환경에 설치되어 있지 않은 것이 정상이다.
기본 실습은 우리가 만든 [client/03_openai_benchmark.py](client/03_openai_benchmark.py)로 진행한다.

이 도구들은 나중에 HTTP 부하 테스트를 더 넓게 비교할 때 사용한다.

| 도구 | 장점 | 단점/주의 | 잘 맞는 상황 | 공식/주요 링크 |
| --- | --- | --- | --- | --- |
| custom Python async benchmark | OpenAI-compatible payload, `max_tokens`, streaming TTFT, CSV 저장을 직접 제어할 수 있다. | benchmark client 구현이 맞는지 스스로 검증해야 한다. 아주 높은 부하 생성에는 한계가 있다. | LLM serving을 처음 배우며 측정 지점을 이해할 때 | [client/03_openai_benchmark.py](client/03_openai_benchmark.py) |
| `hey` | 설치와 사용이 단순하고, 짧은 HTTP endpoint를 빠르게 때려볼 수 있다. | LLM streaming, token usage, prompt 조건 관리에는 약하다. | `/health`, `/metrics`, 간단한 REST endpoint smoke load test | [hey GitHub](https://github.com/rakyll/hey) |
| `wrk` | 매우 높은 HTTP 부하를 만들 수 있고 성능이 좋다. | chat completions JSON payload나 동적 prompt를 다루려면 Lua script가 필요하다. LLM metric 해석은 직접 해야 한다. | gateway, reverse proxy, 단순 HTTP path의 최대 처리량 테스트 | [wrk GitHub](https://github.com/wg/wrk) |
| `k6` | scenario, threshold, metric을 코드로 관리하기 좋고 CI에 붙이기 쉽다. | JavaScript로 test script를 작성해야 하고, LLM token/chunk parsing은 직접 구현해야 한다. | 성능 기준선을 정하고 반복 테스트/CI 검증을 하고 싶을 때 | [k6 docs](https://grafana.com/docs/k6/latest/) |
| `locust` | Python으로 사용자 행동 시나리오를 만들 수 있고 web UI가 편하다. | 부하 생성기 자체의 resource도 신경 써야 하며, 재현 가능한 조건을 잘 고정해야 한다. | 여러 사용자 행동, session, 단계적 부하를 시뮬레이션할 때 | [Locust docs](https://docs.locust.io/) |

처음 선택 기준:

```text
LLM token/streaming까지 보고 싶다 -> custom Python benchmark
간단한 endpoint가 죽지 않는지만 보고 싶다 -> hey
HTTP gateway의 순수 처리량을 세게 밀어보고 싶다 -> wrk
CI에서 성능 기준을 pass/fail로 관리하고 싶다 -> k6
사용자 행동 시나리오를 만들고 싶다 -> locust
```

### vLLM Benchmark Script는 언제 쓰는가

vLLM은 자체 benchmark script를 제공한다.
이 script들은 vLLM project가 권장하는 방식으로 serving throughput과 latency를 측정할 때 유용하다.

이 챕터에서는 직접 만든 [client/03_openai_benchmark.py](client/03_openai_benchmark.py)를 먼저 사용한다.
이유는 benchmark client 내부에서 latency와 TTFT를 어디서 재는지 직접 보기 위해서다.
내가 측정 지점을 이해한 뒤에는 공식 vLLM benchmark와 결과를 비교하면 좋다.

공식 vLLM benchmark를 볼 때 확인할 것:

| 확인할 것 | 이유 |
| --- | --- |
| benchmark script 이름과 위치 | vLLM version에 따라 script 구조가 바뀔 수 있다. |
| backend/server URL option | 이미 떠 있는 OpenAI-compatible server를 칠지, offline engine을 측정할지 구분해야 한다. |
| dataset 또는 synthetic input 설정 | 실제 traffic과 비슷한 prompt/output 길이인지 확인해야 한다. |
| request rate 또는 concurrency 설정 | 내가 만든 custom benchmark의 concurrency 조건과 비교하기 위해 필요하다. |
| 출력 metric 정의 | latency, TTFT, throughput이 어떤 기준으로 계산되는지 확인해야 한다. |

관련 문서는 [references.md](references.md)의 vLLM Benchmarking 항목을 본다.

## 학습 포인트와 파일 안내

| 파일 | 볼 부분 | 이유 |
| --- | --- | --- |
| [client/03_openai_benchmark.py](client/03_openai_benchmark.py) | `run_one_request`, `run_benchmark`, `print_summary` | 요청별 latency/TTFT를 어디서 측정하는지 이해한다. |
| [scripts/03_run_single_benchmark.sh](scripts/03_run_single_benchmark.sh) | 단일 조건 실행 | 처음에는 benchmark 결과 CSV 구조를 확인한다. |
| [scripts/04_run_benchmark_matrix.sh](scripts/04_run_benchmark_matrix.sh) | concurrency/prompt/output 반복 | 한 번에 하나의 조건만 바꾸는 실험 설계를 익힌다. |
| [scripts/05_run_streaming_ttft.sh](scripts/05_run_streaming_ttft.sh) | `--stream` option | streaming에서 TTFT를 측정하는 흐름을 본다. |
| [client/06_summarize_results.py](client/06_summarize_results.py) | CSV 요약 | raw result를 p50/p95 요약표로 바꾸는 방법을 본다. |

## 실습

### 1. benchmark target 준비

먼저 챕터 4, 5, 6 중 하나의 server를 다시 실행한다.

예: 챕터 4 vLLM server

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/02_run_vllm_docker.sh
```

챕터 7 terminal에서는 target 정보를 맞춘다.

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="qwen3-0.6b"
```

### 2. 환경 확인

```bash
bash scripts/01_check_env.sh
```

확인할 것:

- `/v1/models` 응답이 오는가?
- `BASE_URL`이 `/v1`까지 포함하는가?
- `MODEL_NAME`이 server의 served model name과 일치하는가?
- `k6`, `locust`, `hey`, `wrk`가 `not found (optional)`로 나와도 괜찮다. 이 챕터의 기본 실습에는 필요 없다.

### 3. client `.venv` 준비

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 4. warmup

```bash
bash scripts/02_warmup_endpoint.sh
```

첫 요청이 느린 것은 이상한 일이 아니다.
benchmark에는 cold start와 steady state를 섞어 해석하지 않도록 warmup 후 결과를 본다.

### 5. 단일 조건 benchmark

```bash
bash scripts/03_run_single_benchmark.sh
```

이 script의 기본 고정 조건은 아래와 같다.

| 조건 | 기본값 | 의미 |
| --- | --- | --- |
| `BASE_URL` | `http://127.0.0.1:8000/v1` | benchmark target OpenAI-compatible API 주소 |
| `MODEL_NAME` | `qwen3-0.6b` | request payload의 `model` field에 들어갈 이름 |
| `REQUESTS` | `8` | 총 요청 수 |
| `CONCURRENCY` | `2` | 동시에 진행할 최대 요청 수 |
| `PROMPT_SIZE` | `short` | 짧은 prompt 사용 |
| `MAX_TOKENS` | `64` | 요청당 최대 output token 수 |
| `stream` | `false` | streaming이 아닌 일반 응답으로 total latency 측정 |
| `OUTPUT` | `results/single_benchmark.csv` | 요청별 결과 CSV 저장 위치 |

조건을 바꾸고 싶으면 환경변수로 덮어쓴다.

```bash
CONCURRENCY=4 MAX_TOKENS=128 bash scripts/03_run_single_benchmark.sh
```

예상 출력:

```text
## Single benchmark condition
requests=8
concurrency=2
prompt_size=short
max_tokens=64
stream=false

## Benchmark Summary
requests_total=8
requests_success=8
requests_failed=0
elapsed_seconds=...
requests_per_second=...
latency_avg_ms=...
latency_p50_ms=...
latency_p95_ms=...
output=results/single_benchmark.csv
```

CSV에는 요청별 결과가 저장된다.

```bash
head results/single_benchmark.csv
```

### 6. 조건별 benchmark matrix

```bash
bash scripts/04_run_benchmark_matrix.sh
```

처음 관찰할 변화:

| 바꾼 값 | 기대되는 변화 |
| --- | --- |
| concurrency 증가 | requests/sec는 증가할 수 있지만 p95 latency도 증가할 수 있다. |
| prompt size 증가 | prefill 부담이 커져 latency가 증가할 수 있다. |
| max_tokens 증가 | decode가 길어져 total latency가 증가할 수 있다. |
| error 증가 | server overload, timeout, OOM, model name mismatch 가능성을 확인한다. |

### 7. streaming TTFT benchmark

```bash
bash scripts/05_run_streaming_ttft.sh
```

확인할 것:

- `ttft_p50_ms`, `ttft_p95_ms`가 출력되는가?
- total latency는 길어도 TTFT가 짧으면 사용자는 답변이 빨리 시작된다고 느낄 수 있다.
- TTFT가 높으면 prompt 길이, queueing, server 부하, cold start를 함께 의심한다.

### 8. 결과 요약

```bash
bash scripts/06_summarize_results.sh | tee results/summary.csv
```

요약표에서 볼 것:

- 같은 prompt/output 조건에서 concurrency별 p95 latency
- 같은 concurrency에서 prompt size별 latency 변화
- 같은 concurrency에서 max_tokens별 total latency 변화
- streaming 결과의 TTFT p50/p95

### 9. benchmark context 수집

benchmark 숫자만 저장하지 말고, 같은 시점의 server/GPU 상태도 함께 남긴다.

선택한 benchmark target에 맞춰 `CONTAINER_NAME`을 다르게 넣는다.

| 대상 | CONTAINER_NAME | 저장 파일 예시 |
| --- | --- | --- |
| 챕터 4 vLLM | `vllm-intro-server` | `results/context_vllm_intro.txt` |
| 챕터 5 tuned vLLM | `vllm-performance-server` | `results/context_vllm_tuned.txt` |
| 챕터 6 NIM | `nim-llm-server` | `results/context_nim.txt` |

챕터 4 vLLM을 benchmark했다면:

```bash
CONTAINER_NAME=vllm-intro-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_intro.txt
```

챕터 5 tuned vLLM을 benchmark했다면:

```bash
CONTAINER_NAME=vllm-performance-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_tuned.txt
```

챕터 6 NIM을 benchmark했다면:

```bash
CONTAINER_NAME=nim-llm-server \
bash scripts/07_collect_context.sh | tee results/context_nim.txt
```

확인할 것:

- GPU memory가 거의 가득 찼는가?
- GPU utilization이 높은가, 낮은가?
- server log에 OOM, timeout, model loading, auth error가 있는가?
- container가 계속 `Up` 상태인가?

### 10. 실습 마무리

```bash
bash scripts/08_cleanup.sh
deactivate
```

server는 이 챕터가 띄운 것이 아니므로, server를 실행한 챕터에서 종료한다.

예:

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/08_stop_server.sh
```

## 확인 질문

| 질문 | 정리 |
| --- | --- |
| 평균 latency만 보면 왜 부족한가? | 느린 일부 요청을 놓칠 수 있어서 p95/p99 tail latency를 함께 봐야 한다. |
| requests/sec와 tokens/sec는 왜 다르게 해석해야 하는가? | 요청당 token 수가 다르면 같은 request 수라도 실제 연산량이 다르기 때문이다. |
| TTFT가 낮고 total latency가 높으면 어떤 상태인가? | 답변은 빨리 시작하지만 전체 생성이 오래 걸리는 상태다. 긴 output이나 느린 decode를 의심한다. |
| concurrency를 올렸는데 throughput이 더 이상 늘지 않으면? | server/GPU가 포화되었거나 queueing, memory 병목, timeout이 생겼을 수 있다. |
| 일반 HTTP benchmark 도구만으로 LLM 성능을 보기 어려운 이유는? | token 길이, streaming chunk, TTFT, output token 수 같은 LLM 특화 지표를 직접 다루기 어렵기 때문이다. |

## 다음 챕터에서 이어질 내용

다음 챕터에서는 benchmark 숫자를 한 번 보고 끝내지 않고, Prometheus, Grafana, DCGM exporter 같은 관측성 도구로 server와 GPU 상태를 지속적으로 보는 방법을 다룬다.
