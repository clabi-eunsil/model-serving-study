# Chapter 02 Lab Notes

## Sources

- FastAPI documentation: https://fastapi.tiangolo.com/
- Hugging Face Transformers pipelines: https://huggingface.co/docs/transformers/en/main_classes/pipelines
- Uvicorn settings: https://www.uvicorn.org/settings/

## Commands

이 챕터는 `chapters/02-fastapi-serving/.venv`를 사용한다.
터미널을 새로 열 때마다 필요한 경우 `source .venv/bin/activate`를 다시 실행한다.

환경 확인:

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
source .venv/bin/activate
bash scripts/01_check_env.sh
```

터미널 1: 서버 실행

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/02_run_server.sh
```

터미널 2: 서버 호출

```bash
cd ~/study/model-serving/chapters/02-fastapi-serving
source .venv/bin/activate
curl http://127.0.0.1:8000/health
bash scripts/03_curl_generate.sh
python scripts/04_client.py
curl http://127.0.0.1:8000/metrics
```

실습 종료:

```text
터미널 1에서 서버 종료: Ctrl + C
```

```bash
# 각 터미널에서 가상환경 종료
deactivate
```

## Environment

아래 값은 `bash scripts/01_check_env.sh`로 확인한다.

```bash
python --version
which python
python -c "import fastapi; print(fastapi.__version__)"
python -c "import uvicorn; print(uvicorn.__version__)"
python -c "import transformers; print(transformers.__version__)"
python -c "import torch; print(torch.__version__)"
python -c "import torch; print(torch.cuda.is_available())"
```

현재 챕터의 실습은 CPU에서도 가능하다. GPU가 없어도 괜찮다.

- OS: Chapter 01의 [env-summary.txt](../../01-basic-concepts/env-summary.txt) 기준 Ubuntu 24.04.1 LTS
- Python: Chapter 01 기준 Python 3.12.3. 실제 `.venv`의 Python은 `python --version`으로 확인
- FastAPI: `bash scripts/01_check_env.sh` 출력 확인
- Uvicorn: `bash scripts/01_check_env.sh` 출력 확인
- Transformers: `bash scripts/01_check_env.sh` 출력 확인
- Torch: `bash scripts/01_check_env.sh` 출력 확인
- CUDA: `torch.cuda.is_available()` 결과 확인
- GPU: CPU 실습이면 없음. GPU가 잡히면 `scripts/01_check_env.sh`에 GPU 이름 표시

## Model

- Model name: `sshleifer/tiny-gpt2`
- Model purpose: local API structure test
- Model note: 생성 품질 평가용 모델이 아니라 API 흐름 확인용 tiny model

## Request Payload

```json
{
  "prompt": "Model serving is",
  "max_new_tokens": 24,
  "temperature": 0.7
}
```

## Response

`curl http://127.0.0.1:8000/health` 예상 응답:

```json
{
  "status": "ok",
  "model": "sshleifer/tiny-gpt2",
  "model_loaded": true
}
```

`bash scripts/03_curl_generate.sh` 예상 응답 형태:

```json
{
  "model": "sshleifer/tiny-gpt2",
  "prompt": "Model serving is",
  "generated_text": "Model serving is ...",
  "latency_ms": 123.45
}
```

`generated_text`와 `latency_ms`는 실행할 때마다 달라질 수 있다. tiny-gpt2는 품질 좋은 문장을 만들기 위한 모델이 아니므로, 문장이 어색해도 정상이다.

`curl http://127.0.0.1:8000/metrics` 예상 응답 형태:

```json
{
  "requests_total": 1,
  "errors_total": 0,
  "avg_latency_ms": 123.45
}
```

## Observations

- Health check result: `model_loaded`가 `true`이면 모델이 서버 시작 시 로딩된 상태다.
- Latency: 첫 요청은 모델 초기화 영향으로 더 느릴 수 있다. 이후 요청은 더 빨라질 수 있다.
- Generated text: `sshleifer/tiny-gpt2`는 tiny model이라 결과 문장이 어색할 수 있다.
- Metrics: `/generate`를 호출할 때마다 `requests_total`이 증가해야 한다.
- Error count: 정상 요청만 보냈다면 `errors_total`은 0이어야 한다.

## Errors

- `ModuleNotFoundError`: `.venv`가 활성화되지 않았거나 `pip install -r requirements.txt`가 끝나지 않은 상태일 수 있다.
- `Connection refused`: 서버가 떠 있지 않거나 터미널 1에서 `bash scripts/02_run_server.sh`가 실행 중이 아닐 수 있다.
- 첫 실행이 오래 걸림: Hugging Face model을 처음 다운로드하거나 model loading 중일 수 있다.
- `torch.cuda.is_available()`가 `false`: CPU 실습은 가능하다. GPU 실습은 뒤 챕터에서 다시 확인한다.

## Notes

- 이 챕터의 핵심은 생성 품질이 아니라 FastAPI가 모델을 API로 감싸는 구조를 이해하는 것이다.
- 실제 운영용 LLM serving은 이후 vLLM, NIM, KServe에서 더 적절한 도구로 다룬다.
