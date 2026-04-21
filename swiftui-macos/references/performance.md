# Performance (macOS SwiftUI)

Performance work in SwiftUI should be measurement-driven. Optimize only after you can point to a concrete signal: an Instruments trace, a known identity reset boundary, or a specific observation dependency causing churn.

## Fast triage

1. Run the heuristic repo audit:

```bash
python3 swiftui-macos/scripts/swiftui_audit.py /path/to/repo --out /tmp/swiftui_audit.md
```

2. Fix the highest-signal identity issues first:

- `.id(UUID())` and other unstable IDs
- fragile `ForEach` IDs (`id: \.self` with non-unique/non-stable elements)

3. If the issue is runtime-only (hitches, stutters), profile with Instruments.

See also: `references/diagnostics.md`.

## Measure first: Instruments (Instruments 26 / Xcode 26)

When debugging “why is this view updating?” or “why is scrolling janky?” use Instruments.

The SwiftUI template includes a **SwiftUI instrument** with high-level lanes:

- **Update Groups**: when SwiftUI is doing work
- **Long View Body Updates**: slow `body` evaluations
- **Long Representable Updates**: slow `NSViewRepresentable` / `NSViewControllerRepresentable` updates
- **Other Long Updates**: other slow SwiftUI work

Use the **cause → effect** graph to connect a triggering mutation to the resulting view updates.

Notes:

- The prior SwiftUI templates/instruments (View Body / View Properties) are deprecated and replaced in Xcode 26.
- Start with the long updates highlighted in red/orange and work outward.

## View identity discipline

SwiftUI tracks identity primarily by **type** and **position** in the view tree. Identity mistakes commonly present as:

- state resets (`@State` cleared)
- `.task` restarts
- representables recreated
- animations restarting

### Structural identity (`if`/`else`, `switch`)

Branching produces `_ConditionalContent<TrueContent, FalseContent>`. When the branch changes, SwiftUI treats it as a different identity and will destroy the previous subtree (including `@State`, running `.task`s, and backing platform views), then create a new subtree.

Prefer changing *modifier values* over changing the *view structure* when identity must be preserved:

```swift
// Good: same view identity; only a value changes
content.opacity(isVisible ? 1 : 0)

// Risky: identity changes when the structure changes
if isVisible {
    content
} else {
    content.opacity(0)
}
```

## The `.id()` modifier

`.id()` overrides identity. When the value changes, SwiftUI destroys and recreates the view subtree.

```swift
// Catastrophic: new UUID each render -> recreates every time
ItemRow(item: item).id(UUID())

// Correct: stable identity
ItemRow(item: item).id(item.id)
```

Use `.id(...)` only when you intentionally want a reset boundary (for example, resetting selection or scroll position).

## Equatable views

If a view’s inputs are small, stable value types, conforming to `Equatable` can help SwiftUI skip re-evaluating the view’s body when the values haven’t changed.

```swift
struct ExpensiveChart: View, Equatable {
    let data: [DataPoint]
    let style: ChartStyle

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data && lhs.style == rhs.style
    }

    var body: some View { /* expensive */ }
}
```

**Caveat:** avoid `Equatable` views whose inputs are reference-typed model objects (for example, SwiftData `@Model` instances). Compare identifiers or value snapshots instead.

## Representables: optimize `updateNSView`

Assume `updateNSView(_:context:)` can run frequently. Make it:

- fast
- idempotent
- internally diffed (early-out when desired state matches last applied state)

Pattern: store “last applied” values in the coordinator and early-out.

Drop-in helper:

- `assets/dropins/SwiftUIMacOSDiagnostics/RepresentableDiffing.swift`

## Avoid `AnyView`

`AnyView` erases type information that SwiftUI uses to diff efficiently. Prefer `@ViewBuilder`, `Group`, and generics.

## Initializers must be trivial

View initializers must not perform I/O or heavy work. Move work to `.task {}` or model layers.

## Body evaluation: keep hot paths cheap

`body` is recomputed whenever any tracked dependency of that view changes. Avoid expensive derivations inline:

```swift
// Bad: sorts on every recompute
ForEach(items.sorted(by: { $0.date > $1.date })) { /* ... */ }

// Better: derive once per recompute
let sorted = items.sorted(by: { $0.date > $1.date })
ForEach(sorted) { /* ... */ }
```

For expensive derivations that change rarely, cache in `@State` with explicit invalidation.

## ForEach optimization

Extract row bodies into separate `View` structs. This gives each row its own observation scope so changes can localize to a single row.

## Continuous gestures: keep per-frame values in `@State`

Gesture updates can occur at display refresh rates. Store gesture-driven values (`offset`, `scale`, `rotation`) in `@State` rather than an `@Observable` model to avoid routing every frame through the observation pipeline.

## Compile-checked examples in this repo

- [`IdentityExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/IdentityExamples.swift)

## Primary sources (for verification)

- WWDC25: Optimize SwiftUI performance with Instruments: https://developer.apple.com/videos/play/wwdc2025/306/
- WWDC21: Demystify SwiftUI (identity/lifetime/dependencies): https://developer.apple.com/videos/play/wwdc2021/10022/
- WWDC23: Demystify SwiftUI performance: https://developer.apple.com/videos/play/wwdc2023/10160/
- Xcode 26 release notes (SwiftUI instrument template replacement): https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
