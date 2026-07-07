#!/usr/bin/env bash
set -euo pipefail

# 공식 Langfuse compose가 필요로 하는 container image 목록을 만든다.
#
# 폐쇄망에서는 인터넷이 되는 환경에서 image를 pull/save하고,
# 내부망 서버에서 docker load로 불러오는 절차가 필요하다.
# 이 script는 그때 필요한 image 목록을 results/langfuse-self-host-images.txt에 저장한다.

SELF_HOST_DIR="${SELF_HOST_DIR:-self-host/langfuse-official}"
OUTPUT="${OUTPUT:-results/langfuse-self-host-images.txt}"
ENV_FILE="${SELF_HOST_DIR}/.env"

if [[ ! -f "${SELF_HOST_DIR}/docker-compose.yml" ]]; then
  echo "Missing ${SELF_HOST_DIR}/docker-compose.yml"
  echo "Run: bash scripts/06_prepare_self_host_official.sh"
  exit 1
fi

mkdir -p "$(dirname "${OUTPUT}")"

if [[ -f "${ENV_FILE}" ]]; then
  docker compose --env-file "${ENV_FILE}" -f "${SELF_HOST_DIR}/docker-compose.yml" config --images | sort -u | tee "${OUTPUT}"
else
  docker compose -f "${SELF_HOST_DIR}/docker-compose.yml" config --images | sort -u | tee "${OUTPUT}"
fi

cat <<EOF

Image list saved to: ${OUTPUT}

폐쇄망 반입 예시:

1. 인터넷 가능 환경에서:
   while read -r image; do docker pull "\${image}"; done < ${OUTPUT}
   xargs -a ${OUTPUT} docker save -o langfuse-self-host-images.tar

2. 폐쇄망 서버에서:
   docker load -i langfuse-self-host-images.tar
EOF
