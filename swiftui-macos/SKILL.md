---
name: swiftui-macos
description: Write and review SwiftUI code for macOS apps (macOS 15–26) with runtime-level guidance on Observation, Swift Concurrency, view identity/performance, accessibility, and AppKit integration (NSViewRepresentable/NSHostingView, windows, menus). Use for architecture decisions, debugging excessive re-renders, fixing actor-isolation bugs, SwiftData integration, and macOS platform behaviors. Avoid for iOS-only SwiftUI/UIKit or generic Swift questions.
license: MIT
compatibility: macOS-focused (Sequoia 15 through Tahoe 26). References assume Swift 6.2+/Xcode 26 and call out OS 26-only APIs like Observations and Task.immediate, with fallbacks for older deployment targets.
metadata:
  author: kageroumado
  version: "1.1.0"
---

# SwiftUI on macOS: agent workflow

This skill is optimized for **agentic iteration**: small, verifiable steps that respect SwiftUI’s runtime mechanics (Observation + attribute graph) and Swift Concurrency’s isolation rules.

## Scope

In-scope:
- SwiftUI for macOS (App protocol scenes, multi-window, menus/commands, Settings, AppKit bridges)
- Observation (`@Observable`, `@ObservationIgnored`, `withObservationTracking`, `Observations` streams)
- Swift Concurrency patterns that matter for UI code (MainActor discipline, cancellation, isolation changes in Swift 6.2)
- Performance/debugging where **view identity** and **observation scope** are the root causes
- Accessibility and keyboard-first UX

Out-of-scope unless explicitly requested:
- UIKit/iOS-only APIs and UIKit bridges
- “Swift basics” (syntax, generics, introductory concepts)

## How to use this skill

### When writing code
1. Identify the dominant axis: **Observation**, **Concurrency**, **Identity/Performance**, or **Platform**.
2. Load only the relevant reference(s) from `references/` before proposing code.
3. Prefer minimal changes that preserve identity and don’t widen observation scope.

### When reviewing code
1. Triage: confirm the target platform is **macOS** and identify deployment target constraints (15 vs 26).
2. Read the smallest set of files necessary to understand state ownership and window scope.
3. Report issues with:
   - the runtime mechanism (“why”)
   - the concrete risk (bug/perf/UX)
   - a minimal fix (before/after)

## Reference map (progressive disclosure)

| Topic | Load when |
|---|---|
| `references/observation.md` | `@Observable`, `@State`, `ForEach`, unexpected body invalidations, `@ObservationIgnored`, `Observations` streams |
| `references/concurrency.md` | `Task`, `async`/`await`, actors, `MainActor`, strict concurrency warnings, `@concurrent`, `Task.immediate` |
| `references/performance.md` | view identity, `.id()`, expensive body work, large collections, animations, Instruments workflows |
| `references/views.md` | view decomposition, navigation patterns (`NavigationSplitView`), `.task(id:)`, preference keys, custom `Layout` |
| `references/data.md` | state ownership, `@Bindable`, environment injection, SwiftData (`@Model`, `ModelActor`), persistence |
| `references/platform.md` | `NSViewRepresentable`, `NSHostingView`, menus/commands, multi-window, window management |
| `references/api.md` | modern SwiftUI/macOS API choices, macros (`#Preview`, `@Entry`, `@Previewable`) and deprecations |
| `references/accessibility.md` | VoiceOver, keyboard navigation, focus, Dynamic Type, accessibility testing |

Additional sources and “why we believe this is correct” links live in `references/sources.md`.

## Output format for reviews

Organize by file. For each issue:
1. Location (file + symbol; line numbers if available).
2. Diagnosis (runtime mechanism).
3. Fix (minimal patch or code snippet).

End with a prioritized summary: correctness > data-race safety > perf/identity > accessibility.

## Guardrails

- Do not introduce third-party frameworks without asking.
- Avoid private APIs and swizzling unless the user explicitly requests a high-risk approach.
- If an API is OS-version gated (macOS 26-only), provide a macOS 15-compatible fallback.
