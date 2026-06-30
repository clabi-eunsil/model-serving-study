import argparse
import asyncio
import csv
import os
import statistics
import time
from pathlib import Path

from openai import AsyncOpenAI


# 이 benchmark client는 vLLM의 OpenAI-compatible endpoint를 비동기로 호출한다.
#
# 이 파일이 client/ 아래에 있는 이유:
# - 앞 챕터들과 마찬가지로 Python으로 작성한 client logic은 client/에 둔다.
# - scripts/에는 실행 순서를 보여주는 shell wrapper를 둔다.
# - 이렇게 나누면 "실제 요청 로직"과 "실습 실행 순서"가 덜 섞인다.
#
# 목표:
# - concurrency를 바꿨을 때 latency/throughput이 어떻게 변하는지 본다.
# - prompt 길이와 max_tokens가 성능에 어떤 영향을 주는지 본다.
# - streaming 모드에서는 첫 chunk까지의 시간, 즉 간단한 TTFT를 관찰한다.
#
# 정확한 production benchmark 도구는 뒤 챕터에서 더 다룬다.
# 여기서는 "성능 실험의 감각"을 만드는 작은 benchmark로 시작한다.


PROMPTS = {
    # prompt-size 옵션으로 선택할 입력 문장들이다.
    #
    # short:
    #   prefill 비용이 작다. concurrency 변화가 latency/throughput에 주는 영향을 보기 쉽다.
    #
    # medium:
    #   짧지도 길지도 않은 기본 비교용 입력이다.
    #
    # long:
    #   prompt token 수가 늘어나므로 prefill 비용과 KV cache 사용량이 커진다.
    #   같은 max_tokens/concurrency라도 short보다 latency가 늘어날 가능성이 높다.
    "short": "Explain vLLM in one short Korean sentence.",
    "medium": (
        "You are studying model serving. Explain how concurrency, latency, "
        "throughput, and GPU memory interact in vLLM. Answer in Korean."
    ),
    "long": (
        "You are studying model serving with vLLM. "
        "Compare online inference and batch inference, explain why KV cache "
        "grows with prompt length and concurrent requests, describe what TTFT "
        "means in streaming responses, and summarize how max_model_len and "
        "gpu_memory_utilization can affect performance. Answer in Korean."
    ),
}


def percentile(values: list[float], pct: float) -> float:
    # latency 결과는 평균만 보면 느린 요청을 놓치기 쉽다.
    # 그래서 p50, p95 같은 percentile을 함께 본다.
    #
    # p50:
    #   전체 요청 중 가운데 정도의 요청 latency.
    # p95:
    #   느린 쪽 5% 근처의 latency. tail latency가 나빠졌는지 볼 때 중요하다.
    if not values:
        return 0.0
    ordered = sorted(values)
    index = int((len(ordered) - 1) * pct)
    return ordered[index]


async def run_one_request(
    client: AsyncOpenAI,
    *,
    model: str,
    prompt: str,
    max_tokens: int,
    temperature: float,
    stream: bool,
    request_id: int,
) -> dict[str, float | int | str]:
    # 요청 1개를 보내고, 그 요청의 측정 결과를 dict로 돌려준다.
    #
    # 이 함수가 기록하는 값:
    # - total_seconds: 요청 시작부터 응답 완료까지 걸린 시간
    # - first_chunk_seconds: streaming일 때 첫 chunk가 오기까지 걸린 시간, 즉 간단한 TTFT
    # - output_chars: 생성된 글자 수. token 수가 없을 때 대략적인 출력 크기를 보기 위해 기록
    # - prompt_tokens/completion_tokens: server가 usage를 돌려준 경우에만 기록
    # - error: 요청 실패 시 예외 내용을 문자열로 기록
    started = time.perf_counter()
    first_chunk_seconds = 0.0
    output_chars = 0
    prompt_tokens = 0
    completion_tokens = 0
    error = ""

    try:
        if stream:
            # streaming 요청:
            # response 전체가 끝난 뒤 한 번에 오는 것이 아니라, chunk가 여러 번 도착한다.
            # 첫 번째 content chunk가 도착한 시점을 first_chunk_seconds로 기록한다.
            stream_started = time.perf_counter()
            chunks = await client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a concise tutor."},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=max_tokens,
                temperature=temperature,
                stream=True,
            )
            async for chunk in chunks:
                # chunk.choices[0].delta.content에는 이번 chunk에 새로 도착한 text 조각이 들어 있다.
                # 빈 chunk도 올 수 있으므로 content가 있을 때만 집계한다.
                delta = chunk.choices[0].delta.content
                if delta:
                    if first_chunk_seconds == 0.0:
                        first_chunk_seconds = time.perf_counter() - stream_started
                    output_chars += len(delta)
        else:
            # non-streaming 요청:
            # server가 답변 생성을 끝낸 뒤 완성된 JSON response를 한 번에 돌려준다.
            # 전체 latency는 보기 쉽지만, TTFT는 관찰할 수 없다.
            response = await client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a concise tutor."},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=max_tokens,
                temperature=temperature,
            )
            content = response.choices[0].message.content or ""
            output_chars = len(content)
            if response.usage is not None:
                # vLLM/OpenAI-compatible server가 usage를 제공하면 token 수를 기록한다.
                # completion_tokens가 있어야 tokens/sec 계산이 가능하다.
                prompt_tokens = response.usage.prompt_tokens or 0
                completion_tokens = response.usage.completion_tokens or 0
    except Exception as exc:  # noqa: BLE001 - benchmark result에 error를 기록하기 위해 broad catch를 사용한다.
        error = repr(exc)

    total_seconds = time.perf_counter() - started
    # CSV로 저장하기 쉽도록 dict 하나로 정리한다.
    return {
        "request_id": request_id,
        "total_seconds": round(total_seconds, 6),
        "first_chunk_seconds": round(first_chunk_seconds, 6),
        "output_chars": output_chars,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "error": error,
    }


async def run_benchmark(args: argparse.Namespace) -> list[dict[str, float | int | str]]:
    # benchmark 전체를 실행하는 함수다.
    #
    # 전체 흐름:
    # 1. OpenAI-compatible client를 만든다.
    # 2. prompt-size에 맞는 prompt를 고른다.
    # 3. concurrency 값만큼 동시에 요청을 보낼 수 있도록 Semaphore를 만든다.
    # 4. requests 개수만큼 요청 task를 만든다.
    # 5. 모든 요청이 끝나면 latency/throughput summary를 계산한다.
    client = AsyncOpenAI(base_url=args.base_url, api_key=args.api_key)
    prompt = PROMPTS[args.prompt_size]

    # Semaphore는 동시에 실행되는 요청 수를 제한한다.
    # 예를 들어 concurrency=4이면, 전체 requests가 20개여도 동시에 날아가는 요청은 최대 4개다.
    semaphore = asyncio.Semaphore(args.concurrency)
    results: list[dict[str, float | int | str]] = []

    async def guarded_request(request_id: int) -> None:
        # 개별 요청을 semaphore로 감싼다.
        # 이렇게 해야 "전체 요청 수"와 "동시 요청 수"를 분리해서 실험할 수 있다.
        async with semaphore:
            result = await run_one_request(
                client,
                model=args.model,
                prompt=prompt,
                max_tokens=args.max_tokens,
                temperature=args.temperature,
                stream=args.stream,
                request_id=request_id,
            )
            results.append(result)

    started = time.perf_counter()
    # asyncio.gather는 여러 async task를 동시에 진행시키고 모두 끝날 때까지 기다린다.
    # 여기서 wall_seconds는 benchmark 전체가 끝나는 데 걸린 시간이다.
    await asyncio.gather(*(guarded_request(i) for i in range(args.requests)))
    wall_seconds = time.perf_counter() - started

    # 실패한 요청은 latency/throughput 계산에서 제외하고, error 개수로 따로 보여준다.
    # 실패가 많다면 성능 숫자보다 error 원인을 먼저 봐야 한다.
    successful = [row for row in results if not row["error"]]
    latencies = [float(row["total_seconds"]) for row in successful]
    ttfts = [float(row["first_chunk_seconds"]) for row in successful if row["first_chunk_seconds"]]
    completion_tokens = sum(int(row["completion_tokens"]) for row in successful)

    print("## Benchmark Summary")
    print(f"base_url={args.base_url}")
    print(f"model={args.model}")
    print(f"requests={args.requests}")
    print(f"concurrency={args.concurrency}")
    print(f"prompt_size={args.prompt_size}")
    print(f"max_tokens={args.max_tokens}")
    print(f"stream={args.stream}")
    print(f"wall_seconds={wall_seconds:.3f}")
    print(f"success={len(successful)}")
    print(f"errors={len(results) - len(successful)}")
    if latencies:
        # requests/sec:
        #   성공한 요청 수 / benchmark 전체 실행 시간.
        #   concurrency를 올릴수록 어느 지점까지는 증가할 수 있다.
        print(f"latency_avg={statistics.mean(latencies):.3f}")
        print(f"latency_p50={percentile(latencies, 0.50):.3f}")
        print(f"latency_p95={percentile(latencies, 0.95):.3f}")
        print(f"requests_per_second={len(successful) / wall_seconds:.3f}")
    if completion_tokens:
        # completion_tokens/sec:
        #   생성된 output token 수 / benchmark 전체 실행 시간.
        #   LLM serving에서는 requests/sec와 함께 중요하다.
        print(f"completion_tokens_per_second={completion_tokens / wall_seconds:.3f}")
    if ttfts:
        # TTFT는 streaming 요청에서만 계산된다.
        # non-streaming 요청은 첫 token을 따로 볼 수 없으므로 값이 없다.
        print(f"ttft_avg={statistics.mean(ttfts):.3f}")
        print(f"ttft_p50={percentile(ttfts, 0.50):.3f}")
        print(f"ttft_p95={percentile(ttfts, 0.95):.3f}")

    return results


def write_csv(path: Path, rows: list[dict[str, float | int | str]]) -> None:
    # 요청별 raw result를 CSV로 저장한다.
    # summary는 terminal에 출력되고, 자세한 per-request 값은 CSV에서 다시 볼 수 있다.
    #
    # 예:
    #   results/bench_short_mt32_c1.csv
    #   results/bench_streaming.csv
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "request_id",
        "total_seconds",
        "first_chunk_seconds",
        "output_chars",
        "prompt_tokens",
        "completion_tokens",
        "error",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    # CLI 옵션을 정의한다.
    # 대부분 환경변수로도 바꿀 수 있게 해두었다.
    #
    # 예:
    #   CONCURRENCY=4 MAX_TOKENS=128 python client/04_benchmark_async.py
    #
    # 또는:
    #   python client/04_benchmark_async.py --concurrency 4 --max-tokens 128
    parser = argparse.ArgumentParser(description="Small async benchmark for vLLM.")
    parser.add_argument("--base-url", default=os.getenv("BASE_URL", "http://127.0.0.1:8000/v1"))
    parser.add_argument("--api-key", default=os.getenv("OPENAI_API_KEY", "EMPTY"))
    parser.add_argument("--model", default=os.getenv("SERVED_MODEL_NAME", "qwen3-0.6b"))
    parser.add_argument("--requests", type=int, default=int(os.getenv("REQUESTS", "8")))
    parser.add_argument("--concurrency", type=int, default=int(os.getenv("CONCURRENCY", "1")))
    parser.add_argument("--prompt-size", choices=sorted(PROMPTS), default=os.getenv("PROMPT_SIZE", "short"))
    parser.add_argument("--max-tokens", type=int, default=int(os.getenv("MAX_TOKENS", "64")))
    parser.add_argument("--temperature", type=float, default=float(os.getenv("TEMPERATURE", "0.0")))
    parser.add_argument("--stream", action="store_true")
    parser.add_argument(
        "--output",
        default=os.getenv("OUTPUT", "results/benchmark.csv"),
        help="CSV path for per-request results.",
    )
    return parser.parse_args()


async def async_main() -> None:
    # 프로그램의 실제 시작점이다.
    # 1. CLI 옵션을 읽는다.
    # 2. benchmark를 실행한다.
    # 3. 요청별 결과를 CSV로 저장한다.
    args = parse_args()
    results = await run_benchmark(args)
    write_csv(Path(args.output), results)
    print(f"wrote_csv={args.output}")


if __name__ == "__main__":
    asyncio.run(async_main())
