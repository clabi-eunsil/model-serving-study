"""Chapter 2 FastAPI application package.

이 파일은 `app/` 디렉터리를 Python package로 표시한다.
그래서 `uvicorn app.main:app` 명령에서 `app.main`을 안정적으로 import할 수 있다.

현재는 package가 처음 import될 때 실행해야 할 공통 초기화 코드가 없으므로
추가 로직은 넣지 않는다.
"""
