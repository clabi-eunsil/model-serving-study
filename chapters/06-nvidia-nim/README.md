# 6. NVIDIA NIM

이 단원에서는 NVIDIA NIM을 사용해 LLM inference container를 실행하고 OpenAI-compatible API로 호출한다.  
목표는 vLLM을 직접 실행하는 방식과, NVIDIA가 제공하는 NIM container를 사용하는 방식의 차이를 이해하는 것이다.

NIM은 NVIDIA NGC, 지원 모델, 라이선스, image tag, GPU 요구사항이 자주 바뀔 수 있다.
이 문서는 2026년 6월 기준 공식 문서를 바탕으로 작성했다.  
핵심 공식 문서는 본문에 바로 연결해 두고, 전체 목록은 [references.md](references.md)에 모아 둔다.

## 학습 목표

- NIM이 어떤 문제를 해결하려는지 이해한다.
- NGC catalog, NGC container registry, NGC API key, NIM cache의 역할을 설명할 수 있다.
- NIM과 직접 vLLM server 운영 방식의 차이를 안다.
- NIM image/model을 선택하기 전에 license, 지원 GPU, 사용 조건을 확인한다.
- NIM endpoint를 OpenAI-compatible API로 호출한다.
- vLLM과 같은 prompt로 latency를 비교하는 기본 흐름을 만든다.


## 공식 문서 바로가기

| 문서 | 바로 볼 부분 |
| --- | --- |
| [NVIDIA NIM for LLMs](https://docs.nvidia.com/nim/large-language-models/latest/introduction.html) | NIM의 목적, 지원 범위, LLM NIM 개념 |
| [NIM Getting Started](https://docs.nvidia.com/nim/large-language-models/latest/getting-started.html) | NIM container 실행 흐름, API 호출 예시 |
| [NIM API Reference](https://docs.nvidia.com/nim/large-language-models/latest/api-reference.html) | OpenAI-compatible endpoint와 request/response |
| [NGC Catalog](https://catalog.ngc.nvidia.com/) | NIM image, model, license, tag, 실행 방법 |
| [NGC User Guide](https://docs.nvidia.com/ngc/gpu-cloud/ngc-user-guide/index.html) | NGC account, API key, registry 사용 |
| [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) | Docker container에서 NVIDIA GPU 사용 설정 |

## 실행 환경 기준

NIM server는 Docker container 안에서 실행한다.
따라서 server 실행에는 host `.venv`가 필요 없다.

OpenAI SDK client 실습은 Python `.venv`를 사용한다.

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

client 실습 후:

```bash
deactivate
```

## vLLM과 NIM의 차이

vLLM은 open-source serving engine을 직접 실행하고 옵션을 직접 조정하는 방식이다.  
NIM은 NVIDIA가 model serving에 필요한 container, runtime, API surface, 최적화 구성을 packaged microservice 형태로 제공하는 방식이다.

챕터 1의 [모델 서빙 생태계 지도](../01-basic-concepts/README.md#모델-서빙-생태계-지도)를 다시 보면, vLLM은 LLM serving engine 쪽에 있고 NIM은 vendor가 패키징한 runtime 쪽에 있다.
둘 다 OpenAI-compatible API로 호출할 수 있지만, 모델을 고르고 실행 환경을 책임지는 방식이 다르다.

| 구분 | 직접 vLLM 운영 | NVIDIA NIM |
| --- | --- | --- |
| 실행 단위 | `vllm/vllm-openai` image와 직접 선택한 Hugging Face model | NGC에서 제공하는 NIM image |
| 모델 선택 | Hugging Face repo id를 직접 지정 | NGC catalog/NIM 지원 모델 기준 |
| 인증 | public model은 token 없이 가능, gated model은 `HF_TOKEN` | NGC registry login과 `NGC_API_KEY` 필요 |
| 튜닝 | vLLM engine/server option 직접 조정 | NIM image가 제공하는 설정과 문서 기준 |
| 장점 | 유연성, open-source 생태계 | vendor packaging, NVIDIA 최적화/지원 경로 |
| 확인 필요 | vLLM 지원 architecture, GPU memory | license, NGC 접근, 지원 GPU, image tag |

## 핵심 개념 요약

### NIM

NIM은 NVIDIA Inference Microservice의 줄임말이다.
LLM 같은 AI model을 container 형태로 배포하고 API로 호출할 수 있게 제공하는 NVIDIA의 inference microservice다.

이 챕터에서는 NIM을 "NVIDIA가 패키징한 모델 서버 container"라고 먼저 이해하면 된다.

### NGC Catalog

NGC catalog는 NVIDIA가 제공하는 container image, model, resource를 찾는 곳이다.  
NIM image 이름, 지원 model, license, 실행 방법, 필요한 GPU 조건을 확인한다.

### NGC Container Registry

NGC registry는 NIM container image를 pull하는 registry다.  
대개 `nvcr.io/...` 형태의 image를 사용한다.  
private 또는 access-controlled image를 받을 수 있으므로 registry login이 필요하다.

### NGC API Key

NGC API key는 NGC registry와 NIM container 실행에 필요한 인증 secret이다.  
script나 Git repo에 직접 저장하지 않는다.  
terminal session에서 환경변수로 설정해서 사용한다.

```bash
export NGC_API_KEY=...
```

### NIM Cache

NIM container는 실행 중 model artifact나 optimized engine cache를 사용할 수 있다.
container를 다시 실행할 때 cache를 재사용하려면 host directory를 container cache path에 mount한다.  
정확한 cache path와 권장 mount는 NIM model page와 공식 문서를 따른다.  

## NIM image와 모델 선택

이 챕터의 script는 `NIM_IMAGE` 환경변수로 image를 받는다.  
문서에는 예시 기본값을 넣어두었지만, 실제 실습 전 반드시 NGC catalog에서 최신 image/tag와 license를 확인한다.  

```bash
export NIM_IMAGE="nvcr.io/nim/meta/llama-3.1-8b-instruct:latest"
```

주의:

- 위 image 이름은 예시다. NGC catalog에서 실제 사용 가능한 image/tag를 확인한다.
- Meta Llama 계열 등 일부 모델은 license 동의나 사용 조건이 있을 수 있다.
- GPU memory가 부족하면 더 작은 NIM 또는 다른 profile이 필요할 수 있다.
- NIM image마다 지원 option, endpoint, cache path가 다를 수 있다.

## 학습 포인트와 파일 안내

| 파일 | 볼 부분 | 이유 |
| --- | --- | --- |
| [scripts/02_ngc_login.sh](scripts/02_ngc_login.sh) | `docker login nvcr.io` | NGC registry 인증 흐름 이해 |
| [scripts/04_run_nim_container.sh](scripts/04_run_nim_container.sh) | `NGC_API_KEY`, cache mount, port mapping | NIM container 실행 핵심 옵션 |
| [scripts/06_curl_chat.sh](scripts/06_curl_chat.sh) | `/v1/chat/completions` payload | NIM OpenAI-compatible 호출 구조 |
| [client/07_openai_client.py](client/07_openai_client.py) | `OpenAI(base_url=...)` | OpenAI SDK로 NIM endpoint 호출 |
| [scripts/08_compare_latency.sh](scripts/08_compare_latency.sh) | 반복 호출과 latency 측정 | vLLM과 같은 prompt 비교 준비 |
| [scripts/09_collect_runtime_info.sh](scripts/09_collect_runtime_info.sh) | `nvidia-smi`, `docker logs` | GPU/server 상태 확인 |

## 실습

### 1. 환경 확인

```bash
cd ~/study/model-serving/chapters/06-nvidia-nim
bash scripts/01_check_env.sh
```

로컬에 GPU가 없으면 원격 GPU 서버에서 실행한다.

```bash
rsync -av ~/study/model-serving/chapters/06-nvidia-nim/ user@gpu-server:~/nvidia-nim/
ssh user@gpu-server
cd ~/nvidia-nim
```

### 2. NGC API key 준비

NGC 계정에서 API key를 만든 뒤 terminal session에만 환경변수로 설정한다.

```bash
export NGC_API_KEY=...
```

확인:

```bash
test -n "$NGC_API_KEY" && echo "NGC_API_KEY is set"
```

### 3. NGC registry login

```bash
bash scripts/02_ngc_login.sh
```

이 script는 `NGC_API_KEY`를 stdin으로 넘겨 `docker login nvcr.io`를 실행한다.
API key를 command line 인자에 직접 쓰지 않기 위해서다.

### 4. NIM image pull

먼저 NGC catalog에서 image/tag를 확인한다.

```bash
export NIM_IMAGE="nvcr.io/nim/meta/llama-3.1-8b-instruct:latest"
bash scripts/03_pull_nim_image.sh
```

### 5. NIM container 실행

터미널 1에서 실행한다.

```bash
bash scripts/04_run_nim_container.sh
```

처음 실행은 image pull, model artifact download, optimization/cache 준비 때문에 오래 걸릴 수 있다.

### 6. `/v1/models` 확인

터미널 2에서 실행한다.

```bash
bash scripts/05_curl_models.sh
```

### 7. chat completions 호출

```bash
bash scripts/06_curl_chat.sh
```

확인할 것:

- NIM도 OpenAI-compatible API를 제공한다.
- `messages` 구조는 vLLM 챕터에서 본 것과 유사하다.
- response의 `choices[0].message.content`가 생성 결과다.

### 8. OpenAI SDK client 실행

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python client/07_openai_client.py
```

### 9. vLLM과 같은 prompt로 latency 비교

```bash
bash scripts/08_compare_latency.sh
```

이 script는 같은 prompt를 NIM endpoint에 여러 번 보내고, 요청별 latency를 terminal에 출력한다.
vLLM과 비교하려면 챕터 5에서 같은 prompt/max_tokens/concurrency 조건을 맞춰 실행한다.

### 10. runtime 정보 기록

```bash
bash scripts/09_collect_runtime_info.sh
```

기본은 terminal 출력이다.
저장하려면:

```bash
bash scripts/09_collect_runtime_info.sh | tee results/nim_runtime_info.txt
```

### 11. 실습 마무리

container 종료:

```bash
bash scripts/10_stop_container.sh
```

client `.venv` 종료:

```bash
deactivate
```

## 확인 질문

| 질문 | 정리 |
| --- | --- |
| NIM은 vLLM과 완전히 다른 API를 쓰는가? | 아니다. 많은 NIM LLM container는 OpenAI-compatible API를 제공한다. |
| NIM image 이름은 어디서 확인하는가? | NGC catalog와 NVIDIA NIM 문서에서 확인한다. |
| 왜 `NGC_API_KEY`를 script에 저장하지 않는가? | API key는 secret이므로 Git repo와 shell history에 남기지 않는 것이 좋다. |
| NIM과 vLLM latency 비교 시 무엇을 맞춰야 하는가? | prompt, max_tokens, temperature, concurrency, GPU, model 크기를 가능한 맞춘다. |
| NIM 실습 전 반드시 확인할 것은? | license, access 권한, 지원 GPU, image tag, API key, cache path다. |

## 다음 챕터에서 이어질 내용

다음 챕터에서는 성능 테스트 방법론을 더 일반화한다.
TTFT, TTFB, p50/p95/p99, tokens/sec, requests/sec를 더 체계적으로 측정하고 결과표를 만드는 방법을 다룬다.
