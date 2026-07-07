"""Compare prompt variants and prepare Langfuse-friendly observations.

이 script는 prompt versioning/evaluation 감각을 잡기 위한 작은 실습이다.
Langfuse의 실제 Prompt Management API를 쓰기 전, prompt별 latency와 token usage를
어떤 형태로 비교할지 CSV로 먼저 정리한다.
"""

from __future__ import annotations

import csv
import time
from pathlib import Path


PROMPTS = [
    {
        "name": "short-explain",
        "version": "v1",
        "prompt": "Langfuse가 뭔지 한 문장으로 설명해줘.",
    },
    {
        "name": "friendly-explain",
        "version": "v2",
        "prompt": "모델 서빙을 처음 배우는 사람에게 Langfuse가 왜 필요한지 친근하게 설명해줘.",
    },
    {
        "name": "ops-focused",
        "version": "v3",
        "prompt": "운영 관점에서 Langfuse로 latency, token usage, user/session을 보는 이유를 설명해줘.",
    },
]


def estimate_tokens(text: str) -> int:
    return max(1, len(text.split()))


def fake_answer(prompt: str) -> tuple[str, float]:
    """prompt 길이에 따라 latency가 달라지는 fake answer를 만든다."""

    started = time.perf_counter()
    time.sleep(0.05 + estimate_tokens(prompt) * 0.004)
    answer = f"Prompt 길이 {estimate_tokens(prompt)} token 기준의 관측성 비교 예시입니다."
    latency_ms = round((time.perf_counter() - started) * 1000, 2)
    return answer, latency_ms


def main() -> None:
    results_dir = Path("results")
    results_dir.mkdir(exist_ok=True)
    output_path = results_dir / "prompt_comparison.csv"

    rows = []
    for prompt_info in PROMPTS:
        answer, latency_ms = fake_answer(prompt_info["prompt"])
        rows.append(
            {
                "prompt_name": prompt_info["name"],
                "prompt_version": prompt_info["version"],
                "prompt_tokens": estimate_tokens(prompt_info["prompt"]),
                "completion_tokens": estimate_tokens(answer),
                "latency_ms": latency_ms,
                "answer_preview": answer,
            }
        )

    with output_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(f"wrote {output_path}")
    print()
    for row in rows:
        print(row)


if __name__ == "__main__":
    main()
