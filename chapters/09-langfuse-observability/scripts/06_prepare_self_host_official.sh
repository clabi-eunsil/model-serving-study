#!/usr/bin/env bash
set -euo pipefail

# 공식 Langfuse repository를 받아 self-host Docker Compose 실습 디렉터리를 준비한다.
#
# 중요한 점:
# - Langfuse self-host compose는 Langfuse 버전에 따라 바뀔 수 있다.
# - 그래서 이 스터디 repo에 compose 파일을 복사해 고정하지 않고,
#   공식 repo의 docker-compose.yml을 기준으로 실습한다.
# - 폐쇄망에서는 인터넷이 되는 환경에서 이 script를 먼저 실행하거나,
#   공식 repo를 tar로 묶어 내부망으로 반입한다.

SELF_HOST_DIR="${SELF_HOST_DIR:-self-host/langfuse-official}"
LANGFUSE_REPO="${LANGFUSE_REPO:-https://github.com/langfuse/langfuse.git}"
LANGFUSE_VERSION="${LANGFUSE_VERSION:-main}"

mkdir -p "$(dirname "${SELF_HOST_DIR}")"

if [[ -d "${SELF_HOST_DIR}/.git" ]]; then
  echo "Langfuse repo already exists: ${SELF_HOST_DIR}"
else
  echo "Cloning Langfuse official repo..."
  git clone --depth 1 --branch "${LANGFUSE_VERSION}" "${LANGFUSE_REPO}" "${SELF_HOST_DIR}"
fi

cat <<EOF
Prepared: ${SELF_HOST_DIR}

Next:
  cd ${SELF_HOST_DIR}
  grep -n "CHANGEME" docker-compose.yml

공식 문서에 따르면 docker-compose.yml 안의 # CHANGEME secret은 반드시 바꿔야 한다.
학습용 local이라도 SALT, ENCRYPTION_KEY, NEXTAUTH_SECRET, DB/ClickHouse/Redis/MinIO secret은
긴 random 값으로 바꾸는 습관을 들이는 것이 좋다.
EOF
