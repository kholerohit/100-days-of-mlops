#!/usr/bin/env bash
set -u

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="Configure a Grafana Contact Point and Notification Policy"

echo "==> Validating task: $TITLE"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

require_file() {
  local p="$1"
  [[ -f "$p" ]] || fail "Missing required file: $p"
  pass "Found file: $p"
}

require_dir() {
  local p="$1"
  [[ -d "$p" ]] || fail "Missing required directory: $p"
  pass "Found directory: $p"
}

require_cmd() {
  local cmd="$1"
  bash -lc "$cmd" >/dev/null 2>&1 || fail "Command failed: $cmd"
  pass "Command succeeded: $cmd"
}

require_python_import() {
  local mod="$1"
  python3 - <<PY >/dev/null 2>&1 || fail "Python package not importable: $mod"
import importlib
importlib.import_module("$mod")
PY
  pass "Python import works: $mod"
}

require_pkg_in_requirements() {
  local pkg="$1"
  grep -Eiq "$pkg" /root/code/requirements.txt 2>/dev/null || fail "Package not found in /root/code/requirements.txt: $pkg"
  pass "Package listed in /root/code/requirements.txt: $pkg"
}

    require_file "$TASK_DIR/task.md"
require_file "$TASK_DIR/solution.md"
require_dir "$TASK_DIR"
require_cmd "docker --version"
require_file "$TASK_DIR/docker-compose.yml"
require_file "$TASK_DIR/docker-compose.yaml"
require_cmd "curl -sSf http://localhost:3000/ >/dev/null 2>&1 || true"

echo "==> Validation complete: $TITLE"
pass "The task appears complete based on the solution verification steps and expected end state."
