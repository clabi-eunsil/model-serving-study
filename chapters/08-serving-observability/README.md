# 8. 모델 서빙 관측성

이 단원에서는 모델 서버를 운영할 때 어떤 metrics를 봐야 하는지, 그리고 Prometheus와 Grafana로 그 metrics를 어떻게 수집하고 시각화하는지 실습한다.  
챕터 7이 "benchmark를 한 번 실행해서 결과 CSV를 남기는 방법"이었다면, 챕터 8은 "서버가 실행되는 동안 계속 상태를 보는 방법"이다.

관측성 도구, dashboard provisioning 방식, DCGM exporter image tag는 업데이트될 수 있다.  
이 문서는 2026년 7월 기준 공식 문서를 바탕으로 작성했다.  
핵심 공식 문서는 본문에 바로 연결해 두고, 전체 목록은 [references.md](references.md)에 모아 둔다.

## 학습 목표

- 모델 서버에서 필요한 metrics를 정의한다.
- Prometheus metric type과 exposition format을 이해한다.
- FastAPI `/metrics` endpoint를 Prometheus 형식으로 만든다.
- Prometheus가 model server metrics를 scrape하는 흐름을 이해한다.
- Grafana dashboard가 Prometheus datasource를 query하는 방식을 이해한다.
- DCGM exporter가 GPU metric을 Prometheus로 노출하는 방식을 학습한다.
- API latency, error rate, throughput을 함께 해석한다.
- token usage, prompt length, completion length를 추적해야 하는 이유를 정리한다.

## 추천 진행 순서

1. [../../GLOSSARY.md](../../GLOSSARY.md)에서 observability, Prometheus, Grafana 관련 용어를 확인한다.
2. 아래 핵심 개념 요약을 읽는다.
3. [공식 문서 바로가기](#공식-문서-바로가기)에서 Prometheus/Grafana/DCGM 문서의 확인 위치를 본다.
4. [scripts/01_check_env.sh](scripts/01_check_env.sh)로 Python/Docker/GPU 환경을 확인한다.
5. 챕터별 `.venv`를 만들고 dependency를 설치한다.
6. [scripts/02_run_model_server.sh](scripts/02_run_model_server.sh)로 metric을 노출하는 FastAPI server를 실행한다.
7. [scripts/03_curl_generate.sh](scripts/03_curl_generate.sh), [scripts/04_curl_metrics.sh](scripts/04_curl_metrics.sh)로 요청과 metric 출력을 확인한다.
8. [scripts/05_start_monitoring.sh](scripts/05_start_monitoring.sh)로 Prometheus/Grafana를 실행한다.
9. [scripts/06_check_prometheus_targets.sh](scripts/06_check_prometheus_targets.sh)로 scrape 상태를 확인한다.
10. [scripts/07_generate_load.sh](scripts/07_generate_load.sh)로 그래프에 보일 traffic을 만든다.
11. [scripts/08_query_prometheus.sh](scripts/08_query_prometheus.sh)로 PromQL query 결과를 확인한다.
12. GPU 서버라면 [scripts/09_start_dcgm_exporter.sh](scripts/09_start_dcgm_exporter.sh)로 GPU metric을 확인한다.
13. [scripts/10_stop_monitoring.sh](scripts/10_stop_monitoring.sh)와 [templates/lab-notes.md](templates/lab-notes.md)를 보며 실습을 마무리한다.

## 공식 문서 바로가기

| 문서 | 바로 볼 부분 |
| --- | --- |
| [Prometheus metric types](https://prometheus.io/docs/concepts/metric_types/) | Counter, Gauge, Histogram, Summary 차이 |
| [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) | `scrape_configs`, `scrape_interval`, target 설정 |
| [Prometheus naming best practices](https://prometheus.io/docs/practices/naming/) | metric 이름, 단위 suffix, label cardinality 주의 |
| [prometheus_client Python instrumenting](https://prometheus.github.io/client_python/instrumenting/) | Python에서 Counter/Gauge/Histogram 정의 |
| [prometheus_client FastAPI example](https://prometheus.github.io/client_python/exporting/http/fastapi-gunicorn/) | FastAPI에서 `/metrics`를 ASGI app으로 mount |
| [Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/) | datasource와 dashboard 파일 자동 등록 |
| [NVIDIA DCGM Exporter](https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html) | GPU utilization/memory metric을 Prometheus로 노출 |

## 실행 환경 기준

이 챕터는 두 가지 실행 환경을 함께 사용한다.

| 구성요소 | 실행 위치 | 이유 |
| --- | --- | --- |
| FastAPI model server | 챕터 `.venv`의 host process | app code와 `/metrics` 구현을 직접 보기 위해 |
| Prometheus | Docker Compose | scrape server를 빠르게 띄우기 위해 |
| Grafana | Docker Compose | dashboard provisioning을 실습하기 위해 |
| DCGM exporter | Docker Compose, GPU 서버 선택 실습 | GPU utilization/memory metric을 Prometheus로 노출하기 위해 |

Python `.venv` 준비:

```bash
cd ~/study/model-serving/chapters/08-serving-observability
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

실습 후:

```bash
deactivate
```

## 챕터 7과의 차이

| 구분 | 챕터 7 | 챕터 8 |
| --- | --- | --- |
| 질문 | benchmark 결과를 어떻게 측정하고 해석할까? | 운영 중인 서버 상태를 어떻게 계속 볼까? |
| 데이터 | CSV, context snapshot | time series metrics |
| 도구 | custom benchmark client | Prometheus, Grafana, DCGM exporter |
| 관점 | 실험 단위 측정 | 지속적인 관측과 dashboard |

## 핵심 개념 요약

### Observability

Observability는 시스템 밖에서 관찰한 신호를 통해 내부 상태를 추론할 수 있게 만드는 능력이다.
모델 서버에서는 보통 아래 세 가지 신호를 함께 본다.

| 신호 | 예시 | 이 챕터에서 다루는 정도 |
| --- | --- | --- |
| Metrics | latency, error rate, requests/sec, GPU memory | 핵심 실습 |
| Logs | model loading error, OOM, timeout stack trace | 간단히 언급 |
| Traces | 한 요청이 여러 service를 지나간 경로 | 챕터 9 Langfuse에서 더 다룸 |

### 모델 서버에서 필요한 Metrics

모델 서버는 일반 API 서버 metric과 LLM/model-specific metric을 함께 봐야 한다.

| 범주 | Metric | 왜 필요한가 |
| --- | --- | --- |
| Traffic | requests/sec, requests_total | 요청이 얼마나 들어오는지 본다. |
| Error | errors_total, error rate | 실패율이 늘어나는지 본다. |
| Latency | p50/p95/p99 latency | 사용자가 느끼는 응답 지연과 tail latency를 본다. |
| Saturation | in-flight requests, queue depth | server가 밀리고 있는지 본다. |
| Token | prompt tokens, completion tokens, tokens/sec | LLM workload 크기를 request 수보다 더 정확히 본다. |
| GPU | GPU utilization, GPU memory used | GPU 병목과 OOM 위험을 본다. |
| Model state | model loaded, warmup status | 준비되지 않은 server로 traffic이 가는 것을 막는다. |

### Prometheus Metric Types

Prometheus 공식 문서는 핵심 metric type으로 Counter, Gauge, Histogram, Summary를 설명한다.
이 챕터에서는 Counter, Gauge, Histogram을 사용한다.

Metric type은 "그래프 모양"을 뜻하는 말이 아니다.
같은 숫자라도 **그 값이 어떤 성질을 가지는지**에 따라 저장 방식을 고르는 것이다.

| Type | 쉬운 의미 | 값의 움직임 | 모델 서버 예시 |
| --- | --- | --- | --- |
| Counter | 누적 횟수 | 계속 증가한다. 보통 줄어들지 않는다. | `requests_total`, `errors_total`, `generated_tokens_total` |
| Gauge | 현재 상태값 | 증가할 수도 있고 감소할 수도 있다. | `in_flight_requests`, `model_loaded`, GPU memory |
| Histogram | 여러 관측값의 분포 | 값을 bucket 구간별로 쌓는다. | request latency, prompt token length, completion token length |
| Summary | application 쪽에서 요약한 분포/분위수 | client library가 quantile 등을 계산한다. | 이 실습에서는 사용하지 않는다. latency는 Histogram으로 시작한다. |

조금 더 풀어보면 아래처럼 이해하면 된다.

- Counter는 "지금까지 몇 번 일어났는가"를 센다. 예를 들어 총 요청 수는 서버가 재시작되지 않는 한 10에서 9로 줄어들면 이상하다.
- Gauge는 "지금 현재 얼마인가"를 본다. 예를 들어 처리 중인 요청 수는 0에서 5로 늘었다가 요청이 끝나면 다시 0으로 줄 수 있다.
- Histogram은 "값들이 어느 구간에 많이 몰려 있는가"를 본다. 예를 들어 latency가 0.1초 이하인지, 0.5초 이하인지, 1초 이하인지 bucket에 누적해서 p95 같은 값을 계산할 수 있게 한다.
- Summary도 분포를 요약하는 타입이지만, Prometheus server에서 자유롭게 집계하기가 Histogram보다 까다로운 경우가 많다. 그래서 처음 운영 metric을 만들 때는 latency를 Histogram으로 잡는 편이 이해하고 확장하기 쉽다.

Latency는 Histogram으로 남기는 것이 좋다.
Prometheus query에서 `histogram_quantile()`을 사용하면 p50/p95 같은 percentile을 계산할 수 있기 때문이다.

### Prometheus Scrape

Prometheus는 application이 metric을 보내주기를 기다리는 것이 아니라, 설정된 target의 `/metrics` endpoint를 주기적으로 가져간다.
이 방식을 scrape라고 한다.

이번 실습의 흐름:

```text
FastAPI /metrics
  <- Prometheus scrape
  <- Grafana query
```

즉 Grafana가 FastAPI app을 직접 보는 것이 아니다.
Grafana는 Prometheus datasource에 PromQL query를 보내 dashboard를 그린다.

### Label과 Cardinality

Label은 metric을 나누어 보는 차원이다.
예를 들어 `status="success"`와 `status="error"`로 성공/실패를 나눌 수 있다.

Cardinality는 쉽게 말해 "값의 종류가 몇 개나 되는가"다.
Prometheus에서는 metric 이름과 label 조합 하나하나가 별도의 time series가 된다.

예를 들어 아래 metric은 label 조합이 2개라서 time series도 2개다.

```text
model_server_requests_total{status="success"}
model_server_requests_total{status="error"}
```

이 정도는 괜찮다.
그런데 label에 `user_id`를 넣으면 상황이 달라진다.

```text
model_server_requests_total{user_id="user-000001"}
model_server_requests_total{user_id="user-000002"}
model_server_requests_total{user_id="user-000003"}
...
```

사용자가 100,000명이면 이 metric 하나만으로도 time series가 100,000개 생길 수 있다.
여기에 `endpoint`, `model`, `status` 같은 label이 더 붙으면 조합 수는 더 커진다.
이처럼 label 값 조합이 너무 많아지는 상태를 high cardinality라고 한다.

High cardinality가 나쁜 이유는 단순히 "그래프가 복잡해진다"가 아니다.
Prometheus가 저장해야 할 time series 수가 급증하고, memory 사용량과 disk 사용량이 늘고, query가 느려진다.
심하면 monitoring system 자체가 느려져서 장애 상황에서 metric을 확인하기 어려워질 수 있다.

피해야 할 label:

- `user_id`
- raw `prompt`
- request id
- session id
- 긴 URL 전체

좋은 label:

- endpoint
- status
- model
- method

기억할 기준은 이렇다.
값의 종류가 제한되어 있고 운영 판단에 필요한 label은 좋다.
값이 요청마다 계속 새로 생기거나 너무 많은 label은 피한다.

### Token Usage와 Length

LLM serving에서는 request 수만으로 workload를 설명하기 어렵다.
짧은 prompt와 긴 prompt는 같은 1 request라도 비용이 다르다.

예를 들어 아래 두 요청은 API metric으로는 둘 다 `1 request`다.

| 요청 | 입력/출력 예시 | 모델 입장에서의 차이 |
| --- | --- | --- |
| 짧은 질문 | "안녕?" → 20 token 답변 | prompt 처리도 짧고 decode도 금방 끝난다. |
| 긴 문서 요약 | 5,000자 문서 → 800 token 요약 | prefill, KV cache, decode 시간이 모두 커진다. |

그래서 `requests/sec`만 보면 "서버가 초당 요청 몇 개를 받는지"는 알 수 있지만,
모델이 실제로 얼마나 많은 token을 처리했는지는 놓칠 수 있다.
반대로 `tokens/sec`는 prompt와 completion 길이 차이를 더 잘 반영하므로 LLM workload 크기를 이해하는 데 중요하다.

따라서 아래 값을 함께 본다.

| 항목 | 의미 |
| --- | --- |
| prompt length / prompt tokens | prefill 비용과 KV cache 사용량에 영향 |
| completion length / completion tokens | decode 시간과 total latency에 영향 |
| generated tokens/sec | 실제 생성 처리량 |

실무에서는 둘 중 하나만 고르기보다 같이 본다.
`requests/sec`는 API traffic 규모를 보고, `tokens/sec`는 LLM engine이 실제로 처리한 생성량을 본다.
같은 `10 requests/sec`라도 짧은 챗봇 답변 10개와 긴 문서 요약 10개는 GPU 사용량과 latency가 크게 다를 수 있다.

### DCGM Exporter

DCGM exporter는 NVIDIA GPU 상태를 Prometheus metric으로 노출하는 exporter다.
GPU utilization, memory used, power, temperature 같은 값을 볼 수 있다.

이 챕터에서는 optional GPU 실습으로 둔다.
로컬에 GPU가 없으면 FastAPI/Prometheus/Grafana까지만 진행해도 된다.

## 학습 포인트와 파일 안내

| 파일 | 볼 부분 | 이유 |
| --- | --- | --- |
| [app/main.py](app/main.py) | Prometheus metric 정의와 `/metrics` mount | FastAPI app이 metric을 노출하는 방식 이해 |
| [monitoring/prometheus/prometheus.yml](monitoring/prometheus/prometheus.yml) | `scrape_configs` | Prometheus가 어떤 target을 scrape하는지 확인 |
| [docker-compose.yml](docker-compose.yml) | prometheus, grafana, dcgm-exporter service | 관측성 stack 구성 이해 |
| [monitoring/grafana/provisioning](monitoring/grafana/provisioning) | datasource/dashboard 자동 등록 | Grafana provisioning 흐름 이해 |
| [scripts/07_generate_load.sh](scripts/07_generate_load.sh) | 성공/실패 요청 생성 | dashboard에 변화가 보이도록 traffic 만들기 |
| [scripts/08_query_prometheus.sh](scripts/08_query_prometheus.sh) | PromQL query | Grafana 없이 terminal에서 metric 확인 |

## Docker Compose 파일 읽는 법

챕터 8의 [docker-compose.yml](docker-compose.yml)은 모델 서버를 container로 띄우는 파일이 아니다.
모델 서버는 `.venv`에서 `bash scripts/02_run_model_server.sh`로 host process로 실행한다.
Docker Compose는 그 모델 서버를 관측하기 위한 Prometheus, Grafana, 선택 사항인 DCGM exporter를 띄운다.

흐름은 아래처럼 보면 된다.

```text
Host .venv FastAPI server
  http://127.0.0.1:8000/metrics/
          ↑
          | scrape
Prometheus container
  http://127.0.0.1:9090
          ↑
          | PromQL query
Grafana container
  http://127.0.0.1:3000
```

### `prometheus` service

Prometheus는 `monitoring/prometheus/prometheus.yml` 설정을 읽고 target을 scrape한다.
여기서 중요한 부분은 `host.docker.internal:8000`이다.

Prometheus는 Docker container 안에서 실행된다.
container 안의 `127.0.0.1`은 host가 아니라 Prometheus container 자기 자신이다.
그래서 host에서 실행 중인 FastAPI server를 보려면 `host.docker.internal:8000` 같은 host 접근 이름이 필요하다.

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

이 설정은 Linux Docker 환경에서도 `host.docker.internal` 이름이 host gateway를 가리키도록 돕는다.
Docker Desktop에서는 보통 기본 동작하지만, 환경에 따라 이 설정이 있어야 안정적이다.

### `grafana` service

Grafana는 metric을 저장하지 않는다.
Prometheus를 datasource로 등록하고, Prometheus에 query를 보내 dashboard를 그린다.

이 챕터에서는 Grafana UI에서 수동으로 datasource와 dashboard를 만들지 않는다.
대신 아래 디렉터리를 container에 mount해서 시작 시 자동 등록한다.

| Host 경로 | Container 경로 | 역할 |
| --- | --- | --- |
| `monitoring/grafana/provisioning` | `/etc/grafana/provisioning` | datasource/dashboard provider 자동 등록 |
| `monitoring/grafana/dashboards` | `/var/lib/grafana/dashboards` | dashboard JSON 파일 위치 |

이 방식을 provisioning이라고 한다.
실습을 반복하거나 Git으로 관리할 때 UI에서 손으로 만든 dashboard보다 재현성이 좋다.

### `dcgm-exporter` service

DCGM exporter는 GPU metric을 Prometheus 형식으로 노출한다.
하지만 GPU가 없는 로컬 환경에서는 실행할 수 없으므로 `profiles: ["gpu"]`로 분리해두었다.

기본 실행:

```bash
docker compose up -d prometheus grafana
```

GPU 서버에서 선택 실행:

```bash
docker compose --profile gpu up -d dcgm-exporter
```

DCGM exporter가 뜨면 Prometheus는 `dcgm-exporter:9400/metrics`를 scrape하고,
Grafana dashboard의 GPU 패널에 값이 들어오기 시작한다.

## 실습

### 1. 환경 확인

```bash
cd ~/study/model-serving/chapters/08-serving-observability
bash scripts/01_check_env.sh
```

GPU가 없어도 괜찮다.
DCGM exporter 실습만 건너뛰면 된다.

### 2. Python `.venv` 준비

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. FastAPI model server 실행

터미널 1:

```bash
bash scripts/02_run_model_server.sh
```

확인 URL:

```text
http://127.0.0.1:8000/health
http://127.0.0.1:8000/metrics/
```

브라우저나 `curl -v http://127.0.0.1:8000/metrics`에서 `307 Temporary Redirect`가 보여도 이상한 것은 아니다.
FastAPI에 Prometheus ASGI app을 `app.mount("/metrics", ...)`로 붙이면 slash가 없는 `/metrics`를 slash가 있는 `/metrics/`로 보내는 redirect가 발생할 수 있다.
실습 스크립트와 Prometheus 설정은 처음부터 `/metrics/`를 호출하도록 맞춰둔다.

### 4. 요청과 metrics 확인

터미널 2:

```bash
bash scripts/03_curl_generate.sh
bash scripts/04_curl_metrics.sh
```

`/metrics/`에서 아래 이름들이 보이면 성공이다.
처음에는 값 자체보다 "metric이 노출되고 있는지"와 "어떤 의미의 값인지"를 확인한다.

| Metric | Type | 의미 |
| --- | --- | --- |
| `model_server_requests_total` | Counter | `/generate` 요청이 총 몇 번 들어왔는지 센다. `status="success"`와 `status="error"` label로 성공/실패를 나누어 볼 수 있다. |
| `model_server_generated_tokens_total` | Counter | fake model이 지금까지 생성한 output token 수를 누적한다. `rate()`를 적용하면 tokens/sec를 볼 수 있다. |
| `model_server_request_latency_seconds_bucket` | Histogram bucket | 요청 latency가 몇 초 이하 bucket에 들어갔는지 누적한다. p50/p95 latency 계산의 재료가 된다. |
| `model_server_request_latency_seconds_sum` | Histogram sum | 관측된 latency 전체 합계다. 평균 latency를 계산할 때 사용할 수 있다. |
| `model_server_request_latency_seconds_count` | Histogram count | latency가 관측된 요청 수다. |
| `model_server_prompt_tokens_bucket` | Histogram bucket | prompt token 수가 어느 구간에 많이 들어오는지 본다. 긴 입력이 늘어나는지 확인할 때 유용하다. |
| `model_server_completion_tokens_bucket` | Histogram bucket | completion/output token 수 분포를 본다. 긴 답변이 latency를 늘리는지 볼 때 필요하다. |
| `model_server_in_flight_requests` | Gauge | 현재 처리 중인 `/generate` 요청 수다. 요청이 끝나면 다시 줄어든다. |
| `model_server_model_loaded` | Gauge | model이 준비된 상태인지 나타낸다. 이 실습에서는 fake model 준비 시 `1`, 종료 시 `0`으로 둔다. |

Histogram을 만들면 Prometheus 출력에는 보통 `_bucket`, `_sum`, `_count`가 함께 생긴다.
`_bucket`은 percentile 계산에 쓰이고, `_sum`과 `_count`는 평균을 계산할 때 쓸 수 있다.

### 5. Prometheus와 Grafana 실행

```bash
bash scripts/05_start_monitoring.sh
```

접속:

| 도구 | URL | 로그인 |
| --- | --- | --- |
| Prometheus | http://127.0.0.1:9090 | 없음 |
| Grafana | http://127.0.0.1:3000 | `admin` / `admin` |

### 6. Prometheus target 확인

```bash
bash scripts/06_check_prometheus_targets.sh
```

확인할 것:

- `model-server` target이 `up`인가?
- target URL이 `host.docker.internal:8000`인가?
- scrape error가 없는가?
- `dcgm-exporter` target은 GPU 선택 실습 전에는 `down`이어도 괜찮다.

Prometheus UI에서는:

```text
Status > Targets
```

에서 확인한다.

### 7. Load 생성

```bash
bash scripts/07_generate_load.sh
```

이 script는 성공 요청과 의도적 실패 요청을 섞어 보낸다.
그래야 Grafana에서 request rate, error count, latency 변화가 보인다.

### 8. Prometheus query 확인

```bash
bash scripts/07_generate_load.sh
sleep 6
bash scripts/08_query_prometheus.sh
```

`sleep 6`을 두는 이유는 Prometheus scrape interval이 5초이기 때문이다.
load를 만든 직후 바로 query하면 Prometheus가 아직 새 metric 값을 가져가기 전일 수 있다.

주요 query:

| Query | 보는 것 | 해석 |
| --- | --- | --- |
| `sum(rate(model_server_requests_total[1m]))` | 최근 1분 기준 초당 요청 수 | `model_server_requests_total`은 계속 증가하는 Counter다. `rate(...[1m])`는 최근 1분 동안의 초당 증가 속도를 계산하고, `sum(...)`은 label별 값을 합쳐 전체 request rate를 보여준다. |
| `sum(rate(model_server_requests_total{status="error"}[1m]))` | 최근 1분 기준 초당 실패 요청 수 | `status="error"` label만 골라 실패 요청 증가 속도를 본다. error rate가 0보다 크면 실패가 발생하고 있다는 뜻이다. |
| `sum(rate(model_server_generated_tokens_total[1m]))` | 최근 1분 기준 초당 생성 token 수 | LLM이 실제로 생성한 token 처리량을 본다. 요청 수가 같아도 긴 답변이 많으면 이 값이 커질 수 있다. |
| `histogram_quantile(0.95, sum(rate(model_server_request_latency_seconds_bucket[1m])) by (le))` | p95 request latency | latency Histogram bucket을 이용해 최근 1분의 p95 latency를 추정한다. `le`는 bucket upper bound, 즉 "이 시간 이하" 경계값이다. |
| `sum(model_server_in_flight_requests)` | 현재 처리 중인 요청 수 | Gauge라서 현재 값을 바로 본다. 요청이 끝나면 감소한다. 값이 계속 높게 유지되면 처리 지연이나 병목을 의심한다. |

PromQL을 처음 볼 때는 아래처럼 나누어 읽으면 덜 어렵다.

```text
rate(counter[1m])
  → 최근 1분 동안 counter가 초당 얼마나 증가했는가

sum(...)
  → label별로 나뉜 값을 합쳐 전체 값을 본다

histogram_quantile(0.95, ... by (le))
  → histogram bucket을 이용해 p95 값을 추정한다

gauge metric
  → rate를 쓰지 않고 현재 값을 바로 본다
```

Prometheus HTTP API 결과에서 `value`는 아래처럼 두 값으로 나온다.

```json
"value": [
  1783330203.128,
  "0"
]
```

첫 번째 값은 query가 평가된 Unix timestamp다.
두 번째 값이 실제 query 결과다.
따라서 `"0"`이나 `"NaN"`은 무시할 값이 아니라 현재 PromQL 결과로 해석해야 한다.

자주 보이는 결과:

| 결과 | 의미 | 다음에 볼 것 |
| --- | --- | --- |
| `"0"` | 최근 query window에서 증가량이 없거나 현재 처리 중인 요청이 없음 | `bash scripts/07_generate_load.sh` 실행 후 `sleep 6` 뒤 다시 query |
| `"NaN"` | Histogram bucket에 최근 관측값이 없어 percentile을 계산할 수 없음 | `/generate` 요청을 만든 뒤 Prometheus scrape가 된 후 다시 query |
| 값이 있음 | 해당 metric이 Prometheus에 저장되고 query가 계산됨 | Grafana dashboard에서도 같은 흐름 확인 |

특히 `histogram_quantile()`의 `NaN`은 "서버 장애"라기보다
최근 1분 동안 latency histogram에 계산할 관측값이 없다는 뜻인 경우가 많다.
load를 생성하고 Prometheus가 한 번 scrape한 뒤 다시 보면 숫자로 바뀐다.

### 9. Grafana dashboard 확인

Grafana에 접속한다.

```text
http://127.0.0.1:3000
```

왼쪽 메뉴에서 dashboard를 열고 `Model Serving Overview`를 확인한다.

보이는 패널:

- Request Rate
- Error Rate
- Latency Percentiles
- Generated Tokens/sec
- Prompt/Completion Token Length
- In-flight Requests
- GPU Utilization from DCGM
- GPU Memory Used from DCGM

GPU가 없는 환경에서는 DCGM 패널이 비어 있을 수 있다.
이것은 정상이다.

### 10. 선택 실습: DCGM exporter

GPU 서버에서만 실행한다.

```bash
bash scripts/09_start_dcgm_exporter.sh
```

확인:

```bash
curl http://127.0.0.1:9400/metrics | head
```

Prometheus target 목록에서 `dcgm-exporter`가 `up`인지 확인한다.

### 11. 실습 마무리

Prometheus/Grafana/DCGM exporter 종료:

```bash
bash scripts/10_stop_monitoring.sh
```

FastAPI server 종료:

```text
터미널 1에서 Ctrl+C
```

Python `.venv` 종료:

```bash
deactivate
```

## Troubleshooting

### Docker image pull에서 `docker-credential-desktop.exe: exec format error`가 날 때

에러 예시:

```text
error getting credentials - err: fork/exec /usr/bin/docker-credential-desktop.exe: exec format error
```

이 에러는 Prometheus나 Grafana image 문제가 아니라 Docker credential helper 설정 문제다.
WSL 안의 Docker CLI가 image를 pull하기 전에 Docker Desktop credential helper인 `docker-credential-desktop.exe`를 실행하려고 했는데,
현재 WSL 환경에서 이 helper가 Linux 실행 파일처럼 처리되어 실패한 상황이다.

현재 설정 확인:

```bash
cat ~/.docker/config.json
```

아래처럼 되어 있으면 이 문제가 날 수 있다.

```json
{
  "credsStore": "desktop.exe"
}
```

이 챕터에서 사용하는 `prom/prometheus`와 `grafana/grafana`는 public image라 Docker Hub login이 꼭 필요하지 않다.
따라서 실습용으로는 credential helper 설정을 제거해도 된다.

백업 후 수정:

```bash
cp ~/.docker/config.json ~/.docker/config.json.bak-model-serving-study
printf '{}\n' > ~/.docker/config.json
```

그 다음 다시 실행한다.

```bash
bash scripts/05_start_monitoring.sh
```

나중에 Docker Desktop credential helper를 다시 쓰고 싶다면 백업 파일을 되돌린다.

```bash
cp ~/.docker/config.json.bak-model-serving-study ~/.docker/config.json
```

## 확인 질문

| 질문 | 정리 |
| --- | --- |
| Prometheus는 metrics를 push 받는가, scrape하는가? | 기본적으로 target의 `/metrics` endpoint를 주기적으로 scrape한다. |
| Grafana는 metrics를 저장하는가? | 보통 저장하지 않는다. Prometheus 같은 datasource를 query해 dashboard를 그린다. |
| latency에는 왜 Histogram을 쓰는가? | bucket에 관측값을 누적하면 PromQL에서 p50/p95 같은 percentile을 계산할 수 있기 때문이다. |
| Counter와 Gauge의 차이는 무엇인가? | Counter는 계속 증가하는 값이고, Gauge는 증가/감소할 수 있는 현재 상태 값이다. |
| prompt text를 label로 넣으면 왜 안 되는가? | label cardinality가 폭발하고 민감 정보가 metric에 남을 수 있기 때문이다. |
| GPU metric은 왜 API metric과 함께 봐야 하는가? | latency 증가가 GPU 포화, memory 압박, CPU/network 병목 중 무엇과 관련 있는지 추론하기 위해서다. |

## 다음 챕터에서 이어질 내용

다음 챕터에서는 Langfuse를 사용해 LLM 요청 단위 trace, prompt, completion, token usage, latency를 더 application-level 관점에서 추적한다.
