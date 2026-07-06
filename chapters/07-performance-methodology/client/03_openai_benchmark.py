import argparse
import asyncio
import csv
import json
import statistics
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import aiohttp


# 이 파일은 OpenAI-compatible /v1/chat/completions endpoint에
# 여러 요청을 보내고 latency를 CSV로 저장하는 benchmark client다.
#
# 왜 직접 만드는가?
# - wrk/hey 같은 일반 HTTP benchmark 도구는 "HTTP 응답 시간"은 잘 보지만,
#   LLM에서 중요한 prompt 길이, max_tokens, streaming TTFT를 함께 기록하기 어렵다.
# - 이 client는 LLM serving 실험에서 자주 바꾸는 조건을 명시적으로 기록한다.
#
# 측정하는 값:
# - latency_ms: 요청 시작부터 응답 완료까지 걸린 시간
# - ttft_ms: streaming일 때 첫 data chunk가 도착하기까지 걸린 시간
# - output_chars: 응답 text 길이. token 수가 없을 때 대략적인 출력 크기 확인용
# - success/status/error: 실패 요청이 섞였는지 확인하기 위한 정보


PROMPTS = {
    "short": "Explain model serving in one short Korean paragraph.",
    "medium": (
        "Explain model serving in Korean. Include model loading, request validation, "
        "inference, response formatting, latency, throughput, and monitoring."
    ),
    "long": (
        "You are helping a beginner study model serving. Explain the full request path "
        "from client to model server and back to the client. Include REST APIs, "
        "OpenAI-compatible APIs, tokenizer, model weights, GPU memory, KV cache, "
        "batching, streaming, latency percentiles, and why benchmark conditions must be "
        "kept consistent. Answer in Korean with clear paragraphs."
    ),
}


@dataclass
class BenchmarkResult:
    # dataclass는 한 요청의 결과를 구조적으로 담기 위해 사용한다.
    # CSV를 쓸 때도 이 field들이 그대로 column이 된다.
    request_id: int
    prompt_size: str
    concurrency: int
    max_tokens: int
    stream: bool
    success: bool
    status: int
    latency_ms: float
    ttft_ms: float | None
    output_chars: int
    error: str


def percentile(values: list[float], pct: float) -> float:
    # p50, p95 같은 percentile은 tail latency를 보기 위해 필요하다.
    # statistics.quantiles는 sample 수가 적을 때 다루기 불편해서,
    # 여기서는 작은 benchmark에도 동작하는 단순 percentile 함수를 사용한다.
    if not values:
        return 0.0
    ordered = sorted(values)
    index = round((len(ordered) - 1) * pct)
    return ordered[index]


def build_payload(model: str, prompt: str, max_tokens: int, stream: bool) -> dict[str, Any]:
    # OpenAI-compatible chat completions payload를 만든다.
    # vLLM/NIM 같은 server는 이 구조를 받아 내부 prompt 형식으로 변환한다.
    return {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": "You are a concise model serving benchmark assistant.",
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        "max_tokens": max_tokens,
        "temperature": 0.2,
        "stream": stream,
    }


async def run_one_request(
    session: aiohttp.ClientSession,
    url: str,
    model: str,
    request_id: int,
    prompt_size: str,
    concurrency: int,
    max_tokens: int,
    stream: bool,
) -> BenchmarkResult:
    # 한 요청을 보내고 결과를 BenchmarkResult로 반환한다.
    #
    # async 함수인 이유:
    # - benchmark에서는 여러 요청을 동시에 보내야 concurrency를 만들 수 있다.
    # - asyncio + aiohttp를 쓰면 thread를 직접 다루지 않고도 concurrent HTTP 요청을 보낼 수 있다.
    prompt = PROMPTS[prompt_size]
    payload = build_payload(model, prompt, max_tokens, stream)
    started = time.perf_counter()
    first_chunk_at: float | None = None
    output_text_parts: list[str] = []

    try:
        async with session.post(url, json=payload) as response:
            status = response.status

            if stream:
                # streaming 응답은 server가 data chunk를 여러 번 나누어 보낸다.
                # OpenAI-compatible streaming은 보통 "data: {...}" 줄이 반복되고,
                # 마지막에는 "data: [DONE]"이 온다.
                async for raw_line in response.content:
                    line = raw_line.decode("utf-8", errors="replace").strip()
                    if not line or not line.startswith("data:"):
                        continue
                    if first_chunk_at is None:
                        first_chunk_at = time.perf_counter()
                    data = line.removeprefix("data:").strip()
                    if data == "[DONE]":
                        continue
                    try:
                        chunk = json.loads(data)
                        delta = chunk["choices"][0].get("delta", {})
                        output_text_parts.append(delta.get("content", ""))
                    except Exception:
                        # server마다 streaming chunk가 조금 다를 수 있다.
                        # parsing 실패를 전체 요청 실패로 만들기보다 원문 길이만 기록한다.
                        output_text_parts.append(data)
            else:
                # non-streaming 응답은 body 전체가 온 뒤 JSON을 파싱한다.
                body = await response.text()
                if 200 <= status < 300:
                    parsed = json.loads(body)
                    message = parsed["choices"][0]["message"]
                    output_text_parts.append(message.get("content", ""))
                else:
                    raise RuntimeError(f"HTTP {status}: {body[:300]}")

            ended = time.perf_counter()
            latency_ms = (ended - started) * 1000
            ttft_ms = None
            if first_chunk_at is not None:
                ttft_ms = (first_chunk_at - started) * 1000

            return BenchmarkResult(
                request_id=request_id,
                prompt_size=prompt_size,
                concurrency=concurrency,
                max_tokens=max_tokens,
                stream=stream,
                success=200 <= status < 300,
                status=status,
                latency_ms=latency_ms,
                ttft_ms=ttft_ms,
                output_chars=len("".join(output_text_parts)),
                error="",
            )
    except Exception as exc:
        ended = time.perf_counter()
        return BenchmarkResult(
            request_id=request_id,
            prompt_size=prompt_size,
            concurrency=concurrency,
            max_tokens=max_tokens,
            stream=stream,
            success=False,
            status=0,
            latency_ms=(ended - started) * 1000,
            ttft_ms=None,
            output_chars=0,
            error=str(exc),
        )


async def run_benchmark(args: argparse.Namespace) -> list[BenchmarkResult]:
    # semaphore는 동시에 실행되는 request 수를 제한한다.
    # 예를 들어 requests=100, concurrency=4이면 전체 100개 요청을 보내되
    # 동시에 떠 있는 요청은 최대 4개가 된다.
    semaphore = asyncio.Semaphore(args.concurrency)
    timeout = aiohttp.ClientTimeout(total=args.timeout)
    url = args.base_url.rstrip("/") + "/chat/completions"

    async with aiohttp.ClientSession(timeout=timeout) as session:

        async def guarded_request(request_id: int) -> BenchmarkResult:
            async with semaphore:
                return await run_one_request(
                    session=session,
                    url=url,
                    model=args.model,
                    request_id=request_id,
                    prompt_size=args.prompt_size,
                    concurrency=args.concurrency,
                    max_tokens=args.max_tokens,
                    stream=args.stream,
                )

        tasks = [guarded_request(i) for i in range(1, args.requests + 1)]
        return await asyncio.gather(*tasks)


def write_csv(path: Path, rows: list[BenchmarkResult]) -> None:
    # benchmark 결과는 반드시 raw data로 남긴다.
    # 평균/p95 같은 요약값만 남기면 나중에 outlier나 error를 다시 확인하기 어렵다.
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(BenchmarkResult.__dataclass_fields__.keys())
    with path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row.__dict__)


def print_summary(rows: list[BenchmarkResult], elapsed_seconds: float) -> None:
    successful = [row for row in rows if row.success]
    failed = [row for row in rows if not row.success]
    latencies = [row.latency_ms for row in successful]
    ttfts = [row.ttft_ms for row in successful if row.ttft_ms is not None]

    print("## Benchmark Summary")
    print(f"requests_total={len(rows)}")
    print(f"requests_success={len(successful)}")
    print(f"requests_failed={len(failed)}")
    print(f"elapsed_seconds={elapsed_seconds:.3f}")
    if elapsed_seconds > 0:
        print(f"requests_per_second={len(successful) / elapsed_seconds:.3f}")
    if latencies:
        print(f"latency_avg_ms={statistics.mean(latencies):.1f}")
        print(f"latency_p50_ms={percentile(latencies, 0.50):.1f}")
        print(f"latency_p95_ms={percentile(latencies, 0.95):.1f}")
        print(f"latency_max_ms={max(latencies):.1f}")
    if ttfts:
        print(f"ttft_p50_ms={percentile(ttfts, 0.50):.1f}")
        print(f"ttft_p95_ms={percentile(ttfts, 0.95):.1f}")
    if failed:
        print("first_error=" + failed[0].error[:300])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://127.0.0.1:8000/v1")
    parser.add_argument("--model", required=True)
    parser.add_argument("--requests", type=int, default=8)
    parser.add_argument("--concurrency", type=int, default=2)
    parser.add_argument("--prompt-size", choices=sorted(PROMPTS), default="short")
    parser.add_argument("--max-tokens", type=int, default=64)
    parser.add_argument("--stream", action="store_true")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--output", default="results/benchmark.csv")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    started = time.perf_counter()
    rows = asyncio.run(run_benchmark(args))
    elapsed_seconds = time.perf_counter() - started
    write_csv(Path(args.output), rows)
    print_summary(rows, elapsed_seconds)
    print(f"output={args.output}")


if __name__ == "__main__":
    main()
