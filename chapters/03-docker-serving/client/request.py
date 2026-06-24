import os
import time

import requests


# Docker Compose 안에서는 service 이름이 DNS 이름처럼 동작한다.
# docker-compose.yml에 service 이름을 "model-server"로 적어두었기 때문에,
# client container 안에서는 http://model-server:8000 으로 server를 찾을 수 있다.
#
# 주의:
# - host 터미널에서 호출할 때는 보통 http://127.0.0.1:8000 을 사용한다.
# - container끼리 호출할 때는 Compose network 내부 주소인 http://model-server:8000 을 사용한다.
# - MODEL_SERVER_URL 환경변수를 주면 다른 주소로도 바꿀 수 있다.
MODEL_SERVER_URL = os.getenv("MODEL_SERVER_URL", "http://model-server:8000")
SERVER_WAIT_SECONDS = int(os.getenv("SERVER_WAIT_SECONDS", "180"))
SERVER_WAIT_INTERVAL_SECONDS = int(os.getenv("SERVER_WAIT_INTERVAL_SECONDS", "3"))


def wait_for_server() -> None:
    # docker compose의 depends_on은 "container를 먼저 시작"하게 해줄 뿐,
    # FastAPI app이 완전히 뜨고 모델 로딩까지 끝났는지는 보장하지 않는다.
    #
    # 그래서 client는 /generate를 바로 호출하지 않고, 먼저 /health를 반복 호출한다.
    # /health 응답에서 model_loaded=true가 보이면 app/main.py의 startup 단계에서
    # Transformers pipeline이 준비되었다고 판단하고 다음 단계로 넘어간다.
    max_attempts = max(1, SERVER_WAIT_SECONDS // SERVER_WAIT_INTERVAL_SECONDS)
    for attempt in range(1, max_attempts + 1):
        try:
            # timeout을 두는 이유:
            # server가 아직 준비되지 않았거나 network 문제가 있을 때 client가 무한히 멈추지 않게 한다.
            response = requests.get(f"{MODEL_SERVER_URL}/health", timeout=5)
            if response.ok and response.json().get("model_loaded"):
                print("server is ready:", response.json())
                return
            print(
                "waiting for server "
                f"attempt={attempt}/{max_attempts}: "
                f"status_code={response.status_code}, body={response.text}"
            )
        except requests.RequestException as exc:
            # 처음 몇 번은 connection refused가 나올 수 있다.
            # server가 뜨는 중일 수 있으므로 바로 실패시키지 않고 잠깐 기다린다.
            print(f"waiting for server attempt={attempt}/{max_attempts}: {exc}")
        time.sleep(SERVER_WAIT_INTERVAL_SECONDS)

    raise RuntimeError(
        "model server did not become ready in time. "
        "Check server logs with: docker compose logs model-server"
    )


def main() -> None:
    # 1. server가 실제로 요청을 받을 수 있는 상태인지 먼저 확인한다.
    wait_for_server()

    # 2. app/main.py의 GenerateRequest schema와 같은 JSON payload를 만든다.
    #
    # prompt: 모델에게 넣을 입력 문장
    # max_new_tokens: 새로 생성할 token의 최대 개수
    # temperature: 생성 결과의 무작위성 정도. 값이 높을수록 더 다양해질 수 있다.
    payload = {
        "prompt": "Compose client says model serving is",
        "max_new_tokens": 24,
        "temperature": 0.7,
    }

    # 3. FastAPI의 /generate endpoint로 POST 요청을 보낸다.
    #
    # json=payload를 쓰면 requests가 자동으로 JSON 직렬화와
    # Content-Type: application/json header 설정을 처리한다.
    response = requests.post(
        f"{MODEL_SERVER_URL}/generate",
        json=payload,
        timeout=60,
    )

    # 4xx/5xx 응답이면 예외를 발생시켜 실습 실패를 바로 알 수 있게 한다.
    response.raise_for_status()

    # 4. server가 돌려준 GenerateResponse JSON을 출력한다.
    # 예상 key는 generated_text, latency_seconds, input_tokens, output_tokens 등이다.
    print(response.json())


if __name__ == "__main__":
    # Python 파일을 직접 실행했을 때만 main()을 호출한다.
    # 다른 파일에서 import할 때는 자동 실행되지 않는다.
    main()
