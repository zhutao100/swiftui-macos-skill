---
name: update-swiftui-macos-skill
description: >-
  Repo-internal maintenance skill for updating the swiftui-macos skill package.
  Guides agentic sessions to (1) research up-to-date macOS SwiftUI guidance,
  (2) verify and correct existing content, (3) keep examples compiling, and
  (4) maintain Codex/Open-Agent skill standard compliance and repo integrity.
license: MIT
compatibility: >-
  Intended to run in the swiftui-macos-skill repository. Assumes the primary
  skill targets macOS 15 and macOS 26, with Swift 6.2+ and Xcode 16+/26+.
metadata:
  author: swiftui-macos-skill
  version: "1.1.0"
---

Maintain this repository’s `swiftui-macos/` skill content. Use this skill when you need to **update, validate, or extend** the skill with new macOS-relevant SwiftUI patterns.

## Scope and non-goals

- This maintenance skill is **for this repository only**.
- Prioritize **macOS 15+** correctness. Avoid iOS-only recipes unless explicitly mapped to macOS equivalents.
- Do not introduce speculative claims: if you cannot verify a behavior in primary sources, rephrase as a hypothesis or remove it.

## Default workflow

### 1) Inventory and scope

1. Identify the topic area(s): observation, concurrency, identity/performance, platform integration, data/SwiftData, accessibility.
2. Confirm the minimum supported platform: macOS 15 and macOS 26.
3. Determine whether a change requires new compile-checked examples in:
   - `swiftui-macos/assets/examples/SwiftUIMacOSPatterns`

### 2) Web research (macOS-first)

Search strategy:

- Prefer **Apple Developer Documentation**, **WWDC sessions**, **Swift Evolution proposals**, and **Swift Forums**.
- Bias queries toward **macOS** and **AppKit**:
  - include `macOS` in the query
  - explicitly exclude iOS-only terms when needed (e.g., `-UIKit -UIViewRepresentable`)
- Validate OS/toolchain availability:
  - confirm the API exists and is available on macOS 15+/26
  - add `@available(macOS ... )` gates in examples when necessary

### 3) Update the skill content

Edit in this order:

1. `swiftui-macos/SKILL.md` (only when new references are added or scope changes)
2. `swiftui-macos/references/<topic>.md` (topic deep dives)
3. `swiftui-macos/assets/examples/SwiftUIMacOSPatterns` (compile-checked examples)
4. `swiftui-macos/assets/templates/MacOSSwiftUIAppTemplate` (ready-to-run scaffold)

Rules:

- Each reference file should contain at least one **macOS-relevant** code example.
- When the example should compile, place it in the Swift package and link to the source file using a **relative markdown link**.

### 4) Validate

Run from repo root:

```bash
./swiftui-macos/scripts/verify.sh
python3 ./.agents/skills/update-swiftui-macos-skill/scripts/audit_repo.py
```

If you have access to a macOS machine/toolchain, also run:

```bash
(cd swiftui-macos/assets/examples/SwiftUIMacOSPatterns && swift test)
(cd swiftui-macos/assets/templates/MacOSSwiftUIAppTemplate && swift build)
```

### 5) Versioning and changelog discipline

- Bump `swiftui-macos/SKILL.md` `metadata.version` when behavior or guidance changes materially.
- Bump this maintenance skill version (`.agents/skills/update-swiftui-macos-skill/SKILL.md`) when the maintenance workflow changes.
- Prefer small, reviewable commits; keep diffs localized.

## References for maintainers

- See `references/search_strategy.md` for macOS-first query patterns.
- See `references/standard_compliance.md` for the required repo layout and invariants.
