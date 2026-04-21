# Observation tracking discipline (macOS SwiftUI)

`@Observable` makes every stored property a potential observation dependency. Any property read during a SwiftUI view’s `body` evaluation can become a tracked dependency; when that dependency changes, SwiftUI reevaluates `body` for that view.

The goal is not “avoid updates”; the goal is **scope the right updates to the right views** and avoid accidental dependencies.

## Property wrapper decision rule (short)

In SwiftUI + Observation, you can usually get to the right answer with:

- `@State` — view owns a value/reference and SwiftUI owns the lifetime
- `@Environment` — dependency injection
- `@Bindable` — create bindings into an `@Observable` reference

(See WWDC23 “Discover Observation in SwiftUI”.)

## Accidental dependencies (common on macOS)

### Toolbars / commands / menus

On macOS, toolbars and menus are frequently built from SwiftUI view trees. If you build menu content by reading a broad `@Observable` manager, you can accidentally make the entire command tree dependent on “everything”.

Heuristic:

- toolbar/menu views should read only minimal state (IDs, small flags)
- use computed “projection” properties that return small values

## Narrow reads inside hot loops

Avoid repeatedly reading the same observable property inside a `ForEach` body when you can capture once:

```swift
var body: some View {
    let activeID = manager.activeItemID

    return List(items) { item in
        ItemRow(item: item, isActive: item.id == activeID)
    }
}
```

This both reduces repeated reads and makes the dependency surface explicit.

## Mutation granularity: collections

In-place mutations (e.g., `append`, `sort`, mutating an element through a subscript) tend to produce **broad invalidations** because they mutate the storage in place.

```swift
@Observable
final class Model {
    var items: [String] = ["A", "B", "C"]
}

model.items.append("D")  // in-place mutation -> notifies observers
model.items.sort()       // in-place mutation -> notifies observers
```

Heuristic:

- for large lists, prefer **row-level observable references** (one `@Observable` per row item)
- keep large derived arrays (filtered/sorted) out of hot view bodies; cache + invalidate explicitly

## Choose value vs reference semantics in lists

The element type of a collection materially changes update granularity:

- **Value elements (structs)**: mutating one element often mutates the whole collection value → broader notification
- **Reference elements (`@Observable` classes)**: mutating a property on one element can localize updates to views that read that element’s properties

Use reference semantics for list entities when you want “row-level” updates.

## `@ObservationIgnored`

Mark properties that should not participate in observation:

- caches and indices
- callbacks/closures
- non-observable “backing stores” that would explode dependencies

```swift
@Observable
final class Manager {
    var visibleItems: [Item] = []

    @ObservationIgnored private var index: [Item.ID: Item] = [:]
    @ObservationIgnored var onRemoval: ((Item.ID) -> Void)?
}
```

## Observation outside SwiftUI

SwiftUI handles dependency tracking for view updates. Outside SwiftUI, you have two main tools.

### `withObservationTracking` (macOS 15 era)

A classic pattern: re-run work when the observed properties change.

```swift
import Observation

func observeCounter(_ counter: Counter) {
    withObservationTracking {
        print("count:", counter.count)
    } onChange: {
        Task { observeCounter(counter) }
    }
}
```

This is widely available, but it is not transactional: if you perform multiple synchronous mutations, you may observe intermediate states.

### `Observations` async sequence (macOS 26 + Swift 6.2)

`Observations` is an `AsyncSequence` that emits **transactional** updates: synchronous changes coalesce until the next suspension point.

```swift
import Observation

@Observable
final class Counter { var count = 0 }

@MainActor
func printChanges(counter: Counter) async {
    let messages = Observations { "count = \(counter.count)" }
    for await message in messages {
        print(message)
    }
}
```

Prefer `Observations` when:

- you need a long-lived stream of changes
- you want consistent snapshots during bursts of synchronous writes
- you are building “auto-save on change” behaviors (common in multi-window macOS apps)

Drop-in wrapper:

- `assets/dropins/SwiftUIMacOSDiagnostics/ObservationTracing.swift`

## Compile-checked examples in this repo

- [`ObservationExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/ObservationExamples.swift)

## Primary sources (for verification)

- WWDC23: Discover Observation in SwiftUI: https://developer.apple.com/videos/play/wwdc2023/10149/
- Observability proposal (macro model): https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md
- Swift 6.2 release notes (Observations async sequence): https://swift.org/blog/swift-6.2-released/
- Transactional observation proposal (SE-0475): https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md
- Apple docs: `Observations`: https://developer.apple.com/documentation/observation/observations
