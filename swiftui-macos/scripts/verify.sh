#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/swiftui-macos-verify.XXXXXX")"
VERIFY_OK=0
PREFERRED_DEVELOPER_DIR="${DEVELOPER_DIR:-}"

cleanup() {
  if [ "$VERIFY_OK" -eq 1 ]; then
    rm -rf "$LOG_DIR"
  else
    echo "[verify] Logs: $LOG_DIR"
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"

if [ -z "$PREFERRED_DEVELOPER_DIR" ] && command -v xcode-select >/dev/null 2>&1; then
  PREFERRED_DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"
fi

if [[ "$PREFERRED_DEVELOPER_DIR" == */CommandLineTools* ]] && [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  PREFERRED_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

dev_cmd() {
  if [ -n "$PREFERRED_DEVELOPER_DIR" ]; then
    DEVELOPER_DIR="$PREFERRED_DEVELOPER_DIR" "$@"
  else
    "$@"
  fi
}

swift_cmd() {
  if command -v xcrun >/dev/null 2>&1; then
    dev_cmd xcrun --sdk macosx swift "$@"
  elif command -v swift >/dev/null 2>&1; then
    swift "$@"
  else
    return 127
  fi
}

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

if command -v xcodebuild >/dev/null 2>&1 && command -v xcrun >/dev/null 2>&1; then
  xcode_info="$(dev_cmd xcodebuild -version 2>/dev/null || true)"
  xcode_version="$(echo "$xcode_info" | sed -n '1s/^Xcode //p')"
  xcode_build="$(echo "$xcode_info" | sed -n '2s/^Build version //p')"
  macos_sdk_version="$(dev_cmd xcrun --sdk macosx --show-sdk-version 2>/dev/null || true)"

  if [ -n "$xcode_version" ] && [ -n "$macos_sdk_version" ]; then
    if [ -n "$xcode_build" ]; then
      echo "[verify] Toolchain: Xcode ${xcode_version} (${xcode_build}), macOS SDK ${macos_sdk_version}"
    else
      echo "[verify] Toolchain: Xcode ${xcode_version}, macOS SDK ${macos_sdk_version}"
    fi
  fi
fi

echo "[verify] Checking internal markdown links..."
if ! command -v python3 >/dev/null 2>&1; then
  echo "[verify] python3 not found; cannot verify markdown links"
  exit 1
fi
run_logged "markdown links" \
  python3 "${ROOT_DIR}/scripts/verify_links.py" "${ROOT_DIR}/SKILL.md" "${ROOT_DIR}/references"

EXAMPLE_DIR="${ROOT_DIR}/assets/examples/SwiftUIMacOSPatterns"

if command -v swift >/dev/null 2>&1 || command -v xcrun >/dev/null 2>&1; then
  # SwiftUI is only available on Apple platforms. Skip Swift build/test when not available.
  if swift_cmd -e 'import SwiftUI' >/dev/null 2>&1; then
    echo "[verify] Building example package..."
    run_logged "example build" swift_cmd build --package-path "$EXAMPLE_DIR"

    echo "[verify] Running example tests..."
    run_logged "example test" swift_cmd test --package-path "$EXAMPLE_DIR"

    TEMPLATE_DIR="${ROOT_DIR}/assets/templates/MacOSSwiftUIAppTemplate"
    if [ -f "${TEMPLATE_DIR}/Package.swift" ]; then
      echo "[verify] Building template scaffold..."
      run_logged "template build" swift_cmd build --package-path "$TEMPLATE_DIR"
    fi

  else
    echo "[verify] SwiftUI module unavailable; skipping Swift package build/test"
  fi
else
  echo "[verify] swift not found; skipping Swift package build/test"
fi

VERIFY_OK=1
echo "[verify] OK"
