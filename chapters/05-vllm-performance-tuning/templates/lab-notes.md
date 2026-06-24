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

기록할 값:

- Host: local WSL 또는 remote GPU server
- Docker: `docker --version`
- GPU: `nvidia-smi`
- vLLM image: `vllm/vllm-openai:latest` 또는 사용한 tag
- Model: `Qwen/Qwen3-0.6B`
- Served model name: `qwen3-0.6b`

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
