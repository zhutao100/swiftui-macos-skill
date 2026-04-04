---
name: swiftui-macos
description: >-
  Write and review SwiftUI code for macOS with runtime-level understanding of
  Observation (@Observable, withObservationTracking/Observations), Swift 6.x
  concurrency isolation and ordering, view identity/performance, and AppKit
  integration. Use for macOS SwiftUI architecture, debugging re-renders,
  concurrency fixes, SwiftData + SwiftUI data flow, and NSViewRepresentable/
  NSHostingView bridging. Do not use for UIKit-only work, iOS-only design
  guidance, or basic Swift syntax questions.
license: MIT
compatibility: >-
  Targets modern macOS: macOS 15 and macOS 26 (and later).
  Tooling: Xcode 16+ (macOS 15 SDK) and Xcode 26+ (macOS 26 SDK) with Swift 6.x.
  Swift 6.2-specific APIs are gated with `#if swift(>=6.2)` / `@available(...)`.
metadata:
  author: kageroumado
  version: "1.3.0"
---

Guide SwiftUI development for macOS apps. Whether writing new code or reviewing existing code, apply a *mechanistic* understanding of SwiftUI’s update pipeline: how observation dependencies are registered, how view identity affects state retention, and how isolation/executors interact with SwiftUI lifecycles.

## Scope: macOS, not iOS

Be explicit about platform boundaries:

- Assume **AppKit + SwiftUI on macOS 15+** unless the user states otherwise.
- Avoid iOS-only types and recipes (`UIViewRepresentable`, `UIWindowScene`, `UIApplicationDelegateAdaptor`, UIKit appearance proxies, iOS-only navigation idioms).
- macOS has different interaction expectations: menus/commands, keyboard shortcuts, pointer hover, and focus navigation.
- When a web source is iOS-first, translate it to the macOS equivalent (see `references/scope.md`) or discard it.

## Operating mode

### When writing code

1. State the assumed **OS + toolchain** (default: macOS Tahoe 26 + Swift 6.2, add availability gates for macOS 15).
2. Choose the right **state ownership** model (global managers vs per-window state; transient `@State` for gestures).
3. Prefer **deterministic, testable** designs:
   - isolate side effects in manager/model layers
   - use `.task(id:)` for cancellable async work
   - prefer compile-checked patterns (`assets/examples/SwiftUIMacOSPatterns`)
   - prefer “measure first” performance work (Instruments SwiftUI instrument in Xcode 26)

### When reviewing code

Organize findings by file, prioritizing issues that are both correctness- and user-impacting:

- observation scope / over-notification / accidental dependencies
- identity thrash (unstable `.id()`, structural identity churn)
- incorrect isolation (unexpected MainActor work; unsafe non-Sendable crossing)
- AppKit bridge inefficiencies (`updateNSView` churn, coordinator lifetimes)
- SwiftData misuse (model objects crossing actors; CloudKit constraint violations)
- macOS UX gaps (missing menu items/shortcuts, broken focus order)

For each issue: (1) what is wrong, (2) why it matters at runtime, (3) the smallest safe fix.

## References

Load only what the task needs.

| Reference | Load when |
|---|---|
| `references/scope.md` | macOS vs iOS boundary questions; translating iOS-first advice into macOS patterns |
| `references/observation.md` | `@Observable` / `@State` questions, list churn, observation outside SwiftUI, `Observations` streams |
| `references/concurrency.md` | Task ordering, isolation/executors, Sendable friction, Swift 6.2 `nonisolated(nonsending)` / `@concurrent` |
| `references/performance.md` | Excess updates, identity resets, SwiftUI 26 list gains, Instruments SwiftUI instrument |
| `references/views.md` | View decomposition, navigation, `.task(id:)`, `NavigationSplitView`, `Table`, inspectors |
| `references/platform.md` | `NSViewRepresentable`, `NSHostingView`, window management, commands/menus |
| `references/data.md` | Environment-injected managers, `@Bindable`, SwiftData/CloudKit, `@ModelActor` |
| `references/api.md` | Modern SwiftUI APIs/macros (`@Entry`, `@Previewable`, `@Animatable`, WebView, rich text, find/replace) |
| `references/accessibility.md` | VoiceOver, keyboard navigation, focus, Reduce Motion/Transparency |
| `references/workflows.md` | Agentic verification loops, debugging view updates, Xcode/Instruments workflows |

## Local assets

When you need compile-checked examples, use:

- `assets/examples/SwiftUIMacOSPatterns` (Swift package)
- `assets/templates/MacOSSwiftUIAppTemplate` (ready-to-run scaffold; open in Xcode 16+/26+)

When editing this skill package, run:

- `scripts/verify.sh`
