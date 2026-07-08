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
| Serving Platform | Kubernetes 같은 환경 위에서 model server 배포, 라우팅, 확장을 관리하는 platform 개념 |
| ML Workflow | 데이터 준비, 학습, 평가, 배포를 연결하는 pipeline과 workflow 개념 |
| Development Environment | `.venv`, package install, script 실행처럼 실습 환경을 구성하는 개념 |
| Model Registry & Auth | Hugging Face, Docker Hub, NGC, token처럼 모델/image 저장소와 인증 관련 개념 |
| GPU & Runtime | CUDA, GPU memory, runtime option처럼 GPU 실행 환경과 관련된 개념 |
| LLM Observability | prompt, completion, trace, user/session처럼 LLM application 관측과 관련된 개념 |
| Evaluation | dataset, experiment, score처럼 LLM application 품질 평가와 관련된 개념 |

## Terms

| Term | 한국어/의미 | Category | Tags | Chapter | 설명 |
| --- | --- | --- | --- | --- | --- |
| Model Serving | 모델 서빙 | Serving Basics | serving, deployment, inference | [01](chapters/01-basic-concepts/README.md) | 학습된 모델을 API 또는 service 형태로 배포해 외부 요청에 inference 결과를 반환하는 과정 |
| Inference | 추론 | Serving Basics | prediction, model-output | [01](chapters/01-basic-concepts/README.md) | 학습된 모델에 입력을 넣고 예측 결과를 얻는 과정 |
| Model Server | 모델 서버 | Serving Basics | server, runtime, api | [01](chapters/01-basic-concepts/README.md) | 모델 로딩, 요청 수신, 전처리, inference, 후처리, 응답 반환을 담당하는 서버 |
| Inference Server | 추론 서버 | Serving Basics | server, inference, runtime | [01](chapters/01-basic-concepts/README.md) | 모델 추론을 실행하고 API로 결과를 반환하는 서버. model server와 거의 비슷하게 쓰이지만 inference 실행에 더 초점을 둔 표현 |
| ML Serving Framework | ML 모델 서빙 프레임워크 | Serving Basics | framework, serving, general-ml | [01](chapters/01-basic-concepts/README.md) | TensorFlow, PyTorch, ONNX 같은 다양한 ML 모델을 운영 환경에서 서빙하기 위한 범용 framework |
| LLM Serving Engine | LLM 서빙 엔진 | Serving Engine | llm-serving, engine, token-generation | [01](chapters/01-basic-concepts/README.md) | LLM의 token generation, KV cache, batching, streaming을 효율적으로 처리하는 데 특화된 inference engine |
| Deployment Target | 배포 대상/실행 위치 | Serving Platform | local, docker, kubernetes | [01](chapters/01-basic-concepts/README.md) | model server를 어디에서 실행할지 나타내는 대상. 예: local Python process, Docker container, Kubernetes cluster |
| Serving Platform | 서빙 플랫폼 | Serving Platform | kubernetes, deployment, serving | [01](chapters/01-basic-concepts/README.md) | model server나 serving runtime을 Kubernetes 같은 환경 위에서 배포, 확장, 라우팅하기 위한 platform 계층 |
| ML Pipeline | ML 파이프라인 | ML Workflow | pipeline, workflow, training | [01](chapters/01-basic-concepts/README.md) | 데이터 준비, 학습, 평가, 모델 등록, 배포 같은 단계를 순서 있는 workflow로 연결한 것 |
| Kubeflow | 쿠브플로우 | ML Workflow | kubeflow, mlops, platform | [01](chapters/01-basic-concepts/README.md) | Kubernetes 위에서 ML workflow, training, pipeline, serving을 구성하기 위한 MLOps platform |
| Kubeflow Pipelines | 쿠브플로우 파이프라인 | ML Workflow | kubeflow, pipeline, workflow | [01](chapters/01-basic-concepts/README.md) | ML workflow를 component와 pipeline 형태로 정의하고 실행, 추적하는 Kubeflow 구성 요소 |
| KServe | 케이서브 | Serving Platform | kserve, inferenceservice, kubernetes | [01](chapters/01-basic-concepts/README.md) | Kubernetes 위에서 model serving을 표준화하는 platform. `InferenceService` 리소스로 predictor, autoscaling, routing 등을 관리한다. Kubernetes를 대체하는 것이 아니라 그 위에 설치해 사용한다. |
| Knative | 크네이티브 | Serving Platform | knative, serverless, kubernetes | [01](chapters/01-basic-concepts/README.md) | Kubernetes 위에서 serverless-style workload, autoscaling, request routing을 제공하는 구성요소. KServe 설치/운영 방식에 따라 함께 사용될 수 있다. |
| TensorFlow Serving | 텐서플로우 서빙 | Serving Basics | tensorflow, serving-framework, general-ml | [01](chapters/01-basic-concepts/README.md) | TensorFlow 모델을 production 환경에서 서빙하기 위한 framework |
| TorchServe | 토치서브 | Serving Basics | pytorch, serving-framework, general-ml | [01](chapters/01-basic-concepts/README.md) | PyTorch 모델을 handler 기반으로 패키징하고 API로 서빙하기 위한 framework |
| NVIDIA Triton Inference Server | NVIDIA Triton 추론 서버 | Serving Basics | triton, multi-backend, inference-server | [01](chapters/01-basic-concepts/README.md) | TensorRT, ONNX Runtime, PyTorch, Python backend 등 여러 backend를 지원하는 NVIDIA의 범용 inference server |
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
| Cold Start | 콜드 스타트 | Operations | startup, model-loading, latency | [01](chapters/01-basic-concepts/README.md) | 준비가 덜 된 server나 새로 뜬 replica가 첫 요청을 처리하면서 model loading, CUDA 초기화, cache/buffer 준비 같은 초기화 비용까지 함께 치르는 상황 |
| Warmup | 워밍업 | Operations | startup, cuda, cache, benchmark | [01](chapters/01-basic-concepts/README.md) | 실제 사용자 traffic이나 benchmark 전에 가벼운 요청을 미리 보내 model loading 이후 inference 경로, CUDA kernel, memory allocation 등을 준비시키는 과정 |
| Model Loading Time | 모델 로딩 시간 | Operations | model-weights, startup | [01](chapters/01-basic-concepts/README.md) | 모델 weight, tokenizer, config 등을 디스크나 원격 저장소에서 읽어 CPU/GPU memory에 올리는 데 걸리는 시간. cold start를 구성하는 주요 비용 중 하나 |
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
| Requests/sec | 초당 요청 수 | Performance | requests-sec, qps, traffic | [01](chapters/01-basic-concepts/README.md), [08](chapters/08-serving-observability/README.md) | API server가 초당 처리한 request 개수. traffic 규모를 보기 좋지만, LLM에서는 요청마다 prompt/output 길이가 달라 workload 크기를 완전히 설명하지 못할 수 있다. |
| Tokens/sec | 초당 토큰 처리량 | Performance | tokens-sec, throughput, llm | [01](chapters/01-basic-concepts/README.md), [08](chapters/08-serving-observability/README.md) | LLM이 초당 생성하거나 처리한 token 수. 긴 prompt와 긴 output의 비용을 request 수보다 더 잘 반영하므로 LLM workload를 볼 때 중요하다. |
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
| NVIDIA NIM | NVIDIA Inference Microservice | Serving Engine | nvidia, nim, inference-microservice | [06](chapters/06-nvidia-nim/README.md) | NVIDIA가 model serving을 containerized microservice 형태로 제공하는 제품/런타임 |
| Inference Microservice | 추론 마이크로서비스 | Serving Basics | microservice, serving, api | [06](chapters/06-nvidia-nim/README.md) | 모델 추론 기능을 독립적인 service/API 단위로 패키징한 것 |
| NGC Catalog | NVIDIA GPU Cloud catalog | Model Registry & Auth | ngc, catalog, nvidia | [06](chapters/06-nvidia-nim/README.md) | NVIDIA container image, model, resource, license, 실행 방법을 확인하는 catalog |
| NGC Container Registry | NGC 컨테이너 레지스트리 | Model Registry & Auth | nvcr, registry, docker | [06](chapters/06-nvidia-nim/README.md) | `nvcr.io` 주소로 접근하는 NVIDIA container image registry |
| NGC API Key | NGC API 키 | Model Registry & Auth | ngc, api-key, secret | [06](chapters/06-nvidia-nim/README.md) | NGC registry login과 NIM artifact 접근에 사용하는 secret. Git repo에 저장하지 않는다. |
| `nvcr.io` | NVIDIA container registry domain | Model Registry & Auth | nvcr, registry, docker-login | [06](chapters/06-nvidia-nim/README.md) | NVIDIA NGC container image를 pull할 때 사용하는 registry domain |
| NIM Cache | NIM 캐시 | Operations | nim, cache, model-artifact | [06](chapters/06-nvidia-nim/README.md) | NIM container가 model artifact나 optimized engine cache를 재사용하기 위해 사용하는 저장 공간 |
| Model Artifact | 모델 아티팩트 | Model Registry & Auth | model-files, artifact, cache | [06](chapters/06-nvidia-nim/README.md) | model weight, tokenizer, runtime profile, optimized engine처럼 모델 실행에 필요한 파일 묶음 |
| Vendor-Provided Runtime | 벤더 제공 런타임 | Serving Engine | vendor, runtime, nim | [06](chapters/06-nvidia-nim/README.md) | NVIDIA 같은 vendor가 최적화와 패키징을 제공하는 serving runtime |
| License Terms | 라이선스 조건 | Model Registry & Auth | license, terms, model-access | [06](chapters/06-nvidia-nim/README.md) | 모델/image를 사용할 때 따라야 하는 사용 조건. NIM 실행 전 NGC catalog에서 확인해야 한다. |
| End-to-End Latency | 전체 지연 시간 | Performance | latency, client, response | [07](chapters/07-performance-methodology/README.md) | client가 요청을 보내기 시작한 시점부터 응답 전체를 받을 때까지 걸린 시간 |
| Inter-Token Latency | 토큰 사이 지연 시간 | Performance | streaming, token, latency | [07](chapters/07-performance-methodology/README.md) | streaming 중 token 또는 chunk 사이의 시간 간격. 답변이 얼마나 부드럽게 이어지는지 볼 때 중요 |
| Percentile Latency | 백분위 지연 시간 | Performance | p50, p95, p99 | [07](chapters/07-performance-methodology/README.md) | latency를 정렬했을 때 특정 위치의 값. 평균으로 놓치기 쉬운 느린 요청을 보기 위해 사용 |
| p90 Latency | 90번째 percentile 지연 시간 | Performance | percentile, latency, p90 | [07](chapters/07-performance-methodology/README.md) | 요청 중 90%가 이 시간 이하로 끝났다는 의미의 latency 지표 |
| p99 Latency | 99번째 percentile 지연 시간 | Performance | percentile, tail-latency, p99 | [07](chapters/07-performance-methodology/README.md) | 가장 느린 1%에 가까운 요청을 보는 tail latency 지표 |
| Benchmark Workload | 벤치마크 부하 조건 | Performance | workload, benchmark, traffic | [07](chapters/07-performance-methodology/README.md) | benchmark에서 사용하는 요청 수, concurrency, prompt 길이, output 길이 같은 부하 조건 |
| Experiment Matrix | 실험 조건표 | Performance | matrix, experiment, comparison | [07](chapters/07-performance-methodology/README.md) | 여러 workload 조건을 표처럼 정해 순서대로 실행하는 실험 설계 방식 |
| Raw Result | 원본 결과 | Performance | csv, raw-data, benchmark | [07](chapters/07-performance-methodology/README.md) | 요청별 latency, status, error 같은 값을 그대로 저장한 결과. 요약값 이상 여부를 다시 확인할 때 필요 |
| Load Testing Tool | 부하 테스트 도구 | Performance | wrk, hey, k6, locust | [07](chapters/07-performance-methodology/README.md) | server에 여러 요청을 보내 latency, throughput, error rate를 측정하는 도구 |
| k6 | k6 부하 테스트 도구 | Performance | k6, load-test, metrics | [07](chapters/07-performance-methodology/README.md) | JavaScript로 scenario와 threshold를 정의할 수 있는 HTTP load testing 도구 |
| Locust | Locust 부하 테스트 도구 | Performance | locust, python, load-test | [07](chapters/07-performance-methodology/README.md) | Python으로 사용자 행동 기반 load test를 작성하는 도구 |
| hey | hey HTTP benchmark 도구 | Performance | hey, http, benchmark | [07](chapters/07-performance-methodology/README.md) | 단순 HTTP endpoint에 빠르게 부하를 주는 command line benchmark 도구 |
| wrk | wrk HTTP benchmark 도구 | Performance | wrk, http, benchmark | [07](chapters/07-performance-methodology/README.md) | 높은 부하의 HTTP benchmark를 수행하는 command line 도구 |
| Observability | 관측성 | Operations | metrics, logs, traces | [08](chapters/08-serving-observability/README.md) | 시스템 밖에서 수집한 신호로 내부 상태를 추론할 수 있게 하는 능력. metrics, logs, traces가 대표 신호다. |
| Metrics | 메트릭, 수치 지표 | Operations | prometheus, monitoring, time-series | [08](chapters/08-serving-observability/README.md) | 시간에 따라 변하는 수치 데이터. 예: latency, requests/sec, GPU memory |
| Time Series | 시계열 데이터 | Operations | metrics, prometheus, timestamp | [08](chapters/08-serving-observability/README.md) | timestamp와 함께 저장되는 metric 값의 연속 |
| Prometheus | 프로메테우스 | Operations | metrics, scrape, prometheus | [08](chapters/08-serving-observability/README.md) | target의 `/metrics` endpoint를 주기적으로 scrape해 time series metric을 저장하고 PromQL로 query하는 monitoring system |
| Scrape | 스크레이프, 가져오기 | Operations | prometheus, scrape, target | [08](chapters/08-serving-observability/README.md) | Prometheus가 target endpoint에 HTTP 요청을 보내 metrics를 가져오는 동작 |
| Prometheus Target | 프로메테우스 타깃 | Operations | prometheus, scrape, endpoint | [08](chapters/08-serving-observability/README.md) | Prometheus가 scrape할 대상 endpoint. 예: `host.docker.internal:8000` |
| PromQL | Prometheus Query Language | Operations | prometheus, query, promql | [08](chapters/08-serving-observability/README.md) | Prometheus에 저장된 time series를 조회하고 집계하는 query language |
| Counter | 카운터 | Operations | prometheus, metric-type, total | [08](chapters/08-serving-observability/README.md) | "지금까지 몇 번 일어났는가"를 세는 metric type. 보통 계속 증가하며 요청 수, 에러 수, 생성 token 수에 사용 |
| Gauge | 게이지 | Operations | prometheus, metric-type, current-value | [08](chapters/08-serving-observability/README.md) | "현재 얼마인가"를 나타내는 metric type. 증가하거나 감소할 수 있으며 in-flight 요청 수, GPU memory에 사용 |
| Histogram | 히스토그램 | Operations | prometheus, metric-type, latency | [08](chapters/08-serving-observability/README.md) | 관측값을 정해진 bucket 구간에 누적하는 metric type. latency가 어느 구간에 많이 몰리는지 보고 p50/p95 같은 percentile 계산에 사용 |
| Summary | 서머리, 요약 metric | Operations | prometheus, metric-type, quantile | [08](chapters/08-serving-observability/README.md) | application/client library 쪽에서 quantile이나 summary를 계산해 노출하는 metric type. 처음 latency 관측을 만들 때는 보통 Histogram부터 쓰는 편이 이해하기 쉽다. |
| Label Cardinality | 라벨 카디널리티 | Operations | prometheus, labels, cardinality | [08](chapters/08-serving-observability/README.md) | metric label 값 조합의 수. Prometheus에서는 metric 이름과 label 조합마다 별도 time series가 생기므로, `user_id`나 request id처럼 값이 매우 많은 label을 넣으면 저장량, memory 사용량, query 비용이 급증한다. |
| Grafana | 그라파나 | Operations | dashboard, visualization, grafana | [08](chapters/08-serving-observability/README.md) | Prometheus 같은 datasource를 query해 dashboard와 graph를 만드는 visualization tool |
| Datasource | 데이터소스 | Operations | grafana, prometheus, datasource | [08](chapters/08-serving-observability/README.md) | Grafana가 query할 외부 데이터 저장소. 이 챕터에서는 Prometheus를 datasource로 사용 |
| Dashboard Provisioning | 대시보드 프로비저닝 | Operations | grafana, dashboard, provisioning | [08](chapters/08-serving-observability/README.md) | Grafana datasource와 dashboard를 UI가 아니라 파일로 자동 등록하는 방식 |
| DCGM Exporter | DCGM 익스포터 | GPU & Runtime | nvidia, dcgm, gpu-metrics | [08](chapters/08-serving-observability/README.md) | NVIDIA GPU telemetry를 Prometheus metric으로 노출하는 exporter |
| Exporter | 익스포터 | Operations | prometheus, exporter, metrics | [08](chapters/08-serving-observability/README.md) | 어떤 시스템의 상태를 Prometheus가 scrape할 수 있는 `/metrics` 형태로 노출하는 component |
| Langfuse | Langfuse LLM observability platform | LLM Observability | trace, prompt, eval | [09](chapters/09-langfuse-observability/README.md) | LLM application의 trace, prompt, completion, token usage, latency, evaluation을 추적하고 분석하는 open-source AI engineering platform |
| Trace | 트레이스, 요청 단위 기록 | LLM Observability | trace, request, langfuse | [09](chapters/09-langfuse-observability/README.md) | 사용자 요청 하나가 app 내부에서 어떤 단계들을 거쳐 처리되었는지 묶어 기록한 단위 |
| Observation | 관측 항목 | LLM Observability | observation, span, generation | [09](chapters/09-langfuse-observability/README.md) | Langfuse trace 안의 세부 단계. span, generation, event 같은 형태가 있다. |
| Span | 스팬 | LLM Observability | span, workflow, trace | [09](chapters/09-langfuse-observability/README.md) | 전처리, 검색, tool call처럼 LLM 호출이 아닌 일반 작업 단계를 기록하는 observation |
| Generation | 생성 관측 항목 | LLM Observability | generation, llm-call, tokens | [09](chapters/09-langfuse-observability/README.md) | LLM 호출에 특화된 observation. model, prompt/messages, completion, token usage, latency 같은 정보를 기록한다. |
| Session | 세션 | LLM Observability | session, conversation, user | [09](chapters/09-langfuse-observability/README.md) | 여러 trace를 하나의 대화나 workflow로 묶는 ID. multi-turn chatbot 분석에 유용하다. |
| Prompt Versioning | 프롬프트 버전 관리 | LLM Observability | prompt, versioning, langfuse | [09](chapters/09-langfuse-observability/README.md) | prompt 변경 이력을 version/label로 관리해 latency, cost, quality 변화를 비교하는 방식 |
| Evaluation Dataset | 평가 데이터셋 | Evaluation | dataset, eval, experiment | [09](chapters/09-langfuse-observability/README.md) | prompt/model 변경을 같은 입력 묶음으로 비교하기 위한 dataset. input과 expected output을 함께 관리할 수 있다. |
| Kubernetes | 쿠버네티스, 컨테이너 오케스트레이션 플랫폼 | Serving Platform | kubernetes, orchestration, cluster | [10](chapters/10-kubernetes-model-deployment/README.md) | 여러 node 위에서 container workload를 배포, 스케줄링, 복구, 확장, 네트워킹하는 platform. 모델 서버를 반복 배포하고 운영할 때 기본 인프라 계층으로 자주 사용한다. |
| `kubectl apply -f` | 파일 기반 리소스 적용 명령 | Development Environment | kubectl, apply, manifest | [10](chapters/10-kubernetes-model-deployment/README.md) | YAML manifest에 적힌 원하는 상태를 cluster에 반영하는 명령. 이 챕터에서는 모델 서버 Deployment, Service, PVC, Ingress를 적용할 때 사용한다. |
| Helm | 쿠버네티스 패키지 매니저 | Serving Platform | helm, chart, addon | [10](chapters/10-kubernetes-model-deployment/README.md) | 여러 Kubernetes manifest와 설정값을 chart로 묶어 설치/업그레이드하는 도구. 이 챕터에서는 NVIDIA device plugin 같은 third-party add-on 설치 방식으로 소개한다. |
| Pod | 파드 | Serving Platform | kubernetes, pod, container | [10](chapters/10-kubernetes-model-deployment/README.md) | Kubernetes에서 배포되는 가장 작은 실행 단위. 하나 이상의 container, volume mount, network namespace를 함께 묶는다. 모델 서버 container는 보통 Pod 안에서 실행된다. |
| Kubernetes Deployment | 쿠버네티스 디플로이먼트 | Serving Platform | kubernetes, deployment, rollout | [10](chapters/10-kubernetes-model-deployment/README.md) | 원하는 Pod template과 replica 수, update 전략을 선언하는 controller. 모델 서버 Pod를 유지하고 rolling update와 rollback을 관리한다. |
| Kubernetes Service | 쿠버네티스 서비스 | Serving Platform | kubernetes, service, endpoint | [10](chapters/10-kubernetes-model-deployment/README.md) | 바뀔 수 있는 Pod IP 앞에 안정적인 DNS 이름과 virtual IP를 제공하는 object. label selector로 traffic을 보낼 Pod를 찾는다. |
| Ingress | 인그레스 | Serving Platform | kubernetes, ingress, http-routing | [10](chapters/10-kubernetes-model-deployment/README.md) | HTTP host/path 기반 routing 규칙을 선언하는 object. 실제 traffic 처리는 별도의 Ingress controller가 담당한다. |
| PersistentVolumeClaim | PVC, 영구 볼륨 요청 | Serving Platform | kubernetes, storage, pvc | [10](chapters/10-kubernetes-model-deployment/README.md) | Pod가 사용할 storage를 요청하는 object. 이 챕터에서는 Hugging Face/model cache를 Pod 재시작과 분리하기 위해 사용한다. |
| Probe | Kubernetes 상태 확인 | Operations | kubernetes, readiness, liveness, startup | [10](chapters/10-kubernetes-model-deployment/README.md) | kubelet이 HTTP 요청 등으로 container 상태를 확인하는 설정. startup은 느린 시작 보호, readiness는 traffic 투입 여부, liveness는 재시작 여부를 결정한다. |
| GPU Node Scheduling | GPU 노드 스케줄링 | GPU & Runtime | kubernetes, gpu, scheduling | [10](chapters/10-kubernetes-model-deployment/README.md) | GPU workload Pod를 GPU가 있는 node에 배치하는 과정. NVIDIA device plugin, `nvidia.com/gpu` request, nodeSelector, taint/toleration 설정이 함께 작동한다. |
| NVIDIA Device Plugin | NVIDIA 디바이스 플러그인 | GPU & Runtime | nvidia, device-plugin, kubernetes | [10](chapters/10-kubernetes-model-deployment/README.md) | Kubernetes node의 NVIDIA GPU를 `nvidia.com/gpu` 같은 allocatable resource로 노출하는 DaemonSet 형태의 plugin. |
| minikube | 로컬 단일 노드 Kubernetes 도구 | Development Environment | minikube, local-kubernetes, learning | [10](chapters/10-kubernetes-model-deployment/README.md) | 개인 PC나 단일 서버에서 Kubernetes를 쉽게 띄워 학습/개발할 수 있게 해 주는 도구. 이번 챕터의 기본 실습 환경으로 사용한다. |
| KServe | Kubernetes 기반 모델 서빙 플랫폼 | Serving Platform | kserve, kubernetes, model-serving | [11](chapters/11-kserve-intro/README.md) | `InferenceService` 같은 CRD와 controller로 model serving workload를 선언적으로 배포하고 관리하는 platform. |
| InferenceService | KServe 모델 서빙 리소스 | Serving Platform | kserve, inferenceservice, crd | [11](chapters/11-kserve-intro/README.md) | predictor, transformer, explainer 등을 선언해 모델 serving endpoint를 만드는 KServe의 핵심 custom resource. |
| ServingRuntime | KServe 서빙 런타임 정의 | Serving Platform | kserve, runtime, model-server | [11](chapters/11-kserve-intro/README.md) | sklearn, xgboost, triton, custom image처럼 어떤 model server container로 모델을 실행할지 정의하는 KServe runtime resource. |
| Predictor | 예측 수행 component | Serving Runtime | predictor, inference, kserve | [11](chapters/11-kserve-intro/README.md) | 실제 model inference를 수행하는 KServe component. 처음에는 모델 서버 본체라고 이해하면 된다. |
| Transformer | 전처리/후처리 component | Serving Runtime | transformer, preprocessing, postprocessing | [11](chapters/11-kserve-intro/README.md) | predictor 앞뒤에서 request/response를 변환하는 component. feature 변환이나 response formatting에 사용한다. |
| Explainer | 예측 설명 component | Evaluation | explainer, explainability, kserve | [11](chapters/11-kserve-intro/README.md) | 모델 예측 결과에 대한 설명을 제공하는 component. 왜 그런 예측이 나왔는지 분석할 때 사용한다. |
| Scale-to-zero | 요청이 없을 때 0개까지 축소 | Serving Platform | knative, autoscaling, scale-to-zero | [11](chapters/11-kserve-intro/README.md) | Knative mode에서 traffic이 없을 때 Pod를 0개까지 줄이는 기능. 비용 절감에 유리하지만 큰 모델은 cold start가 커질 수 있다. |
