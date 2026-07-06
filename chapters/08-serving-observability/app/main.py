import random
import time
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from prometheus_client import Counter, Gauge, Histogram, make_asgi_app
from pydantic import BaseModel, Field


# 챕터 8은 "실제 LLM 품질"보다 "관측성 구조"를 배우는 단원이다.
# 그래서 큰 모델을 로딩하지 않고, 작은 fake generation 함수로 모델 서버처럼 동작하게 만든다.
#
# 이렇게 하는 이유:
# - Prometheus/Grafana 실습은 CPU-only local 환경에서도 따라 할 수 있어야 한다.
# - latency, token count, error count 같은 metric을 안정적으로 재현해야 한다.
# - 진짜 vLLM/NIM metric은 이후 운영 환경에서 같은 관점으로 보면 된다.

MODEL_NAME = "fake-observability-model"


# Prometheus metric은 보통 module 전역에서 한 번 정의한다.
# request handler 안에서 매번 새로 만들면 같은 이름의 metric이 중복 등록되어 에러가 난다.
#
# metric 이름은 Prometheus naming guideline을 따라 단위와 type을 드러내게 만든다.
# - *_total: 계속 증가하는 counter
# - *_seconds: 초 단위 duration
# - *_tokens: token count

REQUESTS_TOTAL = Counter(
    "model_server_requests_total",
    "Total number of /generate requests.",
    ["endpoint", "status"],
)

TOKENS_TOTAL = Counter(
    "model_server_generated_tokens_total",
    "Total number of generated output tokens.",
    ["model"],
)

REQUEST_LATENCY_SECONDS = Histogram(
    "model_server_request_latency_seconds",
    "End-to-end request latency observed by the FastAPI handler.",
    ["endpoint"],
    # bucket은 latency 분포를 Prometheus query에서 계산하기 위한 경계값이다.
    # 너무 촘촘하면 series가 많아지고, 너무 넓으면 p95 해석이 둔해진다.
    # 실습에서는 짧은 fake generation 기준으로 작은 bucket을 둔다.
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)

PROMPT_TOKENS = Histogram(
    "model_server_prompt_tokens",
    "Distribution of estimated prompt token counts.",
    ["model"],
    buckets=(1, 4, 8, 16, 32, 64, 128, 256),
)

COMPLETION_TOKENS = Histogram(
    "model_server_completion_tokens",
    "Distribution of generated completion token counts.",
    ["model"],
    buckets=(1, 4, 8, 16, 32, 64, 128, 256),
)

MODEL_LOADED = Gauge(
    "model_server_model_loaded",
    "Whether the model is loaded. 1 means loaded, 0 means not loaded.",
    ["model"],
)

IN_FLIGHT_REQUESTS = Gauge(
    "model_server_in_flight_requests",
    "Number of /generate requests currently being handled.",
    ["endpoint"],
)


def estimate_tokens(text: str) -> int:
    # 진짜 tokenizer를 쓰면 모델별 token count가 더 정확하다.
    # 하지만 이 챕터의 목적은 metric 흐름을 배우는 것이므로,
    # 공백 기준 단어 수를 token count의 근사값으로 사용한다.
    return max(1, len(text.split()))


def fake_generate(prompt: str, max_new_tokens: int) -> tuple[str, int]:
    # 실제 모델 대신 deterministic-ish fake generation을 만든다.
    #
    # sleep을 넣는 이유:
    # - latency histogram에 관찰 가능한 값이 쌓이게 하기 위해서다.
    # - prompt 길이와 output 길이에 따라 latency가 조금 늘어나는 모양을 만든다.
    prompt_tokens = estimate_tokens(prompt)
    simulated_latency = 0.02 + min(prompt_tokens, 128) * 0.001 + max_new_tokens * 0.002
    time.sleep(simulated_latency)

    # output token 수는 max_new_tokens 이하의 작은 값으로 만든다.
    # 매번 완전히 같으면 histogram 변화가 심심하므로 약간의 변동을 준다.
    generated_tokens = max(1, min(max_new_tokens, random.randint(4, max(4, max_new_tokens))))
    generated_text = " ".join(["observability"] * generated_tokens)
    return generated_text, generated_tokens


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 실제 모델 서버라면 이 위치에서 model/tokenizer를 로딩한다.
    # 여기서는 fake model이 항상 준비되었다고 보고 gauge를 1로 둔다.
    MODEL_LOADED.labels(model=MODEL_NAME).set(1)
    yield
    # server가 내려갈 때 loaded 상태를 0으로 바꾼다.
    MODEL_LOADED.labels(model=MODEL_NAME).set(0)


app = FastAPI(
    title="Model Serving Observability Study",
    version="0.1.0",
    lifespan=lifespan,
)

# prometheus_client가 제공하는 ASGI app을 /metrics에 mount한다.
# Prometheus는 이 endpoint를 주기적으로 scrape해서 time series로 저장한다.
#
# Starlette/FastAPI의 mount 동작 때문에 사람이 /metrics로 직접 접근하면
# /metrics/로 307 redirect될 수 있다. 실습 script와 Prometheus 설정은
# redirect를 피하기 위해 /metrics/를 직접 사용한다.
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


class GenerateRequest(BaseModel):
    # prompt는 사용자가 모델에 보내는 입력이다.
    # observability 관점에서는 prompt 내용 자체보다 prompt length/token count를 추적하는 경우가 많다.
    prompt: str = Field(..., min_length=1, examples=["Explain model serving observability"])
    max_new_tokens: int = Field(32, ge=1, le=256)
    fail: bool = Field(
        False,
        description="Set true to intentionally return an error and observe error metrics.",
    )


class GenerateResponse(BaseModel):
    model: str
    prompt_tokens: int
    completion_tokens: int
    generated_text: str
    latency_ms: float


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "model": MODEL_NAME,
        "metrics": "/metrics/",
    }


@app.post("/generate", response_model=GenerateResponse)
def generate(request: GenerateRequest) -> GenerateResponse:
    endpoint = "/generate"
    IN_FLIGHT_REQUESTS.labels(endpoint=endpoint).inc()
    started = time.perf_counter()
    prompt_tokens = estimate_tokens(request.prompt)

    try:
        if request.fail:
            # error metric이 어떻게 증가하는지 보기 위한 의도적 실패 경로다.
            REQUESTS_TOTAL.labels(endpoint=endpoint, status="error").inc()
            raise HTTPException(status_code=500, detail="intentional failure for metrics")

        generated_text, completion_tokens = fake_generate(
            request.prompt,
            request.max_new_tokens,
        )

        latency_seconds = time.perf_counter() - started

        # 성공 요청에 대한 metric 업데이트.
        REQUESTS_TOTAL.labels(endpoint=endpoint, status="success").inc()
        REQUEST_LATENCY_SECONDS.labels(endpoint=endpoint).observe(latency_seconds)
        PROMPT_TOKENS.labels(model=MODEL_NAME).observe(prompt_tokens)
        COMPLETION_TOKENS.labels(model=MODEL_NAME).observe(completion_tokens)
        TOKENS_TOTAL.labels(model=MODEL_NAME).inc(completion_tokens)

        return GenerateResponse(
            model=MODEL_NAME,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            generated_text=generated_text,
            latency_ms=round(latency_seconds * 1000, 2),
        )
    finally:
        # 성공/실패와 관계없이 in-flight gauge는 반드시 감소해야 한다.
        # finally에 두면 exception이 발생해도 gauge가 잘못 남는 일을 줄일 수 있다.
        IN_FLIGHT_REQUESTS.labels(endpoint=endpoint).dec()
