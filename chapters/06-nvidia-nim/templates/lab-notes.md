# Chapter 06 Lab Notes

## Sources

- NVIDIA NIM for LLMs: https://docs.nvidia.com/nim/large-language-models/latest/introduction.html
- NIM Getting Started: https://docs.nvidia.com/nim/large-language-models/latest/getting-started.html
- NIM API Reference: https://docs.nvidia.com/nim/large-language-models/latest/api-reference.html
- NGC Catalog: https://catalog.ngc.nvidia.com/
- NGC User Guide: https://docs.nvidia.com/ngc/gpu-cloud/ngc-user-guide/index.html
- NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

## Commands

환경 확인:

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
bash scripts/01_check_env.sh
```

NGC API key 설정:

```bash
export NGC_API_KEY=...
```

NGC login:

```bash
bash scripts/02_ngc_login.sh
```

NIM image pull:

```bash
export NIM_IMAGE="nvcr.io/nim/meta/llama-3.1-8b-instruct:latest"
bash scripts/03_pull_nim_image.sh
```

터미널 1: NIM container 실행

```bash
bash scripts/04_run_nim_container.sh
```

터미널 2: API 호출

```bash
bash scripts/05_curl_models.sh
bash scripts/06_curl_chat.sh
```

터미널 2: OpenAI SDK client

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python client/07_openai_client.py
```

latency 비교:

```bash
bash scripts/08_compare_latency.sh | tee results/nim_latency.txt
```

runtime 상태 기록:

```bash
bash scripts/09_collect_runtime_info.sh | tee results/nim_runtime_info.txt
```

실습 종료:

```bash
bash scripts/10_stop_container.sh
deactivate
```

## Environment

기록할 값:

- Host: local WSL 또는 remote GPU server
- Docker: `docker --version`
- GPU: `nvidia-smi`
- NIM image: NGC catalog에서 확인한 image/tag
- NIM model name: `/v1/models` 응답 또는 NIM model page 기준
- NGC login: 성공 여부

## NIM Image and Access

실제 실행 전 확인:

| 항목 | 확인 위치 | 기록 |
| --- | --- | --- |
| image repository/tag | NGC catalog |  |
| license/terms | NGC model page |  |
| required GPU/memory | NGC model page 또는 NIM docs |  |
| cache path | NIM docs/model page |  |
| API model name | `/v1/models` 응답 |  |

## Request Payload

```json
{
  "model": "meta/llama-3.1-8b-instruct",
  "messages": [
    {
      "role": "system",
      "content": "You are a concise model serving tutor."
    },
    {
      "role": "user",
      "content": "Explain NVIDIA NIM in one short Korean paragraph."
    }
  ],
  "max_tokens": 128,
  "temperature": 0.2
}
```

`model` 값은 NIM image와 `/v1/models` 응답에 맞게 바꾼다.

## Expected Response

`bash scripts/05_curl_models.sh` 예상 형태:

```json
{
  "object": "list",
  "data": [
    {
      "id": "..."
    }
  ]
}
```

`bash scripts/06_curl_chat.sh` 예상 형태:

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "NVIDIA NIM은 ..."
      }
    }
  ]
}
```

## Observations

- 첫 실행은 image pull, model artifact download, cache 준비 때문에 오래 걸릴 수 있다.
- cache가 유지되면 다음 실행이 빨라질 수 있다.
- NIM도 OpenAI-compatible API를 제공하므로 vLLM client 구조와 비슷하게 호출할 수 있다.
- vLLM과 latency를 비교하려면 prompt, max_tokens, temperature, GPU, model 크기를 가능한 맞춘다.

## Errors

- `NGC_API_KEY is not set`: `export NGC_API_KEY=...`를 먼저 실행한다.
- `docker login nvcr.io` 실패: API key, NGC 권한, network를 확인한다.
- image pull 실패: NGC catalog에서 image/tag와 access 권한을 다시 확인한다.
- license/auth error: 해당 model 사용 조건이나 license 동의가 필요한지 확인한다.
- CUDA OOM: 현재 GPU memory에 비해 NIM/model이 크거나 cache 설정이 맞지 않을 수 있다.
- `/v1/models` connection refused: NIM server가 아직 준비 중이거나 container가 실패했다. `docker logs nim-llm-server`를 확인한다.

## Notes

- NIM은 vendor-provided inference microservice이므로, open-source vLLM 직접 운영보다 확인해야 할 license/access 조건이 더 중요하다.
- API key는 절대 Git repo에 저장하지 않는다.
- 실제 운영에서는 image tag를 `latest`가 아니라 고정 version으로 두는 편이 재현성에 좋다.
