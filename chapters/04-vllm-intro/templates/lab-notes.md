# Chapter 04 Lab Notes

## Sources

- vLLM documentation: https://docs.vllm.ai/en/stable/
- vLLM Docker deployment: https://docs.vllm.ai/en/stable/deployment/docker/
- vLLM Online Serving: https://docs.vllm.ai/en/stable/serving/online_serving/
- vLLM engine arguments: https://docs.vllm.ai/en/stable/configuration/engine_args/
- PagedAttention paper: https://arxiv.org/abs/2309.06180

## Commands

이 챕터는 server는 Docker container 안에서 실행하고, client는 필요할 때만 챕터별 `.venv`를 사용한다.
즉, vLLM server 실행에는 `source .venv/bin/activate`가 필요 없다.

환경 확인:

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/01_check_env.sh
```

터미널 1: vLLM server 실행

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/02_run_vllm_docker.sh
```

터미널 2: server 호출

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
bash scripts/03_list_models.sh
bash scripts/04_curl_chat.sh
bash scripts/05_curl_chat_stream.sh
bash scripts/07_collect_runtime_info.sh
```

터미널 2: OpenAI SDK client 실행

```bash
cd ~/study/model-serving/chapters/04-vllm-intro
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python client/06_openai_client.py
```

실습 종료:

```bash
bash scripts/08_stop_server.sh
```

```bash
# client .venv를 사용했다면 종료
deactivate
```

SSH port forwarding을 사용했다면 forwarding terminal에서:

```text
Ctrl + C
```

## Environment

아래 값은 `bash scripts/01_check_env.sh`와 `bash scripts/07_collect_runtime_info.sh`로 확인한다.

```bash
docker --version
docker info
nvidia-smi
docker images vllm/vllm-openai
docker ps
```

로컬에 GPU가 없으면 이 챕터는 원격 GPU 서버에서 실행한다.
원격 서버를 쓸 때는 챕터 4 디렉터리만 복사하면 된다.

```bash
rsync -av ~/study/model-serving/chapters/04-vllm-intro/ user@gpu-server:~/vllm-intro/
ssh user@gpu-server
cd ~/vllm-intro
```

예상 확인:

| 항목 | 의미 | 정상/주의 기준 |
| --- | --- | --- |
| Host | local WSL 또는 remote GPU server | GPU 실습은 GPU가 있는 서버에서 진행한다. |
| Docker | container runtime 확인 | `docker --version`과 `docker info`가 정상 출력되어야 한다. |
| NVIDIA driver/GPU | GPU 인식 여부 | `nvidia-smi`가 GPU와 driver version을 보여야 한다. |
| Docker GPU support | container에서 GPU를 볼 수 있는지 | `docker run --rm --gpus all ... nvidia-smi`가 성공해야 한다. |
| vLLM image | 사용할 server image | `vllm/vllm-openai:latest` 또는 명시한 tag를 사용한다. |
| Port | vLLM server HTTP port | 기본 실습은 `8000`을 사용한다. |

## Model

- Model name: `Qwen/Qwen3-0.6B`
- Served model name: `qwen3-0.6b`
- Model purpose: vLLM Online Serving 흐름 확인
- Model note: 이 챕터의 핵심은 답변 품질 평가가 아니라 vLLM server 실행, OpenAI-compatible API 호출, streaming 응답 관찰이다.

`Qwen/Qwen3-0.6B`는 Hugging Face Hub의 model repository id다.
model page 주소는 아래와 같다.

```text
https://huggingface.co/Qwen/Qwen3-0.6B
```

`--model`과 `--served-model-name`은 다르다.

- `--model`: 실제로 vLLM이 로딩할 Hugging Face model 이름
- `--served-model-name`: client가 API payload의 `model` field에 넣는 이름

다른 모델을 쓰기 전에 확인할 것:

- Hugging Face model page가 존재하는가?
- license와 사용 조건을 확인했는가?
- public model인가, gated/private model이라 `HF_TOKEN`이 필요한가?
- vLLM supported models 문서에서 architecture가 지원되는가?
- 현재 GPU memory에 들어갈 크기인가?
- chat completions에 사용할 chat template이 있는가?

다른 모델 실행 예시:

```bash
MODEL_NAME=Qwen/Qwen3-1.7B \
SERVED_MODEL_NAME=qwen3-1.7b \
bash scripts/02_run_vllm_docker.sh
```

private/gated model이면:

```bash
export HF_TOKEN=hf_xxx
bash scripts/02_run_vllm_docker.sh
```

## Model Download and Cache

vLLM Docker image에는 vLLM server 실행 환경이 들어 있다.
하지만 `Qwen/Qwen3-0.6B` model weight가 image 안에 미리 들어 있는 것은 아니다.

실행 흐름:

```text
docker run vllm/vllm-openai:latest --model Qwen/Qwen3-0.6B
→ container 시작
→ vLLM이 --model 값을 Hugging Face repo id로 해석
→ config/tokenizer/weight files 다운로드 또는 cache reuse
→ model을 GPU memory에 로딩
→ OpenAI-compatible API server 시작
```

cache mount:

```bash
-v "${HOME}/.cache/huggingface:/root/.cache/huggingface"
```

이 mount 때문에 container가 삭제되어도 host의 Hugging Face cache는 남는다.
두 번째 실행부터는 같은 model을 다시 다운로드하지 않고 cache를 재사용할 수 있다.

## Server Options

[scripts/02_run_vllm_docker.sh](../scripts/02_run_vllm_docker.sh)에서 확인할 값:

```bash
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen3-0.6B}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen3-0.6b}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.80}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"
```

주요 옵션:

- `--gpus all`: host GPU를 container 안으로 전달한다.
- `--ipc=host`: PyTorch/vLLM이 shared memory를 더 넉넉하게 쓸 수 있게 한다.
- `--gpu-memory-utilization 0.80`: vLLM이 GPU memory를 어느 정도까지 사용할지 정한다.
- `--max-model-len 2048`: prompt와 output을 합친 최대 token 길이를 정한다.

`--gpu-memory-utilization`과 `--max-model-len`은 GPU memory 사용량과 직접 관련이 있다.
OOM이 나면 더 작은 model을 쓰거나, `MAX_MODEL_LEN` 또는 `GPU_MEMORY_UTILIZATION`을 낮춰 본다.

## Request Payload

04번 non-streaming 요청과 05번 streaming 요청은 거의 같은 `messages` 구조를 사용한다.
차이는 05번에 `"stream": true`가 추가된다는 점이다.

```json
{
  "model": "qwen3-0.6b",
  "messages": [
    {
      "role": "system",
      "content": "You are a concise model serving tutor."
    },
    {
      "role": "user",
      "content": "Explain vLLM in one short Korean paragraph."
    }
  ],
  "max_tokens": 128,
  "temperature": 0.2
}
```

`messages`는 대화 입력 목록이다.

- `system`: 모델의 전반적인 답변 방식이나 역할을 지정한다.
- `user`: 실제 사용자 질문을 담는다.
- `assistant`: 이전에 모델이 답한 내용을 대화 기록으로 넣을 때 사용한다.

## Response

`bash scripts/03_list_models.sh` 예상 응답 형태:

```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen3-0.6b",
      "object": "model"
    }
  ]
}
```

실제 응답에는 field가 더 많을 수 있다.
중요한 것은 `qwen3-0.6b`가 보이는지 확인하는 것이다.

`bash scripts/04_curl_chat.sh` 예상 응답 형태:

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "vLLM은 ..."
      }
    }
  ],
  "usage": {
    "prompt_tokens": 0,
    "completion_tokens": 0,
    "total_tokens": 0
  }
}
```

`choices[0].message.content`가 실제 생성된 답변이다.
`usage` 값은 model, tokenizer, vLLM version에 따라 달라질 수 있다.

`bash scripts/05_curl_chat_stream.sh` 예상 응답 형태:

```text
data: {"id":"chatcmpl-...","object":"chat.completion.chunk", ...}
data: {"id":"chatcmpl-...","object":"chat.completion.chunk", ...}
data: [DONE]
```

streaming 응답은 완성된 JSON 하나가 아니라 여러 chunk로 도착한다.
첫 chunk가 도착하기까지의 시간이 TTFT를 체감하는 지점이다.

## OpenAI SDK Client

`client/06_openai_client.py`는 OpenAI cloud API가 아니라 local 또는 remote vLLM endpoint를 호출한다.

핵심 설정:

```python
client = OpenAI(
    base_url="http://127.0.0.1:8000/v1",
    api_key="EMPTY",
)
```

- `base_url`: OpenAI SDK 요청을 vLLM server로 보내기 위한 API root 주소
- `api_key="EMPTY"`: local vLLM 실습에서는 실제 인증을 쓰지 않지만 SDK 형식상 값이 필요해서 넣는 dummy key

예상 출력:

```text
base_url=http://127.0.0.1:8000/v1
model=qwen3-0.6b

## Non-streaming response
...
elapsed_seconds=...

## Streaming response
first_chunk_seconds=...
...
stream_total_seconds=...
```

## Observations

- 첫 실행은 Docker image pull과 model download 때문에 오래 걸릴 수 있다.
- Hugging Face cache가 유지되면 다음 실행부터 model download 시간이 줄어든다.
- `/v1/models`에서 보이는 이름은 실제 model name이 아니라 `--served-model-name`이다.
- non-streaming은 응답이 완성된 뒤 한 번에 돌아온다.
- streaming은 여러 chunk가 순차적으로 도착한다.
- `first_chunk_seconds`는 간단한 TTFT 관찰 값으로 볼 수 있다.
- `nvidia-smi`에서 GPU memory 사용량이 증가하면 model이 GPU에 올라간 것이다.

## Errors

- `docker: not found`: Docker가 설치되어 있지 않거나 PATH에 없다.
- `Cannot connect to Docker daemon`: Docker daemon이 꺼져 있거나 현재 user 권한이 없다.
- `could not select device driver`: Docker가 GPU를 container에 전달하지 못하는 상태다. NVIDIA Container Toolkit 설정을 확인한다.
- CUDA OOM: model/context/GPU memory 설정이 현재 GPU에 비해 크다. 더 작은 model, 낮은 `MAX_MODEL_LEN`, 낮은 `GPU_MEMORY_UTILIZATION`을 시도한다.
- `/v1/models` connection refused: vLLM server가 아직 준비되지 않았거나 container가 실패했다. `docker logs vllm-intro-server`를 확인한다.
- OpenAI SDK authentication error: OpenAI cloud로 잘못 연결했거나 `base_url`이 누락되었을 수 있다. local vLLM 실습에서는 `base_url=http://127.0.0.1:8000/v1`, `api_key=EMPTY`를 확인한다.

## Notes

- 이 챕터의 핵심은 vLLM으로 LLM serving server를 직접 실행해 보는 것이다.
- FastAPI app을 직접 만들지 않아도 vLLM이 OpenAI-compatible API server를 제공한다.
- 운영 환경에서는 `vllm/vllm-openai:latest` 대신 version tag를 고정하는 편이 재현성에 좋다.
- `--ipc=host`는 shared memory 문제를 줄이는 데 도움이 되지만 container 격리를 일부 완화하므로 운영 정책을 확인해야 한다.
- 다음 챕터에서는 concurrency, token length, GPU memory 설정을 바꿔가며 vLLM 성능을 더 자세히 측정한다.
