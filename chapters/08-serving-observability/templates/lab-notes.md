# Chapter 08 Lab Notes

## Sources

- Prometheus metric types: https://prometheus.io/docs/concepts/metric_types/
- Prometheus configuration: https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- Prometheus naming best practices: https://prometheus.io/docs/practices/naming/
- prometheus_client Python: https://prometheus.github.io/client_python/instrumenting/
- prometheus_client FastAPI: https://prometheus.github.io/client_python/exporting/http/fastapi-gunicorn/
- Grafana provisioning: https://grafana.com/docs/grafana/latest/administration/provisioning/
- NVIDIA DCGM Exporter: https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html

## Commands

환경 확인:

```bash
cd ~/study/model-serving/chapters/08-serving-observability
bash scripts/01_check_env.sh
```

client/server Python 환경:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

터미널 1: metric을 노출하는 FastAPI model server 실행

```bash
bash scripts/02_run_model_server.sh
```

터미널 2: 요청과 metrics 확인

```bash
bash scripts/03_curl_generate.sh
bash scripts/04_curl_metrics.sh
```

터미널 2: Prometheus/Grafana 실행

```bash
bash scripts/05_start_monitoring.sh
bash scripts/06_check_prometheus_targets.sh
```

load 생성:

```bash
bash scripts/07_generate_load.sh
```

Prometheus query:

```bash
bash scripts/08_query_prometheus.sh
```

GPU 서버에서 선택: DCGM exporter 실행

```bash
bash scripts/09_start_dcgm_exporter.sh
```

마무리:

```bash
bash scripts/10_stop_monitoring.sh
deactivate
```

FastAPI server는 실행 중인 터미널에서 `Ctrl+C`로 종료한다.

## Environment

예상 확인:

| 항목 | 의미 | 정상/주의 기준 |
| --- | --- | --- |
| Host | monitoring stack 실행 위치 | local Docker Desktop/WSL 또는 remote server에서 진행한다. |
| Python | FastAPI model server 실행 환경 | `python3 --version`으로 확인한다. |
| Docker | Prometheus/Grafana 실행 기반 | `docker --version`이 정상 출력되어야 한다. |
| Docker Compose | monitoring stack 실행 방식 | `docker compose version`이 정상 출력되어야 한다. |
| Prometheus image | metrics 수집 component | 기본 실습은 `prom/prometheus:v3.5.0`을 사용한다. |
| Grafana image | dashboard component | 기본 실습은 `grafana/grafana:12.0.2`를 사용한다. |
| DCGM exporter image | GPU metrics exporter | GPU 서버에서만 필요하며 공식 문서의 tag를 확인한다. |
| GPU | GPU metrics 확인 가능 여부 | GPU가 없으면 DCGM exporter 실습은 건너뛸 수 있다. |

## Expected Endpoints

| Endpoint | 용도 |
| --- | --- |
| http://127.0.0.1:8000/health | FastAPI model server 상태 확인 |
| http://127.0.0.1:8000/metrics/ | Prometheus exposition format 확인 |
| http://127.0.0.1:9090 | Prometheus UI |
| http://127.0.0.1:3000 | Grafana UI, `admin/admin` |
| http://127.0.0.1:9400/metrics | DCGM exporter, GPU 서버에서만 |

## Expected Metrics

`bash scripts/04_curl_metrics.sh`에서 볼 metric:

| Metric | Type | 의미 |
| --- | --- | --- |
| `model_server_requests_total` | Counter | `/generate` 요청 수 누적. `status` label로 성공/실패를 나누어 본다. |
| `model_server_generated_tokens_total` | Counter | 생성된 output token 수 누적. `rate()`를 적용하면 tokens/sec가 된다. |
| `model_server_request_latency_seconds_bucket` | Histogram bucket | 요청 latency가 각 bucket에 얼마나 쌓였는지 본다. p50/p95 계산 재료다. |
| `model_server_request_latency_seconds_sum` | Histogram sum | 지금까지 관측한 latency 합계다. |
| `model_server_request_latency_seconds_count` | Histogram count | latency를 관측한 요청 수다. |
| `model_server_prompt_tokens_bucket` | Histogram bucket | prompt token 수 분포다. 입력 길이 변화 관측에 사용한다. |
| `model_server_completion_tokens_bucket` | Histogram bucket | completion token 수 분포다. 출력 길이 변화 관측에 사용한다. |
| `model_server_in_flight_requests` | Gauge | 현재 처리 중인 요청 수다. |
| `model_server_model_loaded` | Gauge | model 준비 상태다. 준비되면 `1`, 내려가면 `0`이다. |

Histogram 계열 metric은 하나만 생기지 않고 `_bucket`, `_sum`, `_count`가 함께 노출된다.
처음에는 `_bucket`이 percentile 계산 재료이고, `_sum`/`_count`는 평균 계산 재료라고 이해하면 충분하다.

## Observations

처음 볼 패턴:

| 관찰 | 해석 |
| --- | --- |
| `model_server_requests_total` 증가 | `/generate` 요청이 들어왔다는 뜻 |
| `status="error"` 증가 | 실패 요청이 발생했다는 뜻 |
| latency histogram bucket 증가 | 요청 latency가 bucket 경계에 따라 누적 기록되는 중 |
| generated tokens/sec 증가 | output token 생성량이 늘어나는 중 |
| in-flight requests가 0보다 큼 | 처리 중인 요청이 있다는 뜻 |
| DCGM GPU utilization이 비어 있음 | GPU가 없거나 DCGM exporter가 실행되지 않았을 수 있음 |

## Errors

- Prometheus target이 down: FastAPI server가 꺼졌거나 `host.docker.internal` 연결이 안 되는지 확인한다.
- Grafana dashboard가 비어 있음: 먼저 load를 생성하고 Prometheus target 상태를 확인한다.
- `/metrics`에서 307이 보임: FastAPI mount endpoint가 `/metrics/`로 redirect하는 정상 동작일 수 있다. `bash scripts/04_curl_metrics.sh`처럼 `/metrics/`를 직접 호출한다.
- `/metrics/`가 404: FastAPI app에 Prometheus ASGI app이 mount되었는지 확인한다.
- DCGM exporter 실패: NVIDIA GPU, driver, NVIDIA Container Toolkit, Docker GPU 권한을 확인한다.
- Grafana login 실패: 실습 기본 계정은 `admin/admin`이다.

## Notes

- Prometheus는 application이 직접 push하는 방식이 아니라, 기본적으로 target의 `/metrics`를 주기적으로 scrape한다.
- Grafana는 metric을 저장하지 않고 Prometheus 같은 datasource를 query해서 dashboard를 그린다.
- GPU metric은 model server metric과 같은 시간축으로 봐야 latency 증가와 GPU 병목을 연결해 해석할 수 있다.
