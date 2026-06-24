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
    started = time.perf_counter()
    first_chunk_seconds = 0.0
    output_chars = 0
    prompt_tokens = 0
    completion_tokens = 0
    error = ""

    try:
        if stream:
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
                delta = chunk.choices[0].delta.content
                if delta:
                    if first_chunk_seconds == 0.0:
                        first_chunk_seconds = time.perf_counter() - stream_started
                    output_chars += len(delta)
        else:
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
                prompt_tokens = response.usage.prompt_tokens or 0
                completion_tokens = response.usage.completion_tokens or 0
    except Exception as exc:  # noqa: BLE001 - benchmark result에 error를 기록하기 위해 broad catch를 사용한다.
        error = repr(exc)

    total_seconds = time.perf_counter() - started
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
    client = AsyncOpenAI(base_url=args.base_url, api_key=args.api_key)
    prompt = PROMPTS[args.prompt_size]
    semaphore = asyncio.Semaphore(args.concurrency)
    results: list[dict[str, float | int | str]] = []

    async def guarded_request(request_id: int) -> None:
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
    await asyncio.gather(*(guarded_request(i) for i in range(args.requests)))
    wall_seconds = time.perf_counter() - started

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
        print(f"latency_avg={statistics.mean(latencies):.3f}")
        print(f"latency_p50={percentile(latencies, 0.50):.3f}")
        print(f"latency_p95={percentile(latencies, 0.95):.3f}")
        print(f"requests_per_second={len(successful) / wall_seconds:.3f}")
    if completion_tokens:
        print(f"completion_tokens_per_second={completion_tokens / wall_seconds:.3f}")
    if ttfts:
        print(f"ttft_avg={statistics.mean(ttfts):.3f}")
        print(f"ttft_p50={percentile(ttfts, 0.50):.3f}")
        print(f"ttft_p95={percentile(ttfts, 0.95):.3f}")

    return results


def write_csv(path: Path, rows: list[dict[str, float | int | str]]) -> None:
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
    args = parse_args()
    results = await run_benchmark(args)
    write_csv(Path(args.output), results)
    print(f"wrote_csv={args.output}")


if __name__ == "__main__":
    asyncio.run(async_main())
