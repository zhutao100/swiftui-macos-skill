# Performance (macOS SwiftUI)

Performance work in SwiftUI should be measurement-driven. On macOS Tahoe 26 and Xcode 26, SwiftUI performance tooling improved significantly (new SwiftUI instrument + cause-and-effect graph).

## Measure first: Instruments (Xcode 26)

When debugging “why is this view updating?” or “why is scrolling janky?”:

1. Product → Profile (Instruments).
2. Choose the **SwiftUI** instrument/template.
3. Reproduce the issue.
4. Inspect the **cause-and-effect** graph to see which state mutations triggered which view updates.
5. Use the “hot” nodes as the basis for fixes.

Notes:

- Xcode 26 replaced older “View Body”/“View Properties” instruments with the newer SwiftUI instrument template.
- For quick localization checks, combine Instruments with debug-only `_printChanges()` (see `references/workflows.md`).

## SwiftUI 26 list improvements are not a substitute for good identity

SwiftUI 26 includes large performance gains for big lists on macOS, but the classic failure modes still apply:

- unstable identity (`.id(UUID())`)
- re-sorting/re-filtering in `body` without caching
- row bodies that read “too much” observable state (global invalidations)

Treat framework improvements as headroom, not as permission to ignore identity discipline.

## View identity

SwiftUI tracks view identity primarily by **type** and **position** in the view tree. Identity mistakes are a common source of “why did my state reset?” and “why did this task restart?” issues.

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

Use `.id(...)` only when you intentionally want a reset boundary (e.g., to reset scroll position). Never use a value that changes on every body evaluation.

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

## Representables: optimize `updateNSView`, don’t assume call suppression

For `NSViewRepresentable`, you must assume `updateNSView(_:context:)` can run frequently. Make it:

- fast
- idempotent
- internally diffed (early-out when the desired state matches the last applied state)

Common pattern: store “last applied” values in the coordinator.

```swift
final class Coordinator {
    var lastAppliedText: String?
}
```

Then in `updateNSView`, only apply changes when different.

## Avoid `AnyView`

`AnyView` erases type information that SwiftUI uses to diff efficiently. Prefer `@ViewBuilder`, `Group`, and generics.

## Initializers must be trivial

View initializers must not perform I/O or heavy work. Move work to `.task {}` or to model layers.

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

## Canvas and TimelineView

Use `Canvas` for immediate-mode drawing when a view tree of hundreds of shapes would be expensive.

Use `TimelineView` for scheduled updates (e.g., continuous animations) without driving the entire parent view tree.

## Compile-checked examples in this repo

- [`IdentityExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/IdentityExamples.swift)

## Primary sources (for verification)

- WWDC25: What’s new in SwiftUI (SwiftUI instrument, list improvements): https://developer.apple.com/videos/play/wwdc2025/256/
- Xcode 26 release notes (Instruments SwiftUI template changes): https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes
