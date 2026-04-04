# Agentic workflows for SwiftUI on macOS

This reference focuses on repeatable loops that an agent can run to validate SwiftUI changes on macOS, with specific guidance for macOS 15 and macOS Tahoe 26.

## Minimal verification loop (fast)

Use this loop when changing SwiftUI view code or state management:

1. **Build** (compile errors first)
2. **Run targeted tests** (unit tests; UI tests only when needed)
3. **Collect machine-verifiable signals** (logs, deterministic snapshots, structured diagnostics)

### Xcode build (CLI)

```bash
xcodebuild \
  -scheme MyApp \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

If the project uses SwiftPM (no Xcode project):

```bash
swift build
swift test
```

## macOS-first research loop (avoid iOS confusion)

When you need to look something up:

1. Start with a **primary source** query:
   - Apple docs / WWDC session / Swift Evolution / Swift Forums
2. Add macOS bias and iOS exclusions:
   - include: `macOS`, `AppKit`, `NSViewRepresentable`, `WindowGroup`
   - exclude: `-UIKit -UIViewRepresentable -UIHostingController -UIApplication`
3. Verify the **minimum macOS availability** (15 vs 26) before writing code.

## Debugging “why is this view updating?”

### 1) `Self._printChanges()` (underscored / debug-only)

`Self._printChanges()` is an underscored SwiftUI debugging helper that prints why a view’s body reevaluated.

Pattern:

```swift
var body: some View {
    #if DEBUG
    let _ = Self._printChanges()
    #endif
    return content
}
```

Guidelines:

- Use it for short-lived investigations.
- Do not ship it in release builds.
- Because it is underscored, it may change across OS/toolchain versions.

### 2) Instruments: SwiftUI “cause & effect” (Xcode 26)

Use Instruments when:

- an update is triggered far away from the view you see updating
- you suspect identity thrash (`.id`, conditional subtrees, type erasure)
- you need to correlate observation notifications with UI churn

Practical workflow:

1. Build and run the app.
2. Product → Profile.
3. Select the **SwiftUI** instrument/template.
4. Reproduce the UI issue.
5. Inspect the cause-and-effect graph to identify what change caused which view updates.

### 3) Visual update debugging (Xcode)

When available in Xcode, enable the SwiftUI debug option to flash updated regions to validate whether updates are localized or cascading. Use it to confirm that fixes actually reduce churn.

## Repro harnesses for tricky bugs

### Deterministic reproduction with a “debug scene”

For timing-sensitive view lifecycle or concurrency issues, add a dedicated debug-only scene:

```swift
#if DEBUG
Window("Debug", id: "debug") {
    DebugReproView()
}
#endif
```

Keep `DebugReproView` minimal:

- inject a minimal environment graph
- provide one reproduction action (button/menu item)
- emit structured logs

### Structured logging

Prefer `Logger` (`os.log`) over ad-hoc `print` in production code. For agent-driven debugging, keep logs stable and searchable:

- include an event name
- include IDs (window value, item IDs)
- avoid dumping large objects

## UI testing: when you actually need it

UI tests are expensive and can be flaky. Use them when:

- correctness depends on user flow (window management, focus, keyboard navigation)
- regressions are hard to detect from unit tests

Guidelines:

- Keep UI tests small: one flow per test.
- Use stable accessibility identifiers.
- Avoid sleeps; prefer expectations and predicates.

## Asset-backed examples and templates

This skill repo includes:

- a compile-checked Swift package: `assets/examples/SwiftUIMacOSPatterns`
- a ready-to-run scaffold: `assets/templates/MacOSSwiftUIAppTemplate`

Use them as copy/paste sources, and keep them compiling when updating examples.

## Primary sources (for verification)

- Debugging SwiftUI view updates with `_printChanges`: https://www.avanderlee.com/swiftui/debugging-swiftui-views/
- WWDC25: What’s new in Xcode (SwiftUI instrument): https://developer.apple.com/videos/play/wwdc2025/247/
- Xcode 26 release notes: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
