#!/usr/bin/env bash
set -euo pipefail

# OpenAI-compatible endpoint가 없을 때 챕터 4의 vLLM 서버를 다시 띄우는 안내 script다.
#
# 이 script는 서버를 직접 실행하지 않는다.
# vLLM은 GPU와 Docker image pull이 필요할 수 있어서 환경에 따라 실행 방식이 달라진다.
# 대신 "어느 챕터의 어떤 script를 실행하면 되는지"를 명확히 안내한다.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VLLM_CHAPTER="${ROOT_DIR}/chapters/04-vllm-intro"

cat <<EOF
## Prepare OpenAI-compatible endpoint

Langfuse 자체는 모델을 서빙하지 않는다.
vLLM, NIM, OpenAI API 같은 endpoint 호출 결과를 trace로 기록한다.

챕터 4 vLLM 서버를 다시 띄우려면:

cd ${VLLM_CHAPTER}
bash scripts/02_run_vllm_docker.sh

서버가 준비되었는지 확인:

cd ${VLLM_CHAPTER}
bash scripts/03_list_models.sh

챕터 9에서 사용할 환경변수 예:

cd ${ROOT_DIR}/chapters/09-langfuse-observability
export OPENAI_BASE_URL=http://127.0.0.1:8000/v1
export OPENAI_API_KEY=EMPTY
export OPENAI_MODEL=study-model

실제 served model name은 챕터 4의 --served-model-name 값과 맞춰야 한다.
EOF
