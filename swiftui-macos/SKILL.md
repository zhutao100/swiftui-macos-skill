---
name: swiftui-macos
description: >-
  Write and review SwiftUI code for macOS with runtime-level understanding of
  Observation (@Observable, withObservationTracking/Observations), Swift 6.2
  concurrency isolation and ordering, view identity/performance, and AppKit
  integration. Use for macOS SwiftUI architecture, debugging re-renders,
  concurrency fixes, SwiftData + SwiftUI data flow, and NSViewRepresentable/
  NSHostingView bridging. Do not use for UIKit-only work, iOS-only design
  guidance, or basic Swift syntax questions.
license: MIT
compatibility: >-
  Best with Xcode 26+ / Swift 6.2+ targeting macOS 26+. Provide availability
  gates or alternate patterns when a project targets older macOS.
metadata:
  author: kageroumado
  version: "1.1.0"
---

Guide SwiftUI development for macOS apps. Whether writing new code or reviewing existing code, apply a *mechanistic* understanding of SwiftUI’s update pipeline: how observation dependencies are registered, how view identity affects state retention, and how isolation/executors interact with SwiftUI lifecycles.

## Operating mode

### When writing code

1. Identify the **minimum OS / toolchain** constraints (explicitly, if known; otherwise assume macOS 26 + Swift 6.2, and add availability gates).
2. Choose the right **state ownership** model (environment-injected managers, per-window state, transient `@State` for gestures).
3. Prefer **deterministic, testable** designs:
   - isolate side effects in manager/model layers
   - use `.task(id:)` for cancellable async work
   - use compile-checked examples (see `assets/examples`)

### When reviewing code

Organize findings by file, and prioritize issues that are both **correctness** and **user-impactful**:

- observation scope / over-notification / accidental dependencies
- identity thrash (unstable `.id()`, structural identity churn)
- incorrect isolation (work on MainActor unintentionally; unsafe non-Sendable crossing)
- AppKit bridge inefficiencies (`updateNSView` churn, coordinator lifetimes)
- SwiftData misuse (model objects crossing actors; CloudKit constraint violations)

For each issue: (1) what is wrong, (2) why it matters at runtime, (3) the smallest safe fix.

## References

Load only what the task needs.

| Reference | Load when |
|---|---|
| `references/observation.md` | `@Observable` / `@State` questions, `ForEach` churn, observation outside SwiftUI, `Observations` streams |
| `references/concurrency.md` | Task ordering, default actor isolation, `@concurrent`, `Task.immediate`, Sendable issues |
| `references/performance.md` | Excess re-renders, identity resets, `Equatable` views, `Canvas`/`TimelineView` |
| `references/views.md` | View decomposition, navigation, `.task(id:)`, preference keys, custom `Layout` |
| `references/platform.md` | `NSViewRepresentable`, `NSHostingView`, window management, AppKit bridging |
| `references/data.md` | Environment-injected managers, `@Bindable`, SwiftData/CloudKit, `@ModelActor` |
| `references/api.md` | Modern SwiftUI APIs/macros, `@Entry`, `#Preview`, Tab navigation |
| `references/accessibility.md` | VoiceOver, keyboard navigation, Dynamic Type, Reduce Motion |
| `references/workflows.md` | Agentic verification loops, debugging view updates, Instruments/Xcode workflows |

## Local examples

When you need compile-checked examples, use:

- `assets/examples/SwiftUIMacOSPatterns` (Swift package)

When editing this skill package, run:

- `scripts/verify.sh`
