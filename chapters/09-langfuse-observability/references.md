# References

이 문서는 2026-07-07 기준 공식 문서를 바탕으로 작성했다. Langfuse SDK, self-hosting, prompt management, dataset/evaluation 기능은 업데이트될 수 있으므로 실습 전에 다시 확인한다.

| 문서 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| Langfuse Overview | https://langfuse.com/docs | Langfuse가 observability, prompt management, evaluation을 함께 제공하는 AI engineering platform이라는 큰 그림 |
| Langfuse SDKs / Python SDK | https://langfuse.com/docs/observability/sdk/overview | Python SDK v4, `get_client()`, context manager 방식의 span/generation 생성, `flush()` 필요성 |
| Langfuse Observability Overview | https://langfuse.com/docs/observability/overview | trace, session, user, latency/cost/usage dashboard를 어떤 관점으로 보는지 |
| Langfuse Prompt Management Get Started | https://langfuse.com/docs/prompt-management/get-started | prompt version, label, compile, trace와 prompt 연결 개념 |
| Langfuse Datasets | https://langfuse.com/docs/evaluation/experiments/datasets | dataset item, expected output, dataset versioning, experiment 재현성 |
| Langfuse Self-hosting | https://langfuse.com/self-hosting | Cloud와 self-hosting 선택, Docker Compose는 testing/low-scale deployment용이라는 설명 |
| Langfuse Docker Compose Deployment | https://langfuse.com/self-hosting/deployment/docker-compose | local/VM Docker Compose 요구사항, secret 변경, startup, scaling, shutdown, 폐쇄망 반입 준비 시 볼 기준 |
| OpenAI Chat Completions API | https://platform.openai.com/docs/api-reference/chat/create | OpenAI-compatible endpoint 요청/응답 구조를 비교할 때 참고 |
