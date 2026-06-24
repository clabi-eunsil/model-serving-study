#!/usr/bin/env bash
set -u

# 이 스크립트는 현재 실습 환경을 env-summary.txt에 기록한다.
# 모델 서빙 실습은 Python, Docker, Kubernetes, GPU 상태에 크게 영향을 받기 때문에
# 나중에 결과를 비교하려면 "어떤 환경에서 실행했는지"를 같이 남겨야 한다.

# 첫 번째 인자로 출력 파일명을 받을 수 있다.
# 인자를 주지 않으면 기본값으로 env-summary.txt를 사용한다.
OUT_FILE="${1:-env-summary.txt}"

{
  echo "# Environment Summary"
  echo
  echo "Generated at: $(date -Iseconds)"
  echo
  echo "## OS"
  # Ubuntu 계열이면 lsb_release가 사람이 읽기 좋은 배포판 정보를 보여준다.
  # 없으면 uname으로 kernel 정보를 기록한다.
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a 2>/dev/null
  else
    uname -a
  fi
  echo
  echo "## Python"
  # 어떤 Python command가 잡히는지 확인한다.
  # 일부 환경은 python이 없고 python3만 있을 수 있다.
  if command -v python >/dev/null 2>&1; then
    python --version
  else
    echo "python: not found"
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 --version
  else
    echo "python3: not found"
  fi
  echo
  echo "## Docker"
  # Docker 실습 전 Docker CLI가 현재 shell에서 보이는지 확인한다.
  if command -v docker >/dev/null 2>&1; then
    docker --version
  else
    echo "docker: not found"
  fi
  echo
  echo "## Kubernetes"
  # Kubernetes 실습 전 kubectl client가 설치되어 있는지 확인한다.
  if command -v kubectl >/dev/null 2>&1; then
    kubectl version --client
  else
    echo "kubectl: not found"
  fi
  echo
  echo "## NVIDIA"
  # GPU 실습 전 NVIDIA driver와 GPU가 현재 환경에서 보이는지 확인한다.
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
  else
    echo "nvidia-smi: not found"
  fi
} > "$OUT_FILE"

echo "Wrote $OUT_FILE"
