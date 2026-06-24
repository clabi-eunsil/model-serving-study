#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 FastAPI 모델 서버를 로컬에서 실행한다.
# 실행 전에는 현재 디렉터리가 chapters/02-fastapi-serving 이어야 한다.
#
# uvicorn app.main:app 의 의미:
# - app/main.py 파일을 import한다.
# - 그 파일 안에 있는 FastAPI 객체 app을 HTTP server에 연결한다.
# - app 생성 시 연결한 lifespan()이 실행되면서 모델이 로딩된다.
#
# 옵션:
# - --host 127.0.0.1: 내 컴퓨터에서만 접근 가능하게 실행한다.
# - --port 8000: http://127.0.0.1:8000 주소로 server를 연다.
# - --reload: 코드가 바뀌면 개발 중 자동 재시작한다.
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
