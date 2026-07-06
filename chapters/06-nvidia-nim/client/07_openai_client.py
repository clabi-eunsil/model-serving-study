import os
import time

from openai import OpenAI


# NIM LLM container가 OpenAI-compatible API를 제공하면 OpenAI SDK로 호출할 수 있다.
#
# OpenAI cloud API를 호출하는 것이 아니라, base_url을 local/remote NIM endpoint로 바꾼다.
BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:8000/v1")

# model 이름은 /v1/models 응답 또는 NIM model page를 확인한다.
NIM_MODEL = os.getenv("NIM_MODEL", "meta/llama-3.1-8b-instruct")


def main() -> None:
    # local NIM endpoint가 별도 API key를 검사하지 않는 구성이라도,
    # OpenAI SDK는 api_key 값을 요구하므로 dummy 값을 넣는다.
    client = OpenAI(base_url=BASE_URL, api_key=os.getenv("OPENAI_API_KEY", "EMPTY"))

    print(f"base_url={BASE_URL}")
    print(f"model={NIM_MODEL}")

    started = time.perf_counter()
    response = client.chat.completions.create(
        model=NIM_MODEL,
        messages=[
            {"role": "system", "content": "You are a concise model serving tutor."},
            {"role": "user", "content": "Explain NVIDIA NIM in Korean."},
        ],
        max_tokens=128,
        temperature=0.2,
    )
    elapsed = time.perf_counter() - started

    print("## Response")
    print(response.choices[0].message.content)
    print(f"elapsed_seconds={elapsed:.3f}")
    if response.usage is not None:
        print(f"usage={response.usage}")


if __name__ == "__main__":
    main()
