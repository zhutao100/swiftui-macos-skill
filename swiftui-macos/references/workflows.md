# Agentic workflows for SwiftUI on macOS

This reference focuses on **repeatable loops** that an agent can run to validate SwiftUI changes.

## Minimal verification loop (fast)

Use this loop when changing SwiftUI view code or state management:

1. **Build** (compile errors first)
2. **Run targeted tests** (unit tests; UI tests only when needed)
3. **Collect machine-verifiable signals** (console logs, deterministic snapshots, or structured diagnostics)

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

## Debugging “why is this view updating?”

### 1) `Self._printChanges()` (debug-only)

`Self._printChanges()` is a commonly used (private) SwiftUI debugging hook that prints what triggered a `body` reevaluation.

Pattern:

```swift
var body: some View {
    #if DEBUG
    let _ = Self._printChanges()
    #endif

    return content
}
```

Use it to confirm whether an observed property, identity change, or environment mutation is the true invalidation source.

### 2) Instruments: SwiftUI “cause & effect”

Use Instruments when:

- an update is triggered far away from the view you see re-rendering
- you suspect identity thrash (`.id`, `_ConditionalContent`, `AnyView`)
- you need to correlate observation notifications with UI churn

Practical workflow:

1. Build and run the app.
2. Open Instruments and select the **SwiftUI** instrument (or the SwiftUI template when available).
3. Reproduce the UI issue.
4. Inspect the cause-and-effect graph to identify what change caused which view updates.

### 3) Visual update debugging

When available in Xcode, enable the SwiftUI debug option to **flash updated regions** to validate whether a change is localized or cascading through the tree.

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

Then keep a single minimal `DebugReproView` that:

- injects a minimal environment graph
- has a single reproduction action (a button)
- prints structured logs for the agent to read

### Structured logging

Prefer `Logger` (os.log) over ad-hoc `print` in production code. For agent-driven debugging, keep logs **stable** and **searchable**:

- include an event name
- include IDs (window ID, item IDs)
- avoid dumping large objects

## UI testing: when you actually need it

UI tests are expensive and can be flaky. Use them when:

- correctness depends on user flow (window management, focus, keyboard navigation)
- regressions are hard to detect from unit tests

Guidelines:

- Keep UI tests small: one flow per test.
- Use stable accessibility identifiers.
- Avoid sleeps; prefer expectations and predicates.

## Asset-backed examples

This skill repo includes a compile-checked Swift package:

- `assets/examples/SwiftUIMacOSPatterns`

Use it as a starting point for copy-pasteable patterns, and keep it compiling when updating examples.
