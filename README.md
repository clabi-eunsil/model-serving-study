# Model Serving Study Roadmap

이 문서는 모델 서빙을 처음부터 실습 중심으로 익히기 위한 학습 로드맵이다.
각 항목은 공부하면서 체크하고, `실습`이 표시된 항목은 직접 실행 결과나 메모를 남기는 것을 목표로 한다.

## 진행 상태 표시

- `[ ]` 아직 시작하지 않음
- `[x]` 완료
- `실습` 직접 실행, 배포, 벤치마크, 관측 구성이 필요한 항목

## 파일 관리 방식

이 스터디는 루트 README를 전체 지도와 진도표로 사용하고, 실제 학습 자료와 실습 파일은 `chapters/` 아래 단원별 폴더에 둔다.

추천 구조:

```text
model-serving/
├── Agent.md
├── assets/
│   ├── diagrams/
│   └── external/
├── GLOSSARY.md
├── README.md
├── chapters/
│   ├── 01-basic-concepts/
│   │   ├── README.md
│   │   ├── references.md
│   │   ├── scripts/
│   │   └── templates/
│   ├── 02-fastapi-serving/
│   ├── 03-docker-serving/
│   └── ...
├── shared/
│   ├── scripts/
│   ├── manifests/
│   └── notes/
└── results/
    ├── benchmarks/
    └── screenshots/
```

관리 규칙:

- `chapters/NN-topic/README.md`: 해당 단원의 학습 순서와 핵심 개념
- `GLOSSARY.md`: 전체 단원 용어집. chapter, category, tag 기준으로 관리
- `chapters/NN-topic/references.md`: 공식 문서와 근거 URL. 문서가 많을 때만 분리
- `chapters/NN-topic/scripts/`: 실행 가능한 실습 스크립트
- `chapters/NN-topic/templates/`: 실습 기록 템플릿
- `assets/diagrams/`: 직접 만든 학습용 그림
- `assets/external/`: 공식 문서에서 출처를 확인하고 내려받은 참고 그림
- `results/`: benchmark 결과, 로그, 스크린샷처럼 실행 결과만 보관
- 루트 `README.md`는 너무 길어지지 않게 체크리스트와 링크 중심으로 유지

챕터별 기본 원칙:

- 먼저 `chapters/NN-topic/README.md` 하나만 읽어도 학습 흐름이 이해되게 만든다.
- 확인 질문과 작은 실습은 README 안에 둔다.
- 코드, shell script, YAML처럼 실행 파일만 별도 파일로 둔다.
- 참고 문서가 길어질 때만 `references.md`로 분리한다.

## 실행 환경 원칙

Python을 직접 실행하는 챕터는 각 챕터 폴더 안에 **별도 `.venv`**를 만든다.
공용 `.venv` 하나를 계속 쓰지 않는 이유는 챕터별로 필요한 package와 version이 달라질 수 있기 때문이다.

예시:

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

Docker, Kubernetes, KServe처럼 실행 환경이 container나 cluster 안에 있는 챕터는 host `.venv`를 만들지 않아도 된다.
그런 챕터에서는 Docker image, container, YAML manifest, cluster 설정이 실행 환경의 기준이 된다.

## 자료 생성 현황

- [x] [1. 모델 서빙 기본 개념](chapters/01-basic-concepts/README.md)
- [x] [2. 로컬 FastAPI 모델 서빙](chapters/02-fastapi-serving/README.md)
- [x] [3. Docker 기반 모델 서빙](chapters/03-docker-serving/README.md)
- [x] [4. vLLM 입문](chapters/04-vllm-intro/README.md)
- [x] [5. vLLM 성능 튜닝](chapters/05-vllm-performance-tuning/README.md)
- [x] [6. NVIDIA NIM](chapters/06-nvidia-nim/README.md)
- [x] [7. 성능 테스트 방법론](chapters/07-performance-methodology/README.md)
- [x] [8. 모델 서빙 관측성](chapters/08-serving-observability/README.md)
- [x] [9. Langfuse와 LLM Observability](chapters/09-langfuse-observability/README.md)
- [x] [10. Kubernetes 기반 모델 배포](chapters/10-kubernetes-model-deployment/README.md)
- [x] [11. KServe 입문](chapters/11-kserve-intro/README.md)
- [x] [12. KServe로 LLM 서빙](chapters/12-kserve-llm-serving/README.md)
- [x] [13. 고급 서빙 주제](chapters/13-advanced-serving-topics/README.md)
- [ ] 14. 운영 관점
- [ ] 15. 최종 미니 프로젝트

## 1. 모델 서빙 기본 개념

- [x] 모델 서버가 하는 역할 이해
- [x] 모델 서빙 프레임워크, LLM serving engine, serving platform, ML pipeline 차이 이해
- [x] REST API, gRPC, OpenAI-compatible API 차이 이해
- [x] online inference와 batch inference 차이 이해
- [x] latency, throughput, concurrency 개념 정리
- [x] cold start, warmup, model loading time 개념 정리
- [x] TTFT, TTFB, TTFP, TPS, QPS, tokens/sec 의미 정리
- [x] 모델 서빙에서 GPU memory, KV cache가 중요한 이유 이해

자료: [chapters/01-basic-concepts/README.md](chapters/01-basic-concepts/README.md)

## 2. 로컬 FastAPI 모델 서빙

- [x] FastAPI 기반 모델 서버 구조 이해
- [x] `/health`, `/generate`, `/metrics` 같은 기본 엔드포인트 설계
- [x] Hugging Face Transformers pipeline 사용법 학습
- [x] tokenizer, model, generation config 기본 개념 이해
- [x] 실습: 작은 모델을 FastAPI로 로컬 서빙
- [x] 실습: `curl`로 `/generate` 호출
- [x] 실습: Python client로 요청 보내기
- [x] 실습: 요청/응답 schema를 Pydantic으로 정의

자료: [chapters/02-fastapi-serving/README.md](chapters/02-fastapi-serving/README.md)

## 3. Docker 기반 모델 서빙

- [x] Docker image, container, Dockerfile, build context 기본 구조 이해
- [x] dependency, model cache, volume, image size 관리 방식 이해
- [x] port mapping, `docker run`, Docker Compose 실행 방식 이해
- [x] CPU/GPU container 차이와 NVIDIA Container Toolkit 역할 이해
- [x] Docker Hub, NGC, Hugging Face token이 필요한 경우 구분
- [x] 원격 GPU 서버에서 챕터 디렉터리만 복사해 실습하는 흐름 이해
- [x] 실습: Docker 환경 확인, image build, CPU/GPU container 실행 흐름 준비
- [x] 실습: Docker Compose server/client 구성과 image size 확인
- [x] 실습 마무리: container, compose, volume, SSH port forwarding 정리

자료: [chapters/03-docker-serving/README.md](chapters/03-docker-serving/README.md)

## 4. vLLM 입문

- [x] vLLM이 FastAPI + Transformers 직접 구현과 어떻게 다른지 이해
- [x] PagedAttention, KV cache 관리, continuous batching 개념 이해
- [x] OpenAI-compatible server와 `/v1/models`, `/v1/chat/completions` 구조 이해
- [x] `--model`, `--served-model-name`, `--gpu-memory-utilization`, `--max-model-len` 주요 옵션 학습
- [x] 실습: vLLM Docker server 실행
- [x] 실습: `curl`로 models/chat completions/streaming 호출
- [x] 실습: OpenAI SDK로 vLLM endpoint 호출
- [x] 실습 마무리: server 종료, client `.venv` deactivate, 결과 기록

자료: [chapters/04-vllm-intro/README.md](chapters/04-vllm-intro/README.md)

## 5. vLLM 성능 튜닝

- [x] concurrency, latency, throughput 관계 이해
- [x] prompt length, output token length, KV cache, GPU memory 관계 이해
- [x] `--max-model-len`, `--gpu-memory-utilization`, `--max-num-seqs`, `--max-num-batched-tokens` 역할 이해
- [x] prefix caching, chunked prefill, quantization, tensor parallelism 개념 정리
- [x] 실습: vLLM server를 튜닝 가능한 옵션으로 실행
- [x] 실습: concurrency별 latency/throughput 측정
- [x] 실습: prompt 길이와 output token 수를 바꿔 benchmark
- [x] 실습: streaming TTFT와 total latency 측정
- [x] 실습: GPU memory와 server log 기록
- [x] 실습 마무리: benchmark 결과 CSV 정리, server 종료, `.venv` deactivate

자료: [chapters/05-vllm-performance-tuning/README.md](chapters/05-vllm-performance-tuning/README.md)

## 6. NVIDIA NIM

- [x] NIM의 목적과 vLLM 직접 운영 방식 차이 이해
- [x] NGC catalog, NGC registry, NGC API key, NIM cache 개념 이해
- [x] NIM image/model 선택 전 license, 지원 GPU, 사용 조건 확인
- [x] NIM OpenAI-compatible API 구조 이해
- [x] 실습: NGC login과 NIM image pull 준비
- [x] 실습: NIM container 실행
- [x] 실습: `/v1/models`, `/v1/chat/completions` 호출
- [x] 실습: OpenAI SDK로 NIM endpoint 호출
- [x] 실습: vLLM과 같은 prompt로 latency 비교
- [x] 실습 마무리: NIM container 종료, `.venv` deactivate, 결과 기록

자료: [chapters/06-nvidia-nim/README.md](chapters/06-nvidia-nim/README.md)

## 7. 성능 테스트 방법론

- [x] TTFT, TTFB, TTFP 차이 정리
- [x] end-to-end latency와 inter-token latency 차이 이해
- [x] p50, p90, p95, p99 latency 해석 방법 학습
- [x] requests/sec와 tokens/sec 차이 이해
- [x] throughput과 latency trade-off 이해
- [x] `wrk`, `hey`, `k6`, `locust` 용도 비교
- [x] vLLM benchmark script 사용법 학습
- [x] 실습: custom Python async benchmark 작성
- [x] 실습: concurrency별 latency 측정
- [x] 실습: input/output token 길이별 결과 비교
- [x] 실습: benchmark 결과를 표로 정리

자료: [chapters/07-performance-methodology/README.md](chapters/07-performance-methodology/README.md)

## 8. 모델 서빙 관측성

- [x] 모델 서버에서 필요한 metrics 정의
- [x] Prometheus metrics format 이해
- [x] Grafana dashboard 기본 구성 이해
- [x] DCGM exporter로 GPU metrics 수집하는 방법 학습
- [x] API latency, error rate, throughput 수집 방법 이해
- [x] token usage, prompt length, completion length 추적 항목 정리
- [x] 실습: FastAPI `/metrics` endpoint 만들기
- [x] 실습: Prometheus로 metrics scrape
- [x] 실습: Grafana dashboard 구성
- [x] 실습: DCGM exporter로 GPU utilization 확인

자료: [chapters/08-serving-observability/README.md](chapters/08-serving-observability/README.md)

## 9. Langfuse와 LLM Observability

- [x] Langfuse가 해결하는 문제 이해
- [x] trace, span, generation 개념 학습
- [x] prompt, completion, latency, token usage 추적 방식 이해
- [x] session/user 단위 관측 방법 이해
- [x] prompt versioning 개념 이해
- [x] evaluation dataset 관리 방식 이해
- [x] 실습: Langfuse self-hosted local 또는 cloud 환경 준비
- [x] 실습: Python SDK로 trace 전송
- [x] 실습: vLLM/OpenAI-compatible endpoint 호출 결과 추적
- [x] 실습: prompt별 latency와 token usage 비교

자료: [chapters/09-langfuse-observability/README.md](chapters/09-langfuse-observability/README.md)

## 10. Kubernetes 기반 모델 배포

- [x] Deployment, Service, Ingress로 모델 서버 배포하는 흐름 이해
- [x] GPU node scheduling 이해
- [x] `nvidia.com/gpu` resource request 사용법 학습
- [x] nodeSelector, taints, tolerations 개념 정리
- [x] PVC로 model cache 관리하는 방법 학습
- [x] readiness probe와 liveness probe 설계
- [x] 실습: FastAPI 모델 서버를 Kubernetes Deployment로 배포
- [x] 실습: GPU resource request 설정
- [x] 실습: Service로 endpoint 노출
- [x] 실습: Ingress 또는 port-forward로 호출
- [x] 실습: rolling update 시 모델 서버 동작 확인

자료: [chapters/10-kubernetes-model-deployment/README.md](chapters/10-kubernetes-model-deployment/README.md)

## 11. KServe 입문

- [ ] KServe가 제공하는 추상화 이해
- [ ] `InferenceService` 리소스 구조 학습
- [ ] predictor, transformer, explainer 개념 이해
- [ ] built-in runtime과 custom runtime 차이 이해
- [ ] Knative, Istio, Gateway와의 관계 정리
- [ ] autoscaling과 scale-to-zero 개념 이해
- [ ] 실습: KServe 설치 상태 확인
- [ ] 실습: sklearn 또는 간단한 torch model 예제 배포
- [ ] 실습: `InferenceService`로 endpoint 호출
- [ ] 실습: autoscaling 동작 확인

자료: [chapters/11-kserve-intro/README.md](chapters/11-kserve-intro/README.md)

## 12. KServe로 LLM 서빙

- [ ] KServe에서 LLM을 서빙할 때의 제약 이해
- [ ] custom runtime으로 vLLM을 올리는 방식 학습
- [ ] Hugging Face model URI와 storage initializer 개념 이해
- [ ] GPU resource 설정 방법 정리
- [ ] 일반 Kubernetes Deployment와 KServe 방식 비교
- [ ] 실습: vLLM custom runtime 구성
- [ ] 실습: KServe `InferenceService`로 LLM 배포
- [ ] 실습: GPU resource request 적용
- [ ] 실습: OpenAI-compatible endpoint 호출
- [ ] 실습: autoscaling 정책 실험

자료: [chapters/12-kserve-llm-serving/README.md](chapters/12-kserve-llm-serving/README.md)

## 13. 고급 서빙 주제

- [ ] quantization: AWQ, GPTQ, bitsandbytes 차이 이해
- [ ] tensor parallelism 개념 정리
- [ ] pipeline parallelism 개념 정리
- [ ] multi-LoRA serving 개념 학습
- [ ] speculative decoding 개념 학습
- [ ] model warmup 전략 이해
- [ ] prompt cache와 response cache 차이 이해
- [ ] rate limiting 설계
- [ ] authentication과 API key 관리 방식 정리
- [ ] multi-tenant serving 고려사항 정리
- [ ] 실습: quantized model 서빙
- [ ] 실습: LoRA adapter 서빙 실험
- [ ] 실습: rate limit 적용

자료: [chapters/13-advanced-serving-topics/README.md](chapters/13-advanced-serving-topics/README.md)

## 14. 운영 관점

- [ ] 모델 버전 관리 전략 정리
- [ ] canary 배포 개념 이해
- [ ] blue/green 배포 개념 이해
- [ ] rollback 전략 정리
- [ ] GPU 비용 최적화 관점 정리
- [ ] OOM, timeout, stuck request 대응 방법 정리
- [ ] 로그, 메트릭, 트레이스 기반 디버깅 흐름 정리
- [ ] 실습: 모델 버전별 endpoint 분리
- [ ] 실습: canary traffic split 구성
- [ ] 실습: OOM 상황 재현 및 대응 메모
- [ ] 실습: timeout 설정 변경 후 동작 확인

## 15. 최종 미니 프로젝트

- [ ] 요구사항 정의: 어떤 모델을 어떤 API로 제공할지 결정
- [ ] vLLM 기반 모델 서버 구성
- [ ] Docker 이미지화
- [ ] Kubernetes Deployment 배포
- [ ] KServe 배포 방식 추가
- [ ] Langfuse trace 연동
- [ ] Prometheus/Grafana metrics 연동
- [ ] benchmark 시나리오 설계
- [ ] vLLM, NIM, FastAPI 방식 비교
- [ ] 최종 리포트 작성
- [ ] 실습: 전체 시스템 실행
- [ ] 실습: 동시 요청 benchmark 수행
- [ ] 실습: latency/throughput 결과 정리
- [ ] 실습: 운영 관점 장단점 비교

## 추천 학습 순서

1. FastAPI로 가장 단순한 모델 서버 만들기
2. Docker로 모델 서버 실행하기
3. vLLM으로 LLM 서빙하기
4. 성능 테스트로 숫자 읽기
5. Prometheus/Grafana로 관측하기
6. Langfuse로 LLM trace 남기기
7. Kubernetes에 모델 서버 배포하기
8. KServe로 추상화된 배포 방식 익히기
9. NIM으로 관리형 최적화 container 방식 경험하기
10. 최종 프로젝트로 방식별 비교 리포트 만들기

## 학습 메모

공부하면서 각 단계별로 아래 내용을 남긴다.

- 실행한 명령어
- 사용한 모델
- GPU 종류와 memory
- 요청 payload
- latency, throughput, tokens/sec 결과
- 실패한 점과 해결 방법
- 다음에 다시 확인할 질문
