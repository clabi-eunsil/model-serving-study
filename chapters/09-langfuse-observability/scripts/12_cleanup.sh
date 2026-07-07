#!/usr/bin/env bash
set -euo pipefail

# 챕터 9 실습 마무리 안내.
#
# Langfuse Cloud를 사용했다면 끌 local process는 없다.
# vLLM endpoint를 챕터 4에서 띄웠다면 챕터 4의 stop script를 사용한다.

cat <<'EOF'
## Cleanup

1. self-host Langfuse를 띄웠다면:

bash scripts/10_stop_self_host.sh

2. vLLM server를 챕터 4에서 띄웠다면:

cd ../04-vllm-intro
bash scripts/07_collect_runtime_info.sh
bash scripts/08_stop_server.sh

3. 챕터 9 가상환경 종료:

cd ../09-langfuse-observability
deactivate

4. 결과 확인:

- Langfuse UI: traces, sessions, users
- Local CSV: results/prompt_comparison.csv
EOF
