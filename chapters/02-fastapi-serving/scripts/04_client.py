import requests


# 이 파일은 curl 대신 Python 코드로 /generate endpoint를 호출하는 예제다.
# 실제 서비스에서는 application code가 이런 방식으로 모델 서버를 호출하게 된다.

# FastAPI 서버에 보낼 JSON payload다.
# app/main.py의 GenerateRequest schema와 같은 필드를 가져야 한다.
payload = {
    "prompt": "Model serving is",
    "max_new_tokens": 24,
    "temperature": 0.7,
}

# 실행 중인 로컬 모델 서버에 HTTP POST 요청을 보낸다.
# json=payload를 쓰면 requests가 JSON 직렬화와 Content-Type header 설정을 처리한다.
response = requests.post(
    "http://127.0.0.1:8000/generate",
    json=payload,
    # 모델 로딩이나 첫 inference가 느릴 수 있으므로 timeout을 조금 넉넉하게 둔다.
    timeout=60,
)

# HTTP status code가 4xx/5xx면 예외를 발생시켜 실패를 바로 알 수 있게 한다.
response.raise_for_status()

# 성공하면 서버가 돌려준 JSON response를 출력한다.
# response에는 generated_text와 latency_ms가 들어 있다.
print(response.json())
