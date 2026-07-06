#!/usr/bin/env bash
set -euo pipefail

# 챕터 7 마무리 안내를 출력한다.
#
# 이 챕터는 server를 직접 띄우지 않으므로 stop_server script가 없다.
# 대신 benchmark client의 .venv에서 나오고, results/에 남은 CSV를 확인한다.

echo "## Cleanup checklist"
echo "1. If a Python virtual environment is active, run: deactivate"
echo "2. Check benchmark CSV files: ls -lh results/"
echo "3. Summarize results: bash scripts/06_summarize_results.sh"
echo "4. Collect context if needed: CONTAINER_NAME=... bash scripts/07_collect_context.sh | tee results/context.txt"
echo "5. Stop the server in the chapter that started it, for example chapter 04, 05, or 06."
