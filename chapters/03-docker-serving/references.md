# References

Docker, Compose, NVIDIA Container Toolkit은 버전과 설치 환경에 따라 동작이 달라질 수 있다.
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 문서 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| Docker Desktop WSL 2 backend | https://docs.docker.com/desktop/features/wsl/ | WSL 터미널에서 Docker Desktop의 Docker daemon을 사용하는 구조와 WSL integration 설정을 본다. |
| Docker Desktop Windows install | https://docs.docker.com/desktop/setup/install/windows-install/ | Windows 환경에서 Docker Desktop을 설치하는 공식 절차를 본다. |
| Docker Engine Ubuntu install | https://docs.docker.com/engine/install/ubuntu/ | Ubuntu에 Docker Engine을 직접 설치하는 공식 절차를 본다. WSL에서 Docker Desktop을 쓰지 않을 때 참고한다. |
| Docker login CLI reference | https://docs.docker.com/reference/cli/docker/login/ | Docker Hub 또는 private registry에 인증하는 방법과 credential 저장 방식을 본다. |
| Dockerfile reference | https://docs.docker.com/reference/dockerfile/ | `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `CMD` 같은 Dockerfile instruction의 의미를 확인한다. |
| Docker bind mounts | https://docs.docker.com/engine/storage/bind-mounts/ | host directory를 container 안에 연결하는 방식과 주의점을 본다. |
| Docker volumes | https://docs.docker.com/engine/storage/volumes/ | container 재생성 후에도 데이터를 유지하는 volume 개념을 본다. |
| Docker Compose GPU support | https://docs.docker.com/compose/how-tos/gpu-support/ | Compose에서 GPU device reservation을 설정하는 방법을 본다. |
| NVIDIA Container Toolkit install guide | https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html | Docker container에서 NVIDIA GPU를 쓰기 위한 toolkit 설치와 runtime 설정을 본다. |
| NVIDIA NGC User Guide | https://docs.nvidia.com/ngc/latest/ngc-user-guide.html | `nvcr.io` registry에 Docker CLI로 login할 때 NGC API key와 `$oauthtoken` username을 사용하는 방식을 본다. |
| Hugging Face cache management | https://huggingface.co/docs/huggingface_hub/guides/manage-cache | Hugging Face model cache 위치와 관리 방식을 본다. |
| Hugging Face CLI authentication | https://huggingface.co/docs/huggingface_hub/en/guides/cli | private/gated model 접근에 필요한 `hf auth login`, `HF_TOKEN`, `hf auth whoami` 흐름을 본다. |

## 확인 필요 항목

- Docker Desktop WSL integration 여부는 사용자 환경마다 다르다.
- GPU container는 host driver, Docker version, NVIDIA Container Toolkit 설정에 영향을 받는다.
- CUDA image tag는 시간이 지나면 바뀔 수 있다.
- `torch` CPU/GPU build는 설치 방식에 따라 달라진다.
- Docker Hub rate limit, NGC 권한, Hugging Face gated model 정책은 계정/조직/시점에 따라 달라질 수 있다.
