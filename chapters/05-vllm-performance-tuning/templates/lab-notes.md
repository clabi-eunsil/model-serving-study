# Chapter 05 Lab Notes

## Sources

- vLLM Optimization and Tuning: https://docs.vllm.ai/en/stable/configuration/optimization/
- vLLM Engine Arguments: https://docs.vllm.ai/en/stable/configuration/engine_args/
- vLLM Automatic Prefix Caching: https://docs.vllm.ai/en/stable/features/automatic_prefix_caching/
- vLLM benchmark scripts: https://github.com/vllm-project/vllm/tree/main/benchmarks
- PagedAttention paper: https://arxiv.org/abs/2309.06180

## Commands

환경 확인:

```bash
cd ~/study/model-serving/chapters/05-vllm-performance-tuning
bash scripts/01_check_env.sh
```

터미널 1: server 실행

```bash
bash scripts/02_run_vllm_tuned.sh
```

터미널 2: warmup

```bash
bash scripts/03_warmup.sh
```

터미널 2: client `.venv` 준비

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

터미널 2: benchmark

```bash
python client/04_benchmark_async.py --requests 8 --concurrency 2 --prompt-size short --max-tokens 64 --output results/bench_single.csv
bash scripts/05_run_benchmark_matrix.sh
bash scripts/06_benchmark_streaming.sh
bash scripts/07_collect_gpu_metrics.sh
```

실습 종료:

```bash
bash scripts/08_stop_server.sh
deactivate
```

## Environment

예상 확인:

| 항목 | 의미 | 정상/주의 기준 |
| --- | --- | --- |
| Host | benchmark를 실행할 위치 | GPU benchmark는 remote GPU server에서 진행하는 것이 자연스럽다. |
| Docker | vLLM server 실행 기반 | `docker --version`이 정상 출력되어야 한다. |
| GPU | model serving 자원 | `nvidia-smi`로 GPU memory와 utilization을 확인한다. |
| vLLM image | benchmark 대상 server image | `vllm/vllm-openai:latest` 또는 사용한 tag를 명시한다. |
| Model | benchmark 대상 model | 기본 실습은 `Qwen/Qwen3-0.6B`를 사용한다. |
| Served model name | client가 요청에 넣는 model 이름 | 기본 실습은 `qwen3-0.6b`를 사용한다. |

## Server Options

기본값:

```text
GPU_MEMORY_UTILIZATION=0.80
MAX_MODEL_LEN=2048
MAX_NUM_SEQS=16
MAX_NUM_BATCHED_TOKENS=4096
```

옵션을 바꾸면 아래에 기록한다.

| Run | GPU_MEMORY_UTILIZATION | MAX_MODEL_LEN | MAX_NUM_SEQS | MAX_NUM_BATCHED_TOKENS | VLLM_EXTRA_ARGS |
| --- | --- | --- | --- | --- | --- |
| baseline | 0.80 | 2048 | 16 | 4096 | none |

## Benchmark Matrix

기본 matrix:

| Prompt Size | Max Tokens | Concurrency |
| --- | --- | --- |
| short | 32 | 1, 2, 4 |
| short | 128 | 1, 2, 4 |
| long | 32 | 1, 2, 4 |
| long | 128 | 1, 2, 4 |

결과 파일:

```bash
ls -lh results/
```

처음에는 아래 순서로 실험하면 해석하기 쉽다.

### 1. Baseline

```bash
python client/04_benchmark_async.py \
  --requests 8 \
  --concurrency 1 \
  --prompt-size short \
  --max-tokens 32 \
  --output results/baseline.csv
```

기대:

- latency가 가장 낮은 편이어야 한다.
- throughput은 높지 않을 수 있다.
- error는 없어야 한다.

### 2. Concurrency 증가

```bash
python client/04_benchmark_async.py \
  --requests 16 \
  --concurrency 4 \
  --prompt-size short \
  --max-tokens 32 \
  --output results/concurrency4.csv
```

기대:

- `requests_per_second`가 baseline보다 증가할 수 있다.
- `latency_p95`는 baseline보다 증가할 수 있다.
- GPU memory와 GPU utilization도 함께 확인한다.

### 3. Prompt 길이 증가

```bash
python client/04_benchmark_async.py \
  --requests 8 \
  --concurrency 1 \
  --prompt-size long \
  --max-tokens 32 \
  --output results/long_prompt.csv
```

기대:

- prefill 비용 때문에 latency가 증가할 수 있다.
- streaming benchmark에서는 TTFT가 증가할 수 있다.

### 4. Output 길이 증가

```bash
python client/04_benchmark_async.py \
  --requests 8 \
  --concurrency 1 \
  --prompt-size short \
  --max-tokens 128 \
  --output results/long_output.csv
```

기대:

- decode 시간이 길어져 total latency가 증가할 수 있다.
- TTFT보다는 전체 완료 시간이 더 영향을 받을 가능성이 높다.

### 기록 표

| 실험 | requests | concurrency | prompt_size | max_tokens | latency_p50 | latency_p95 | requests/sec | tokens/sec | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 8 | 1 | short | 32 |  |  |  |  |  |
| concurrency4 | 16 | 4 | short | 32 |  |  |  |  |  |
| long_prompt | 8 | 1 | long | 32 |  |  |  |  |  |
| long_output | 8 | 1 | short | 128 |  |  |  |  |  |

## Expected Summary

`client/04_benchmark_async.py`는 아래 형태의 summary를 출력한다.

```text
## Benchmark Summary
requests=8
concurrency=2
prompt_size=short
max_tokens=64
stream=False
wall_seconds=...
success=8
errors=0
latency_avg=...
latency_p50=...
latency_p95=...
requests_per_second=...
completion_tokens_per_second=...
wrote_csv=results/bench_single.csv
```

streaming benchmark에서는 아래 값도 확인한다.

```text
ttft_avg=...
ttft_p50=...
ttft_p95=...
```

## Observations

- concurrency를 올리면 GPU 활용률과 throughput이 올라갈 수 있다.
- 어느 지점부터는 queueing 때문에 p95 latency가 나빠질 수 있다.
- prompt가 길면 prefill 비용과 KV cache memory가 늘어난다.
- max_tokens가 크면 decode 시간이 늘어나 total latency가 길어진다.
- streaming에서는 total latency보다 TTFT가 사용자 체감에 더 가까울 수 있다.
- benchmark 중 error가 있으면 평균 latency를 해석하기 전에 error 원인을 먼저 봐야 한다.

## GPU and Server Logs

상태 확인:

```bash
bash scripts/07_collect_gpu_metrics.sh
```

이 명령은 기본적으로 terminal에만 출력한다.
실험 기록으로 남기고 싶으면 아래처럼 저장한다.

```bash
bash scripts/07_collect_gpu_metrics.sh | tee results/gpu_metrics_after_c4.txt
```

기록할 것:

| 항목 | 볼 위치 | 기록/해석 |
| --- | --- | --- |
| GPU memory | `nvidia-smi`의 Memory-Usage | 거의 꽉 차면 OOM 또는 KV cache 부족 가능성 |
| GPU utilization | `nvidia-smi`의 GPU-Util | 낮으면 GPU보다 다른 병목일 수 있음 |
| GPU process | `nvidia-smi`의 Processes | vLLM/python process가 GPU memory를 쓰는지 확인 |
| container state | `docker ps` | `vllm-perf-server`가 Up 상태인지 확인 |
| OOM | `docker logs` | CUDA out of memory, OOM 메시지 확인 |
| preemption/cache warning | `docker logs` | latency 급증이나 throughput 저하와 연결될 수 있음 |
| worker crash | `docker logs` | benchmark 결과보다 서버 안정성 문제를 먼저 확인 |

해석 예시:

- `latency_p95`가 크게 증가했고 GPU memory가 거의 가득 찼다면, concurrency나 `max_tokens`가 과할 수 있다.
- `requests_per_second`가 낮고 GPU-Util도 낮다면, client 요청 수가 너무 적거나 server가 아직 warmup되지 않았을 수 있다.
- CSV의 `error` column에 값이 있고 logs에 OOM이 보이면, 그 run의 latency 평균은 의미가 약하다.

## Errors

- `Connection refused`: vLLM server가 아직 준비되지 않았거나 container가 실패했다.
- `RateLimitError`처럼 보이는 SDK error: local vLLM이 아니라 다른 endpoint를 보고 있는지 `base_url`을 확인한다.
- CUDA OOM: model/context/concurrency가 GPU memory에 비해 크다.
- p95 latency가 갑자기 커짐: concurrency가 너무 높거나 queueing/preemption이 생겼을 수 있다.
- CSV가 비어 있음: 모든 요청이 실패했을 수 있다. `error` column을 확인한다.

## Notes

- 이 챕터의 benchmark는 학습용이다. production-grade benchmark는 더 긴 duration, warmup 분리, 고정 dataset, 재시도 정책, percentile 분석이 필요하다.
- 결과는 단일 숫자보다 추세로 본다.
- vLLM option은 release마다 바뀔 수 있으므로 tuning 전 공식 문서를 확인한다.
