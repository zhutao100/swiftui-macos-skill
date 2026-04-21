#!/usr/bin/env python3
"""Static SwiftUI/macOS heuristics audit.

This script is designed for agentic workflows:
- fast, local-only (no network)
- produces a compact Markdown report
- focuses on high-signal SwiftUI footguns: identity, concurrency, observation, representables

It does *not* parse Swift syntax; it uses targeted regex heuristics.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Finding:
    rule_id: str
    severity: str  # "HIGH" | "MED" | "LOW" | "INFO"
    category: str
    path: Path
    line: int
    column: int
    message: str
    snippet: str
    recommendation: str
    reference: str


EXCLUDE_DIR_EXACT: set[str] = {
    ".git",
    ".build",
    ".swiftpm",
    "DerivedData",
    "Pods",
    "Carthage",
    "SourcePackages",
    "Build",
    "build",
}

EXCLUDE_DIR_SUFFIXES: tuple[str, ...] = (
    ".xcassets",
    ".xcodeproj",
    ".xcworkspace",
)


def _should_skip_path(path: Path) -> bool:
    for part in path.parts:
        if part in EXCLUDE_DIR_EXACT:
            return True
        if any(part.endswith(suffix) for suffix in EXCLUDE_DIR_SUFFIXES):
            return True
    return False


def iter_swift_files(repo: Path, include_tests: bool) -> list[Path]:
    files: list[Path] = []
    for p in repo.rglob("*.swift"):
        if _should_skip_path(p):
            continue
        if not include_tests and any(part == "Tests" or part.endswith("Tests") for part in p.parts):
            continue
        files.append(p)
    return sorted(files)


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def _line_col(text: str, idx: int) -> tuple[int, int]:
    """Compute 1-based line/column for a string index."""
    line = text.count("\n", 0, idx) + 1
    last_nl = text.rfind("\n", 0, idx)
    col = idx + 1 if last_nl == -1 else (idx - last_nl)
    return line, col


def _snippet_line(text: str, line_no: int, max_len: int = 160) -> str:
    lines = text.splitlines()
    if not (1 <= line_no <= len(lines)):
        return ""
    s = lines[line_no - 1].rstrip("\n")
    if len(s) <= max_len:
        return s
    return s[: max_len - 1] + "…"


@dataclass(frozen=True)
class Rule:
    rule_id: str
    severity: str
    category: str
    pattern: re.Pattern[str]
    message: str
    recommendation: str
    reference: str


def rules() -> list[Rule]:
    """Keep this list small and high-signal."""
    return [
        Rule(
            rule_id="ID001",
            severity="HIGH",
            category="Identity",
            pattern=re.compile(r"\.id\s*\(\s*UUID\s*\(\s*\)\s*\)"),
            message="Unstable identity: `.id(UUID())` recreates the subtree on every update.",
            recommendation="Use stable identity (e.g. `.id(item.id)`) or remove `.id` unless you intend a reset boundary.",
            reference="swiftui-macos/references/performance.md#the-id-modifier",
        ),
        Rule(
            rule_id="ID002",
            severity="MED",
            category="Identity",
            pattern=re.compile(r"ForEach\([^\n\)]*id:\s*\\\.self"),
            message="Potentially fragile identity: `ForEach(..., id: \\.self)`.",
            recommendation="Prefer `Identifiable` elements or `id: \\.stableID`. Ensure uniqueness/stability or you may lose row state and restart tasks.",
            reference="swiftui-macos/references/performance.md#foreach-optimization",
        ),
        Rule(
            rule_id="PERF001",
            severity="MED",
            category="Performance",
            pattern=re.compile(r"\bAnyView\b"),
            message="`AnyView` type-erasure can increase diffing work and hide identity changes.",
            recommendation="Prefer `@ViewBuilder`, `Group`, and generics. If you need erasure, isolate it behind a boundary and keep the erased subtree small.",
            reference="swiftui-macos/references/performance.md#avoid-anyview",
        ),
        Rule(
            rule_id="PERF002",
            severity="LOW",
            category="Performance",
            pattern=re.compile(r"\.sorted\s*\("),
            message="Potential hot-path work: `.sorted(...)` on a frequently-executed path.",
            recommendation="If this runs in a view `body` or other hot loop, cache the derived value or move the sort into the model layer (invalidate explicitly when inputs change).",
            reference="swiftui-macos/references/performance.md#body-evaluation-keep-hot-paths-cheap",
        ),
        Rule(
            rule_id="CON001",
            severity="MED",
            category="Concurrency",
            pattern=re.compile(r"\bTask\.detached\b"),
            message="`Task.detached` drops actor inheritance and requires strict `Sendable` capture discipline.",
            recommendation="Prefer `Task {}` (inherits context) or design an explicit async API (`@concurrent` / actor) for off-main work.",
            reference="swiftui-macos/references/concurrency.md#task-inheritance",
        ),
        Rule(
            rule_id="CON002",
            severity="LOW",
            category="Concurrency",
            pattern=re.compile(r"DispatchQueue\.main\.async"),
            message="`DispatchQueue.main.async` is often a legacy workaround; it can hide ordering problems.",
            recommendation="Prefer `@MainActor` isolation and `await` to yield. If you need to hop, use `Task { @MainActor in ... }`.",
            reference="swiftui-macos/references/concurrency.md#ordering-and-scheduling",
        ),
        Rule(
            rule_id="APPKIT001",
            severity="LOW",
            category="AppKit bridging",
            pattern=re.compile(r"\bupdateNSView\s*\("),
            message="Representable updates can be frequent; `updateNSView` should be fast and idempotent.",
            recommendation="Add internal diffing (cache last-applied values in the coordinator) and early-out on no-op updates.",
            reference="swiftui-macos/references/platform.md#nsviewrepresentable",
        ),
        Rule(
            rule_id="SCOPE001",
            severity="INFO",
            category="Platform scope",
            pattern=re.compile(r"\bUIViewRepresentable\b|\bUIHostingController\b|\bimport\s+UIKit\b"),
            message="UIKit symbols detected. If this is macOS-only code, this is likely accidental.",
            recommendation="For macOS-only targets, prefer AppKit equivalents (`NSViewRepresentable`, `NSHostingView`). For multiplatform targets, ensure correct `#if os(...)` gating.",
            reference="swiftui-macos/references/scope.md",
        ),
    ]


def collect_findings(repo: Path, files: list[Path]) -> list[Finding]:
    all_rules = rules()
    findings: list[Finding] = []

    for path in files:
        text = _read_text(path)
        for rule in all_rules:
            for m in rule.pattern.finditer(text):
                line, col = _line_col(text, m.start())
                findings.append(
                    Finding(
                        rule_id=rule.rule_id,
                        severity=rule.severity,
                        category=rule.category,
                        path=path,
                        line=line,
                        column=col,
                        message=rule.message,
                        snippet=_snippet_line(text, line),
                        recommendation=rule.recommendation,
                        reference=rule.reference,
                    )
                )
    return findings


def _count_tokens(text: str, needles: list[str]) -> dict[str, int]:
    return {n: text.count(n) for n in needles}


def summarize_usage(files: list[Path]) -> dict[str, int]:
    needles = [
        "@Observable",
        "ObservableObject",
        "@StateObject",
        "@ObservedObject",
        "@State ",
        "@Environment",
        "@Bindable",
        "withObservationTracking",
        "Observations",
        ".task(",
        "Task {",
        "Task.detached",
        ".id(",
        "NSViewRepresentable",
        "NSHostingView",
        "WindowGroup",
        "openWindow",
        "CommandGroup",
        "MenuBarExtra",
    ]

    counts: dict[str, int] = {n: 0 for n in needles}
    for p in files:
        text = _read_text(p)
        for k, v in _count_tokens(text, needles).items():
            counts[k] += v
    return counts


def render_markdown(repo: Path, findings: list[Finding], usage: dict[str, int]) -> str:
    now = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")

    by_sev: dict[str, int] = {"HIGH": 0, "MED": 0, "LOW": 0, "INFO": 0}
    for f in findings:
        by_sev[f.severity] = by_sev.get(f.severity, 0) + 1

    lines: list[str] = []
    lines.append("# SwiftUI/macOS audit report")
    lines.append("")
    lines.append(f"- Repo: `{repo}`")
    lines.append(f"- Generated: `{now}`")
    lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append("| Severity | Count |")
    lines.append("|---:|---:|")
    for sev in ("HIGH", "MED", "LOW", "INFO"):
        lines.append(f"| {sev} | {by_sev.get(sev, 0)} |")
    lines.append("")

    lines.append("## SwiftUI surface area (rough)")
    lines.append("")
    lines.append("| Token | Count |")
    lines.append("|---|---:|")
    for k in sorted(usage.keys()):
        lines.append(f"| `{k}` | {usage[k]} |")
    lines.append("")

    lines.append("## Findings")
    lines.append("")

    if not findings:
        lines.append("No findings from the current heuristic rules.")
        return "\n".join(lines) + "\n"

    lines.append("Notes:")
    lines.append("- These are heuristic matches, not a SwiftSyntax parse.")
    lines.append("- Use the linked reference docs for the runtime rationale and safe fix patterns.")
    lines.append("")

    def sort_key(f: Finding) -> tuple[int, str, str, int, int]:
        sev_rank = {"HIGH": 0, "MED": 1, "LOW": 2, "INFO": 3}.get(f.severity, 9)
        return (sev_rank, f.category, str(f.path), f.line, f.column)

    findings_sorted = sorted(findings, key=sort_key)

    current_category: str | None = None
    for f in findings_sorted:
        if current_category != f.category:
            current_category = f.category
            lines.append(f"### {current_category}")
            lines.append("")

        try:
            rel = f.path.relative_to(repo)
        except ValueError:
            rel = f.path

        loc = f"{rel}:{f.line}:{f.column}"
        lines.append(f"- **{f.severity}** `{f.rule_id}` — `{loc}`")
        lines.append(f"  - {f.message}")
        if f.snippet.strip():
            lines.append("  - Snippet:")
            lines.append("\n    ```swift")
            lines.append(f"    {f.snippet}")
            lines.append("    ```")
        lines.append(f"  - Fix: {f.recommendation}")
        lines.append(f"  - Reference: `{f.reference}`")
        lines.append("")

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Heuristic SwiftUI/macOS audit")
    p.add_argument("repo", nargs="?", default=".", help="Path to the target repository")
    p.add_argument("--out", default="-", help="Output path for Markdown report (default: stdout)")
    p.add_argument("--include-tests", action="store_true", help="Include Tests/ in the scan")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).expanduser().resolve()

    if not repo.exists():
        raise SystemExit(f"Repo path does not exist: {repo}")

    files = iter_swift_files(repo, include_tests=bool(args.include_tests))
    findings = collect_findings(repo, files)
    usage = summarize_usage(files)

    report = render_markdown(repo, findings, usage)

    if args.out == "-":
        print(report, end="")
    else:
        out_path = Path(args.out).expanduser().resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(report, encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
