"""Call a KServe LLM InferenceService with the OpenAI Python SDK.

KServe's Hugging Face runtime exposes an OpenAI-compatible API path:

    /openai/v1/chat/completions

That means the request shape is familiar from vLLM/NIM/OpenAI-compatible
servers. The local gateway part is the only slightly unusual bit:

1. The base URL points at the gateway port-forward.
2. The Host header tells the gateway which InferenceService route to use.

This file is intentionally verbose because the goal is to read and learn from it,
not to be the shortest possible client.
"""

from __future__ import annotations

import argparse
import os
from typing import Any

from openai import OpenAI


def build_client(base_url: str, service_hostname: str) -> OpenAI:
    """Create an OpenAI SDK client configured for the KServe gateway.

    Parameters
    ----------
    base_url:
        The OpenAI-compatible API root. For KServe local port-forward this is
        usually "http://127.0.0.1:8080/openai/v1".
    service_hostname:
        The host from InferenceService status.url, for example
        "qwen-llm.kserve-llm.example.com". KServe's gateway uses this header
        to route the request to the right InferenceService.
    """

    return OpenAI(
        api_key=os.getenv("OPENAI_API_KEY", "not-needed-for-local-kserve"),
        base_url=base_url,
        default_headers={"Host": service_hostname},
    )


def run_chat(client: OpenAI, model: str, prompt: str) -> dict[str, Any]:
    """Send one chat completion request and return a small readable result."""

    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant. Answer in Korean.",
            },
            {
                "role": "user",
                "content": prompt,
            },
        ],
        max_tokens=180,
        temperature=0.2,
    )

    choice = response.choices[0]
    return {
        "model": response.model,
        "finish_reason": choice.finish_reason,
        "content": choice.message.content,
        "usage": response.usage.model_dump() if response.usage else None,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Call KServe LLM with OpenAI SDK.")
    parser.add_argument(
        "--base-url",
        default=os.getenv("OPENAI_BASE_URL", "http://127.0.0.1:8080/openai/v1"),
        help="KServe OpenAI-compatible base URL.",
    )
    parser.add_argument(
        "--service-hostname",
        default=os.getenv("SERVICE_HOSTNAME", ""),
        help="InferenceService hostname used as Host header.",
    )
    parser.add_argument(
        "--model",
        default=os.getenv("MODEL_NAME", "qwen"),
        help="Served model name. It must match --model_name in the InferenceService args.",
    )
    parser.add_argument(
        "--prompt",
        default="KServe에서 LLM을 서빙할 때 InferenceService와 vLLM의 역할을 설명해줘.",
        help="User prompt to send.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if not args.service_hostname:
        raise SystemExit(
            "SERVICE_HOSTNAME is required. Run scripts/08_openai_client.sh "
            "or export SERVICE_HOSTNAME from the InferenceService status.url."
        )

    client = build_client(args.base_url, args.service_hostname)
    result = run_chat(client, args.model, args.prompt)

    print("== OpenAI SDK response summary ==")
    print(f"model: {result['model']}")
    print(f"finish_reason: {result['finish_reason']}")
    print(f"usage: {result['usage']}")
    print()
    print(result["content"])


if __name__ == "__main__":
    main()
