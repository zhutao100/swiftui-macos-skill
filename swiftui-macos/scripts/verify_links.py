#!/usr/bin/env python3
"""Lightweight internal link checker for this skill repo.

- Only checks relative markdown links pointing to repo paths.
- Ignores http(s) links.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def iter_markdown_files(paths: list[Path]) -> list[Path]:
    out: list[Path] = []
    for p in paths:
        if p.is_dir():
            out.extend(sorted(p.rglob("*.md")))
        else:
            out.append(p)
    return out


def is_external(link: str) -> bool:
    return link.startswith("http://") or link.startswith("https://")


def normalize_target(base: Path, link: str) -> Path:
    # Strip URL fragments and query.
    link = link.split("#", 1)[0].split("?", 1)[0]
    return (base / link).resolve()


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: verify_links.py <file-or-dir> [<file-or-dir> ...]", file=sys.stderr)
        return 2

    input_paths = [Path(a).resolve() for a in argv[1:]]
    md_files = iter_markdown_files(input_paths)

    failures: list[str] = []

    for md in md_files:
        base = md.parent
        text = md.read_text(encoding="utf-8")
        for raw_link in LINK_RE.findall(text):
            link = raw_link.strip()
            if not link or is_external(link) or link.startswith("mailto:"):
                continue
            if link.startswith("/" ):
                # Treat absolute paths as repo-root relative.
                base_for_abs = md.anchor and Path(md.anchor) or Path("/")
                # We'll just reject; these aren't used in this repo.
                failures.append(f"{md}: absolute link not allowed: {raw_link}")
                continue

            target = normalize_target(base, link)
            if not target.exists():
                failures.append(f"{md}: missing target for link {raw_link!r} -> {target}")

    if failures:
        print("[verify_links] FAIL")
        for f in failures:
            print(" -", f)
        return 1

    print("[verify_links] OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
