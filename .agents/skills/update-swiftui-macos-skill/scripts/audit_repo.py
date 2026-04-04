#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]  # .agents/skills/update-swiftui-macos-skill/scripts/audit_repo.py

REQUIRED_ROOT = [
    "README.md",
    "AGENTS.md",
    "LICENSE",
    "swiftui-macos/SKILL.md",
]

REQUIRED_SKILL_DIRS = [
    "swiftui-macos/references",
    "swiftui-macos/scripts",
    "swiftui-macos/assets",
]

REQUIRED_UPDATE_SKILL = [
    ".agents/skills/update-swiftui-macos-skill/SKILL.md",
    ".agents/skills/update-swiftui-macos-skill/references",
    ".agents/skills/update-swiftui-macos-skill/scripts",
]


def check_exists(rel: str) -> str | None:
    p = (REPO_ROOT / rel).resolve()
    if not p.exists():
        return rel
    return None


def main() -> int:
    missing: list[str] = []

    for rel in REQUIRED_ROOT + REQUIRED_SKILL_DIRS + REQUIRED_UPDATE_SKILL:
        miss = check_exists(rel)
        if miss:
            missing.append(miss)

    if missing:
        print("[audit_repo] FAIL: missing required paths:")
        for m in missing:
            print(" -", m)
        return 1

    # Basic sanity: swiftui-macos/SKILL.md frontmatter presence.
    skill = (REPO_ROOT / "swiftui-macos/SKILL.md").read_text(encoding="utf-8")
    if not skill.startswith("---"):
        print("[audit_repo] FAIL: swiftui-macos/SKILL.md missing frontmatter fence ('---').")
        return 1

    print("[audit_repo] OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
