# 2. 로컬 FastAPI 모델 서빙

이 단원에서는 가장 단순한 형태의 모델 서버를 직접 만든다.
목표는 "모델을 API로 감싸면 어떤 구조가 되는지"를 손으로 확인하는 것이다.
운영용 고성능 LLM 서버는 아니지만, 이후 Docker, vLLM, KServe를 이해하는 기준점이 된다.

## 학습 목표

- FastAPI 기반 모델 서버의 기본 구조를 이해한다.
- `/health`, `/generate`, `/metrics` endpoint가 왜 필요한지 설명할 수 있다.
- Hugging Face Transformers `pipeline`으로 작은 text generation 모델을 호출한다.
- tokenizer, model, generation config의 역할을 구분한다.
- Pydantic으로 request/response schema를 정의한다.
- `curl`과 Python client로 로컬 모델 서버를 호출한다.


## 실행 환경 기준

이 챕터는 챕터 폴더 안에 별도 `.venv`를 만들어 사용한다.
FastAPI, Transformers, Torch 같은 Python package를 host에서 직접 실행하기 때문이다.

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

가상환경을 나올 때:

```bash
deactivate
```

다음 챕터인 Docker 실습에서는 host `.venv`가 아니라 Docker image 안에 Python dependency를 설치한다.

## 핵심 개념 요약

### FastAPI

FastAPI는 Python type hint를 기반으로 API를 만드는 web framework다.
요청 body를 Pydantic model로 정의하면 입력 검증, 타입 변환, OpenAPI 문서 생성이 함께 된다.
모델 서빙에서는 `prompt`, `max_new_tokens`, `temperature` 같은 입력값을 명확히 검증하는 데 유용하다.

### Uvicorn과 ASGI

FastAPI app 자체는 Python object이고, 실제 HTTP 요청을 받아 app에 전달하는 서버가 필요하다.
이번 실습에서는 Uvicorn을 사용한다.
Uvicorn은 ASGI server이고, ASGI는 Python web app과 server 사이의 비동기 interface 규격이다.

### Python package와 `__init__.py`

이 챕터의 app 코드는 아래 구조로 둔다.

```text
app/
├── __init__.py
└── main.py
```

`__init__.py`는 `app/` 디렉터리를 Python package로 표시하는 파일이다.
내용이 비어 있어도 정상이고, 지금처럼 설명 주석만 있어도 괜찮다.

이 파일이 있으면 Uvicorn이 아래 명령에서 `app.main`을 Python module로 import하기 쉽다.

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

여기서 앞의 `app`은 디렉터리 이름이고, `main`은 `main.py` 파일 이름이고, 마지막 `app`은 `main.py` 안에 있는 FastAPI 객체 이름이다.
즉 `app.main:app`은 "app package 안의 main module에서 app 객체를 찾아 실행하라"는 뜻이다.

### 기본 endpoint

- `/health`: 서버가 살아 있는지 확인한다.
- `/generate`: prompt를 받아 모델 output을 생성한다.
- `/metrics`: 아주 간단한 요청 수와 latency를 확인한다. Prometheus 연동은 뒤 챕터에서 더 제대로 다룬다.

### Hugging Face pipeline

Transformers `pipeline`은 tokenizer, model 호출, 후처리를 task 단위로 묶어주는 편의 API다.
이번 챕터에서는 `text-generation` pipeline을 사용한다.
실습 모델은 `sshleifer/tiny-gpt2`를 기본값으로 둔다. 품질이 좋은 모델은 아니고, 빠르게 서버 구조를 확인하기 위한 작은 모델이다.

### Request/Response Schema

모델 서버는 입력과 출력 형식을 안정적으로 유지해야 한다.
이번 실습에서는 Pydantic으로 다음 schema를 정의한다.

- `GenerateRequest`: `prompt`, `max_new_tokens`, `temperature`
- `GenerateResponse`: `model`, `prompt`, `generated_text`, `latency_ms`

### Pydantic이 맡는 역할

[app/main.py](app/main.py)에서는 Pydantic으로 요청과 응답의 schema를 정의한다.
관련 코드는 이 import에서 시작한다.

```python
from pydantic import BaseModel, Field
```

`BaseModel`을 상속받는 class가 Pydantic model이다.

```python
class GenerateRequest(BaseModel):
    prompt: str = Field(..., min_length=1, examples=["Model serving is"])
    max_new_tokens: int = Field(32, ge=1, le=128)
    temperature: float = Field(0.7, ge=0.0, le=2.0)
```

이 class는 `/generate`로 들어오는 JSON body의 규칙이다.
예를 들어 `prompt`는 비어 있으면 안 되고, `max_new_tokens`는 1 이상 128 이하만 허용된다.

응답도 Pydantic model로 정의한다.

```python
class GenerateResponse(BaseModel):
    model: str
    prompt: str
    generated_text: str
    latency_ms: float
```

FastAPI가 이 schema를 실제 endpoint에 연결하는 부분은 여기다.

```python
@app.post("/generate", response_model=GenerateResponse)
def generate(request: GenerateRequest) -> GenerateResponse:
```

- `request: GenerateRequest`: client가 보낸 JSON을 `GenerateRequest` 규칙으로 검증한다.
- `response_model=GenerateResponse`: server가 돌려주는 응답을 `GenerateResponse` 형태로 맞춘다.

즉, Pydantic은 이 코드에서 "입력과 출력의 모양을 정하고 검증하는 역할"을 한다.

## 코드 워크스루

이 섹션은 [app/main.py](app/main.py)를 처음부터 읽을 때 어떤 부분이 어떤 역할을 하는지 설명한다.

### 1. 필요한 도구 가져오기

```python
import time
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from transformers import pipeline
```

- `time`: 모델 호출에 걸린 시간을 재기 위해 사용한다.
- `asynccontextmanager`: FastAPI 서버가 시작하고 종료될 때 실행할 코드를 정의하기 위해 사용한다.
- `Any`: Hugging Face pipeline 객체 타입을 단순하게 표시하기 위해 사용한다.
- `FastAPI`: API application 객체를 만들기 위해 사용한다.
- `HTTPException`: 서버가 503 같은 HTTP error를 명확히 반환할 때 사용한다.
- `BaseModel`, `Field`: Pydantic schema를 만들고 입력값 조건을 정할 때 사용한다.
- `pipeline`: Hugging Face Transformers에서 tokenizer, model, 후처리를 한 번에 묶어 호출할 때 사용한다.

### 2. 어떤 모델을 쓸지 정하기

```python
MODEL_NAME = "sshleifer/tiny-gpt2"
```

여기서 사용할 Hugging Face model 이름을 정한다.
이 값이 `pipeline("text-generation", model=MODEL_NAME)`에 전달되어 실제 모델 로딩에 사용된다.

### 3. 모델 객체를 담을 변수 만들기

```python
generator: Any | None = None
```

처음에는 모델이 아직 로딩되지 않았기 때문에 `None`이다.
서버가 시작되면 `lifespan()` 안에서 이 변수에 실제 text generation pipeline이 들어간다.

### 4. 간단한 metrics 저장소 만들기

```python
stats = {
    "requests_total": 0,
    "errors_total": 0,
    "latency_ms_total": 0.0,
}
```

이번 실습에서는 Prometheus를 아직 쓰지 않는다.
대신 memory 안에 요청 수, 에러 수, latency 합계를 저장해서 `/metrics`에서 확인한다.

### 5. 서버 시작 시 모델 로딩하기

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    global generator
    generator = pipeline("text-generation", model=MODEL_NAME)
    yield
```

`lifespan()`은 FastAPI application의 생명주기, 즉 시작과 종료 시점을 다루는 함수다.

- `yield` 이전: 서버가 시작될 때 실행된다.
- `yield` 이후: 서버가 종료될 때 실행된다.

이번 코드에서는 `yield` 이전에 모델을 로딩한다.
즉, 서버가 시작되면서 `pipeline("text-generation", model=MODEL_NAME)`이 실행되고, tokenizer와 model이 준비된다.

`@asynccontextmanager`는 이 함수를 "시작 전/종료 후 작업을 가진 context manager"로 만들어준다.
지금은 async 동작을 깊게 알 필요는 없고, "FastAPI가 서버 시작 시 이 함수를 호출하게 만드는 장치"로 이해하면 된다.

### 6. FastAPI application 만들기

```python
app = FastAPI(
    title="Local Model Serving Study",
    version="0.1.0",
    lifespan=lifespan,
)
```

이 `app`이 실제 API application 객체다.
`bash scripts/02_run_server.sh` 안의 명령어는 다음과 같다.

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

여기서 `app.main:app`의 의미는 다음과 같다.

- 첫 번째 `app`: `app/` 디렉터리다. `app/__init__.py`가 있어 Python package처럼 다룰 수 있다.
- `main`: `app/main.py` 파일을 Python module로 import한다.
- 마지막 `app`: 그 파일 안에 있는 `FastAPI(...)` 객체를 사용한다.

`lifespan=lifespan`을 넘겼기 때문에 Uvicorn이 app을 실행할 때 모델 로딩 코드도 같이 실행된다.

### 7. 요청 schema 정의하기

```python
class GenerateRequest(BaseModel):
    prompt: str = Field(..., min_length=1, examples=["Model serving is"])
    max_new_tokens: int = Field(32, ge=1, le=128)
    temperature: float = Field(0.7, ge=0.0, le=2.0)
```

이 class는 `/generate` endpoint가 받을 JSON body의 규칙이다.

- `prompt`: 반드시 있어야 하고 빈 문자열이면 안 된다.
- `max_new_tokens`: 기본값은 32이고, 1 이상 128 이하만 허용한다.
- `temperature`: 기본값은 0.7이고, 0.0 이상 2.0 이하만 허용한다.

잘못된 요청이 오면 FastAPI와 Pydantic이 자동으로 422 error를 반환한다.

### 8. 응답 schema 정의하기

```python
class GenerateResponse(BaseModel):
    model: str
    prompt: str
    generated_text: str
    latency_ms: float
```

이 class는 `/generate`가 돌려줄 JSON response의 모양이다.
모델 이름, 입력 prompt, 생성 결과, latency를 함께 반환한다.

### 9. `/health` endpoint 만들기

```python
@app.get("/health")
def health() -> dict[str, Any]:
```

`@app.get("/health")`는 HTTP GET 요청을 `/health` 주소에 연결한다.
즉, `curl http://127.0.0.1:8000/health`를 실행하면 바로 아래 `health()` 함수가 호출된다.

이 endpoint는 모델이 로딩되었는지 확인한다.
모델 서버에서는 프로세스가 떠 있는 것보다 "모델까지 준비되었는지"가 더 중요하다.

### 10. `/generate` endpoint 만들기

```python
@app.post("/generate", response_model=GenerateResponse)
def generate(request: GenerateRequest) -> GenerateResponse:
```

`@app.post("/generate")`는 HTTP POST 요청을 `/generate` 주소에 연결한다.
client가 JSON body를 보내면 FastAPI가 먼저 `GenerateRequest`로 검증한다.

`response_model=GenerateResponse`는 함수가 돌려주는 값을 `GenerateResponse` schema에 맞춰 응답하겠다는 의미다.

이 함수 안에서 실제 모델 호출이 일어난다.

```python
outputs = generator(
    request.prompt,
    max_new_tokens=request.max_new_tokens,
    temperature=request.temperature,
    do_sample=request.temperature > 0,
)
```

여기서 `generator`는 서버 시작 시 로딩한 Hugging Face pipeline이다.
즉, 이 줄이 prompt를 모델에 넣고 text를 생성하는 핵심 inference 부분이다.

### 11. latency 측정하기

```python
started = time.perf_counter()
...
latency_ms = (time.perf_counter() - started) * 1000
```

모델 호출 전 시간을 기록하고, 호출 후 시간과의 차이를 계산한다.
초 단위 차이에 `1000`을 곱해서 millisecond 단위 latency로 바꾼다.

### 12. `/metrics` endpoint 만들기

```python
@app.get("/metrics")
def metrics() -> dict[str, Any]:
```

`/metrics`는 지금까지 처리한 요청 수, 에러 수, 평균 latency를 반환한다.
운영 환경에서는 이 부분을 Prometheus 형식으로 바꾸고, p95/p99 latency 같은 지표도 추가하게 된다.

### 13. 요청이 들어왔을 때 전체 흐름

```text
서버 시작
→ lifespan() 실행
→ pipeline으로 tokenizer와 model 로딩
→ /health 요청으로 로딩 상태 확인
→ /generate 요청 수신
→ GenerateRequest로 JSON 검증
→ generator pipeline으로 inference 실행
→ GenerateResponse 형태로 응답
→ stats 업데이트
→ /metrics에서 결과 확인
```

## 이 단원에서 반드시 가져갈 정리

### 1. 모델 서버 코드는 세 부분으로 나뉜다

첫째, startup 단계에서 모델을 로딩한다.
둘째, request 단계에서 입력을 검증하고 inference를 실행한다.
셋째, response 단계에서 결과와 latency 같은 메타데이터를 반환한다.

이 구조는 FastAPI뿐 아니라 vLLM, NIM, KServe를 볼 때도 계속 반복된다.

### 2. `/health`는 단순하지만 중요하다

`/health`는 "프로세스가 떠 있다"만 확인할 수도 있고, "모델까지 로딩됐다"를 확인할 수도 있다.
모델 서버에서는 후자가 더 중요하다. 서버 프로세스는 살아 있어도 모델 로딩에 실패하면 inference는 불가능하기 때문이다.

### 3. `/generate`는 모델 서버의 핵심 endpoint다

`/generate`는 prompt를 받아 text를 생성한다.
이번 실습에서는 단순한 JSON API지만, 나중에 OpenAI-compatible API로 가면 `/v1/chat/completions` 같은 표준화된 endpoint를 쓰게 된다.

### 4. `/metrics`는 운영으로 가는 입구다

처음에는 request count, error count, average latency만 봐도 충분하다.
운영 단계에서는 Prometheus histogram, GPU memory, tokens/sec, p95/p99 latency까지 확장한다.

### 5. 작은 모델은 품질보다 구조 확인이 목적이다

`sshleifer/tiny-gpt2`는 좋은 답변을 만드는 모델이 아니다.
이 챕터에서는 "모델을 로딩하고 API로 호출하는 흐름"을 확인하는 것이 목적이다.
성능과 품질은 뒤 챕터에서 vLLM과 더 적절한 모델로 비교한다.

## 실습

### 1. 가상환경과 dependency 설치

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

주의: `pip install`과 모델 다운로드는 네트워크가 필요하다.

환경과 package version은 아래 명령으로 확인한다.

```bash
bash scripts/01_check_env.sh
```

### 2. 서버 실행

서버 실행은 터미널 1에서 진행한다.
이 터미널은 FastAPI 서버가 계속 떠 있어야 하므로, 실습 중에는 닫지 않는다.

```bash
bash scripts/02_run_server.sh
```

서버가 실행되면 기본 주소는 `http://127.0.0.1:8000`이다.

### 3. health check

아래 요청들은 터미널 2에서 실행한다.
터미널 2에서도 Python client를 실행하려면 같은 가상환경을 활성화해야 한다.

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
source .venv/bin/activate
```

```bash
curl http://127.0.0.1:8000/health
```

예상 응답 형태:

```json
{
  "status": "ok",
  "model": "sshleifer/tiny-gpt2",
  "model_loaded": true
}
```

### 4. text generation 요청

```bash
bash scripts/03_curl_generate.sh
```

또는:

```bash
python scripts/04_client.py
```

### 5. metrics 확인

```bash
curl http://127.0.0.1:8000/metrics
```

예상 응답 형태:

```json
{
  "requests_total": 1,
  "errors_total": 0,
  "avg_latency_ms": 123.45
}
```

`avg_latency_ms` 값은 환경마다 달라진다. 중요한 것은 요청을 보낸 뒤 `requests_total`이 증가하고, `errors_total`이 0인지 확인하는 것이다.

### 6. 서버 종료와 가상환경 나가기

실습이 끝나면 터미널 1에서 서버를 종료한다.

```text
Ctrl + C
```

그 다음 각 터미널에서 가상환경을 나온다.

```bash
deactivate
```

프롬프트 앞의 `(.venv)` 표시가 사라지면 가상환경에서 나온 것이다.

## 실습 마무리

챕터 2 실습이 끝나면 아래 순서로 정리한다.

1. 터미널 1에서 FastAPI server 종료

```text
Ctrl + C
```

2. 터미널 2에서 마지막 metrics 확인

```bash
curl http://127.0.0.1:8000/metrics
```

3. 각 터미널에서 가상환경 나가기

```bash
deactivate
```

4. 실습 기록 확인

[templates/lab-notes.md](templates/lab-notes.md)의 아래 항목을 실제 실행 결과와 비교한다.

- Environment
- Request Payload
- Response
- Observations
- Errors

5. 다음 챕터로 넘어가기 전 확인

- `/health`에서 `model_loaded: true`를 확인했는가?
- `/generate`를 `curl`과 Python client로 모두 호출했는가?
- `/metrics`에서 `requests_total`이 증가했는가?
- FastAPI server를 종료했는가?
- 모든 터미널에서 `.venv`를 빠져나왔는가?

## 확인 질문

| 질문 | 정리 방향 |
| --- | --- |
| FastAPI가 모델 서빙에서 맡는 역할은 무엇인가? | HTTP 요청을 받고, 입력을 검증하고, 모델 호출 결과를 JSON response로 반환하는 API layer 역할을 한다. |
| Uvicorn은 왜 필요한가? | FastAPI app에 실제 HTTP 요청을 전달하는 ASGI server가 필요하기 때문이다. |
| `/health`는 왜 필요한가? | 서버와 모델이 inference 가능한 상태인지 외부에서 확인하기 위해 필요하다. |
| Pydantic schema를 쓰는 이유는 무엇인가? | 입력 검증, 타입 변환, API 문서화를 자동화해 request/response contract를 안정적으로 만든다. |
| pipeline은 무엇을 대신 처리해주는가? | tokenizer 호출, model inference, output 후처리 흐름을 task 단위로 묶어준다. |
| 작은 모델을 쓰는 이유는 무엇인가? | 품질보다 서버 구조와 호출 흐름을 빠르게 확인하기 위해서다. |

## 실습 기록

기준 기록은 [templates/lab-notes.md](templates/lab-notes.md)에 미리 정리해 두었다.
실행 후 실제 결과가 예시와 어떻게 다른지만 비교하면 된다.

- 실행한 명령어
- 사용한 모델: `sshleifer/tiny-gpt2`
- Python, FastAPI, Transformers, Torch version
- 요청 payload
- 응답 결과
- latency
- 실패한 점과 해결 방법

## 다음 챕터에서 이어질 내용

다음 챕터에서는 이 FastAPI 모델 서버를 Docker image로 만들고, CPU/GPU container 실행 차이를 확인한다.
