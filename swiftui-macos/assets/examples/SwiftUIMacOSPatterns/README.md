# SwiftUIMacOSPatterns

A small Swift package containing **compile-checked** SwiftUI/AppKit patterns used by this skill.

## Requirements

- Xcode 26+ (Swift 6.2+) recommended
- Deployment target: macOS 15+ (Sequoia)
  Some examples are gated to macOS Tahoe 26 with `@available(macOS 26.0, *)`.

## Build / test

```bash
swift build
swift test
```

## Contents

- Observation: `Sources/Patterns/ObservationExamples.swift`
- Concurrency: `Sources/Patterns/ConcurrencyExamples.swift`
- Identity/perf: `Sources/Patterns/IdentityExamples.swift`
- AppKit bridging: `Sources/Patterns/PlatformExamples.swift`
- Windowing: `Sources/Patterns/WindowingExamples.swift`
- New APIs (Tahoe 26): `Sources/Patterns/APIExamples.swift`, `WebViewExamples.swift`
