# Diagnostics and tooling (SwiftUI on macOS)

This reference is about **getting answers fast** when SwiftUI behaves unexpectedly: extra updates, identity resets, task restarts, or UI hitches.

## Quick triage: run the repo audit

Use the audit script to get a high-signal map of common SwiftUI footguns (identity, concurrency, representables):

```bash
python3 swiftui-macos/scripts/swiftui_audit.py /path/to/target-repo --out /tmp/swiftui_audit.md
```

Use the report to pick the first concrete targets:

- `.id(UUID())` / unstable identity
- `Task.detached` misuse
- `updateNSView` hotspots
- `AnyView` type erasure

## Install drop-in diagnostics (optional)

When you need runtime assertions or cheap tracing, install the drop-ins:

```bash
bash swiftui-macos/scripts/install_dropins.sh /path/to/target-repo
```

For SwiftPM repos, you can install into a specific target:

```bash
bash swiftui-macos/scripts/install_dropins.sh /path/to/target-repo --swiftpm-target MyTarget
```

Drop-in contents live at:

- `swiftui-macos/assets/dropins/SwiftUIMacOSDiagnostics`

Key utilities:

- `MainActorChecks.assertIsolated()`
- `TaskTracing.run("label") { ... }`
- `ObservationTracing.startLoop { ... }` and `Observations` wrappers
- `.onWindowResolved { window in ... }`

## Debug “why did this view update?”

### 1) `_printChanges()` (debug-only)

The fastest locality check:

```swift
var body: some View {
    #if DEBUG
    let _ = Self._printChanges()
    #endif
    return content
}
```

Use `_printChanges()` as a short-lived probe, then remove it.

### 2) Instruments: SwiftUI cause → effect

When the triggering mutation is far away from the view you see updating (or you suspect identity churn), use Instruments:

1. Product → Profile
2. Choose the SwiftUI template
3. Reproduce the hitch / churn
4. Inspect the cause-and-effect graph and long-update lanes

See also: `references/performance.md`.

## Debug “why did my task restart?”

Tasks restart primarily due to **identity changes**:

- `.id(...)` changes
- conditional subtree swaps (`if/else`, `switch`)
- list identity churn (`ForEach` IDs, reorder)

Use:

- `references/performance.md` (identity)
- `references/concurrency.md` (`.task(id:)` semantics)

## Debug “why did my state reset?”

State resets are almost always identity resets. Start with:

- `.id(...)` usage
- structural changes around the state owner
- ForEach ID stability

See: `references/performance.md`.
