# 3. Docker 기반 모델 서빙

이 단원에서는 챕터 2에서 만든 FastAPI 모델 서버를 Docker image로 만든다.  
목표는 "내 컴퓨터의 Python 환경"에 의존하지 않고, 같은 모델 서버를 container로 실행하는 흐름을 이해하는 것이다.

## 학습 목표

- 모델 서버용 Dockerfile 구조를 이해한다.
- Python dependency와 model cache를 분리하는 이유를 이해한다.
- CPU container와 GPU container 실행 차이를 구분한다.
- NVIDIA Container Toolkit이 왜 필요한지 설명할 수 있다.
- Docker volume 또는 bind mount로 Hugging Face model cache를 관리하는 방법을 이해한다.
- Docker Compose로 모델 서버를 실행하고 호출한다.
- image size를 확인하고 줄일 수 있는 지점을 찾는다.


## 실행 환경 기준

이 챕터는 host의 `.venv`를 사용하지 않는다.
Python, FastAPI, Transformers, Torch dependency는 Docker image 안에 설치한다.

즉, 챕터 2에서는:

```bash
source .venv/bin/activate
python scripts/04_client.py
```

처럼 host Python 가상환경을 사용했지만, 챕터 3에서는:

```bash
bash scripts/02_build_image.sh
bash scripts/03_run_container.sh
```

처럼 Docker image와 container가 실행 환경이 된다.

단, Docker CLI 자체는 host 또는 WSL shell에서 실행해야 하므로 `bash scripts/01_check_env.sh`로 Docker 연결 상태를 먼저 확인한다.

## 챕터 2 코드와의 차이

이 챕터의 [app/main.py](app/main.py)는 챕터 2의 FastAPI app을 거의 그대로 사용한다.
endpoint 구조, Pydantic schema, model loading 방식, `/health`, `/generate`, `/metrics`는 동일하다.

다른 점은 모델 이름을 정하는 부분이다.

챕터 2:

```python
MODEL_NAME = "sshleifer/tiny-gpt2"
```

챕터 3:

```python
MODEL_NAME = os.getenv("MODEL_NAME", "sshleifer/tiny-gpt2")
```

Docker에서는 container 실행 시 환경변수로 설정을 바꾸는 일이 많다.
그래서 챕터 3에서는 `MODEL_NAME` 환경변수를 읽고, 값이 없으면 기본값으로 `sshleifer/tiny-gpt2`를 사용하게 했다.
즉, 모델 서버의 핵심 동작은 챕터 2와 같고, Docker 실행 환경에 맞게 설정 주입 방식만 바뀌었다.

## 핵심 개념 요약

### Docker Image

Docker image는 application 실행에 필요한 파일, dependency, 실행 명령을 묶은 package다.
이번 챕터에서는 Python, FastAPI app, requirements, 실행 명령을 하나의 image로 만든다.

### Container

Container는 image를 실행한 프로세스다.
image가 "실행 가능한 묶음"이라면, container는 "실제로 실행 중인 인스턴스"다.

### Dockerfile

Dockerfile은 image를 만드는 방법을 적은 파일이다.
`FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `CMD` 같은 instruction으로 구성된다.

### Port Mapping

container 안에서 FastAPI는 `8000` port로 열린다.
host에서 접근하려면 `-p 8000:8000`처럼 host port와 container port를 연결해야 한다.

### Model Cache

Hugging Face model은 처음 실행할 때 다운로드된다.
container를 매번 새로 만들 때마다 모델을 다시 받으면 느리고 비효율적이다.
그래서 Docker volume을 `/root/.cache/huggingface`에 붙여 model cache를 재사용한다.

### CPU Container vs GPU Container

CPU container는 Docker만 있으면 실행할 수 있다.
GPU container는 host에 NVIDIA driver가 있고, Docker가 GPU를 container에 전달할 수 있어야 한다.
이때 NVIDIA Container Toolkit이 필요하다.

## 이 단원에서 반드시 가져갈 정리

### 1. Docker는 Python 환경을 image 안에 고정한다

챕터 2에서는 `.venv`를 만들고 직접 `pip install`을 했다.
Docker에서는 이런 실행 환경을 image build 단계에 넣는다.
그래서 다른 컴퓨터에서도 같은 image를 실행하면 비슷한 환경으로 서버를 띄울 수 있다.

### 2. Dockerfile은 실행 순서가 중요하다

이번 Dockerfile은 먼저 `requirements.txt`를 복사하고 dependency를 설치한 뒤, app 코드를 복사한다.
이렇게 하면 app 코드만 바뀌었을 때 dependency install layer를 재사용할 수 있다.

### 3. container 안의 `127.0.0.1`과 host의 `127.0.0.1`은 다르다

FastAPI를 container 안에서만 `127.0.0.1`로 열면 host에서 접근하기 어렵다.
그래서 container에서는 `--host 0.0.0.0`으로 모든 interface에서 요청을 받게 하고, Docker의 `-p`로 host port를 연결한다.

### 4. model cache는 image에 넣을 수도 있고 volume으로 분리할 수도 있다

처음에는 volume으로 분리하는 방식을 쓴다.
image 안에 모델 weight를 넣으면 image가 커지고 build 시간이 길어진다.
반대로 volume cache를 쓰면 첫 실행은 느리지만, 이후 실행은 cache를 재사용할 수 있다.

### 5. GPU container는 Docker만으로 끝나지 않는다

`docker run --gpus all ...`을 쓰려면 host의 NVIDIA driver와 NVIDIA Container Toolkit 설정이 필요하다.
현재 WSL 환경에서 `nvidia-smi`가 보이지 않는다면 GPU container 실습은 나중에 환경을 정리한 뒤 진행한다.

## 코드 워크스루

### 1. Dockerfile

[Dockerfile](Dockerfile)은 image를 만드는 방법을 정의한다.

```dockerfile
FROM python:3.12-slim
```

Python 3.12가 들어 있는 작은 Debian 기반 image에서 시작한다.

```dockerfile
WORKDIR /app
```

container 안의 작업 디렉터리를 `/app`으로 정한다.
이후 `COPY`, `RUN`, `CMD`는 기본적으로 이 위치를 기준으로 실행된다.

```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

Python dependency를 먼저 설치한다.
`--no-cache-dir`는 pip download cache를 image에 남기지 않아 image size를 줄이는 데 도움이 된다.

```dockerfile
COPY app ./app
```

FastAPI app 코드를 container 안의 `/app/app`으로 복사한다.

```dockerfile
EXPOSE 8000
```

이 image가 8000 port를 사용한다는 문서 역할을 한다.
실제 host 연결은 `docker run -p 8000:8000`이 담당한다.

```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

container가 시작될 때 FastAPI server를 실행한다.
`--host 0.0.0.0`은 container 밖에서 접근할 수 있게 하기 위해 필요하다.

### 2. docker-compose.yml

[docker-compose.yml](docker-compose.yml)은 여러 Docker 실행 옵션을 YAML로 기록한 파일이다.
이번 챕터에서는 model server 하나만 실행하지만, 나중에는 server, client, monitoring을 함께 띄울 때 유용하다.

### 3. docker run과 Docker Compose의 차이

이번 실습에서는 같은 FastAPI 모델 서버를 두 가지 방식으로 실행한다.

첫 번째 방식은 `docker build`와 `docker run`을 직접 사용하는 방식이다.
이 방식은 image build, container 이름, port mapping, volume, 환경변수를 명령어로 직접 지정한다.

```bash
bash scripts/02_build_image.sh
bash scripts/03_run_container.sh
```

두 번째 방식은 Docker Compose를 사용하는 방식이다.
Compose는 `docker run`에 길게 적던 실행 설정을 [docker-compose.yml](docker-compose.yml)에 적어두고 실행한다.

```bash
docker compose up --build
```

이번 챕터에서는 container가 하나뿐이라 결과만 보면 두 방식이 거의 같아 보인다.
하지만 차이는 "서버가 어떻게 뜨느냐"가 아니라 "실행 설정을 어디에 기록하느냐"에 있다.

| 관점 | `docker build` + `docker run` | `docker compose up --build` |
| --- | --- | --- |
| 실행 방식 | 명령어에 옵션을 직접 적는다 | YAML 파일에 설정을 선언한다 |
| image build | `docker build -t ... .` | `build:` 설정과 `--build` 옵션으로 처리 |
| container 이름 | `--name model-serving-fastapi` | `container_name: model-serving-fastapi` |
| port mapping | `-p 8000:8000` | `ports: ["8000:8000"]` |
| model cache | `-v hf-cache:/root/.cache/huggingface` | `volumes:` 설정 |
| 환경변수 | `-e MODEL_NAME=...` | `environment:` 설정 |
| 여러 service 실행 | 명령이 길어지고 관리가 어려워진다 | server, client, DB, monitoring을 함께 관리하기 쉽다 |
| 실습에서 좋은 점 | Docker 동작을 단계별로 이해하기 좋다 | 반복 실행과 팀 공유가 쉽다 |

정리하면, 처음 배울 때는 `docker build`와 `docker run`을 직접 실행해보는 것이 좋다.
그러면 image, container, port, volume이 각각 무엇인지 분리해서 볼 수 있다.
그 다음 Compose를 보면 "아, 이 긴 실행 옵션들을 YAML로 저장한 것이구나"라고 이해하기 쉽다.

### 4. scripts

- [scripts/01_check_env.sh](scripts/01_check_env.sh): Docker CLI, Compose, NVIDIA runtime 상태를 확인한다.
- [scripts/02_build_image.sh](scripts/02_build_image.sh): Docker image를 build한다.
- [scripts/03_run_container.sh](scripts/03_run_container.sh): CPU container를 실행한다.
- [scripts/04_curl_generate.sh](scripts/04_curl_generate.sh): container 안의 모델 서버를 호출한다.
- [scripts/05_compose_client.sh](scripts/05_compose_client.sh): Docker Compose로 server/client를 함께 실행한다.
- [scripts/06_image_size.sh](scripts/06_image_size.sh): image size와 큰 layer를 확인한다.
- [scripts/07_run_container_gpu.sh](scripts/07_run_container_gpu.sh): GPU container를 실행한다. GPU 환경이 준비된 경우에만 사용한다.
- [scripts/08_remote_gpu_checklist.sh](scripts/08_remote_gpu_checklist.sh): 원격 GPU 서버에서 Docker/GPU 상태를 확인한다.

## 실습

### 1. Docker 환경 확인

```bash
cd ~/study/model-serving/chapters/03-docker-serving
bash scripts/01_check_env.sh
```

Docker가 보이지 않으면 먼저 Docker Desktop WSL integration 또는 Docker Engine 설치 상태를 확인해야 한다.

#### Docker가 없을 때 설치/연결 방법

현재 환경이 WSL이라면 추천 경로는 Docker Desktop for Windows를 설치하고 WSL integration을 켜는 것이다.

1. Windows에 Docker Desktop을 설치한다.
2. Docker Desktop Settings에서 WSL integration을 활성화한다.
3. 사용하는 WSL distro, 예를 들어 Ubuntu를 integration 대상으로 켠다.
4. WSL 터미널을 새로 열고 아래 명령을 확인한다.

```bash
docker --version
docker compose version
docker info
```

Ubuntu Linux에 Docker Engine을 직접 설치하는 방식도 가능하다.
다만 WSL + Docker Desktop을 쓰는 경우와 Docker Engine을 WSL 안에 직접 설치하는 경우가 섞이면 헷갈릴 수 있으므로, 이 스터디에서는 우선 Docker Desktop WSL integration 방식을 권장한다.

공식 문서:

- Docker Desktop WSL 2 backend: https://docs.docker.com/desktop/features/wsl/
- Docker Desktop Windows install: https://docs.docker.com/desktop/setup/install/windows-install/
- Docker Engine Ubuntu install: https://docs.docker.com/engine/install/ubuntu/

### 2. Image build

```bash
bash scripts/02_build_image.sh
```

예상 결과:

```text
Successfully tagged model-serving-fastapi:chapter-03
```

### 3. CPU container 실행

터미널 1에서 실행한다.

```bash
bash scripts/03_run_container.sh
```

### 4. 서버 호출

터미널 2에서 실행한다.

```bash
curl http://127.0.0.1:8000/health
bash scripts/04_curl_generate.sh
curl http://127.0.0.1:8000/metrics
```

### 5. Container 종료

터미널 1에서:

```text
Ctrl + C
```

또는 다른 터미널에서:

```bash
docker stop model-serving-fastapi
```

### 6. Docker Compose로 실행

이 단계는 앞에서 실행한 `02_build_image.sh` + `03_run_container.sh`와 비슷한 결과를 만든다.
차이는 실행 설정을 명령어가 아니라 [docker-compose.yml](docker-compose.yml)에 기록해 둔다는 점이다.
실제로는 `build`, `image`, `container_name`, `ports`, `volumes`, `environment` 설정이 `docker build`와 `docker run` 옵션을 대신한다.

```bash
docker compose up --build
```

다른 터미널에서:

```bash
bash scripts/04_curl_generate.sh
```

종료:

```bash
docker compose down
```

### 7. Docker Compose로 server/client 구성

앞 단계의 Compose 실행은 server만 띄우고 host 터미널에서 `curl`로 호출했다.
이번 단계에서는 Compose 안에 `model-client` service를 추가해서, client container가 server container를 호출하게 만든다.

```bash
bash scripts/05_compose_client.sh
```

이때 통신 경로는 host의 `127.0.0.1:8000`이 아니라 Compose network 내부의 `http://model-server:8000`이다.
즉, container끼리는 service 이름으로 서로를 찾는다.

처음 실행할 때는 model download와 loading 때문에 시간이 걸릴 수 있다.
`Connection refused`가 1-2번 보이는 것은 server가 아직 요청을 받을 준비가 되지 않았다는 뜻일 수 있다.
다만 계속 준비되지 않으면 script가 최근 `model-server` log를 출력한다.

직접 확인하고 싶을 때:

```bash
docker compose ps
docker compose logs -f model-server
curl http://127.0.0.1:8000/health
```

대기 시간을 더 늘리고 싶으면:

```bash
SERVER_WAIT_SECONDS=300 bash scripts/05_compose_client.sh
```

실습 후 server를 정리한다.

```bash
docker compose down
```

### 8. Container image size 확인과 줄이기 실험

이 실습은 container를 실행하는 실습이라기보다, 완성된 Docker image를 분석하는 실습이다.
모델 서버 image는 일반 web server image보다 커지기 쉽다.
`torch`, `transformers` 같은 dependency가 크고, model weight까지 image에 넣으면 build, push, pull 시간이 모두 길어진다.

그래서 운영에서는 image size를 보는 습관이 중요하다.
image size를 줄이려면 먼저 어떤 image와 layer가 큰지 확인해야 한다.

실행 전 확인:

- [Dockerfile](Dockerfile)에서 `RUN pip install --no-cache-dir -r requirements.txt` 부분을 찾는다.
- [.dockerignore](.dockerignore)에서 `.venv`, `__pycache__`, cache 파일을 제외하는지 확인한다.
- [scripts/03_run_container.sh](scripts/03_run_container.sh)에서 `-v hf-cache:/root/.cache/huggingface` 부분을 찾는다.
- 위 volume mount 때문에 model weight는 image 안에 굽지 않고, container 실행 중 cache volume에 저장된다.

실행:

```bash
bash scripts/06_image_size.sh
```

출력에서 확인할 것:

| 출력 | 의미 | 확인할 질문 |
| --- | --- | --- |
| `docker images` | local Docker에 저장된 image의 전체 크기 | `model-serving-fastapi:chapter-03`가 얼마나 큰가? |
| `docker image inspect ... .Size` | image size를 bytes 단위로 출력 | 이후 실험 전후 크기를 숫자로 비교할 수 있는가? |
| `docker history` | Dockerfile instruction별 layer 크기 | 어떤 instruction이 가장 큰 layer를 만들었는가? |
| `RUN pip install ...` layer | Python dependency 설치 결과 | `torch`, `transformers` 때문에 커졌는가? |
| `COPY app ./app` layer | application code 복사 결과 | app code 자체는 비교적 작은가? |

중요한 해석:

- image size가 크다고 무조건 나쁜 것은 아니다. 모델 서빙에서는 ML dependency 때문에 어느 정도 커질 수 있다.
- 다만 사용하지 않는 package가 들어가 있거나, model weight를 image 안에 넣으면 운영 비용이 커진다.
- `docker history`에서 큰 layer를 찾으면 Dockerfile의 어느 줄을 개선해야 하는지 감이 생긴다.
- model weight는 image에 포함할 수도 있지만, 이 챕터에서는 `hf-cache` volume으로 분리한다.
- volume으로 분리하면 첫 실행 때는 다운로드가 필요하지만, 이후 실행에서는 cache를 재사용할 수 있다.

이번 Dockerfile에서 이미 적용한 줄이기 포인트:

- `.dockerignore`로 `.venv`, `__pycache__`, cache 파일 제외
- `pip install --no-cache-dir` 사용
- model weight를 image 안에 넣지 않고 `hf-cache` volume으로 분리
- `requirements.txt`를 app code보다 먼저 복사해 Docker layer cache 재사용

더 줄일 수 있는 방향:

- 사용하지 않는 package를 `requirements.txt`에서 제거
- CPU/GPU 용도에 맞는 base image와 PyTorch build 선택
- 운영 image와 개발 image를 분리
- 모델 weight를 image에 포함하지 않고 외부 volume/cache로 관리

실습 기록에 남길 것:

- `docker images`에서 확인한 image size
- `docker image inspect`에서 확인한 bytes 값
- `docker history`에서 가장 커 보이는 layer
- image size를 줄이려면 가장 먼저 손볼 것 같은 파일 또는 dependency

### 9. GPU container 선택 실습

#### 원격 GPU 서버에서 실행하는 경우

로컬에 GPU가 없고 별도의 GPU 서버가 있다면, 실습은 그 서버 안에서 진행한다.
로컬에서 container를 실행하는 것이 아니라, SSH로 GPU 서버에 접속한 뒤 해당 서버에서 `docker build`, `docker run --gpus all`을 실행하는 방식이다.

전체 흐름:

```text
로컬의 챕터 3 디렉터리
→ GPU 서버로 챕터 3 디렉터리만 복사
→ GPU 서버에 SSH 접속
→ GPU 서버에서 Docker/GPU 확인
→ GPU 서버에서 image build
→ GPU 서버에서 container 실행
→ GPU 서버 안에서 curl로 확인하거나 SSH port forwarding으로 로컬에서 확인
```

1. 로컬에서 GPU 서버로 챕터 3 디렉터리만 복사

GPU 서버에서는 이 챕터만 있으면 된다.
`model-serving` 전체를 복사하지 않아도 Docker build에 필요한 파일은 [chapters/03-docker-serving](.) 안에 모두 들어 있다.

예시 1: `scp`

```bash
scp -r ~/study/model-serving/chapters/03-docker-serving user@gpu-server:~/docker-serving
```

예시 2: `rsync`

```bash
rsync -av ~/study/model-serving/chapters/03-docker-serving/ user@gpu-server:~/docker-serving/
```

Git repository로 관리하고 있고 전체 repo를 이미 GPU 서버에 받아둔 상태라면 `git pull`을 써도 된다.
하지만 이 챕터만 실습할 목적이라면 챕터 3 디렉터리만 복사하는 편이 더 가볍다.

2. GPU 서버 접속

```bash
ssh user@gpu-server
cd ~/docker-serving
```

3. GPU 서버 환경 확인

```bash
bash scripts/08_remote_gpu_checklist.sh
nvidia-smi
docker --version
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

4. GPU 서버에서 image build

```bash
bash scripts/02_build_image.sh
```

5. GPU container 실행

```bash
bash scripts/07_run_container_gpu.sh
```

6. GPU 서버 안에서 바로 확인

새 SSH 터미널을 하나 더 열거나, 같은 서버의 다른 terminal session에서 실행한다.

```bash
curl http://127.0.0.1:8000/health
bash scripts/04_curl_generate.sh
curl http://127.0.0.1:8000/metrics
```

7. 로컬 브라우저/터미널에서 확인하고 싶을 때

GPU 서버가 외부에 8000 port를 열지 않아도, SSH port forwarding으로 로컬에서 접근할 수 있다.
로컬 터미널에서 아래처럼 실행한다.

```bash
ssh -L 8000:127.0.0.1:8000 user@gpu-server
```

그 상태에서 로컬의 다른 터미널에서:

```bash
curl http://127.0.0.1:8000/health
```

주의:

- cloud/security group/firewall에서 8000 port를 직접 열 필요는 없다. 우선 SSH port forwarding을 권장한다.
- GPU 서버에 Docker가 설치되어 있고, 현재 user가 Docker를 실행할 권한이 있어야 한다.
- `nvidia-smi`는 host GPU 확인이고, `docker run --gpus all ... nvidia-smi`는 container 안에서 GPU가 보이는지 확인하는 것이다.
- 이 챕터의 기본 image는 로컬 build image이므로 Docker login이 필수는 아니다.

#### Docker login이 필요한 경우

이 챕터의 기본 실습은 Docker login 없이 진행할 수 있다.
우리가 만드는 `model-serving-fastapi:chapter-03` image는 로컬에서 직접 build하고, 실습 모델 `sshleifer/tiny-gpt2`도 public Hugging Face model이다.

다만 아래 경우에는 login이나 token이 필요할 수 있다.

| 상황 | 필요한 인증 |
| --- | --- |
| Docker Hub pull rate limit에 걸리거나 private image를 pull/push할 때 | `docker login` |
| NGC registry, 예: `nvcr.io/...` image를 pull할 때 | `docker login nvcr.io --username '$oauthtoken'` 후 NGC API key 입력 |
| Hugging Face private/gated model을 container 안에서 받을 때 | Hugging Face token, 보통 `HF_TOKEN` 환경변수 |
| 회사/private registry image를 pull할 때 | 해당 registry의 `docker login <registry>` |

Docker Hub login:

```bash
docker login
```

NGC registry login:

```bash
docker login nvcr.io --username '$oauthtoken'
```

위 명령을 실행하면 password 입력 prompt가 나오고, 여기에 NGC API key를 입력한다.
API key를 명령어에 직접 쓰면 shell history에 남을 수 있으므로 피한다.

Hugging Face gated model을 쓸 때는 host에서 token을 환경변수로 둔 뒤 container에 넘긴다.

```bash
export HF_TOKEN=hf_xxx
docker run --rm \
  -p 8000:8000 \
  -v hf-cache:/root/.cache/huggingface \
  -e MODEL_NAME=meta-llama/Some-Gated-Model \
  -e HF_TOKEN="$HF_TOKEN" \
  model-serving-fastapi:chapter-03
```

이 챕터에서는 secret을 script에 저장하지 않는다.
token은 terminal session 환경변수나 secret manager를 사용한다.

#### GPU 서버에서 확인할 순서

GPU가 Docker에서 보이는지 먼저 확인한다.

```bash
nvidia-smi
docker --version
docker info
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

성공하면:

```bash
bash scripts/07_run_container_gpu.sh
```

실패하면 NVIDIA driver, Docker GPU support, NVIDIA Container Toolkit 설정을 확인해야 한다.

## 실습 마무리

챕터 3 실습이 끝나면 실행 방식에 따라 아래 항목을 정리한다.

### docker run 방식으로 실행한 경우

터미널 1에서 container를 실행 중이라면:

```text
Ctrl + C
```

다른 터미널에서 종료하려면:

```bash
docker stop model-serving-fastapi
```

실행 중인 container가 남아 있는지 확인한다.

```bash
docker ps
```

### Docker Compose로 실행한 경우

Compose로 실행했다면 아래 명령으로 container와 network를 정리한다.

```bash
docker compose down
```

named volume인 `hf-cache`는 기본적으로 유지된다.
모델 cache까지 지우고 싶을 때만 아래 명령을 사용한다.

```bash
docker volume rm docker-serving_hf-cache
```

volume 이름은 환경에 따라 다를 수 있으므로 먼저 확인한다.

```bash
docker volume ls
```

### 원격 GPU 서버에서 실행한 경우

GPU 서버에서 container를 종료한다.

```bash
docker stop model-serving-fastapi-gpu
```

SSH port forwarding을 사용했다면 로컬의 forwarding 터미널도 종료한다.

```text
Ctrl + C
```

GPU 서버에서 실행 상태를 확인한다.

```bash
docker ps
nvidia-smi
```

### 결과 정리

[templates/lab-notes.md](templates/lab-notes.md)의 아래 항목을 실제 실행 결과와 비교한다.

- Environment
- Docker Run vs Docker Compose
- Registry Login Notes
- Remote GPU Server Notes
- Expected Response
- Observations
- Common Errors

다음 챕터로 넘어가기 전 확인:

- `docker build` 또는 `docker compose up --build`가 성공했는가?
- `/health`에서 `model_loaded: true`를 확인했는가?
- `/generate` 호출이 성공했는가?
- `docker ps`에서 불필요한 container가 남아 있지 않은가?
- 유지할 volume과 삭제할 volume을 구분했는가?
- 원격 서버를 사용했다면 SSH port forwarding을 종료했는가?

## 확인 질문

| 질문 | 정리 방향 |
| --- | --- |
| Docker image와 container의 차이는 무엇인가? | image는 실행 가능한 package이고, container는 image를 실제로 실행한 프로세스다. |
| Dockerfile에서 `COPY requirements.txt`를 먼저 하는 이유는 무엇인가? | dependency layer cache를 재사용해 app 코드만 바뀐 경우 build 시간을 줄이기 위해서다. |
| container 안에서 `--host 0.0.0.0`을 쓰는 이유는 무엇인가? | host에서 port mapping을 통해 container server에 접근할 수 있게 하기 위해서다. |
| `-p 8000:8000`은 무엇을 하는가? | host의 8000 port를 container의 8000 port로 연결한다. |
| Hugging Face cache volume을 쓰는 이유는 무엇인가? | 모델 다운로드 결과를 재사용해 container 재실행 시 시간을 줄이기 위해서다. |
| GPU container 실행에 Docker 외에 필요한 것은 무엇인가? | host NVIDIA driver와 NVIDIA Container Toolkit 설정이 필요하다. |

## 실습 기록

기준 기록은 [templates/lab-notes.md](templates/lab-notes.md)에 미리 정리해 두었다.
실행 후 실제 결과가 예시와 어떻게 다른지만 비교하면 된다.

## 다음 챕터에서 이어질 내용

다음 챕터에서는 Docker로 감싼 서버 대신 vLLM을 사용해 LLM serving에 특화된 server를 실행한다.
OpenAI-compatible API와 streaming 응답도 함께 확인한다.
