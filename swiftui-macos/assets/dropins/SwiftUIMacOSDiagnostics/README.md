# SwiftUIMacOSDiagnostics (drop-in)

A small set of **drop-in Swift files** for debugging and hardening SwiftUI apps on **macOS**.

## How to use

### 1) Copy into your repo

Either:

- Copy the whole folder into your repo (recommended for agentic workflows):
  - `Support/SwiftUIMacOSDiagnostics/`

or

- Copy individual files into an existing target/module.

### 2) Add the files to a build target

- **SwiftPM**: install under `Sources/<Target>/Support/SwiftUIMacOSDiagnostics/` (keep only `.swift` files under `Sources/`; `install_dropins.sh --swiftpm-target` handles this).
- **Xcode project**: add the folder to the target (File Inspector → Target Membership).

### 3) Use the helpers

- **Main-actor assertions**: `MainActorChecks.assertIsolated()`
- **Task cancellation tracing**: `TaskTracing.run("label") { ... }`
- **Observation outside SwiftUI**:
  - `ObservationTracing.startLoop { ... }` (works on macOS 15+)
  - `Observations` async sequence (macOS 26+, Swift 6.2)
- **NSWindow access from SwiftUI**: `.onWindowResolved { window in ... }`
- **Representable diffing**: `RepresentableDiffing.applyIfChanged(...)`

## Files

- `MainActorChecks.swift` — debug-only assertions for MainActor isolation.
- `TaskTracing.swift` — cancellation-aware task helpers with `os.Logger`.
- `ObservationTracing.swift` — `withObservationTracking` loops + `Observations` wrappers.
- `WindowReader.swift` — `NSWindow` access without global singletons.
- `RepresentableDiffing.swift` — micro-helpers for idempotent `updateNSView`.

## Design constraints

- No external dependencies.
- Safe defaults (debug-only assertions/logging).
- Prefer compile-time gating:
  - `@available(macOS 26.0, *)` / `#if swift(>=6.2)` for `Observations`.
