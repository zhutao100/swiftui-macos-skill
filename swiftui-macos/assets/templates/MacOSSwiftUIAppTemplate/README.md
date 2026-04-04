# MacOSSwiftUIAppTemplate

A **ready-to-run** macOS SwiftUI scaffold aligned with this skill’s guidance:

- macOS 15+ deployment target (Sequoia)
- macOS Tahoe 26-specific features are gated with `@available(macOS 26.0, *)`
- Swift 6.x (Xcode 26 recommended)

## Quick start (Xcode)

1. Open this folder in Xcode (File → Open → `Package.swift`).
2. Select the `AppTemplate` scheme.
3. Run.

## Quick start (CLI)

This is intentionally a SwiftPM-first scaffold. You can run it from Terminal:

```bash
swift run AppTemplate
```

Note: when running from `swift run`, AppKit sometimes starts in an “accessory” activation policy (no dock icon, window not frontmost). The template’s `App` initializer applies a small activation shim to behave like a normal app.

## What’s included

- Multi-window pattern: `WindowGroup` + `WindowGroup(for:)` + `openWindow`
- Menu commands and keyboard shortcuts (`commands`)
- `@Observable` + `@Entry` environment injection
- `.task(id:)` for cancellable async work
- An AppKit bridge example (`NSViewRepresentable` wrapping `NSTextView`)
- A Tahoe 26-rich text editor path (AttributedString) behind availability checks
