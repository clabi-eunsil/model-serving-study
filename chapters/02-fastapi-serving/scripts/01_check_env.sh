#!/usr/bin/env bash
set -euo pipefail

# 이 스크립트는 챕터 2 실습에 필요한 Python package version을 확인한다.
# 서버가 잘 안 뜨거나 import error가 날 때, 먼저 이 출력으로 환경을 확인한다.

echo "## Python"
python --version

echo
echo "## Python executable"
which python

echo
echo "## Packages"
python - <<'PY'
import importlib.metadata as metadata

packages = ["fastapi", "uvicorn", "transformers", "torch", "requests", "pydantic"]

for package in packages:
    try:
        print(f"{package}: {metadata.version(package)}")
    except metadata.PackageNotFoundError:
        print(f"{package}: not installed")
PY

echo
echo "## Torch CUDA"
python - <<'PY'
try:
    import torch

    print(f"torch.cuda.is_available: {torch.cuda.is_available()}")
    print(f"torch.version.cuda: {torch.version.cuda}")
    if torch.cuda.is_available():
        print(f"gpu: {torch.cuda.get_device_name(0)}")
except Exception as exc:
    print(f"torch check failed: {exc}")
PY
