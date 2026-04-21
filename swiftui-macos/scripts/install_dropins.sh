#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DROPINS_DIR="${ROOT_DIR}/assets/dropins/SwiftUIMacOSDiagnostics"

usage() {
  cat <<USAGE
Usage:
  install_dropins.sh <target-repo-root> [--swiftpm-target <TargetName>] [--dest <relative-path>] [--force]

Copies the SwiftUIMacOSDiagnostics drop-in folder into a target repository.

Defaults:
  - If no destination is provided, copies to:  <target>/Support/SwiftUIMacOSDiagnostics
  - If --swiftpm-target is provided, copies to: <target>/Sources/<TargetName>/Support/SwiftUIMacOSDiagnostics

Notes:
  - For Xcode projects, you still need to add the copied files to a build target.
  - For SwiftPM packages, copying under Sources/<Target>/ makes them part of that target.
USAGE
}

TARGET="${1:-}"
if [ -z "$TARGET" ] || [[ "$TARGET" == "-h" ]] || [[ "$TARGET" == "--help" ]]; then
  usage
  exit 2
fi
shift

SWIFTPM_TARGET=""
DEST_REL=""
FORCE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --swiftpm-target)
      SWIFTPM_TARGET="${2:-}"
      shift 2
      ;;
    --dest)
      DEST_REL="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ ! -d "$DROPINS_DIR" ]; then
  echo "Drop-ins not found: $DROPINS_DIR" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

if [ -n "$SWIFTPM_TARGET" ]; then
  if [ -z "$DEST_REL" ]; then
    DEST_REL="Sources/${SWIFTPM_TARGET}/Support/SwiftUIMacOSDiagnostics"
  fi
else
  if [ -z "$DEST_REL" ]; then
    DEST_REL="Support/SwiftUIMacOSDiagnostics"
  fi
fi

DEST_ABS="${TARGET}/${DEST_REL}"
PARENT_ABS="$(dirname "$DEST_ABS")"
mkdir -p "$PARENT_ABS"

if [ -e "$DEST_ABS" ] && [ "$FORCE" -ne 1 ]; then
  echo "Destination already exists: $DEST_ABS" >&2
  echo "Re-run with --force to overwrite." >&2
  exit 1
fi

rm -rf "$DEST_ABS"
cp -R "$DROPINS_DIR" "$DEST_ABS"

if [ -n "$SWIFTPM_TARGET" ]; then
  # SwiftPM warns about non-source files under Sources/<Target>/.
  rm -f "$DEST_ABS/README.md"
fi

cat <<EOFMSG
[install_dropins] Copied:
  from: $DROPINS_DIR
  to:   $DEST_ABS

Next steps:
  - SwiftPM: ensure the destination is under Sources/<Target>/ so it compiles.
  - Xcode: add the folder/files to your target (Target Membership).

Suggested follow-up:
  - Run the audit script to find hot spots:
      python3 "$ROOT_DIR/scripts/swiftui_audit.py" "$TARGET" --out /tmp/swiftui_audit.md
EOFMSG
