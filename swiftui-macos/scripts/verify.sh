#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

echo "[verify] Checking internal markdown links..."
python3 "${ROOT_DIR}/scripts/verify_links.py" "${ROOT_DIR}/SKILL.md" "${ROOT_DIR}/references"

EXAMPLE_DIR="${ROOT_DIR}/assets/examples/SwiftUIMacOSPatterns"

if command -v swift >/dev/null 2>&1; then
  # SwiftUI is only available on Apple platforms. Skip Swift build/test when not available.
  if swift -e 'import SwiftUI' >/dev/null 2>&1; then
    echo "[verify] Building example package..."
    (cd "$EXAMPLE_DIR" && swift build)

    echo "[verify] Running example tests..."
    (cd "$EXAMPLE_DIR" && swift test)
  else
    echo "[verify] SwiftUI module unavailable; skipping Swift package build/test"
  fi
else
  echo "[verify] swift not found; skipping Swift package build/test"
fi

echo "[verify] OK"
