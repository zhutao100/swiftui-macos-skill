# Agent instructions for this repository

This repository is an **agent skill package**, not a Swift app. The deliverable is the `swiftui-macos/` skill directory.

## Working agreements

- Prefer **small, verifiable edits**: update one reference topic at a time; keep examples compiling.
- This repo targets **modern macOS** (macOS **15** and **26**) and **SwiftUI on AppKit**:
  - When searching the web, bias queries toward **macOS** and **AppKit**.
  - Treat iOS-first answers as suspect unless the API is clearly cross-platform and available on macOS.
- When adding or changing claims about Swift/SwiftUI behavior:
  - Prefer primary sources (Apple Developer Documentation, Swift Evolution proposals, Swift Forums, WWDC sessions).
  - If a claim cannot be verified, rephrase it as a hypothesis or remove it.
- Keep **`swiftui-macos/SKILL.md` concise** (progressive disclosure). Put deep dives in `swiftui-macos/references/`.

## Repo layout rules

- The skill root is `swiftui-macos/`.

### Operable assets and scripts

This skill is intended to be usable without “reading the prose first”. Prefer making new additions **agent-operable**:

- Put **drop-in code** under `swiftui-macos/assets/dropins/` so an agent can `cp -R` it into a target repo.
- Put **ready-to-run scripts** under `swiftui-macos/scripts/` so an agent can run them against a target repo.
  - Scripts must be non-interactive and accept a repo path argument.
  - Prefer producing a **report file** (Markdown) over printing long output.

### Docs

- `swiftui-macos/SKILL.md`:
  - Must include `name` and `description` frontmatter.
  - Keep it operational (commands + checklists). Point to reference files by relative path.
- `swiftui-macos/references/`:
  - One topic per file; include concrete, macOS-relevant code examples.
  - Link to compile-checked sources under `assets/examples/SwiftUIMacOSPatterns` when the example should build.

## Validation

Run the local verification script after edits:

```bash
./swiftui-macos/scripts/verify.sh
```

This script:

- Checks internal markdown links in `swiftui-macos/`.
- Builds and tests the example Swift package in `swiftui-macos/assets/examples/SwiftUIMacOSPatterns` when run on an Apple platform with `SwiftUI` available.

## Adding or updating examples

- Prefer adding compile-checked examples to the Swift package under `swiftui-macos/assets/examples/SwiftUIMacOSPatterns`.
- Keep examples minimal and focused:
  - one concept per file
  - small, runnable views or functions
- When using OS- or compiler-version-specific APIs, gate with `@available(...)` and/or `#if swift(>=...)`.

## Common tasks

- Update diagnostic workflows: edit `swiftui-macos/references/diagnostics.md` and `swiftui-macos/references/workflows.md`.
- Update observation guidance: edit `swiftui-macos/references/observation.md`.
- Update concurrency guidance: edit `swiftui-macos/references/concurrency.md`.
- Update view identity/perf guidance: edit `swiftui-macos/references/performance.md` and `swiftui-macos/references/views.md`.
- Update platform/AppKit bridging: edit `swiftui-macos/references/platform.md`.
- Update SwiftData guidance: edit `swiftui-macos/references/data.md`.
- Update macOS-vs-iOS boundary guidance: edit `swiftui-macos/references/scope.md`.
- Update the repo-maintenance skill: edit `.agents/skills/update-swiftui-macos-skill`.
