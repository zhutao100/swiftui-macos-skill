# Web research strategy (macOS-first)

## Primary sources (preferred)

1. Apple Developer Documentation (API reference + conceptual docs)
2. WWDC sessions (transcripts / sample code links)
3. Swift Evolution proposals + vision docs
4. Swift Forums threads (especially when clarifying new Swift 6.2 behavior)

## Query patterns

### Prefer macOS/AppKit results


- `WebKit for SwiftUI WebView WebPage macOS Tahoe 26`
- `Observations AsyncSequence Observation framework macOS 26`
- `SwiftUI Instruments SwiftUI instrument Xcode 26 cause and effect`
- `SwiftUI macOS 15 openWindow dismissWindow WindowGroup(for:)`
- `NSViewRepresentable updateNSView coordinator NSTextView macOS`
- `Swift 6.2 nonisolated(nonsending) @concurrent SE-0461`

### Avoid iOS-first answers

Add explicit exclusions when necessary:

- `SwiftUI toolbar placement macOS -UIKit -UIViewController`
- `SwiftUI representable macOS -UIViewRepresentable -UIKit`

### Verify availability

When an API seems “new”, verify:

- the symbol exists in Apple docs
- platform availability includes macOS 15+ (or macOS 26 when relevant)
- whether the docs page requires JavaScript; if so, use alternate sources (WWDC transcript, Swift Forums) to confirm details

## What to do when sources disagree

- Prefer Apple docs and Swift Evolution over blogs.
- If there is still ambiguity:
  - downgrade the claim to a hypothesis
  - include a minimal reproducible example and a test plan
