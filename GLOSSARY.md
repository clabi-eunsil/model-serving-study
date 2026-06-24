# Glossary

모델 서빙 스터디 전체 용어집이다.  
자주 쓰는 개념, 약어 안에 숨어 있는 하위 개념도 함께 정리한다.

## 관리 방식

- `Chapter`: 이 용어를 처음 다룬 단원
- `Category`: 용어가 속한 지식 영역
- `Tags`: 나중에 검색하기 좋은 키워드

## Category Index

| Category | 설명 |
| --- | --- |
| Serving Basics | 모델 서빙의 기본 구조와 역할 |
| API & Protocol | API 형태, 통신 방식, protocol 관련 개념 |
| Application Framework | API 서버와 application 구현에 쓰는 framework와 runtime |
| Inference Modes | online/batch처럼 inference를 실행하는 방식 |
| Performance | latency, throughput, 동시성, 성능 지표 |
| LLM Internals | Transformer, token, KV cache처럼 LLM 내부 동작과 관련된 개념 |
| Operations | 운영, health check, warmup, 장애 대응과 관련된 개념 |
| Containerization | Docker image, container, volume처럼 application 실행 환경을 포장하는 개념 |
| Serving Engine | vLLM, TensorRT-LLM처럼 모델 서빙을 위해 최적화된 engine 관련 개념 |
| Development Environment | `.venv`, package install, script 실행처럼 실습 환경을 구성하는 개념 |
| Model Registry & Auth | Hugging Face, Docker Hub, NGC, token처럼 모델/image 저장소와 인증 관련 개념 |
| GPU & Runtime | CUDA, GPU memory, runtime option처럼 GPU 실행 환경과 관련된 개념 |

## Terms

| Term | 한국어/의미 | Category | Tags | Chapter | 설명 |
| --- | --- | --- | --- | --- | --- |
| Model Serving | 모델 서빙 | Serving Basics | serving, deployment, inference | [01](chapters/01-basic-concepts/README.md) | 학습된 모델을 API 또는 service 형태로 배포해 외부 요청에 inference 결과를 반환하는 과정 |
| Inference | 추론 | Serving Basics | prediction, model-output | [01](chapters/01-basic-concepts/README.md) | 학습된 모델에 입력을 넣고 예측 결과를 얻는 과정 |
| Model Server | 모델 서버 | Serving Basics | server, runtime, api | [01](chapters/01-basic-concepts/README.md) | 모델 로딩, 요청 수신, 전처리, inference, 후처리, 응답 반환을 담당하는 서버 |
| API | Application Programming Interface, 애플리케이션 프로그래밍 인터페이스 | API & Protocol | interface, endpoint | [01](chapters/01-basic-concepts/README.md) | 다른 프로그램이 기능을 호출할 수 있도록 정해둔 약속. 모델 서버에서는 요청/응답 형식을 뜻하는 경우가 많다. |
| Endpoint | 엔드포인트, 호출 주소 | API & Protocol | url, route, api | [01](chapters/01-basic-concepts/README.md) | API를 호출하는 구체적인 주소. 예: `/health`, `/generate`, `/v1/chat/completions` |
| REST API | REST 방식 API | API & Protocol | http, json, api | [01](chapters/01-basic-concepts/README.md) | HTTP method, URL, JSON payload를 이용해 요청과 응답을 주고받는 API 방식 |
| RPC | Remote Procedure Call, 원격 프로시저 호출 | API & Protocol | remote-call, protocol | [01](chapters/01-basic-concepts/README.md) | 다른 서버에 있는 함수를 마치 내 코드의 함수처럼 호출하는 통신 방식 |
| gRPC | Google Remote Procedure Call | API & Protocol | rpc, protobuf, http2 | [01](chapters/01-basic-concepts/README.md) | protobuf와 HTTP/2 기반 RPC framework. 내부 service 간 빠르고 명확한 schema 기반 통신에 자주 사용 |
| Protocol Buffers | protobuf, 직렬화 형식 | API & Protocol | protobuf, schema, serialization | [01](chapters/01-basic-concepts/README.md) | 데이터를 어떤 구조로 주고받을지 정의하고 binary 형태로 효율적으로 직렬화하는 Google의 data format |
| HTTP/2 | HTTP 2 버전 | API & Protocol | http, network, grpc | [01](chapters/01-basic-concepts/README.md) | 하나의 연결에서 여러 요청을 효율적으로 처리할 수 있는 HTTP protocol. gRPC가 기반으로 사용한다. |
| OpenAI-compatible API | OpenAI 호환 API | API & Protocol | openai, chat-completions, sdk | [01](chapters/01-basic-concepts/README.md) | OpenAI API와 비슷한 endpoint, request, response schema를 제공하는 API 형태 |
| Online Inference | 온라인 추론 | Inference Modes | realtime, latency, user-facing | [01](chapters/01-basic-concepts/README.md) | 사용자 요청에 거의 실시간으로 응답하는 inference 방식. latency와 안정성이 중요 |
| Batch Inference | 배치 추론 | Inference Modes | batch, offline, throughput | [01](chapters/01-basic-concepts/README.md) | 많은 입력을 모아 한 번에 처리하는 inference 방식. throughput과 비용 효율이 중요 |
| Latency | 지연 시간 | Performance | latency, response-time | [01](chapters/01-basic-concepts/README.md) | 요청을 보낸 시점부터 응답을 받을 때까지 걸린 시간 |
| Throughput | 처리량 | Performance | throughput, tokens-sec, qps | [01](chapters/01-basic-concepts/README.md) | 단위 시간당 처리량. requests/sec, tokens/sec, samples/sec 등으로 표현 |
| Concurrency | 동시성 | Performance | concurrent-requests, load | [01](chapters/01-basic-concepts/README.md) | 동시에 처리되거나 대기 중인 요청 수 |
| Queueing | 대기열 발생 | Performance | queue, overload, tail-latency | [01](chapters/01-basic-concepts/README.md) | 처리 가능한 용량보다 요청이 많아 일부 요청이 기다리는 현상 |
| Tail Latency | 꼬리 지연 시간 | Performance | p95, p99, latency | [01](chapters/01-basic-concepts/README.md) | 가장 느린 일부 요청의 latency. p95, p99 같은 percentile로 자주 본다. |
| Cold Start | 콜드 스타트 | Operations | startup, model-loading | [01](chapters/01-basic-concepts/README.md) | 서버 또는 모델이 준비되지 않은 상태에서 첫 요청을 처리하며 초기화 비용이 발생하는 상황 |
| Warmup | 워밍업 | Operations | startup, cuda, cache | [01](chapters/01-basic-concepts/README.md) | 실제 트래픽 전에 모델 로딩, CUDA kernel 준비, cache 초기화 등을 미리 수행하는 과정 |
| Model Loading Time | 모델 로딩 시간 | Operations | model-weights, startup | [01](chapters/01-basic-concepts/README.md) | 모델 weight와 tokenizer 등을 디스크나 원격 저장소에서 읽어 메모리/GPU에 올리는 데 걸리는 시간 |
| Token | 토큰 | LLM Internals | tokenizer, generation | [01](chapters/01-basic-concepts/README.md) | 모델이 텍스트를 처리하는 기본 단위. 한 글자, 단어 조각, 단어에 가까운 단위가 될 수 있다. |
| Autoregressive Generation | 자기회귀 생성 | LLM Internals | generation, token, decoder | [01](chapters/01-basic-concepts/README.md) | 이전에 생성한 token들을 다시 입력 문맥으로 사용해 다음 token을 하나씩 생성하는 방식 |
| Transformer Decoder | 트랜스포머 디코더 | LLM Internals | transformer, decoder, llm | [01](chapters/01-basic-concepts/README.md) | 이전 token 문맥을 보고 다음 token을 예측하는 Transformer 구성 요소. GPT 계열 LLM은 decoder-only 구조가 많다. |
| Key/Value Tensor | Key/Value 텐서 | LLM Internals | attention, kv-cache, tensor | [01](chapters/01-basic-concepts/README.md) | self-attention 계산에서 이전 token 정보를 재사용하기 위해 저장하는 key와 value 값 |
| KV Cache | Key/Value 캐시 | LLM Internals | kv-cache, memory, attention | [01](chapters/01-basic-concepts/README.md) | Transformer decoder가 이전 token들의 key/value tensor를 저장해 다음 token 생성 시 재계산을 줄이는 cache |
| TTFT | 첫 토큰까지 걸린 시간 | Performance | streaming, first-token, latency | [01](chapters/01-basic-concepts/README.md) | Time To First Token. LLM streaming에서 첫 token을 받을 때까지 걸린 시간 |
| TTFB | 첫 바이트까지 걸린 시간 | Performance | http, first-byte, latency | [01](chapters/01-basic-concepts/README.md) | Time To First Byte. HTTP 응답의 첫 byte를 받을 때까지 걸린 시간 |
| TTFP | 첫 예측까지 걸린 시간 | Performance | first-prediction, latency | [01](chapters/01-basic-concepts/README.md) | Time To First Prediction. 도구나 조직마다 정의가 다를 수 있어 사용할 때 정의를 함께 적어야 함 |
| TPS | 초당 토큰 수 | Performance | tokens-sec, throughput | [01](chapters/01-basic-concepts/README.md) | Tokens Per Second. 초당 생성 또는 처리한 token 수 |
| QPS | 초당 요청 수 | Performance | queries-sec, throughput | [01](chapters/01-basic-concepts/README.md) | Queries Per Second. 초당 처리한 요청 수 |
| Continuous Batching | 연속 배치 처리 | Performance | batching, scheduler, throughput | [01](chapters/01-basic-concepts/README.md) | LLM serving에서 진행 중인 batch에 새 요청을 계속 합류시키며 GPU 활용도를 높이는 scheduling 방식 |
| FastAPI | FastAPI Python web framework | Application Framework | python, api, pydantic | [02](chapters/02-fastapi-serving/README.md) | Python type hint를 기반으로 HTTP API를 만들고 request validation과 OpenAPI 문서화를 제공하는 framework |
| ASGI | Asynchronous Server Gateway Interface | Application Framework | python, async, server | [02](chapters/02-fastapi-serving/README.md) | Python 비동기 web server와 application 사이의 interface 규격 |
| Uvicorn | Uvicorn ASGI server | Application Framework | asgi, server, uvicorn | [02](chapters/02-fastapi-serving/README.md) | FastAPI 같은 ASGI application에 HTTP 요청을 전달하는 Python server |
| Pydantic | Pydantic data validation | Application Framework | validation, schema, type-hint | [02](chapters/02-fastapi-serving/README.md) | Python type annotation을 기반으로 입력 데이터를 검증하고 변환하는 library |
| Request Schema | 요청 스키마 | API & Protocol | request, validation, contract | [02](chapters/02-fastapi-serving/README.md) | client가 server에 보내야 하는 입력 데이터의 구조와 타입 정의 |
| Response Schema | 응답 스키마 | API & Protocol | response, contract, json | [02](chapters/02-fastapi-serving/README.md) | server가 client에 반환하는 출력 데이터의 구조와 타입 정의 |
| Health Check | 상태 확인 | Operations | health, readiness, liveness | [02](chapters/02-fastapi-serving/README.md) | server 또는 model이 요청을 처리할 수 있는 상태인지 확인하는 endpoint나 검사 방식 |
| Metrics Endpoint | 메트릭 엔드포인트 | Operations | metrics, observability, monitoring | [02](chapters/02-fastapi-serving/README.md) | 요청 수, 에러 수, latency 같은 운영 지표를 노출하는 endpoint |
| Pipeline | 파이프라인 | LLM Internals | transformers, inference, task | [02](chapters/02-fastapi-serving/README.md) | Hugging Face Transformers에서 tokenizer, model 호출, 후처리를 task 단위로 묶은 편의 API |
| Tokenizer | 토크나이저 | LLM Internals | token, preprocessing, text | [02](chapters/02-fastapi-serving/README.md) | 텍스트를 모델이 처리할 수 있는 token id로 바꾸고, 모델 출력을 다시 텍스트로 바꾸는 구성 요소 |
| Generation Config | 생성 설정 | LLM Internals | generation, max-new-tokens, temperature | [02](chapters/02-fastapi-serving/README.md) | text generation에서 output 길이, sampling 방식, temperature 같은 생성 동작을 제어하는 설정 |
| Temperature | 온도값 | LLM Internals | sampling, randomness, generation | [02](chapters/02-fastapi-serving/README.md) | 다음 token을 샘플링할 때 분포를 얼마나 날카롭거나 다양하게 만들지 조절하는 값 |
| Virtual Environment | Python 가상환경, `.venv` | Development Environment | python, venv, dependency | [02](chapters/02-fastapi-serving/README.md) | 프로젝트나 챕터별로 Python package를 분리해 설치하기 위한 격리된 실행 환경 |
| Dependency | 의존성 package | Development Environment | package, requirements, pip | [02](chapters/02-fastapi-serving/README.md) | application 실행에 필요한 외부 library. 예: `fastapi`, `uvicorn`, `transformers` |
| `requirements.txt` | Python 의존성 목록 파일 | Development Environment | pip, dependency, install | [02](chapters/02-fastapi-serving/README.md) | `pip install -r requirements.txt`로 설치할 package 목록을 적는 파일 |
| JSON Payload | JSON 요청 본문 | API & Protocol | json, request-body, payload | [02](chapters/02-fastapi-serving/README.md) | client가 POST 요청 등으로 server에 보내는 JSON 형식의 입력 데이터 |
| HTTP Method | HTTP 메서드 | API & Protocol | get, post, http | [02](chapters/02-fastapi-serving/README.md) | API 요청의 동작 종류를 나타내는 값. 예: `GET`은 조회, `POST`는 데이터 전송/생성에 자주 사용 |
| HTTP Header | HTTP 헤더 | API & Protocol | content-type, metadata, http | [02](chapters/02-fastapi-serving/README.md) | 요청/응답 본문 외의 부가 정보. 예: `Content-Type: application/json` |
| HTTP Status Code | HTTP 상태 코드 | API & Protocol | status-code, error, response | [02](chapters/02-fastapi-serving/README.md) | HTTP 응답 결과를 숫자로 표현한 값. 예: `200` 성공, `422` validation error, `503` 준비 안 됨 |
| Route Decorator | 라우트 데코레이터 | Application Framework | fastapi, decorator, route | [02](chapters/02-fastapi-serving/README.md) | `@app.get("/health")`처럼 Python 함수와 API endpoint를 연결하는 FastAPI 문법 |
| Lifespan | 애플리케이션 생명주기 | Application Framework | startup, shutdown, fastapi | [02](chapters/02-fastapi-serving/README.md) | FastAPI app 시작/종료 시점에 실행할 로직. 모델 로딩처럼 server startup에 필요한 작업을 넣는다. |
| Async Context Manager | 비동기 컨텍스트 매니저 | Application Framework | async, lifespan, contextmanager | [02](chapters/02-fastapi-serving/README.md) | `async with` 흐름에 맞춰 startup/shutdown 전후 작업을 감싸는 Python 구조. FastAPI lifespan 구현에 사용 |
| Type Hint | 타입 힌트 | Application Framework | python, typing, pydantic | [02](chapters/02-fastapi-serving/README.md) | `prompt: str`, `max_new_tokens: int`처럼 변수나 함수 인자의 기대 타입을 코드에 적는 문법 |
| Field Validation | 필드 검증 | Application Framework | pydantic, validation, schema | [02](chapters/02-fastapi-serving/README.md) | Pydantic `Field`로 최소 길이, 숫자 범위 같은 입력 조건을 검사하는 것 |
| `curl` | command line HTTP client | Development Environment | cli, http, request | [02](chapters/02-fastapi-serving/README.md) | 터미널에서 HTTP API를 호출하는 도구. 서버 동작을 빠르게 확인할 때 사용 |
| Python Requests | Python `requests` library | Development Environment | python, client, http | [02](chapters/02-fastapi-serving/README.md) | Python 코드에서 HTTP 요청을 보내는 library. 실습 client에서 `/generate` 호출에 사용 |
| Reload Mode | 개발용 자동 재시작 모드 | Application Framework | uvicorn, reload, dev | [02](chapters/02-fastapi-serving/README.md) | `uvicorn --reload`처럼 코드 변경 시 server를 자동 재시작하는 개발 편의 기능 |
| Docker Image | 도커 이미지 | Containerization | docker, image, build | [03](chapters/03-docker-serving/README.md) | application 실행에 필요한 파일, dependency, 실행 명령을 묶은 package |
| Container | 컨테이너 | Containerization | docker, runtime, process | [03](chapters/03-docker-serving/README.md) | Docker image를 실제로 실행한 프로세스 또는 실행 인스턴스 |
| Dockerfile | 도커파일 | Containerization | dockerfile, image, build | [03](chapters/03-docker-serving/README.md) | Docker image를 어떻게 만들지 instruction으로 적는 파일 |
| Build Context | 빌드 컨텍스트 | Containerization | docker-build, context, copy | [03](chapters/03-docker-serving/README.md) | `docker build`가 Docker daemon에 보내는 파일 묶음. Dockerfile의 `COPY`는 기본적으로 이 범위 안에서만 동작한다. |
| Layer Cache | 레이어 캐시 | Containerization | docker, cache, build | [03](chapters/03-docker-serving/README.md) | Docker build 단계별 결과를 재사용해 다음 build를 빠르게 하는 cache |
| Port Mapping | 포트 매핑 | Containerization | docker-run, port, networking | [03](chapters/03-docker-serving/README.md) | host port와 container port를 연결하는 설정. 예: `-p 8000:8000` |
| Docker Volume | 도커 볼륨 | Containerization | volume, cache, persistence | [03](chapters/03-docker-serving/README.md) | container가 삭제되어도 데이터를 유지하기 위해 Docker가 관리하는 저장 공간 |
| Bind Mount | 바인드 마운트 | Containerization | mount, host-path, volume | [03](chapters/03-docker-serving/README.md) | host의 특정 directory/file을 container 안의 경로에 직접 연결하는 방식 |
| Docker Compose | 도커 컴포즈 | Containerization | compose, yaml, multi-service | [03](chapters/03-docker-serving/README.md) | 여러 container 실행 설정을 YAML 파일로 관리하고 실행하는 Docker 도구 |
| NVIDIA Container Toolkit | NVIDIA 컨테이너 툴킷 | Containerization | gpu, nvidia, docker | [03](chapters/03-docker-serving/README.md) | Docker container가 host의 NVIDIA GPU를 사용할 수 있도록 연결해 주는 도구 |
| Base Image | 베이스 이미지 | Containerization | dockerfile, from, base-image | [03](chapters/03-docker-serving/README.md) | Dockerfile의 `FROM`에 적는 시작 image. 예: `python:3.12-slim` |
| Image Tag | 이미지 태그 | Containerization | docker, tag, version | [03](chapters/03-docker-serving/README.md) | 같은 image repository 안에서 version이나 용도를 구분하는 이름. 예: `model-serving-fastapi:chapter-03`의 `chapter-03` |
| `.dockerignore` | Docker build 제외 목록 | Containerization | docker-build, context, ignore | [03](chapters/03-docker-serving/README.md) | build context에 포함하지 않을 파일을 적는 파일. `.venv`, cache, `__pycache__` 제외에 사용 |
| Docker Layer | 도커 레이어 | Containerization | docker, layer, image-size | [03](chapters/03-docker-serving/README.md) | Dockerfile instruction 결과가 쌓여 만들어지는 image 구성 단위. `docker history`로 확인 가능 |
| Docker Daemon | 도커 데몬 | Containerization | docker, daemon, engine | [03](chapters/03-docker-serving/README.md) | 실제 container/image 작업을 수행하는 Docker background service. CLI는 daemon에 요청을 보낸다. |
| Docker CLI | 도커 명령줄 도구 | Containerization | docker, cli, command | [03](chapters/03-docker-serving/README.md) | 사용자가 `docker build`, `docker run` 같은 명령을 실행하는 command line client |
| Docker Registry | 도커 이미지 저장소 | Model Registry & Auth | registry, docker-hub, image | [03](chapters/03-docker-serving/README.md) | Docker image를 push/pull하는 저장소. 예: Docker Hub, NGC, private registry |
| Docker Hub | Docker 공식 public registry | Model Registry & Auth | docker-hub, registry, image | [03](chapters/03-docker-serving/README.md) | Docker image를 공유하고 내려받는 public registry. rate limit이나 private image 사용 시 login이 필요할 수 있다. |
| NGC | NVIDIA GPU Cloud catalog/registry | Model Registry & Auth | nvidia, ngc, registry | [03](chapters/03-docker-serving/README.md) | NVIDIA가 제공하는 container image, model, resource catalog. NIM 같은 image를 받을 때 사용 |
| Hugging Face Hub | Hugging Face 모델 저장소 | Model Registry & Auth | huggingface, model, hub | [03](chapters/03-docker-serving/README.md) | model weight, tokenizer, dataset 등을 저장하고 내려받는 platform |
| Access Token | 접근 토큰 | Model Registry & Auth | token, auth, secret | [03](chapters/03-docker-serving/README.md) | private/gated model이나 registry 접근 권한을 증명하는 secret 값. script에 직접 저장하지 않는다. |
| Gated Model | 접근 승인이 필요한 모델 | Model Registry & Auth | huggingface, gated, license | [03](chapters/03-docker-serving/README.md) | 라이선스 동의나 권한 승인이 있어야 다운로드할 수 있는 모델 |
| Environment Variable | 환경변수 | Development Environment | env-var, config, runtime | [03](chapters/03-docker-serving/README.md) | 실행 시 configuration을 주입하는 key/value 값. 예: `MODEL_NAME`, `HF_TOKEN` |
| Docker Compose Service | Compose 서비스 | Containerization | compose, service, container | [03](chapters/03-docker-serving/README.md) | `docker-compose.yml`의 `services:` 아래에 정의하는 실행 단위. 보통 하나의 container 역할을 한다. |
| Compose Profile | Compose 프로필 | Containerization | compose, profile, optional-service | [03](chapters/03-docker-serving/README.md) | 특정 service를 선택적으로 실행하기 위한 Compose 기능. client처럼 필요할 때만 실행하는 service에 사용 |
| Detached Mode | 백그라운드 실행 모드 | Containerization | docker, compose, background | [03](chapters/03-docker-serving/README.md) | `-d` 옵션으로 container를 foreground가 아니라 background에서 실행하는 방식 |
| Restart Policy | 재시작 정책 | Containerization | docker, restart, operations | [03](chapters/03-docker-serving/README.md) | container가 비정상 종료되었을 때 Docker가 다시 시작할지 정하는 설정. 예: `unless-stopped` |
| Docker Network | 도커 네트워크 | Containerization | docker, network, service-discovery | [03](chapters/03-docker-serving/README.md) | container끼리 통신하기 위한 가상 network. Compose에서는 service 이름으로 서로를 찾을 수 있다. |
| Service Discovery | 서비스 발견 | Operations | network, dns, compose | [03](chapters/03-docker-serving/README.md) | client가 server의 실제 IP를 몰라도 service 이름으로 endpoint를 찾는 방식 |
| `nvidia-smi` | NVIDIA GPU 상태 확인 명령 | GPU & Runtime | nvidia, gpu, monitoring | [03](chapters/03-docker-serving/README.md) | GPU driver, GPU 사용률, memory 사용량, 실행 중인 process를 확인하는 NVIDIA CLI 도구 |
| CUDA | Compute Unified Device Architecture | GPU & Runtime | cuda, nvidia, gpu | [03](chapters/03-docker-serving/README.md) | NVIDIA GPU에서 병렬 계산을 수행하기 위한 software platform/API |
| GPU Passthrough | GPU 전달 | GPU & Runtime | docker, gpu, runtime | [03](chapters/03-docker-serving/README.md) | host GPU를 container 안에서 사용할 수 있게 runtime이 연결해 주는 것 |
| SSH Port Forwarding | SSH 포트 포워딩 | Operations | ssh, remote-server, port-forward | [03](chapters/03-docker-serving/README.md) | 원격 서버의 port를 로컬 port처럼 접근하도록 SSH tunnel을 만드는 방식. 예: `ssh -L 8000:127.0.0.1:8000` |
| vLLM | vLLM 서빙 엔진 | Serving Engine | llm-serving, inference-engine, openai-compatible | [04](chapters/04-vllm-intro/README.md) | LLM inference와 serving을 위해 KV cache, batching, API server 등을 최적화해 제공하는 open-source serving engine |
| PagedAttention | 페이지드 어텐션, block 기반 KV cache 관리 방식 | Serving Engine | pagedattention, kv-cache, memory | [04](chapters/04-vllm-intro/README.md) | KV cache를 고정 크기 block 단위로 관리해 GPU memory 낭비를 줄이는 vLLM의 핵심 아이디어 |
| Model Repository ID | 모델 저장소 ID | Model Registry & Auth | huggingface, repo-id, model-name | [04](chapters/04-vllm-intro/README.md) | Hugging Face Hub에서 model repository를 가리키는 이름. 예: `Qwen/Qwen3-0.6B` |
| Model Card | 모델 카드 | Model Registry & Auth | huggingface, license, model-info | [04](chapters/04-vllm-intro/README.md) | 모델 설명, 사용법, license, 제한 사항, benchmark 등을 적어둔 model page 문서 |
| Model Weight | 모델 가중치 | LLM Internals | weight, checkpoint, model-files | [04](chapters/04-vllm-intro/README.md) | 학습된 parameter 값이 저장된 파일. vLLM container 실행 시 Hugging Face에서 다운로드되거나 cache에서 로딩된다. |
| `HF_TOKEN` | Hugging Face 접근 토큰 환경변수 | Model Registry & Auth | huggingface, token, env-var | [04](chapters/04-vllm-intro/README.md) | gated/private model을 다운로드할 때 container에 전달하는 Hugging Face token 환경변수 |
| Model Resolution | 모델 해석/매칭 과정 | Serving Engine | vllm, architecture, config | [04](chapters/04-vllm-intro/README.md) | vLLM이 model repo의 `config.json` 등을 읽고 어떤 model implementation으로 로딩할지 결정하는 과정 |
| Model Architecture | 모델 아키텍처 | LLM Internals | architecture, config, transformer | [04](chapters/04-vllm-intro/README.md) | 모델 구조 종류. vLLM은 Hugging Face repo의 `config.json`에 있는 architecture 정보를 보고 지원 여부를 판단한다. |
| Chat Template | 채팅 템플릿 | API & Protocol | chat, tokenizer, messages | [04](chapters/04-vllm-intro/README.md) | `system/user/assistant` messages를 모델이 이해하는 prompt 문자열로 바꾸는 tokenizer-side 규칙 |
| Served Model Name | 서빙 모델 이름, API alias | API & Protocol | model-alias, openai-compatible | [04](chapters/04-vllm-intro/README.md) | 실제 model path와 별개로 client가 API 요청의 `model` field에 넣는 이름 |
| Chat Completions | 채팅 완성 API | API & Protocol | chat-completions, openai-compatible | [04](chapters/04-vllm-intro/README.md) | `messages` 배열을 입력으로 받아 assistant 답변을 생성하는 OpenAI-compatible API 형식 |
| Streaming Response | 스트리밍 응답 | API & Protocol | streaming, sse, ttft | [04](chapters/04-vllm-intro/README.md) | 생성 결과를 한 번에 보내지 않고 token 또는 chunk가 준비되는 대로 나누어 보내는 응답 방식 |
| Base URL | 기본 API 주소 | API & Protocol | endpoint, sdk, client | [04](chapters/04-vllm-intro/README.md) | SDK client가 요청을 보낼 API root 주소. vLLM 실습에서는 `http://127.0.0.1:8000/v1`처럼 지정한다. |
| Chat Message | 채팅 메시지 | API & Protocol | messages, role, content | [04](chapters/04-vllm-intro/README.md) | Chat Completions API에서 `role`과 `content`로 구성되는 대화 입력 한 줄 |
| Message Role | 메시지 역할 | API & Protocol | role, system, user, assistant | [04](chapters/04-vllm-intro/README.md) | 메시지를 누가 말했는지 나타내는 값. 대표적으로 `system`, `user`, `assistant`가 있다. |
| System Message | 시스템 메시지 | API & Protocol | system, instruction, chat | [04](chapters/04-vllm-intro/README.md) | 모델의 전반적인 행동 방식이나 답변 스타일을 지시하는 message |
| User Message | 사용자 메시지 | API & Protocol | user, prompt, chat | [04](chapters/04-vllm-intro/README.md) | 사용자가 실제로 묻거나 요청하는 내용을 담는 message |
| Assistant Message | 어시스턴트 메시지 | API & Protocol | assistant, response, chat-history | [04](chapters/04-vllm-intro/README.md) | 모델이 이전 turn에서 답한 내용을 나타내는 message. multi-turn 대화 문맥에 사용 |
| Inference Engine | 추론 엔진 | Serving Engine | inference, runtime, serving | [04](chapters/04-vllm-intro/README.md) | 모델 실행, scheduling, memory 관리 등을 담당하는 핵심 runtime. vLLM은 LLM inference engine 역할을 한다. |
| Scheduler | 스케줄러 | Serving Engine | batching, queue, throughput | [04](chapters/04-vllm-intro/README.md) | 여러 요청을 어떤 순서와 batch로 GPU에 보낼지 결정하는 구성 요소 |
| Engine Arguments | 엔진 옵션 | Serving Engine | vllm, args, configuration | [04](chapters/04-vllm-intro/README.md) | vLLM engine 동작을 제어하는 실행 옵션. 예: `--model`, `--gpu-memory-utilization`, `--max-model-len` |
| Server Arguments | 서버 옵션 | Serving Engine | vllm, host, port | [04](chapters/04-vllm-intro/README.md) | vLLM API server의 host, port 등 HTTP server 동작을 제어하는 실행 옵션 |
| GPU Memory Utilization | GPU 메모리 사용 비율 | GPU & Runtime | gpu-memory, vllm, oom | [04](chapters/04-vllm-intro/README.md) | vLLM이 GPU memory 중 어느 정도까지 사용할지 정하는 비율. 너무 높으면 OOM 위험이 있다. |
| Max Model Length | 최대 모델 길이 | LLM Internals | context-length, kv-cache, vllm | [04](chapters/04-vllm-intro/README.md) | 한 요청에서 prompt와 generated token을 합쳐 다룰 수 있는 최대 sequence length |
| Context Length | 컨텍스트 길이 | LLM Internals | context, sequence, tokens | [04](chapters/04-vllm-intro/README.md) | 모델이 한 번에 참고할 수 있는 token sequence 길이. 길수록 KV cache memory 요구량이 커진다. |
| Sequence Length | 시퀀스 길이 | LLM Internals | tokens, context, length | [04](chapters/04-vllm-intro/README.md) | 모델 입력/출력을 token 나열로 보았을 때의 길이 |
| Chunk | 응답 조각 | API & Protocol | streaming, chunk, response | [04](chapters/04-vllm-intro/README.md) | streaming 응답에서 한 번에 도착하는 작은 데이터 조각 |
| SSE | Server-Sent Events | API & Protocol | streaming, http, event-stream | [04](chapters/04-vllm-intro/README.md) | server가 HTTP 연결을 유지한 채 event data를 client로 계속 보내는 streaming 방식 |
| OpenAI SDK | OpenAI Python SDK | API & Protocol | sdk, client, openai-compatible | [04](chapters/04-vllm-intro/README.md) | OpenAI API 호출용 client library. `base_url`을 vLLM으로 바꿔 OpenAI-compatible server 호출에 사용할 수 있다. |
| Dummy API Key | 더미 API 키 | API & Protocol | sdk, auth, local-server | [04](chapters/04-vllm-intro/README.md) | local vLLM처럼 실제 인증을 쓰지 않아도 SDK 형식상 필요한 임시 API key 값. 예: `EMPTY` |
| IPC | Inter-Process Communication, 프로세스 간 통신 | GPU & Runtime | ipc, process, shared-memory | [04](chapters/04-vllm-intro/README.md) | 여러 process가 데이터를 주고받거나 동기화하기 위한 통신 방식. Docker의 `--ipc=host` 옵션에서 등장한다. |
| IPC Namespace | IPC 네임스페이스 | Containerization | docker, ipc, shared-memory | [04](chapters/04-vllm-intro/README.md) | process 간 shared memory 같은 IPC resource를 격리하는 Linux/Docker 개념. vLLM Docker 실행에서 `--ipc=host`를 사용한다. |
| Shared Memory | 공유 메모리 | GPU & Runtime | pytorch, ipc, docker | [04](chapters/04-vllm-intro/README.md) | 여러 process가 함께 사용할 수 있는 memory 영역. PyTorch/vLLM Docker 실행에서 부족하면 문제가 생길 수 있다. |
| OOM | Out Of Memory, 메모리 부족 | GPU & Runtime | gpu-memory, error, oom | [04](chapters/04-vllm-intro/README.md) | GPU 또는 system memory가 부족해 model loading이나 inference가 실패하는 상황 |
| Benchmark | 벤치마크, 성능 측정 실험 | Performance | benchmark, measurement, test | [05](chapters/05-vllm-performance-tuning/README.md) | 특정 조건에서 latency, throughput, GPU memory 같은 성능 지표를 측정하는 실험 |
| Benchmark Matrix | 벤치마크 매트릭스 | Performance | benchmark, matrix, experiment | [05](chapters/05-vllm-performance-tuning/README.md) | concurrency, prompt length, max tokens처럼 여러 조건 조합을 표처럼 바꿔가며 실행하는 실험 구성 |
| p50 Latency | 중앙값 지연 시간 | Performance | percentile, latency, p50 | [05](chapters/05-vllm-performance-tuning/README.md) | 요청 latency를 정렬했을 때 가운데에 해당하는 값. 일반적인 요청 체감을 보는 데 사용 |
| p95 Latency | 95번째 percentile 지연 시간 | Performance | percentile, tail-latency, p95 | [05](chapters/05-vllm-performance-tuning/README.md) | 요청 중 느린 쪽 5% 경계에 있는 latency. tail latency 문제를 볼 때 중요 |
| Prefill | 프리필 단계 | LLM Internals | prompt, kv-cache, prefill | [05](chapters/05-vllm-performance-tuning/README.md) | prompt token을 한 번에 처리해 KV cache를 채우는 LLM inference 단계 |
| Decode | 디코드 단계 | LLM Internals | generation, token, decode | [05](chapters/05-vllm-performance-tuning/README.md) | 이미 만들어진 KV cache를 사용해 output token을 하나씩 생성하는 단계 |
| Prefix Caching | 프리픽스 캐싱 | Serving Engine | prefix, cache, prefill | [05](chapters/05-vllm-performance-tuning/README.md) | 여러 요청이 같은 앞부분 prompt를 공유할 때 해당 prefix의 KV cache를 재사용해 prefill 비용을 줄이는 기법 |
| Chunked Prefill | 청크 단위 프리필 | Serving Engine | prefill, scheduling, latency | [05](chapters/05-vllm-performance-tuning/README.md) | 긴 prompt prefill을 작은 조각으로 나누어 decode 작업과 섞어 처리하는 scheduling 최적화 |
| Quantization | 양자화 | LLM Internals | quantization, memory, inference | [05](chapters/05-vllm-performance-tuning/README.md) | weight나 activation precision을 낮춰 memory 사용량과 계산 비용을 줄이는 기법. 품질/속도 trade-off가 있다. |
| Tensor Parallelism | 텐서 병렬화 | GPU & Runtime | multi-gpu, parallelism, tensor | [05](chapters/05-vllm-performance-tuning/README.md) | 큰 model tensor를 여러 GPU에 나누어 올리고 계산하는 병렬화 방식 |
| Max Num Seqs | 최대 sequence 수 | Serving Engine | vllm, batching, scheduler | [05](chapters/05-vllm-performance-tuning/README.md) | vLLM scheduler가 동시에 처리할 수 있는 sequence 수의 상한을 정하는 option |
| Max Num Batched Tokens | 최대 batch token 수 | Serving Engine | vllm, batching, tokens | [05](chapters/05-vllm-performance-tuning/README.md) | 한 scheduler iteration에서 batch로 묶을 수 있는 token 수의 상한을 정하는 option |
| Request Lifecycle | 요청 생명주기 | Serving Engine | request, scheduler, lifecycle | [05](chapters/05-vllm-performance-tuning/README.md) | 요청이 waiting, prefill, decode, finished 같은 상태를 거쳐 응답 완료에 이르는 흐름 |
| Active Sequence | 활성 sequence | Serving Engine | sequence, scheduler, running | [05](chapters/05-vllm-performance-tuning/README.md) | vLLM scheduler가 현재 처리 중이거나 관리 중인 token sequence. 실습에서는 요청 1개와 거의 대응한다고 이해하면 된다. |
| Waiting Queue | 대기 queue | Serving Engine | queue, waiting, scheduler | [05](chapters/05-vllm-performance-tuning/README.md) | 아직 GPU 실행에 들어가지 못하고 scheduler의 처리 순서를 기다리는 요청 목록 |
| Finished Request | 완료된 요청 | Serving Engine | finished, response, scheduler | [05](chapters/05-vllm-performance-tuning/README.md) | stop condition에 도달해 더 이상 token을 생성하지 않고 응답 반환을 마친 요청 |
