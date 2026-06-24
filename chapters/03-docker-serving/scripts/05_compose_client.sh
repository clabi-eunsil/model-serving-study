#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 Docker Compose로 model server와 client를 함께 실행하는 실습이다.
#
# 지금까지의 흐름:
# - scripts/02_build_image.sh 는 image를 만든다.
# - scripts/03_run_container.sh 는 docker run으로 server container 하나를 실행한다.
# - scripts/04_curl_generate.sh 는 host 터미널에서 127.0.0.1:8000으로 server를 호출한다.
#
# 이 스크립트에서 새로 보는 것:
# - docker-compose.yml에 정의된 model-server service를 background로 실행한다.
# - docker-compose.yml에 정의된 model-client service를 1회성 client container로 실행한다.
# - client container는 같은 Compose network 안에서 http://model-server:8000으로 server를 호출한다.
#
# 이 실습의 핵심:
# - host에서는 127.0.0.1:8000 으로 접근한다.
# - Compose 내부 service끼리는 service 이름인 model-server로 접근한다.
# - "server container가 떠 있다"와 "server가 요청을 받을 준비가 됐다"는 다르다.
#   그래서 client/request.py는 /health를 먼저 반복 확인한 뒤 /generate를 호출한다.

SERVER_URL="${SERVER_URL:-http://127.0.0.1:8000}"
SERVER_WAIT_SECONDS="${SERVER_WAIT_SECONDS:-180}"
SERVER_WAIT_INTERVAL_SECONDS="${SERVER_WAIT_INTERVAL_SECONDS:-3}"

# 1. model-server service를 먼저 실행한다.
#
# --build:
#   Dockerfile 또는 app 코드가 바뀌었을 수 있으므로 image를 다시 build한다.
# -d:
#   detached mode. server container를 background에서 계속 실행한다.
# model-server:
#   docker-compose.yml에 있는 service 이름이다.
docker compose up --build -d model-server

# 2. host에서 먼저 model-server의 /health를 확인한다.
#
# 왜 client 실행 전에 여기서 한 번 더 기다릴까?
# - docker compose up -d는 "container process를 시작했다"는 뜻이지,
#   FastAPI app과 model loading이 끝났다는 뜻은 아니다.
# - model-server가 아직 startup 중이면 client container는 connection refused를 볼 수 있다.
# - 여기서 server 상태를 먼저 확인하면, 진짜 문제인지 단순 대기인지 구분하기 쉽다.
#
# 실패 시 docker compose logs model-server를 출력해서 원인 확인으로 바로 이어지게 한다.
echo "waiting for model-server health at ${SERVER_URL}/health"
max_attempts=$((SERVER_WAIT_SECONDS / SERVER_WAIT_INTERVAL_SECONDS))
if [[ "${max_attempts}" -lt 1 ]]; then
  max_attempts=1
fi

server_ready="false"
for attempt in $(seq 1 "${max_attempts}"); do
  if health_response="$(curl -fsS "${SERVER_URL}/health" 2>/dev/null)"; then
    echo "health attempt=${attempt}/${max_attempts}: ${health_response}"
    if [[ "${health_response}" == *'"model_loaded":true'* || "${health_response}" == *'"model_loaded": true'* ]]; then
      server_ready="true"
      break
    fi
  else
    echo "health attempt=${attempt}/${max_attempts}: server is not accepting requests yet"
  fi
  sleep "${SERVER_WAIT_INTERVAL_SECONDS}"
done

if [[ "${server_ready}" != "true" ]]; then
  echo
  echo "model-server did not become ready within ${SERVER_WAIT_SECONDS}s."
  echo "Recent model-server logs:"
  docker compose logs --tail 80 model-server
  exit 1
fi

# 3. model-client service를 1회 실행한다.
#
# --profile client:
#   docker-compose.yml의 model-client는 profiles: ["client"] 아래에 있다.
#   profile을 켜야 평소 server만 띄울 때 client까지 자동 실행되지 않는다.
# run:
#   long-running service가 아니라 "한 번 실행하고 끝나는 작업"을 실행할 때 쓴다.
# --rm:
#   client container가 종료되면 container 기록을 남기지 않고 삭제한다.
docker compose --profile client run --rm \
  -e SERVER_WAIT_SECONDS="${SERVER_WAIT_SECONDS}" \
  -e SERVER_WAIT_INTERVAL_SECONDS="${SERVER_WAIT_INTERVAL_SECONDS}" \
  model-client

echo
echo "client run complete."
echo "server is still running. Stop it with: docker compose down"
