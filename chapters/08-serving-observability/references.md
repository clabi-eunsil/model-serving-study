# References

모델 서버 관측성 도구와 metric 이름, dashboard provisioning 방식, DCGM exporter image tag는 업데이트될 수 있다.
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| Prometheus metric types | https://prometheus.io/docs/concepts/metric_types/ | Counter, Gauge, Histogram, Summary 차이와 latency에는 Histogram이 적합한 이유를 본다. |
| Prometheus configuration | https://prometheus.io/docs/prometheus/latest/configuration/configuration/ | `scrape_configs`, `scrape_interval`, target 설정 방법을 확인한다. |
| Prometheus naming best practices | https://prometheus.io/docs/practices/naming/ | metric 이름에 단위와 suffix를 넣는 관례, label cardinality 주의사항을 본다. |
| prometheus_client Python instrumenting | https://prometheus.github.io/client_python/instrumenting/ | Python에서 Counter, Gauge, Histogram을 어떻게 정의하고 사용하는지 본다. |
| prometheus_client FastAPI example | https://prometheus.github.io/client_python/exporting/http/fastapi-gunicorn/ | FastAPI에서 `/metrics`를 ASGI app으로 mount하는 예시를 본다. |
| Grafana provisioning | https://grafana.com/docs/grafana/latest/administration/provisioning/ | datasource와 dashboard를 파일로 자동 등록하는 방법을 확인한다. |
| NVIDIA DCGM Exporter | https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html | GPU utilization, memory 같은 GPU metric을 Prometheus로 노출하는 방법을 본다. |

## 업데이트 가능성이 큰 정보

- Prometheus/Grafana/DCGM exporter Docker image tag
- Grafana dashboard JSON schema version
- DCGM exporter 실행 옵션과 권한 설정
- Docker Compose GPU device reservation 방식
- Prometheus native histogram 지원과 권장 사용 방식
