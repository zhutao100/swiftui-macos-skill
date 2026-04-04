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
- `swiftui-macos/SKILL.md`:
  - Must include `name` and `description` frontmatter.
  - Should point to reference files by relative path (one level deep).
- `swiftui-macos/references/`:
  - One topic per file; include concrete, macOS-relevant code examples.
  - For examples that are meant to compile, place the source in `swiftui-macos/assets/examples/SwiftUIMacOSPatterns` and link to it.

## Validation

Run the local verification script after edits:

```bash
./swiftui-macos/scripts/verify.sh
```

This script:

- Checks internal markdown links in `swiftui-macos/`.
- Builds and tests the example Swift package in `swiftui-macos/assets/examples/SwiftUIMacOSPatterns` when run on an Apple platform with `SwiftUI` available.

## Adding or updating examples

- Prefer adding examples to the Swift package under `swiftui-macos/assets/examples/SwiftUIMacOSPatterns`.
- Keep examples minimal and focused:
  - One concept per file.
  - Include a short comment at the top describing what the example demonstrates.
- When using OS- or compiler-version-specific APIs, gate with `@available(...)` and/or `#if swift(>=...)`.

## Common tasks

- Update observation guidance: edit `swiftui-macos/references/observation.md`.
- Update concurrency guidance: edit `swiftui-macos/references/concurrency.md`.
- Update view identity/perf guidance: edit `swiftui-macos/references/performance.md` and `swiftui-macos/references/views.md`.
- Update platform/AppKit bridging: edit `swiftui-macos/references/platform.md`.
- Update SwiftData guidance: edit `swiftui-macos/references/data.md`.
- Update macOS-vs-iOS boundary guidance: edit `swiftui-macos/references/scope.md`.
- Update the repo-maintenance skill: edit `.agents/skills/update-swiftui-macos-skill`.
