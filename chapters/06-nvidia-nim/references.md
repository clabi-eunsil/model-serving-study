# References

NVIDIA NIM은 지원 모델, image tag, license, 실행 옵션이 바뀔 수 있다.
실습 전 공식 문서와 NGC catalog를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| NVIDIA NIM for LLMs | https://docs.nvidia.com/nim/large-language-models/latest/introduction.html | NIM의 목적, 지원 범위, LLM NIM 개념 |
| NIM Getting Started | https://docs.nvidia.com/nim/large-language-models/latest/getting-started.html | NIM container 실행 흐름, API 호출 예시 |
| NIM APIs | https://docs.nvidia.com/nim/large-language-models/latest/api-reference.html | OpenAI-compatible endpoint와 request/response |
| NGC Catalog | https://catalog.ngc.nvidia.com/ | NIM image, model, license, tag, 실행 방법 확인 |
| NGC User Guide | https://docs.nvidia.com/ngc/gpu-cloud/ngc-user-guide/index.html | NGC account, API key, registry 사용 |
| NVIDIA Container Toolkit | https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html | Docker container에서 NVIDIA GPU 사용 설정 |

## 업데이트 가능성이 큰 정보

- NIM image repository와 tag
- NIM별 지원 GPU와 memory 요구사항
- model license와 사용 조건
- NGC API key 발급 UI와 절차
- NIM container 환경변수와 cache path
- OpenAI-compatible API 세부 field
