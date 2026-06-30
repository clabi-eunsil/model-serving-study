#!/usr/bin/env bash
set -euo pipefail

# NGC container registry에 로그인한다.
#
# NIM image는 보통 nvcr.io registry에서 pull한다.
# 이 registry 접근에는 NGC API key가 필요할 수 있다.
#
# 중요한 보안 습관:
# - API key를 script에 직접 적지 않는다.
# - API key를 command line 인자로 직접 넘기지 않는다.
# - 환경변수 NGC_API_KEY로 두고, docker login에는 stdin으로 넘긴다.

if [[ -z "${NGC_API_KEY:-}" ]]; then
  echo "NGC_API_KEY is not set."
  echo "Run: export NGC_API_KEY=..."
  exit 1
fi

echo "${NGC_API_KEY}" | docker login nvcr.io --username '$oauthtoken' --password-stdin
echo "NGC registry login complete."
