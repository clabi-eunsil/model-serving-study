# 이 Dockerfile은 챕터 2의 FastAPI 모델 서버를 container image로 만든다.
# 목표는 내 로컬 .venv 없이도 같은 서버를 실행할 수 있게 만드는 것이다.

# Python 3.12가 포함된 작은 기본 image에서 시작한다.
# slim image는 비교적 작지만, 필요한 OS package가 적게 들어 있다.
FROM python:3.12-slim

# Python이 .pyc 파일과 stdout buffering으로 헷갈리는 상황을 줄인다.
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV MODEL_NAME=sshleifer/tiny-gpt2

# Hugging Face cache 위치를 명시한다.
# docker run에서 이 경로에 volume을 붙이면 model cache를 재사용할 수 있다.
ENV HF_HOME=/root/.cache/huggingface

# container 안의 작업 디렉터리다.
WORKDIR /app

# requirements를 먼저 복사한다.
# app 코드보다 dependency가 덜 자주 바뀌므로 Docker layer cache를 재사용하기 쉽다.
COPY requirements.txt .

# Python dependency를 image 안에 설치한다.
# --no-cache-dir는 pip cache를 image에 남기지 않아 image size를 줄이는 데 도움이 된다.
RUN pip install --no-cache-dir -r requirements.txt

# FastAPI application code를 container 안으로 복사한다.
COPY app ./app

# Docker Compose client 실습에 사용할 간단한 client code다.
# server-only 실행에서는 사용하지 않지만, 같은 image로 client container를 실행할 수 있게 둔다.
COPY client ./client

# 이 image가 8000 port를 사용한다는 문서 역할을 한다.
# 실제 host와 연결하려면 docker run에서 -p 8000:8000이 필요하다.
EXPOSE 8000

# container가 시작될 때 실행할 기본 명령이다.
# --host 0.0.0.0은 container 밖에서 접근 가능하게 하기 위해 필요하다.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
