import os
import time

from openai import OpenAI


# 이 client는 OpenAI cloud API가 아니라 vLLM의 OpenAI-compatible endpoint를 호출한다.
#
# 핵심은 base_url이다.
# - OpenAI cloud를 쓸 때는 기본 base_url을 사용한다.
# - vLLM을 쓸 때는 http://127.0.0.1:8000/v1 처럼 vLLM server 주소를 넣는다.
# - 원격 GPU 서버를 SSH port forwarding으로 연결했다면 로컬에서도 127.0.0.1:8000으로 접근할 수 있다.
BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:8000/v1")

# scripts/02_run_vllm_docker.sh의 --served-model-name과 맞춘다.
# 실제 Hugging Face model 이름(Qwen/Qwen3-0.6B)이 아니라 API alias(qwen3-0.6b)를 사용한다.
MODEL = os.getenv("SERVED_MODEL_NAME", "qwen3-0.6b")


def main() -> None:
    # vLLM은 기본 실습에서 API key 검증을 하지 않는다.
    # 하지만 OpenAI SDK는 api_key 값이 필요하므로 관례적으로 "EMPTY" 같은 dummy 값을 넣는다.
    client = OpenAI(base_url=BASE_URL, api_key=os.getenv("OPENAI_API_KEY", "EMPTY"))

    print(f"base_url={BASE_URL}")
    print(f"model={MODEL}")

    # 1. non-streaming 요청.
    # 응답이 완성된 뒤 한 번에 돌아오므로 전체 latency를 보기 쉽다.
    start = time.perf_counter()
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a concise model serving tutor."},
            {"role": "user", "content": "Explain why vLLM is useful in Korean."},
        ],
        max_tokens=128,
        temperature=0.2,
    )
    elapsed = time.perf_counter() - start

    print("\n## Non-streaming response")
    print(response.choices[0].message.content)
    print(f"elapsed_seconds={elapsed:.3f}")
    if response.usage is not None:
        print(f"usage={response.usage}")

    # 2. streaming 요청.
    # 첫 chunk가 도착하는 시간을 재면 간단한 TTFT 관찰이 가능하다.
    print("\n## Streaming response")
    stream_start = time.perf_counter()
    first_chunk_at = None
    chunks = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "user", "content": "Give me three short bullets about PagedAttention."},
        ],
        max_tokens=128,
        temperature=0.2,
        stream=True,
    )

    for chunk in chunks:
        delta = chunk.choices[0].delta.content
        if delta:
            if first_chunk_at is None:
                first_chunk_at = time.perf_counter()
                print(f"\nfirst_chunk_seconds={first_chunk_at - stream_start:.3f}")
            print(delta, end="", flush=True)

    print()
    total = time.perf_counter() - stream_start
    print(f"stream_total_seconds={total:.3f}")


if __name__ == "__main__":
    main()
