# Agent instructions for this repository

This repository is an **agent skill package**, not a Swift app. The deliverable is the `swiftui-macos/` skill directory.

## Working agreements

- Prefer **small, verifiable edits**: update one reference topic at a time; keep examples compiling.
- When adding or changing claims about Swift/SwiftUI behavior:
  - Prefer primary sources (Apple docs, Swift Evolution proposals, Swift Forums, WWDC sessions).
  - If a claim cannot be verified, rephrase it as a hypothesis or remove it.
- Keep **`swiftui-macos/SKILL.md` concise** (progressive disclosure). Put deep dives in `swiftui-macos/references/`.

## Repo layout rules

- The skill root is `swiftui-macos/`.
- `swiftui-macos/SKILL.md`:
  - Must include `name` and `description` frontmatter.
  - Should point to reference files by relative path (one level deep).
- `swiftui-macos/references/`:
  - One topic per file; include concrete code examples.
  - For examples that are meant to compile, place the source in `swiftui-macos/assets/examples/` and link to it.

## Validation

Run the local verification script after edits:

```bash
./swiftui-macos/scripts/verify.sh
```

This script:

- Builds and tests the example Swift package in `swiftui-macos/assets/examples/SwiftUIMacOSPatterns`.
- Performs basic repo hygiene checks (broken internal links, missing referenced files).

## Adding new examples

- Prefer adding examples to the Swift package under `swiftui-macos/assets/examples/SwiftUIMacOSPatterns`.
- Keep examples minimal and focused:
  - One concept per file.
  - Include a short comment at the top describing what the example demonstrates.
- When using OS- or compiler-version-specific APIs, gate with `#if swift(>=...)` and/or `@available`.

## Common tasks

- Update observation/concurrency guidance: edit `swiftui-macos/references/observation.md` and `swiftui-macos/references/concurrency.md`.
- Update view identity/perf guidance: edit `swiftui-macos/references/performance.md` and `swiftui-macos/references/views.md`.
- Update platform bridging: edit `swiftui-macos/references/platform.md`.
- Update SwiftData guidance: edit `swiftui-macos/references/data.md`.
