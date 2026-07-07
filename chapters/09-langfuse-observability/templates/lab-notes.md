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
export LANGFUSE_HOST=http://localhost:3000
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

| 컬럼 | 의미 |
| --- | --- |
| `prompt_name` | prompt 변형 이름 |
| `prompt_version` | prompt version처럼 다룰 label |
| `prompt_tokens` | 입력 길이 |
| `completion_tokens` | 출력 길이 |
| `latency_ms` | 요청 처리 시간 |

## Cleanup

```bash
bash scripts/12_cleanup.sh
```

가상환경 종료:

```bash
deactivate
```
