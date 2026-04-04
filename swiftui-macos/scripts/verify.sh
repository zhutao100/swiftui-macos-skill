#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/swiftui-macos-verify.XXXXXX")"
VERIFY_OK=0

cleanup() {
  if [ "$VERIFY_OK" -eq 1 ]; then
    rm -rf "$LOG_DIR"
  else
    echo "[verify] Logs: $LOG_DIR"
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"

run_logged() {
  local label="$1"
  shift

  local safe_label
  safe_label="$(echo "$label" | tr -cs '[:alnum:]._-' '_' | sed 's/^_//;s/_$//')"
  local log_file="${LOG_DIR}/${safe_label}.log"

  if ! "$@" >"$log_file" 2>&1; then
    echo "[verify] FAILED: ${label}"
    echo "[verify] Command: $*"
    echo "[verify] Output (tail):"
    tail -n 200 "$log_file"
    exit 1
  fi
}

echo "[verify] Checking internal markdown links..."
if ! command -v python3 >/dev/null 2>&1; then
  echo "[verify] python3 not found; cannot verify markdown links"
  exit 1
fi
run_logged "markdown links" \
  python3 "${ROOT_DIR}/scripts/verify_links.py" "${ROOT_DIR}/SKILL.md" "${ROOT_DIR}/references"

EXAMPLE_DIR="${ROOT_DIR}/assets/examples/SwiftUIMacOSPatterns"

if command -v swift >/dev/null 2>&1; then
  # SwiftUI is only available on Apple platforms. Skip Swift build/test when not available.
  if swift -e 'import SwiftUI' >/dev/null 2>&1; then
    echo "[verify] Building example package..."
    run_logged "example build" swift build --package-path "$EXAMPLE_DIR"

    echo "[verify] Running example tests..."
    run_logged "example test" swift test --package-path "$EXAMPLE_DIR"

    TEMPLATE_DIR="${ROOT_DIR}/assets/templates/MacOSSwiftUIAppTemplate"
    if [ -f "${TEMPLATE_DIR}/Package.swift" ]; then
      echo "[verify] Building template scaffold..."
      run_logged "template build" swift build --package-path "$TEMPLATE_DIR"
    fi

  else
    echo "[verify] SwiftUI module unavailable; skipping Swift package build/test"
  fi
else
  echo "[verify] swift not found; skipping Swift package build/test"
fi

VERIFY_OK=1
echo "[verify] OK"
