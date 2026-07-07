# Chapter 9 Lab Notes

## Environment

```bash
cd ~/study/model-serving/chapters/09-langfuse-observability
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/01_check_env.sh
```

예상 확인:

- `langfuse`: installed
- `openai`: installed
- `LANGFUSE_PUBLIC_KEY`: dry-run이면 없어도 됨
- `LANGFUSE_SECRET_KEY`: dry-run이면 없어도 됨

## Trace 구조 dry-run

```bash
bash scripts/02_send_trace.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| trace name | 요청 하나의 최상위 묶음 |
| session_id | 같은 대화/실습 흐름을 묶는 ID |
| user_id | 어떤 사용자 요청인지 묶는 ID |
| span | 전처리, retrieval, tool call 같은 일반 작업 |
| generation | LLM 호출. model, prompt, completion, token usage를 함께 기록 |

## 실제 Langfuse로 보내기

`.env.example`을 참고해서 `.env`를 만든 뒤:

```bash
DRY_RUN=false bash scripts/02_send_trace.sh
```

Langfuse UI에서 확인할 것:

- Traces 목록에 `chapter-09-first-trace`가 보이는가?
- timeline에 `prepare-request`, `fake-llm-call`이 보이는가?
- generation에 input/output/token usage가 기록되었는가?
- session/user filter로 묶어 볼 수 있는가?

## Self-host Langfuse

공식 repo 준비:

```bash
bash scripts/06_prepare_self_host_official.sh
```

예상 관찰:

- `self-host/langfuse-official` 공식 repo가 준비된다.
- `self-host/langfuse-official/.env`가 생성된다.
- `SALT`, `NEXTAUTH_SECRET`, DB/ClickHouse/Redis/MinIO secret이 random 값으로 채워진다.
- UI에서 첫 계정을 직접 만들면 `admin` / `admin123`을 학습용으로 사용한다.

폐쇄망 반입용 image 목록:

```bash
bash scripts/07_list_self_host_images.sh
```

local/VM 실행:

```bash
bash scripts/08_start_self_host.sh
```

상태 확인:

```bash
bash scripts/09_check_self_host.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| `langfuse-web` | UI/API container |
| `langfuse-worker` | event 처리 worker |
| `postgres` | transactional DB |
| `clickhouse` | trace/observation 분석용 OLAP DB |
| `redis` 또는 `valkey` | queue/cache |
| `minio` | local S3/blob storage |

Python SDK 연결:

```bash
export LANGFUSE_BASE_URL=http://localhost:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
DRY_RUN=false bash scripts/02_send_trace.sh
```

정리:

```bash
bash scripts/10_stop_self_host.sh
```

## OpenAI-compatible endpoint trace

endpoint가 아직 없으면 먼저 안내를 확인한다.

```bash
bash scripts/03_prepare_vllm_endpoint.sh
```

dry-run:

```bash
bash scripts/04_trace_openai_compatible.sh
```

실제 vLLM/NIM endpoint와 Langfuse에 보내기:

```bash
export OPENAI_BASE_URL=http://127.0.0.1:8000/v1
export OPENAI_API_KEY=EMPTY
export OPENAI_MODEL=study-model
DRY_RUN=false bash scripts/04_trace_openai_compatible.sh
```

## Prompt 비교

```bash
bash scripts/05_compare_prompts.sh
```

생성 파일:

```text
results/prompt_comparison.csv
```

볼 컬럼:

| 컬럼 | 의미 | 기록할 것 |
| --- | --- | --- |
| `prompt_name` | prompt 변형 이름 | 어떤 의도로 만든 prompt인지 |
| `prompt_version` | prompt version처럼 다룰 label | 나중에 같은 조건을 재현할 수 있는지 |
| `prompt_tokens` | 입력 길이 | 입력이 길어져 latency/cost가 늘었는지 |
| `completion_tokens` | 출력 길이 | 답변이 길어서 decode 시간이 늘었는지 |
| `latency_ms` | 요청 처리 시간 | 가장 빠른/느린 prompt와 그 이유 |
| `answer_preview` | 답변 미리보기 | 숫자는 좋아도 답변 품질이 충분한지 |

정리 예:

- `short-explain`: 가장 짧고 빠르지만 설명이 부족할 수 있다.
- `friendly-explain`: 초보자에게 더 친절하지만 prompt가 길어 latency가 조금 늘 수 있다.
- `ops-focused`: 운영 관점 정보가 많지만 token/cost가 더 커질 수 있다.

최종 선택은 숫자 하나로 하지 않는다.
품질, latency, token cost, 안정성을 함께 본다.

## Cleanup

```bash
bash scripts/12_cleanup.sh
```

가상환경 종료:

```bash
deactivate
```
