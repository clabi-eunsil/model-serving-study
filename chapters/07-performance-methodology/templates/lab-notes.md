# Chapter 07 Lab Notes

## Sources

- vLLM Benchmarking: https://docs.vllm.ai/en/latest/contributing/benchmarks.html
- vLLM Production Metrics: https://docs.vllm.ai/en/latest/usage/metrics.html
- OpenAI Chat Completions API: https://platform.openai.com/docs/api-reference/chat/create
- k6 HTTP metrics: https://grafana.com/docs/k6/latest/using-k6/metrics/reference/
- Locust documentation: https://docs.locust.io/
- hey: https://github.com/rakyll/hey
- wrk: https://github.com/wg/wrk

## Commands

target server 다시 실행:

선택 A. 챕터 4 vLLM:

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/02_run_vllm_docker.sh
```

선택 B. 챕터 5 tuned vLLM:

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/02_run_vllm_tuned.sh
```

선택 C. 챕터 6 NIM:

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
export NGC_API_KEY=...
export NIM_IMAGE="NGC catalog에서 확인한 image/tag"
bash scripts/04_run_nim_container.sh
```

benchmark client target 설정:

```bash
export BASE_URL="http://127.0.0.1:8000/v1"
export MODEL_NAME="qwen3-0.6b"
```

환경 확인:

```bash
cd ~/study/model-serving/chapters/07-performance-methodology
bash scripts/01_check_env.sh
```

client 환경:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

warmup:

```bash
bash scripts/02_warmup_endpoint.sh
```

단일 조건:

```bash
bash scripts/03_run_single_benchmark.sh
```

기본 조건:

| 조건 | 값 |
| --- | --- |
| requests | `8` |
| concurrency | `2` |
| prompt_size | `short` |
| max_tokens | `64` |
| stream | `false` |
| output | `results/single_benchmark.csv` |

matrix:

```bash
bash scripts/04_run_benchmark_matrix.sh
```

streaming TTFT:

```bash
bash scripts/05_run_streaming_ttft.sh
```

요약:

```bash
bash scripts/06_summarize_results.sh | tee results/summary.csv
```

context 수집:

선택한 benchmark target에 맞춰 하나만 실행한다.

챕터 4 vLLM:

```bash
CONTAINER_NAME=vllm-intro-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_intro.txt
```

챕터 5 tuned vLLM:

```bash
CONTAINER_NAME=vllm-performance-server \
bash scripts/07_collect_context.sh | tee results/context_vllm_tuned.txt
```

챕터 6 NIM:

```bash
CONTAINER_NAME=nim-llm-server \
bash scripts/07_collect_context.sh | tee results/context_nim.txt
```

마무리:

```bash
bash scripts/08_cleanup.sh
deactivate
```

server 종료:

```bash
# 챕터 4 vLLM
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/08_stop_server.sh

# 챕터 5 tuned vLLM
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/08_stop_server.sh

# 챕터 6 NIM
cd ~/study/model-serving/chapters/06-nvidia-nim
bash scripts/10_stop_container.sh
```

## Environment

기록할 값:

- Target server: vLLM / NIM / FastAPI
- BASE_URL: `http://127.0.0.1:8000/v1`
- MODEL_NAME: `/v1/models` 응답 기준
- Client Python: `python3 --version`
- Client package: `pip freeze`
- GPU/server 정보: server를 실행한 챕터의 runtime 기록 참고
- Optional tools: `k6`, `locust`, `hey`, `wrk`는 처음에는 없어도 정상

## Tool Choice

처음에는 custom Python benchmark만 사용한다.
다른 도구는 목적이 생겼을 때 설치한다.

| 목적 | 추천 도구 |
| --- | --- |
| LLM prompt/output/streaming TTFT를 직접 기록 | custom Python benchmark |
| 간단한 HTTP endpoint smoke load test | `hey` |
| gateway나 단순 HTTP path의 높은 부하 테스트 | `wrk` |
| CI에서 threshold 기반 성능 검증 | `k6` |
| 사용자 행동 시나리오 기반 load test | `locust` |

## Expected Results

단일 조건 benchmark 예상 출력:

```text
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

streaming benchmark 예상 출력:

```text
ttft_p50_ms=...
ttft_p95_ms=...
output=results/streaming_ttft.csv
```

## Observations

처음 볼 패턴:

| 실험 | 관찰 포인트 | 해석 |
| --- | --- | --- |
| concurrency 1 -> 8 | requests/sec, p95 latency | throughput이 오르다가 p95가 급격히 나빠지는 지점을 찾는다. |
| short -> long prompt | latency 증가 여부 | prompt가 길수록 prefill 비용이 커진다. |
| max_tokens 32 -> 128 | total latency 증가 여부 | output이 길수록 decode 시간이 길어진다. |
| streaming | TTFT와 total latency 차이 | 답변 시작 체감과 전체 완료 시간을 분리해서 본다. |

latency가 높을 때 나누어 볼 구간:

| 구간 | 확인할 것 |
| --- | --- |
| network | local/remote 차이, SSH port forwarding, 같은 서버 안에서 client 실행 시 차이 |
| queueing | concurrency 증가 시 p95/p99 급증, requests/sec 정체 여부 |
| model inference | prompt 길이, max_tokens, TTFT, tokens/sec, GPU utilization |
| response serialization | 응답 크기, streaming chunk 수, server CPU/log |
| cold start/warmup | 첫 요청과 warmup 이후 요청의 latency 차이 |

benchmark context에서 같이 볼 것:

| 항목 | 확인 이유 |
| --- | --- |
| `/v1/models` | benchmark target server가 의도한 model을 노출하는지 확인 |
| `nvidia-smi` | GPU memory, GPU utilization, 실행 process 확인 |
| `docker ps` | server container가 살아 있는지 확인 |
| `docker logs --tail` | OOM, timeout, auth error, model loading 실패 확인 |

## Errors

- `/v1/models` 실패: server가 아직 안 떴거나 `BASE_URL`이 틀렸을 수 있다.
- `model not found`: `MODEL_NAME`이 served model name과 다를 수 있다.
- timeout: concurrency나 output 길이가 server 처리량을 넘었을 수 있다.
- failed request 증가: overload, OOM, server crash, connection reset을 확인한다.
- TTFT가 비어 있음: `--stream`을 쓰지 않았거나 server streaming format이 예상과 다를 수 있다.

## Notes

- benchmark는 한 번의 숫자보다 같은 조건을 반복했을 때의 경향이 중요하다.
- 실험 조건은 한 번에 하나씩 바꾼다.
- raw CSV를 지우지 않는다. 요약값이 이상할 때 다시 확인해야 한다.
- server log와 GPU memory 기록을 함께 보면 숫자의 이유를 찾기 쉽다.
