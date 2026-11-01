#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

count=0
for script in "$ROOT"/Days/Day*/validate.sh; do
  [[ -f "$script" ]] || continue
  count=$((count + 1))
  echo "=== Running $script ==="
  bash "$script" || exit 1
  echo
 done

echo "Validated $count day tasks successfully."
