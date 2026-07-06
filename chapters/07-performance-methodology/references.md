# References

성능 테스트 도구, metric 이름, vLLM benchmark script 옵션은 버전에 따라 바뀔 수 있다.
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| vLLM Benchmarking | https://docs.vllm.ai/en/latest/contributing/benchmarks.html | vLLM이 제공하는 benchmark script 종류와 serving benchmark 관점을 확인한다. |
| vLLM Production Metrics | https://docs.vllm.ai/en/latest/usage/metrics.html | 운영 환경에서 latency, throughput, scheduler, cache 관련 metric을 어떻게 보는지 확인한다. |
| OpenAI Chat Completions API | https://platform.openai.com/docs/api-reference/chat/create | OpenAI-compatible server에 보낼 request/response 구조를 비교한다. |
| k6 HTTP metrics | https://grafana.com/docs/k6/latest/using-k6/metrics/reference/ | HTTP load test에서 기본 제공되는 latency, request rate, failure metric을 확인한다. |
| Locust documentation | https://docs.locust.io/ | Python으로 user behavior 기반 load test를 작성하는 방식을 본다. |
| hey GitHub repository | https://github.com/rakyll/hey | 단순 HTTP endpoint에 빠르게 부하를 주는 CLI 도구의 옵션을 본다. |
| wrk GitHub repository | https://github.com/wg/wrk | 고성능 HTTP benchmark 도구의 thread/connection/duration 개념을 확인한다. |

## 업데이트 가능성이 큰 정보

- vLLM benchmark script 위치와 option 이름
- k6, Locust, hey, wrk의 설치 방법과 CLI option
- OpenAI-compatible API의 세부 response field
- 각 serving engine이 노출하는 token usage, streaming chunk 형식
