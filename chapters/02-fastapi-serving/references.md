# References

최신 버전, 설치 방법, API 옵션, 모델 다운로드 방식은 업데이트될 수 있다.
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 문서 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| FastAPI documentation | https://fastapi.tiangolo.com/ | FastAPI가 Python type hint 기반 API framework이고, 자동 문서화와 Pydantic 기반 검증을 제공한다는 점을 본다. |
| FastAPI Request Body | https://fastapi.tiangolo.com/tutorial/body/ | Pydantic model로 request body를 정의하고 검증하는 방식을 본다. |
| FastAPI Response Model | https://fastapi.tiangolo.com/tutorial/response-model/ | response schema를 명확하게 정의하는 방식을 본다. |
| FastAPI Testing | https://fastapi.tiangolo.com/tutorial/testing/ | TestClient를 이용해 endpoint를 테스트하는 방식을 본다. |
| Uvicorn settings | https://www.uvicorn.org/settings/ | `--host`, `--port`, `--reload` 같은 실행 옵션을 본다. |
| Hugging Face Transformers pipelines | https://huggingface.co/docs/transformers/en/main_classes/pipelines | `pipeline("text-generation")`이 어떤 task abstraction인지 확인한다. |
| Hugging Face AutoTokenizer | https://huggingface.co/docs/transformers/en/model_doc/auto#transformers.AutoTokenizer | tokenizer를 자동으로 로딩하는 방식을 본다. |
| Hugging Face text generation | https://huggingface.co/docs/transformers/en/llm_tutorial | text generation에서 token, generation parameter가 어떤 의미인지 본다. |
| Pydantic documentation | https://docs.pydantic.dev/ | Python type annotation 기반 data validation 개념을 본다. |

## 확인 필요 항목

- FastAPI, Pydantic, Transformers는 버전 변화에 따라 import 방식이나 옵션이 바뀔 수 있다.
- Hugging Face model은 처음 실행할 때 인터넷에서 다운로드된다.
- `sshleifer/tiny-gpt2`는 실습용 작은 모델이며, 생성 품질을 평가하기 위한 모델이 아니다.
- GPU 사용 여부는 설치한 PyTorch build와 CUDA 환경에 따라 달라진다.
