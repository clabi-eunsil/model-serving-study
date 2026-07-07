# 9. Langfuse와 LLM Observability

챕터 8에서는 Prometheus/Grafana로 서버의 숫자 지표를 봤다.
챕터 9에서는 Langfuse로 **LLM 요청 하나의 내용과 흐름**을 본다.

Prometheus가 "요청 수, latency, tokens/sec가 얼마나 나오는가"를 보는 데 강하다면,
Langfuse는 "어떤 prompt가 들어왔고, 어떤 답변이 나왔고, 어떤 사용자/session에서 발생했으며, 어떤 generation이 느렸는가"를 보는 데 강하다.

Langfuse SDK, Cloud region, self-hosting 방식, prompt/evaluation 기능은 업데이트될 수 있다.  
이 문서는 2026-07-07 기준 공식 문서를 바탕으로 작성했다.  
실습 전 [references.md](references.md)의 공식 문서를 다시 확인한다.

## 학습 목표

- Langfuse가 해결하는 문제를 Prometheus/Grafana와 비교해 이해한다.
- trace, observation, span, generation의 차이를 설명한다.
- prompt, completion, latency, token usage를 요청 단위로 추적하는 방법을 배운다.
- session/user 단위로 LLM 요청을 묶어 보는 이유를 이해한다.
- prompt versioning과 evaluation dataset의 목적을 정리한다.
- Langfuse Cloud 또는 self-hosted Langfuse를 사용할 때 필요한 환경변수를 안다.
- Python SDK로 trace를 전송하는 실습을 한다.
- vLLM/NIM 같은 OpenAI-compatible endpoint 호출 결과를 Langfuse generation으로 기록한다.
- prompt별 latency와 token usage 비교 결과를 정리한다.

## 추천 진행 순서

1. [../../GLOSSARY.md](../../GLOSSARY.md)에서 Langfuse, trace, span, generation 용어를 확인한다.
2. 아래 핵심 개념 요약을 읽는다.
3. [references.md](references.md)에서 공식 문서와 업데이트 가능성이 큰 부분을 확인한다.
4. 챕터별 `.venv`를 만든다.
5. [scripts/01_check_env.sh](scripts/01_check_env.sh)로 환경을 확인한다.
6. [scripts/02_send_trace.sh](scripts/02_send_trace.sh)를 dry-run으로 실행해 trace 구조를 먼저 본다.
7. Langfuse key가 있으면 `DRY_RUN=false`로 실제 trace를 보낸다.
8. 폐쇄망이나 local 실습이 필요하면 [Self-host Langfuse](#self-host-langfuse) 섹션을 먼저 진행한다.
9. [scripts/03_prepare_vllm_endpoint.sh](scripts/03_prepare_vllm_endpoint.sh)로 OpenAI-compatible endpoint 준비 흐름을 확인한다.
10. [scripts/04_trace_openai_compatible.sh](scripts/04_trace_openai_compatible.sh)로 endpoint 호출 결과를 trace한다.
11. [scripts/05_compare_prompts.sh](scripts/05_compare_prompts.sh)로 prompt별 latency/token usage 비교 CSV를 만든다.
12. [templates/lab-notes.md](templates/lab-notes.md)를 보며 결과를 정리하고 [scripts/12_cleanup.sh](scripts/12_cleanup.sh)로 마무리한다.

## 실행 환경 기준

| 구성요소 | 실행 위치 | 이유 |
| --- | --- | --- |
| Python scripts | 챕터 `.venv` | Langfuse SDK와 OpenAI SDK를 직접 사용 |
| Langfuse | Cloud 또는 self-hosted | trace 저장/조회 UI |
| vLLM/NIM endpoint | 선택 실습 | OpenAI-compatible 호출 결과를 generation으로 기록 |
| CSV 결과 | `results/` | prompt 비교 결과를 로컬에 기록 |

Python `.venv` 준비:

```bash
cd ~/study/model-serving/chapters/09-langfuse-observability
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

실습 후:

```bash
deactivate
```

## 챕터 8과의 차이

| 구분 | 챕터 8 Prometheus/Grafana | 챕터 9 Langfuse |
| --- | --- | --- |
| 주요 질문 | 서버 상태가 괜찮은가? | 이 LLM 요청에서 무슨 일이 있었는가? |
| 데이터 단위 | metric time series | trace, observation, generation |
| 잘 보는 것 | latency p95, error rate, requests/sec, GPU memory | prompt, completion, token usage, user/session, prompt version |
| 민감 정보 | 보통 metric label에 넣지 않음 | prompt/completion을 저장할 수 있으므로 보안/마스킹 고려 필요 |
| 사용 목적 | 운영 지표 모니터링 | LLM 앱 디버깅, prompt 개선, evaluation 연결 |

## Self-host Langfuse

폐쇄망에서 일하는 경우 Langfuse Cloud에 trace를 보낼 수 없다.
이럴 때는 Langfuse를 내부망에 self-host하고 Python SDK의 `LANGFUSE_HOST`를 내부 Langfuse 주소로 설정한다.

공식 문서 기준으로 Langfuse self-host v3는 Docker로 실행할 수 있으며, local/VM Docker Compose 방식은 testing/low-scale deployment에 권장된다.
고가용성, scale-out, backup이 필요한 운영 환경은 Kubernetes Helm 같은 production-scale deployment를 검토해야 한다.

### Self-host 구성요소

Langfuse self-host는 단일 container 하나로 끝나지 않는다.
공식 문서의 architecture 기준으로 아래 구성요소가 함께 필요하다.

| 구성요소 | 역할 |
| --- | --- |
| Langfuse Web | UI와 API를 제공하는 main web application |
| Langfuse Worker | trace/event를 비동기로 처리하는 worker |
| Postgres | transactional workload를 저장하는 main database |
| ClickHouse | trace, observation, score 분석용 OLAP database |
| Redis/Valkey | queue와 cache |
| S3/Blob Store | incoming event, media, export 등을 저장하는 object storage. local compose에서는 MinIO를 사용 |

이 구조 때문에 폐쇄망에서는 단순히 `langfuse/langfuse` image 하나만 반입하면 부족하다.
공식 `docker-compose.yml`이 요구하는 모든 image와 volume, secret, port 정책을 함께 준비해야 한다.

### Local/VM self-host 실습

공식 repository를 가져온다.

```bash
bash scripts/06_prepare_self_host_official.sh
```

공식 compose 파일의 secret 변경 위치를 확인한다.

```bash
cd self-host/langfuse-official
grep -n "CHANGEME" docker-compose.yml
```

공식 문서는 `# CHANGEME`로 표시된 secret을 긴 random 값으로 바꾸라고 권장한다.
특히 아래 값은 학습용 local이라도 바꾸는 습관을 들인다.

- `SALT`
- `ENCRYPTION_KEY`
- `NEXTAUTH_SECRET`
- Postgres password
- ClickHouse password
- Redis auth
- MinIO access/secret key

실행:

```bash
cd ~/study/model-serving/chapters/09-langfuse-observability
bash scripts/08_start_self_host.sh
```

첫 실행은 image pull, migration, dependency 준비 때문에 시간이 걸릴 수 있다.
공식 문서는 local/VM compose 실행 후 web container가 ready 상태가 되기까지 약 2-3분 정도 걸릴 수 있다고 설명한다.

상태 확인:

```bash
bash scripts/09_check_self_host.sh
```

접속:

```text
http://localhost:3000
```

Langfuse UI에서 project를 만들고 public/secret key를 발급받은 뒤 Python SDK 환경변수를 설정한다.

```bash
bash scripts/11_print_self_host_env.sh
```

예시:

```bash
export LANGFUSE_HOST=http://localhost:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
DRY_RUN=false bash scripts/02_send_trace.sh
```

### 폐쇄망 반입 흐름

폐쇄망에서는 `git clone`, `docker pull`, package install이 바로 되지 않는 경우가 많다.
따라서 인터넷이 되는 준비 환경에서 아래 산출물을 만들어 내부망으로 가져간다.

| 산출물 | 만드는 곳 | 내부망에서 하는 일 |
| --- | --- | --- |
| Langfuse official repo snapshot | 인터넷 가능 환경 | `self-host/langfuse-official`로 복사 |
| Docker images tar | 인터넷 가능 환경 | `docker load -i ...` |
| Python wheelhouse | 인터넷 가능 환경 | `pip install --no-index --find-links ...` |
| 내부망용 `.env`/secret | 내부망 보안 절차 | Git에 커밋하지 않고 서버에만 배치 |

공식 compose가 필요로 하는 image 목록을 만든다.

```bash
bash scripts/07_list_self_host_images.sh
```

인터넷 가능 환경에서 image 저장:

```bash
while read -r image; do docker pull "${image}"; done < results/langfuse-self-host-images.txt
xargs -a results/langfuse-self-host-images.txt docker save -o langfuse-self-host-images.tar
```

폐쇄망 서버에서 image 불러오기:

```bash
docker load -i langfuse-self-host-images.tar
```

폐쇄망 운영 체크포인트:

- inbound port는 Langfuse Web `3000`과 필요한 경우 MinIO console `9090`만 열고 나머지는 내부 network로 제한한다.
- Postgres와 ClickHouse timezone은 UTC 기준을 지킨다.
- trace에는 prompt/completion이 저장될 수 있으므로 개인정보/민감정보 masking 정책을 정한다.
- backup은 Postgres, ClickHouse, object storage volume을 모두 고려한다.
- compose 방식은 HA/scale-out/backup이 부족하므로 production은 Kubernetes Helm 등으로 확장 계획을 세운다.

## 핵심 개념 요약

### Langfuse가 해결하는 문제

LLM application은 일반 API보다 디버깅이 어렵다.
같은 코드라도 prompt, model, temperature, RAG context, user history에 따라 결과가 달라진다.

Langfuse는 이런 질문에 답하기 위한 도구다.

- 어떤 prompt가 들어왔는가?
- 어떤 completion이 나왔는가?
- 어떤 model과 parameter를 썼는가?
- latency와 token usage는 얼마였는가?
- 같은 session 안에서 이전 요청과 어떻게 이어지는가?
- 특정 prompt version이 더 느리거나 더 비싼가?
- 평가 dataset으로 재현 가능한 비교를 할 수 있는가?

### Trace, Observation, Span, Generation

Langfuse에서 가장 먼저 잡아야 할 구조는 아래와 같다.

```text
Trace: 사용자 요청 하나의 전체 흐름
  ├─ Span: 전처리, 검색, tool call 같은 일반 작업
  └─ Generation: LLM 호출
```

| 용어 | 쉬운 의미 | 예시 |
| --- | --- | --- |
| Trace | 요청 하나의 전체 기록 | 사용자가 "요약해줘"라고 보낸 한 번의 처리 흐름 |
| Observation | trace 안의 세부 단계 | span, generation, event 등 |
| Span | LLM이 아닌 일반 작업 | request validation, prompt formatting, RAG retrieval |
| Generation | LLM 호출에 특화된 observation | vLLM `/v1/chat/completions` 호출 |

Generation에는 보통 아래 정보가 들어간다.

- model
- input prompt/messages
- output completion
- model parameters
- token usage
- latency
- cost metadata

### Session과 User

`session_id`는 여러 trace를 하나의 대화나 workflow로 묶는다.
chatbot에서는 한 사용자의 multi-turn conversation을 볼 때 유용하다.

`user_id`는 어떤 사용자의 요청인지 묶는 값이다.
사용자별 비용, latency, 실패 패턴을 볼 수 있지만 개인정보 정책에 맞게 익명화해야 한다.

Metric label에는 `user_id`를 넣지 말라고 했지만, Langfuse trace metadata에는 user 관점 분석을 위해 넣을 수 있다.
다만 raw 개인정보를 그대로 넣는 것은 피하고 내부 익명 ID를 쓰는 편이 좋다.

### Prompt, Completion, Token Usage

Langfuse는 prompt와 completion을 함께 저장할 수 있다.
그래서 "왜 이 답변이 나왔는지"를 metric보다 훨씬 자세히 볼 수 있다.

하지만 prompt와 completion에는 민감 정보가 들어갈 수 있다.
실제 운영에서는 아래를 함께 고려한다.

- PII masking
- secret redaction
- 저장 기간
- 프로젝트 접근 권한
- Cloud region 또는 self-hosting 선택

Token usage는 비용과 latency 분석에 중요하다.
같은 request 1개라도 긴 prompt와 긴 completion은 더 많은 비용과 시간이 든다.

### Prompt Versioning

Prompt versioning은 prompt를 코드처럼 버전 관리하는 개념이다.
Langfuse Prompt Management에서는 prompt를 만들고, label로 production 버전을 가져오고, 특정 version을 지정해 가져오는 흐름을 제공한다.

이 챕터에서는 실제 prompt management API를 깊게 쓰기보다,
prompt별 latency/token usage를 비교하는 CSV 실습으로 "어떤 값을 비교해야 하는지"를 먼저 익힌다.

### Evaluation Dataset

Evaluation dataset은 여러 prompt/model 버전을 같은 입력 묶음으로 비교하기 위한 기준 데이터다.
dataset item은 보통 input과 expected output을 가진다.

이것이 필요한 이유:

- prompt를 바꿨을 때 답변 품질이 좋아졌는지 비교
- model을 바꿨을 때 latency/cost/quality 변화 비교
- 과거 dataset version으로 실험을 재현
- production trace에서 문제 사례를 dataset으로 승격

## 학습 포인트와 파일 안내

| 파일 | 볼 부분 | 이유 |
| --- | --- | --- |
| [client/02_send_trace.py](client/02_send_trace.py) | `start_as_current_observation`, `generation`, `flush()` | Langfuse SDK로 trace를 보내는 기본 구조 |
| [client/04_trace_openai_compatible.py](client/04_trace_openai_compatible.py) | OpenAI SDK 호출, generation 기록 | vLLM/NIM endpoint 결과를 Langfuse로 기록하는 흐름 |
| [client/06_compare_prompts.py](client/06_compare_prompts.py) | prompt별 CSV 생성 | prompt version 비교 시 필요한 값 이해 |
| [scripts/03_prepare_vllm_endpoint.sh](scripts/03_prepare_vllm_endpoint.sh) | 챕터 4 vLLM 재실행 안내 | 이전 챕터 서버를 다시 띄우는 방법 |
| [.env.example](.env.example) | Langfuse/OpenAI-compatible 환경변수 | key와 endpoint 설정 방법 |

## 실습

### 1. 환경 확인

```bash
cd ~/study/model-serving/chapters/09-langfuse-observability
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/01_check_env.sh
```

Langfuse key가 없어도 괜찮다.
처음에는 dry-run으로 trace 구조를 먼저 본다.

### 2. Trace 구조 dry-run

```bash
bash scripts/02_send_trace.sh
```

기본값은 `DRY_RUN=true`다.
Langfuse에 아무것도 보내지 않고 trace 모양만 출력한다.

볼 것:

- trace name
- session_id
- user_id
- span
- generation
- input/output
- latency_ms
- usage prompt/completion tokens

### 3. 실제 Langfuse로 trace 전송

Langfuse Cloud나 self-hosted Langfuse project에서 API key를 발급받은 뒤 `.env`를 만든다.

```bash
cp .env.example .env
```

`.env`에서 아래 값을 채운다.

```text
LANGFUSE_PUBLIC_KEY=...
LANGFUSE_SECRET_KEY=...
LANGFUSE_HOST=...
```

전송:

```bash
DRY_RUN=false bash scripts/02_send_trace.sh
```

짧은 CLI script에서는 `langfuse.flush()`가 중요하다.
SDK가 event를 background로 보내기 때문에 process가 바로 종료되면 전송 전에 끝날 수 있다.

### 4. Self-host Langfuse 선택 실습

Cloud가 아니라 local/self-hosted Langfuse를 쓰려면 먼저 아래 흐름을 진행한다.

```bash
bash scripts/06_prepare_self_host_official.sh
bash scripts/07_list_self_host_images.sh
bash scripts/08_start_self_host.sh
bash scripts/09_check_self_host.sh
```

실습이 끝난 뒤 self-host stack을 내릴 때:

```bash
bash scripts/10_stop_self_host.sh
```

데이터 volume까지 지우려면:

```bash
REMOVE_VOLUMES=true bash scripts/10_stop_self_host.sh
```

### 5. OpenAI-compatible endpoint 준비

Langfuse는 모델 서버가 아니다.
vLLM/NIM/OpenAI API 같은 endpoint 호출 결과를 관측하는 도구다.

챕터 4의 vLLM endpoint를 다시 띄우는 흐름은 아래 script가 안내한다.

```bash
bash scripts/03_prepare_vllm_endpoint.sh
```

### 6. OpenAI-compatible endpoint 결과 trace

dry-run:

```bash
bash scripts/04_trace_openai_compatible.sh
```

실제 endpoint와 Langfuse로 보내기:

```bash
export OPENAI_BASE_URL=http://127.0.0.1:8000/v1
export OPENAI_API_KEY=EMPTY
export OPENAI_MODEL=study-model
DRY_RUN=false bash scripts/04_trace_openai_compatible.sh
```

`OPENAI_MODEL`은 vLLM을 띄울 때 지정한 `--served-model-name`과 맞아야 한다.

### 7. Prompt별 latency/token usage 비교

```bash
bash scripts/05_compare_prompts.sh
```

결과:

```text
results/prompt_comparison.csv
```

이 CSV는 Langfuse Prompt Management 자체를 대체하지 않는다.
다만 prompt version을 비교할 때 어떤 값을 봐야 하는지 연습하기 위한 작은 실습이다.

### 8. 실습 마무리

```bash
bash scripts/12_cleanup.sh
```

가상환경 종료:

```bash
deactivate
```

결과 확인:

- Langfuse UI의 traces
- Langfuse UI의 sessions/users
- `results/prompt_comparison.csv`

## Troubleshooting

| 증상 | 원인 후보 | 확인/해결 |
| --- | --- | --- |
| dry-run만 실행됨 | Langfuse key가 없거나 `DRY_RUN=true` | `.env`와 `DRY_RUN=false` 확인 |
| trace가 UI에 안 보임 | `LANGFUSE_HOST` region 불일치, key 오류, flush 누락 | `.env` 값과 `langfuse.flush()` 확인 |
| self-host UI가 안 열림 | container 준비 중, migration 진행 중, port 충돌 | `bash scripts/09_check_self_host.sh`, `docker compose logs --tail=100 langfuse-web` |
| 폐쇄망에서 image pull 실패 | image tar 미반입, registry mirror 미설정 | `scripts/07_list_self_host_images.sh`로 목록 생성 후 `docker save/load` |
| OpenAI-compatible 호출 실패 | vLLM/NIM server가 꺼짐, model name 불일치 | 챕터 4/6 server 상태와 `OPENAI_MODEL` 확인 |
| token usage가 정확하지 않음 | fake tokenizer 사용 | 운영에서는 provider response usage 또는 tokenizer 사용 |
| prompt 내용 저장이 부담됨 | 민감 정보 포함 가능 | masking/redaction/self-hosting 검토 |

## 확인 질문

| 질문 | 정리 |
| --- | --- |
| Langfuse와 Prometheus의 차이는 무엇인가? | Prometheus는 time series metric 중심이고, Langfuse는 LLM 요청의 prompt/completion/trace 중심이다. |
| generation은 span과 무엇이 다른가? | generation은 LLM 호출에 특화되어 model, usage, cost 같은 필드를 기록한다. |
| session_id는 왜 필요한가? | 여러 trace를 하나의 대화나 workflow로 묶어 보기 위해서다. |
| user_id를 기록할 때 주의할 점은? | 개인정보를 직접 넣기보다 익명화된 내부 ID를 쓰고 접근 권한을 관리한다. |
| prompt versioning은 왜 필요한가? | prompt 변경이 latency, cost, quality에 미치는 영향을 버전별로 비교하기 위해서다. |
| evaluation dataset은 왜 필요한가? | 같은 입력 묶음으로 prompt/model 변경을 재현 가능하게 비교하기 위해서다. |

## 다음 챕터에서 이어질 내용

다음 챕터에서는 Kubernetes Deployment, Service, Ingress를 사용해 모델 서버를 cluster 위에 배포하는 흐름을 다룬다.
