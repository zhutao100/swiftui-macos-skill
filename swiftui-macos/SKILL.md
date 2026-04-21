---
name: swiftui-macos
description: >-
  Write and review SwiftUI code for macOS with runtime-level understanding of
  Observation (@Observable, withObservationTracking/Observations), Swift 6.x
  concurrency isolation and ordering, view identity/performance, and AppKit
  integration. Includes ready-to-run audit/install scripts and drop-in
  diagnostics to keep agent workflows fast and concrete.
license: MIT
compatibility: >-
  Targets modern macOS: macOS 15 and macOS 26 (and later).
  Tooling: Xcode 16+ (macOS 15 SDK) and Xcode 26+ (macOS 26 SDK) with Swift 6.x.
  Swift 6.2-specific APIs are gated with `#if swift(>=6.2)` / `@available(...)`.
metadata:
  author: swiftui-macos-skill
  version: "1.4.0"
---

Use this skill when you need **mechanistic** SwiftUI guidance for macOS: how observation dependencies are registered, how identity affects state/task lifetimes, and how Swift concurrency interacts with SwiftUI’s event loop.

## Quickstart (agent-operable)

### 1) Audit a target repo (no code changes)

```bash
python3 swiftui-macos/scripts/swiftui_audit.py /path/to/target-repo --out /tmp/swiftui_audit.md
```

Use the report to pick the first concrete fixes (identity, tasks, representables, type erasure).

### 2) Install drop-in diagnostics (optional)

```bash
bash swiftui-macos/scripts/install_dropins.sh /path/to/target-repo
```

For SwiftPM repos, install directly into a target:

```bash
bash swiftui-macos/scripts/install_dropins.sh /path/to/target-repo --swiftpm-target MyTarget
```

Drop-ins provide:

- `MainActorChecks.assertIsolated()`
- `TaskTracing.run("label") { ... }`
- observation helpers (`withObservationTracking` loop + `Observations` wrappers)
- `NSWindow` access via `.onWindowResolved { window in ... }`
- representable diff helpers for `updateNSView`

### 3) Verify changes

Use the tight loop in `references/workflows.md`:

- build
- run targeted tests
- use Instruments / `_printChanges()` only when you have a concrete hypothesis

## Scope: macOS, not iOS

- Assume **AppKit + SwiftUI on macOS 15+** unless the user states otherwise.
- Translate iOS-first advice into macOS equivalents or discard it.
- Prefer macOS UX conventions: menus/commands, keyboard shortcuts, pointer + focus navigation.

## Review checklist (prioritized)

For each issue: (1) what is wrong, (2) why it matters at runtime, (3) the smallest safe fix.

- observation scope / accidental dependencies / over-notification
- identity thrash (unstable `.id()`, list IDs, structural churn)
- isolation issues (unexpected MainActor work; unsafe non-Sendable crossing)
- AppKit bridge inefficiencies (`updateNSView` churn, coordinator lifetime bugs)
- SwiftData misuse (models crossing actors; CloudKit constraints)
- macOS UX gaps (menus/shortcuts, focus order, accessibility)

## References

Load only what the task needs.

| Reference | Load when |
|---|---|
| `references/diagnostics.md` | fastest debugging + tooling loop; audit script + drop-ins |
| `references/scope.md` | macOS vs iOS boundary questions |
| `references/observation.md` | `@Observable` / `withObservationTracking` / `Observations` |
| `references/concurrency.md` | actor isolation, ordering, `.task(id:)`, Swift 6 strictness |
| `references/performance.md` | extra updates, identity resets, Instruments SwiftUI instrument |
| `references/views.md` | view decomposition, navigation containers, `.task(id:)` patterns |
| `references/platform.md` | `NSViewRepresentable`, windowing/scenes, commands/menus |
| `references/data.md` | environment-injected managers, `@Bindable`, SwiftData/CloudKit |
| `references/api.md` | modern SwiftUI APIs/macros, WebKit, rich text |
| `references/accessibility.md` | VoiceOver, keyboard navigation, focus |
| `references/workflows.md` | verification loops, view-update debugging workflows |

## Local assets

### Scripts (agent-run)

- `scripts/swiftui_audit.py` — heuristic repo audit (identity/concurrency/representables)
- `scripts/install_dropins.sh` — copy drop-in diagnostics into a target repo
- `scripts/verify.sh` — validate this skill repo (links + example package build)

### Assets (copy into target repos)

- `assets/dropins/SwiftUIMacOSDiagnostics` — drop-in diagnostics utilities
- `assets/examples/SwiftUIMacOSPatterns` — compile-checked reference examples (Swift package)
- `assets/templates/MacOSSwiftUIAppTemplate` — ready-to-run scaffold
