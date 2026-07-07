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

try:
    from dotenv import load_dotenv
except ImportError:
    # dry-run은 Langfuse나 dotenv package가 없어도 trace 모양을 볼 수 있어야 한다.
    # 챕터 실습처럼 `pip install -r requirements.txt`를 실행하면 실제 load_dotenv가 쓰인다.
    def load_dotenv() -> bool:
        return False


DEFAULT_TRACE_NAME = "chapter-09-first-trace"
DEFAULT_SESSION_ID = "study-session-001"
DEFAULT_USER_ID = "study-user-local"
DEFAULT_MODEL_NAME = "fake-observability-model"


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
    trace_name = os.getenv("TRACE_NAME", DEFAULT_TRACE_NAME)
    session_id = os.getenv("SESSION_ID", DEFAULT_SESSION_ID)
    user_id = os.getenv("USER_ID", DEFAULT_USER_ID)
    model_name = os.getenv("MODEL_NAME", DEFAULT_MODEL_NAME)

    print("## Dry-run trace preview")
    print(f"trace name: {trace_name}")
    print(f"session_id: {session_id}")
    print(f"user_id: {user_id}")
    print("span: prepare-request")
    print("generation: fake-llm-call")
    print(f"model: {model_name}")
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

    # Langfuse 최신 문서는 LANGFUSE_BASE_URL을 사용한다.
    # 기존 예제나 내부 환경에서 LANGFUSE_HOST를 쓰는 경우도 있어서,
    # HOST만 설정되어 있으면 BASE_URL로 복사해 최신 SDK가 읽을 수 있게 한다.
    if os.getenv("LANGFUSE_HOST") and not os.getenv("LANGFUSE_BASE_URL"):
        os.environ["LANGFUSE_BASE_URL"] = os.environ["LANGFUSE_HOST"]

    from langfuse import get_client, propagate_attributes

    langfuse = get_client()
    trace_name = os.getenv("TRACE_NAME", DEFAULT_TRACE_NAME)
    session_id = os.getenv("SESSION_ID", DEFAULT_SESSION_ID)
    user_id = os.getenv("USER_ID", DEFAULT_USER_ID)
    model_name = os.getenv("MODEL_NAME", DEFAULT_MODEL_NAME)

    # propagate_attributes는 trace-level 속성을 현재 context 안의 observation들에
    # 전파한다. session_id/user_id/tags/trace_name처럼 trace를 묶어서 검색하는 값은
    # observation metadata에 직접 넣기보다 이 context manager로 올리는 것이 최신 SDK
    # 권장 방식이다.
    with propagate_attributes(
        trace_name=trace_name,
        session_id=session_id,
        user_id=user_id,
        tags=["model-serving-study", "chapter-09"],
        metadata={
            "chapter": "09-langfuse-observability",
            "mode": "fake-llm",
        },
    ):
        # root span은 "요청 하나의 시작점"이다. Langfuse UI에서는 이 span 아래에
        # prepare-request span과 fake-llm-call generation이 tree 형태로 보인다.
        with langfuse.start_as_current_observation(
            as_type="span",
            name="chapter-09-request",
            input={"prompt": prompt},
        ) as root_span:
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
            # model도 학습용 기본값이다. 실제 vLLM/NIM/OpenAI 호출에서는 요청에 사용한
            # served model name 또는 provider model name을 그대로 기록한다.
            with langfuse.start_as_current_observation(
                as_type="generation",
                name="fake-llm-call",
                model=model_name,
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
