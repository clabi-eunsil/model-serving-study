import os
import time
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from transformers import pipeline


# 이번 실습에서 사용할 아주 작은 text generation 모델이다.
# 챕터 2에서는 MODEL_NAME을 코드에 고정했다.
# Docker에서는 환경변수 MODEL_NAME으로 모델을 바꿀 수 있게 해 둔다.
# 환경변수가 없으면 기본값으로 tiny-gpt2를 사용한다.
MODEL_NAME = os.getenv("MODEL_NAME", "sshleifer/tiny-gpt2")

# generator에는 Hugging Face pipeline 객체가 들어간다.
# 처음에는 None이고, FastAPI 서버가 시작될 때 lifespan()에서 실제 모델을 로딩한다.
generator: Any | None = None

# 운영 환경에서는 Prometheus 같은 도구로 metrics를 수집한다.
# 여기서는 개념 확인을 위해 메모리 안에 아주 단순한 통계만 저장한다.
stats = {
    "requests_total": 0,
    "errors_total": 0,
    "latency_ms_total": 0.0,
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # FastAPI 서버가 시작될 때 한 번 실행된다.
    # pipeline("text-generation", model=MODEL_NAME)이 tokenizer와 model을 함께 로딩한다.
    # 이 줄이 실행되어야 /generate 요청에서 실제 모델을 호출할 수 있다.
    global generator
    generator = pipeline("text-generation", model=MODEL_NAME)

    # yield 이전은 startup 단계, yield 이후는 shutdown 단계라고 생각하면 된다.
    # 이번 실습에서는 종료 시 따로 정리할 자원이 없어서 yield 뒤에 코드를 두지 않는다.
    yield


# FastAPI application 객체다.
# uvicorn app.main:app 명령에서 마지막 app이 바로 이 변수다.
# lifespan을 연결했기 때문에 서버가 시작될 때 위의 모델 로딩 코드가 실행된다.
app = FastAPI(
    title="Local Model Serving Study",
    version="0.1.0",
    lifespan=lifespan,
)


class GenerateRequest(BaseModel):
    # BaseModel을 상속받았기 때문에 이 class는 Pydantic model이다.
    # client가 /generate에 보내야 하는 JSON body 구조다.
    # Pydantic이 타입과 범위를 검사해서 잘못된 요청을 자동으로 422 error로 돌려준다.
    # 예: prompt가 빈 문자열이거나 max_new_tokens가 128보다 크면 요청이 거절된다.
    prompt: str = Field(..., min_length=1, examples=["Model serving is"])
    max_new_tokens: int = Field(32, ge=1, le=128)
    temperature: float = Field(0.7, ge=0.0, le=2.0)


class GenerateResponse(BaseModel):
    # 이 class도 Pydantic model이다.
    # /generate가 client에게 돌려주는 JSON response 구조다.
    # response_model=GenerateResponse와 함께 쓰면 응답 형태가 이 schema에 맞춰진다.
    model: str
    prompt: str
    generated_text: str
    latency_ms: float


@app.get("/health")
def health() -> dict[str, Any]:
    # health check endpoint다.
    # 서버 프로세스만 떠 있는지보다 "모델까지 로딩되었는지"를 확인하는 것이 중요하다.
    return {
        "status": "ok" if generator is not None else "loading",
        "model": MODEL_NAME,
        "model_loaded": generator is not None,
    }


@app.post("/generate", response_model=GenerateResponse)
def generate(request: GenerateRequest) -> GenerateResponse:
    # text generation endpoint다.
    # request는 이미 GenerateRequest schema로 검증된 상태로 들어온다.
    if generator is None:
        stats["errors_total"] += 1
        raise HTTPException(status_code=503, detail="model is not loaded")

    # inference latency를 재기 위해 모델 호출 직전 시간을 기록한다.
    started = time.perf_counter()
    try:
        # Hugging Face pipeline에 prompt와 generation option을 넘긴다.
        # max_new_tokens는 새로 생성할 token 수의 상한이다.
        # temperature가 0보다 크면 sampling을 사용해 매번 조금 다른 결과가 나올 수 있다.
        outputs = generator(
            request.prompt,
            max_new_tokens=request.max_new_tokens,
            temperature=request.temperature,
            do_sample=request.temperature > 0,
        )

        # 모델 호출이 끝난 뒤 걸린 시간을 ms 단위로 계산한다.
        latency_ms = (time.perf_counter() - started) * 1000

        # 간단한 metrics를 업데이트한다.
        stats["requests_total"] += 1
        stats["latency_ms_total"] += latency_ms

        # pipeline 결과는 list 형태로 오며, text-generation 결과는 generated_text에 들어 있다.
        return GenerateResponse(
            model=MODEL_NAME,
            prompt=request.prompt,
            generated_text=outputs[0]["generated_text"],
            latency_ms=round(latency_ms, 2),
        )
    except Exception:
        # 모델 호출 중 에러가 나면 error count를 올리고 FastAPI가 error response를 만들게 다시 던진다.
        stats["errors_total"] += 1
        raise


@app.get("/metrics")
def metrics() -> dict[str, Any]:
    # 아주 단순한 metrics endpoint다.
    # 뒤 챕터에서는 Prometheus 형식과 histogram으로 더 제대로 확장한다.
    requests_total = stats["requests_total"]
    avg_latency_ms = (
        stats["latency_ms_total"] / requests_total if requests_total else 0.0
    )
    return {
        "requests_total": requests_total,
        "errors_total": stats["errors_total"],
        "avg_latency_ms": round(avg_latency_ms, 2),
    }
