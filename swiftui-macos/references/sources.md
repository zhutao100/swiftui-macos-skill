# Sources and validation references

This skill is intentionally macOS-focused. When updating claims, prefer **primary sources**:
Apple Developer Documentation, WWDC session pages, Swift Evolution proposals, and Swift.org release notes.

## Skill format / progressive disclosure

- Agent Skills specification: https://agentskills.io/specification
- Codex Agent Skills documentation: https://developers.openai.com/codex/skills/

## Platform baselines

- macOS Tahoe 26 update notes (versioned): https://support.apple.com/en-us/122868
- Xcode release index (Swift toolchain mapping): https://xcodereleases.com/

## Swift 6.2 + concurrency semantics

- Swift 6.2 release notes: https://swift.org/blog/swift-6.2-released/
- SE-0461 (async function isolation; `nonisolated(nonsending)`): https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
- SE-0472 (`Task.immediate`): https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md
- `@concurrent` in SE-0461 (and related writeups): https://www.avanderlee.com/concurrency/concurrent-explained-with-code-examples/

## Observation framework

- Apple documentation: `Observations` (AsyncSequence): https://developer.apple.com/documentation/observation/observations
- `Observations` usage (community validation):
  - https://useyourloaf.com/blog/swift-observations-asyncsequence-for-state-changes/
  - https://www.donnywals.com/using-observations-to-observe-observable-model-properties/

## SwiftUI macros and environment keys

- `@Entry` macro:
  - Apple documentation: https://developer.apple.com/documentation/swiftui/entry()
  - WWDC24: “What’s new in SwiftUI” (mentions Entry + ContainerValues): https://developer.apple.com/videos/play/wwdc2024/10144/
- `@Previewable` macro:
  - Apple documentation: https://developer.apple.com/documentation/swiftui/previewable()
  - https://useyourloaf.com/blog/swiftui-previewable-macro/

## Windows, scenes, and macOS app structure

- `openWindow` / `dismissWindow` environment actions:
  - https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow
  - https://developer.apple.com/documentation/swiftui/environmentvalues/dismisswindow
- WWDC24: “Work with windows in SwiftUI”: https://developer.apple.com/videos/play/wwdc2024/10149/
- macOS 15 example: `defaultLaunchBehavior(.suppressed)` (discussion / validation): https://stackoverflow.com/questions/76551669/hide-all-windows-by-default-in-swiftui-macos-app

## Accessibility

- Apple HIG: Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- SwiftUI Concepts tutorial: scaling views for Dynamic Type: https://developer.apple.com/tutorials/swiftui-concepts/scaling-views-to-complement-text
