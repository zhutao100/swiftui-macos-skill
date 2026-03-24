#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_DIR / "SKILL.md"


@dataclass(frozen=True)
class Issue:
    level: str  # "ERROR" | "WARN"
    message: str
    path: Path | None = None

    def format(self) -> str:
        loc = f"{self.path}: " if self.path else ""
        return f"[{self.level}] {loc}{self.message}"


NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def read_frontmatter(md: str) -> tuple[dict[str, str | dict[str, str]], str]:
    # Minimal YAML frontmatter parser (sufficient for Agent Skills fields).
    # We intentionally avoid external deps.
    if not md.startswith("---\n"):
        raise ValueError("SKILL.md must start with YAML frontmatter ('---').")

    end = md.find("\n---\n", 4)
    if end < 0:
        raise ValueError("SKILL.md frontmatter must end with '---' delimiter.")

    fm_text = md[4:end].strip("\n")
    body = md[end + len("\n---\n") :]

    # Parse a limited subset: key: value, plus one-level nested mapping under metadata:
    fm: dict[str, str | dict[str, str]] = {}
    current_map_key: str | None = None

    for raw in fm_text.splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue

        if re.match(r"^\s", line):
            # nested key
            if current_map_key is None:
                raise ValueError(f"Unexpected indented line in frontmatter: {raw!r}")
            m = re.match(r"^\s+([A-Za-z0-9_.-]+):\s*(.*)$", line)
            if not m:
                raise ValueError(f"Invalid nested frontmatter line: {raw!r}")
            k, v = m.group(1), m.group(2).strip()
            v = v.strip('"').strip("'")
            nested = fm.setdefault(current_map_key, {})
            if not isinstance(nested, dict):
                raise ValueError(f"Frontmatter key {current_map_key!r} used as both scalar and map.")
            nested[k] = v
            continue

        m = re.match(r"^([A-Za-z0-9_.-]+):\s*(.*)$", line)
        if not m:
            raise ValueError(f"Invalid frontmatter line: {raw!r}")
        key, value = m.group(1), m.group(2).strip()
        if value == "":
            # begin mapping
            fm[key] = {}
            current_map_key = key
        else:
            value = value.strip('"').strip("'")
            fm[key] = value
            current_map_key = None

    return fm, body


def find_relative_links(md_body: str) -> set[Path]:
    # Collect markdown links like [text](relative/path)
    links: set[Path] = set()
    for m in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", md_body):
        target = m.group(1).strip()
        if "://" in target or target.startswith("#") or target.startswith("mailto:"):
            continue
        # Remove optional anchor
        target = target.split("#", 1)[0]
        if not target:
            continue
        links.add(Path(target))
    return links


def main() -> int:
    issues: list[Issue] = []

    if not SKILL_MD.exists():
        issues.append(Issue("ERROR", "Missing SKILL.md", SKILL_MD))
        print("\n".join(i.format() for i in issues))
        return 1

    md = SKILL_MD.read_text(encoding="utf-8")
    try:
        fm, body = read_frontmatter(md)
    except Exception as e:
        issues.append(Issue("ERROR", f"Frontmatter parse failed: {e}", SKILL_MD))
        print("\n".join(i.format() for i in issues))
        return 1

    name = fm.get("name")
    if not isinstance(name, str) or not name:
        issues.append(Issue("ERROR", "Frontmatter must include non-empty 'name'.", SKILL_MD))
    else:
        if not NAME_RE.match(name):
            issues.append(Issue("ERROR", f"Invalid name {name!r}. Use lowercase letters, numbers, and hyphens.", SKILL_MD))
        if name != SKILL_DIR.name:
            issues.append(Issue("ERROR", f"'name' ({name}) must match directory name ({SKILL_DIR.name}).", SKILL_MD))

    desc = fm.get("description")
    if not isinstance(desc, str) or not desc.strip():
        issues.append(Issue("ERROR", "Frontmatter must include non-empty 'description'.", SKILL_MD))
    else:
        if len(desc) > 1024:
            issues.append(Issue("ERROR", f"'description' exceeds 1024 chars ({len(desc)}).", SKILL_MD))
        if "macos" not in desc.lower():
            issues.append(Issue("WARN", "Description does not mention macOS; consider adding explicit scope keywords.", SKILL_MD))

    # Required directories (per repo conventions, not spec-minimum)
    for rel in ["references", "scripts", "assets", "agents"]:
        p = SKILL_DIR / rel
        if not p.exists():
            issues.append(Issue("ERROR", f"Missing required directory '{rel}/'.", p))

    # Validate openai.yaml icon paths if present
    openai_yaml = SKILL_DIR / "agents" / "openai.yaml"
    if openai_yaml.exists():
        yaml_text = openai_yaml.read_text(encoding="utf-8")
        for key in ["icon_small", "icon_large"]:
            m = re.search(rf"^\s*{re.escape(key)}:\s*\"?(.+?)\"?\s*$", yaml_text, flags=re.MULTILINE)
            if m:
                icon_rel = m.group(1).strip()
                icon_path = (SKILL_DIR / icon_rel).resolve()
                if not icon_path.exists():
                    issues.append(Issue("ERROR", f"{key} points to missing file: {icon_rel}", openai_yaml))

    # Validate internal links in SKILL.md
    for link in find_relative_links(body):
        target = (SKILL_DIR / link).resolve()
        if not target.exists():
            issues.append(Issue("ERROR", f"Broken link target: {link.as_posix()}", SKILL_MD))

    # Validate reference files exist and are not empty
    ref_dir = SKILL_DIR / "references"
    for ref in sorted(ref_dir.glob("*.md")):
        if ref.stat().st_size == 0:
            issues.append(Issue("ERROR", "Empty reference file.", ref))

    # Print results
    if issues:
        for i in issues:
            print(i.format())
        return 1 if any(i.level == "ERROR" for i in issues) else 0

    print("OK: skill bundle structure looks valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
