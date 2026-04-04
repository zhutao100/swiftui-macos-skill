# Observation tracking discipline (macOS SwiftUI)

`@Observable` makes every stored property a potential observation dependency. Any property read during a SwiftUI view’s `body` evaluation can become a tracked dependency; when that dependency changes, SwiftUI reevaluates `body` for that view.

The goal is not “avoid updates”; the goal is **scope the right updates to the right views** and avoid accidental dependencies.

> macOS note: iOS-first articles often discuss `ObservableObject`/Combine. This file focuses on Swift’s Observation framework (`@Observable`) as used by SwiftUI on macOS.

## Common macOS pitfall: accidental dependencies in menu/toolbars

On macOS, toolbars and menus are frequently built from SwiftUI view trees. If you build menu content by reading a broad `@Observable` manager, you can accidentally make the entire command tree dependent on “everything”.

Heuristic:

- Toolbar/menu views should read only the minimum state needed (IDs, small flags).
- Prefer computed “projection” properties on the manager that return simple values.

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

This reduces repeated reads, and—more importantly—makes the dependency surface explicit.

## Mutation granularity: collections and `_modify`

In-place mutations (e.g., `append`, `sort`, mutating an element through a subscript) tend to produce **broad invalidations** because they mutate the storage in place.

```swift
@Observable
final class Model {
    var items: [String] = ["A", "B", "C"]
}

model.items.append("D")  // in-place mutation -> notifies observers
model.items.sort()       // in-place mutation -> notifies observers
```

**Heuristic:** for large lists, prefer *row-level* observable references (one `@Observable` per row item) over storing everything in one big observable array.

## Choose value vs reference semantics in lists

The element type of a collection materially changes update granularity:

- **Value elements (structs)**: mutating one element often mutates the whole collection value → broader notification.
- **Reference elements (`@Observable` classes)**: mutating a property on one element can localize updates to views that read that element’s properties.

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

### `withObservationTracking` (macOS 14+ era)

Use `withObservationTracking` to rerun work when the observed properties change:

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

### `Observations` async sequence (macOS Tahoe 26 + Swift 6.2)

On macOS 26+, `Observations` provides an `AsyncSequence` of **transactional** updates (synchronous mutations coalesce until the next suspension point).

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
- you want transactional snapshots (avoid intermediate states during a burst of synchronous writes)
- you are building “auto-save on change” behaviors (common in multi-window macOS apps)

## Compile-checked examples in this repo

- [`ObservationExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/ObservationExamples.swift)

## Primary sources (for verification)

- Observation framework overview: https://developer.apple.com/documentation/Observation
- `Observations` API: https://developer.apple.com/documentation/observation/observations
- Observability proposal (macro model): https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md
- Transactional observation pitch/discussion: https://forums.swift.org/t/pitch-transactional-observation-of-values/78315
