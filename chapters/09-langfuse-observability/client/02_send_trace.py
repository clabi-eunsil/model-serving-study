"""Send one beginner-friendly Langfuse trace.

이 파일의 목표는 "Langfuse trace가 어떤 구조로 생기는지"를 보는 것이다.
실제 LLM endpoint가 없어도 dry-run으로 실행할 수 있고, Langfuse key가 있으면
동일한 코드 흐름으로 trace/span/generation을 전송한다.

실행 예:
  python client/02_send_trace.py --dry-run
  python client/02_send_trace.py
"""

from __future__ import annotations

import argparse
import os
import time
from dataclasses import dataclass
from typing import Any

from dotenv import load_dotenv


@dataclass
class FakeLLMResult:
    """실제 LLM response에서 관심 있는 값만 담는 작은 자료 구조."""

    output: str
    prompt_tokens: int
    completion_tokens: int
    latency_ms: float


def estimate_tokens(text: str) -> int:
    """토큰 수를 아주 단순하게 추정한다.

    Langfuse에는 token usage를 함께 보내는 것이 중요하다.
    실제 운영에서는 tokenizer 또는 provider response의 usage 값을 쓰는 것이 맞다.
    이 실습에서는 외부 모델 없이도 흐름을 볼 수 있도록 공백 기준 근사값을 사용한다.
    """

    return max(1, len(text.split()))


def fake_llm_call(prompt: str) -> FakeLLMResult:
    """실제 LLM 대신 작은 fake response를 만든다.

    Langfuse 실습의 핵심은 답변 품질이 아니라 trace 구조다.
    그래서 여기서는 일부러 짧은 sleep을 넣어 latency를 만들고,
    prompt/completion token 값을 만들어 generation observation에 기록한다.
    """

    started = time.perf_counter()
    time.sleep(0.15)
    output = (
        "Langfuse는 LLM 요청의 입력, 출력, latency, token usage를 "
        "trace 단위로 관찰하게 해주는 도구입니다."
    )
    latency_ms = round((time.perf_counter() - started) * 1000, 2)

    return FakeLLMResult(
        output=output,
        prompt_tokens=estimate_tokens(prompt),
        completion_tokens=estimate_tokens(output),
        latency_ms=latency_ms,
    )


def has_langfuse_credentials() -> bool:
    """Langfuse에 실제로 보낼 수 있는 환경변수가 있는지 확인한다."""

    return bool(os.getenv("LANGFUSE_PUBLIC_KEY") and os.getenv("LANGFUSE_SECRET_KEY"))


def run_dry_run(prompt: str) -> None:
    """Langfuse key가 없을 때도 trace 구조를 눈으로 확인하는 경로."""

    result = fake_llm_call(prompt)

    print("## Dry-run trace preview")
    print("trace name: chapter-09-first-trace")
    print("session_id: study-session-001")
    print("user_id: study-user-local")
    print("span: prepare-request")
    print("generation: fake-llm-call")
    print(f"input: {prompt}")
    print(f"output: {result.output}")
    print(f"latency_ms: {result.latency_ms}")
    print(f"usage.prompt_tokens: {result.prompt_tokens}")
    print(f"usage.completion_tokens: {result.completion_tokens}")
    print()
    print("Langfuse key를 설정하면 같은 구조가 Langfuse UI에 trace로 전송된다.")


def send_langfuse_trace(prompt: str) -> None:
    """Langfuse Python SDK로 trace/span/generation을 전송한다.

    공식 문서의 최신 Python SDK 흐름은 get_client()로 client를 만들고,
    start_as_current_observation(...) context manager로 span/generation을 만드는 방식이다.
    generation은 LLM 호출에 특화된 observation type이라 model, usage_details 같은
    LLM 전용 필드를 함께 기록할 수 있다.
    """

    from langfuse import get_client

    langfuse = get_client()

    # trace-level metadata는 "이 요청이 어떤 사용자/세션/실험 조건에 속하는가"를
    # 나중에 UI에서 필터링하기 위해 넣는다.
    with langfuse.start_as_current_observation(
        as_type="span",
        name="chapter-09-request",
        input={"prompt": prompt},
        metadata={
            "chapter": "09-langfuse-observability",
            "mode": "fake-llm",
        },
    ) as root_span:
        # Langfuse UI에서 multi-turn conversation이나 같은 실습 묶음을 보기 쉽도록
        # session_id/user_id를 trace에 연결한다.
        root_span.update_trace(
            name="chapter-09-first-trace",
            session_id="study-session-001",
            user_id="study-user-local",
            tags=["model-serving-study", "chapter-09"],
        )

        with langfuse.start_as_current_observation(
            as_type="span",
            name="prepare-request",
            input={"raw_prompt": prompt},
        ) as prepare_span:
            prepared_prompt = prompt.strip()
            prepare_span.update(output={"prepared_prompt": prepared_prompt})

        started = time.perf_counter()
        result = fake_llm_call(prepared_prompt)
        latency_ms = round((time.perf_counter() - started) * 1000, 2)

        # generation은 LLM call을 나타낸다.
        # prompt, completion, model, token usage를 한 곳에 묶어 UI에서 볼 수 있다.
        with langfuse.start_as_current_observation(
            as_type="generation",
            name="fake-llm-call",
            model="fake-observability-model",
            input=prepared_prompt,
            metadata={"provider": "local-fake"},
            usage_details={
                "input": result.prompt_tokens,
                "output": result.completion_tokens,
                "total": result.prompt_tokens + result.completion_tokens,
            },
        ) as generation:
            generation.update(
                output=result.output,
                metadata={"latency_ms": latency_ms},
            )

        root_span.update(
            output={
                "answer": result.output,
                "latency_ms": latency_ms,
                "prompt_tokens": result.prompt_tokens,
                "completion_tokens": result.completion_tokens,
            }
        )

    # 짧은 CLI script는 process가 바로 종료되므로 flush를 호출해야 한다.
    # 그렇지 않으면 background queue에 남은 event가 전송되기 전에 종료될 수 있다.
    langfuse.flush()
    print("Trace sent to Langfuse. Check the Langfuse UI traces page.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--prompt",
        default="Langfuse와 Prometheus observability의 차이를 초보자에게 설명해줘.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not send anything to Langfuse. Print the trace shape locally.",
    )
    return parser.parse_args()


def main() -> None:
    load_dotenv()
    args = parse_args()

    if args.dry_run or not has_langfuse_credentials():
        run_dry_run(args.prompt)
        return

    send_langfuse_trace(args.prompt)


if __name__ == "__main__":
    main()
