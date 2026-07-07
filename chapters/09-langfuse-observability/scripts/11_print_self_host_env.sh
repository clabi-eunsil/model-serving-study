#!/usr/bin/env bash
set -euo pipefail

# self-host Langfuse에 Python SDK를 연결할 때 필요한 환경변수 예시를 출력한다.
#
# public/secret key는 Langfuse UI에서 project를 만든 뒤 발급받아 채운다.

cat <<'EOF'
## Python SDK environment for self-hosted Langfuse

export LANGFUSE_HOST=http://localhost:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...

확인:
  DRY_RUN=false bash scripts/02_send_trace.sh

폐쇄망에서는 LANGFUSE_HOST가 내부망 주소가 될 수 있다.
예:
  export LANGFUSE_HOST=http://langfuse.internal.example:3000
EOF
