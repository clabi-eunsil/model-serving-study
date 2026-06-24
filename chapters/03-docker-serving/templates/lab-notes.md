# Chapter 03 Lab Notes


## Sources

- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Docker bind mounts: https://docs.docker.com/engine/storage/bind-mounts/
- Docker volumes: https://docs.docker.com/engine/storage/volumes/
- Docker Compose GPU support: https://docs.docker.com/compose/how-tos/gpu-support/
- NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

## Commands

환경 확인:

```bash
cd ~/study/model-serving/chapters/03-docker-serving
bash scripts/01_check_env.sh
```

이 챕터는 host `.venv`를 사용하지 않는다.
Python dependency는 Docker image 안에 설치한다.
따라서 `source .venv/bin/activate` 없이 Docker 명령을 실행한다.

image build:

```bash
bash scripts/02_build_image.sh
```

터미널 1: container 실행

```bash
bash scripts/03_run_container.sh
```

터미널 2: server 호출

```bash
curl http://127.0.0.1:8000/health
bash scripts/04_curl_generate.sh
curl http://127.0.0.1:8000/metrics
```

종료:

```text
터미널 1에서 서버 종료: Ctrl + C
```

또는:

```bash
docker stop model-serving-fastapi
```

Compose 실행:

```bash
docker compose up --build
docker compose down
```

Compose server/client 실행:

```bash
bash scripts/05_compose_client.sh
docker compose down
```

image size 확인:

```bash
bash scripts/06_image_size.sh
```

## Docker Run vs Docker Compose

이번 챕터에서는 같은 서버를 두 방식으로 실행한다.

| 항목 | `docker run` 방식 | Docker Compose 방식 |
| --- | --- | --- |
| build | `bash scripts/02_build_image.sh` | `docker compose up --build` |
| run | `bash scripts/03_run_container.sh` | `docker compose up --build` |
| 설정 위치 | shell script와 명령어 옵션 | `docker-compose.yml` |
| port | `-p 8000:8000` | `ports: ["8000:8000"]` |
| cache volume | `-v hf-cache:/root/.cache/huggingface` | `volumes:` |
| 환경변수 | `-e MODEL_NAME=...` | `environment:` |

관찰 포인트:

- 두 방식 모두 최종적으로는 같은 FastAPI server를 container로 실행한다.
- `docker run` 방식은 Docker 개념을 단계별로 보기 좋다.
- Compose 방식은 실행 구성을 파일로 남겨 반복 실행하기 좋다.
- service가 여러 개로 늘어나면 Compose 방식이 훨씬 관리하기 쉽다.

## Compose Server/Client Notes

`docker-compose.yml`에는 두 service가 있다.

- `model-server`: FastAPI 모델 서버
- `model-client`: server를 호출하는 1회성 client container

실행:

```bash
bash scripts/05_compose_client.sh
```

관찰 포인트:

- client는 host의 `127.0.0.1`이 아니라 `http://model-server:8000`으로 server를 호출한다.
- Compose 내부에서는 service 이름이 DNS 이름처럼 동작한다.
- client container는 요청이 끝난 뒤 `--rm`으로 삭제된다.
- server container는 계속 실행 중이므로 마지막에 `docker compose down`으로 정리한다.

## Image Size Notes

실행:

```bash
bash scripts/06_image_size.sh
```

관찰 포인트:

- `docker images`에서 image 전체 크기를 확인한다.
- `docker history`에서 큰 layer를 확인한다.
- `pip install -r requirements.txt` layer가 크다면 `torch`, `transformers` 같은 dependency가 주요 원인일 수 있다.
- `.dockerignore`와 `pip install --no-cache-dir`는 image size를 줄이는 기본 장치다.
- model weight는 image에 넣지 않고 `hf-cache` volume으로 분리한다.

## Environment

아래 값은 `bash scripts/01_check_env.sh`로 확인한다.

- Docker: `docker --version` 출력 확인
- Docker Compose: `docker compose version` 출력 확인
- Docker daemon: `docker info` 접근 가능 여부 확인
- NVIDIA GPU: `nvidia-smi` 출력 확인
- Docker GPU support: `docker run --rm --gpus all ... nvidia-smi`로 확인

## Registry Login Notes

이 챕터의 기본 실습은 Docker login 없이 진행할 수 있다.

- Local image: `model-serving-fastapi:chapter-03`
- Base image: `python:3.12-slim`
- Test CUDA image: `nvidia/cuda:12.4.1-base-ubuntu22.04`
- Test model: public model `sshleifer/tiny-gpt2`

login/token이 필요한 경우:

| 상황 | 필요한 것 |
| --- | --- |
| Docker Hub rate limit 또는 private image | `docker login` |
| NGC/NIM image pull | `docker login nvcr.io --username '$oauthtoken'` 후 NGC API key 입력 |
| Hugging Face private/gated model | `HF_TOKEN` 환경변수 |

명령 예시:

```bash
# Docker Hub
docker login

# NVIDIA NGC
docker login nvcr.io --username '$oauthtoken'

# Hugging Face gated/private model
export HF_TOKEN=hf_xxx
docker run --rm \
  -p 8000:8000 \
  -v hf-cache:/root/.cache/huggingface \
  -e MODEL_NAME=meta-llama/Some-Gated-Model \
  -e HF_TOKEN="$HF_TOKEN" \
  model-serving-fastapi:chapter-03
```

주의:

- token을 script에 직접 저장하지 않는다.
- API key를 명령어에 직접 넣으면 shell history에 남을 수 있다.
- NGC/NIM 실습은 뒤 챕터에서 별도로 더 자세히 다룬다.

## Remote GPU Server Notes

로컬에 GPU가 없고 별도 GPU 서버에서 실행하는 경우, 실습은 GPU 서버 안에서 진행한다.

코드 전달:

```bash
# 로컬 터미널에서 실행
rsync -av ~/study/model-serving/chapters/03-docker-serving/ user@gpu-server:~/docker-serving/
```

GPU 서버 접속:

```bash
ssh user@gpu-server
cd ~/docker-serving
```

GPU 서버 환경 확인:

```bash
bash scripts/08_remote_gpu_checklist.sh
nvidia-smi
docker --version
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

GPU 서버에서 실행:

```bash
bash scripts/02_build_image.sh
bash scripts/07_run_container_gpu.sh
```

GPU 서버 안에서 확인:

```bash
curl http://127.0.0.1:8000/health
bash scripts/04_curl_generate.sh
curl http://127.0.0.1:8000/metrics
```

로컬에서 확인하고 싶을 때:

```bash
# 로컬 터미널에서 실행
ssh -L 8000:127.0.0.1:8000 user@gpu-server
```

그 다음 로컬의 다른 터미널에서:

```bash
curl http://127.0.0.1:8000/health
```

관찰 포인트:

- `nvidia-smi`는 GPU 서버 host에서 GPU가 보이는지 확인한다.
- `docker run --gpus all ... nvidia-smi`는 container 안에서 GPU가 보이는지 확인한다.
- SSH port forwarding을 쓰면 GPU 서버의 8000 port를 외부에 직접 열지 않아도 된다.

Chapter 01의 환경 기록 기준으로 현재 WSL distro 안에서는 Docker, kubectl, nvidia-smi가 보이지 않았다.
따라서 실제 Docker 실습 전 Docker Desktop WSL integration 또는 Docker Engine 상태를 먼저 확인해야 한다.

Docker가 없거나 WSL에서 보이지 않을 때:

1. Windows Docker Desktop 설치 여부를 확인한다.
2. Docker Desktop Settings에서 WSL integration을 켠다.
3. 현재 Ubuntu distro가 integration 대상인지 확인한다.
4. WSL terminal을 새로 열고 `docker --version`, `docker compose version`, `docker info`를 다시 실행한다.

공식 문서:

- Docker Desktop WSL 2 backend: https://docs.docker.com/desktop/features/wsl/
- Docker Desktop Windows install: https://docs.docker.com/desktop/setup/install/windows-install/
- Docker Engine Ubuntu install: https://docs.docker.com/engine/install/ubuntu/

## Image

- Image name: `model-serving-fastapi:chapter-03`
- Base image: `python:3.12-slim`
- App port: `8000`
- Cache volume: `hf-cache:/root/.cache/huggingface`

## Expected Response

`curl http://127.0.0.1:8000/health` 예상 응답:

```json
{
  "status": "ok",
  "model": "sshleifer/tiny-gpt2",
  "model_loaded": true
}
```

`bash scripts/04_curl_generate.sh` 예상 응답 형태:

```json
{
  "model": "sshleifer/tiny-gpt2",
  "prompt": "Containerized model serving is",
  "generated_text": "Containerized model serving is ...",
  "latency_ms": 123.45
}
```

`generated_text`와 `latency_ms`는 실행할 때마다 달라질 수 있다.

## Observations

- 첫 실행은 model download 때문에 느릴 수 있다.
- `hf-cache` volume이 유지되면 두 번째 실행부터 model download 시간이 줄어든다.
- `docker images`로 image size를 확인할 수 있다.
- `docker ps`로 실행 중인 container를 확인할 수 있다.
- container 안에서 server는 `0.0.0.0:8000`으로 떠야 host에서 접근할 수 있다.

## Common Errors

- `docker: not found`: Docker CLI가 현재 shell에서 보이지 않는다.
- `Cannot connect to the Docker daemon`: Docker daemon이 실행 중이 아니거나 WSL integration이 꺼져 있을 수 있다.
- `Connection refused`: container가 실행 중이 아니거나 `-p 8000:8000` port mapping이 빠졌을 수 있다.
- 첫 요청이 느림: 모델을 처음 다운로드하거나 로딩 중일 수 있다.
- `--gpus all` 실패: NVIDIA Container Toolkit 또는 host GPU driver 설정을 확인해야 한다.

## Notes

- 이 챕터의 핵심은 Docker가 모델 서버 실행 환경을 image로 고정한다는 점이다.
- GPU container는 Docker만으로 되는 것이 아니라 host driver와 NVIDIA runtime 설정이 함께 필요하다.
