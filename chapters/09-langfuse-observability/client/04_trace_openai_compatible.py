"""Trace an OpenAI-compatible endpoint call with Langfuse.

이 script는 vLLM/NIM처럼 OpenAI-compatible API를 제공하는 서버를 호출하고,
그 요청 결과를 Langfuse generation으로 기록한다.

실제 endpoint가 없으면 --dry-run으로 구조만 확인할 수 있다.
"""

from __future__ import annotations

import argparse
import os
import time
from typing import Any

from dotenv import load_dotenv
from openai import OpenAI


def estimate_tokens(text: str) -> int:
    return max(1, len(text.split()))


def has_langfuse_credentials() -> bool:
    return bool(os.getenv("LANGFUSE_PUBLIC_KEY") and os.getenv("LANGFUSE_SECRET_KEY"))


def build_messages(prompt: str) -> list[dict[str, str]]:
    """OpenAI-compatible chat completions 요청의 messages를 만든다."""

    return [
        {
            "role": "system",
            "content": "You are a concise Korean tutor for model serving study.",
        },
        {
            "role": "user",
            "content": prompt,
        },
    ]


def call_openai_compatible(messages: list[dict[str, str]]) -> dict[str, Any]:
    """OpenAI-compatible endpoint를 호출한다.

    OPENAI_BASE_URL을 vLLM/NIM endpoint로 바꾸면 같은 OpenAI SDK 코드로
    backend만 교체해서 호출할 수 있다.
    """

    client = OpenAI(
        base_url=os.getenv("OPENAI_BASE_URL", "http://127.0.0.1:8000/v1"),
        api_key=os.getenv("OPENAI_API_KEY", "EMPTY"),
    )
    model = os.getenv("OPENAI_MODEL", "study-model")

    response = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0.2,
        max_tokens=128,
    )

    content = response.choices[0].message.content or ""
    usage = response.usage

    return {
        "model": model,
        "content": content,
        "usage": {
            "input": getattr(usage, "prompt_tokens", None) or estimate_tokens(str(messages)),
            "output": getattr(usage, "completion_tokens", None) or estimate_tokens(content),
            "total": getattr(usage, "total_tokens", None)
            or estimate_tokens(str(messages)) + estimate_tokens(content),
        },
    }


def fake_openai_result(messages: list[dict[str, str]]) -> dict[str, Any]:
    """endpoint 없이 실행할 때 쓰는 fake response."""

    time.sleep(0.12)
    content = "OpenAI-compatible endpoint 결과를 Langfuse generation으로 기록하는 예시입니다."
    return {
        "model": os.getenv("OPENAI_MODEL", "dry-run-model"),
        "content": content,
        "usage": {
            "input": estimate_tokens(str(messages)),
            "output": estimate_tokens(content),
            "total": estimate_tokens(str(messages)) + estimate_tokens(content),
        },
    }


def print_dry_run(messages: list[dict[str, str]], result: dict[str, Any], latency_ms: float) -> None:
    print("## Dry-run OpenAI-compatible trace preview")
    print(f"model: {result['model']}")
    print(f"messages: {messages}")
    print(f"output: {result['content']}")
    print(f"latency_ms: {latency_ms}")
    print(f"usage: {result['usage']}")


def send_trace(messages: list[dict[str, str]], result: dict[str, Any], latency_ms: float) -> None:
    from langfuse import get_client

    langfuse = get_client()

    with langfuse.start_as_current_observation(
        as_type="generation",
        name="openai-compatible-chat",
        model=result["model"],
        input=messages,
        output=result["content"],
        model_parameters={
            "temperature": 0.2,
            "max_tokens": 128,
        },
        usage_details=result["usage"],
        metadata={
            "base_url": os.getenv("OPENAI_BASE_URL", "http://127.0.0.1:8000/v1"),
            "latency_ms": latency_ms,
            "chapter": "09-langfuse-observability",
        },
    ) as generation:
        generation.update_trace(
            name="chapter-09-openai-compatible-call",
            session_id="study-session-openai-compatible",
            user_id="study-user-local",
            tags=["model-serving-study", "openai-compatible"],
        )

    langfuse.flush()
    print("OpenAI-compatible call traced to Langfuse.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--prompt",
        default="vLLM endpoint를 Langfuse로 관측하면 어떤 정보가 보이나요?",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> None:
    load_dotenv()
    args = parse_args()
    messages = build_messages(args.prompt)

    started = time.perf_counter()
    if args.dry_run:
        result = fake_openai_result(messages)
    else:
        result = call_openai_compatible(messages)
    latency_ms = round((time.perf_counter() - started) * 1000, 2)

    if args.dry_run or not has_langfuse_credentials():
        print_dry_run(messages, result, latency_ms)
        return

    send_trace(messages, result, latency_ms)


if __name__ == "__main__":
    main()
