# Observation tracking discipline

`@Observable` makes every stored property a potential observation dependency. Any property read during a SwiftUI view’s `body` evaluation can become a tracked dependency; when that dependency changes, SwiftUI reevaluates `body` for that view.

The goal is not “avoid updates”; the goal is **scope the right updates to the right views** and avoid accidental dependencies.

## Narrow reads inside hot loops

Avoid repeatedly reading the same observable property inside a `ForEach` body when you can capture once:

```swift
// Prefer capturing once per body evaluation
var body: some View {
    let activeID = manager.activeItemID

    return List(items) { item in
        ItemRow(item: item, isActive: item.id == activeID)
    }
}
```

This reduces repeated reads, reduces the chance of accidentally widening dependencies, and makes the tracking surface explicit.

## `shouldNotifyObservers` and “equatable” notification

When you expand the `@Observable` macro, you’ll find helper overloads that decide whether a `set` should notify observers.

Conceptually:

```swift
func shouldNotifyObservers<T>(_ old: T, _ new: T) -> Bool { true }                  // non-Equatable
func shouldNotifyObservers<T: Equatable>(_ old: T, _ new: T) -> Bool { old != new } // Equatable
func shouldNotifyObservers<T: AnyObject>(_ old: T, _ new: T) -> Bool { old !== new } // identity
```

Implications:

- **Non-Equatable value types**: any `set` notifies, even if the value is “logically the same”.
- **Equatable value types**: `set` can be a no-op if values are equal.
- **Reference types**: notification depends on identity unless the type is also `Equatable`.

Practical rule: make observable value types `Equatable` whenever it is semantically correct.

## `_modify` always notifies

In-place mutations (e.g., appending to an array, mutating an element via subscript, sorting) go through `_modify` accessors. `_modify` avoids equality checks because checking equality would require copying or otherwise materializing the old value.

```swift
@Observable
final class Model {
    var items: [String] = ["A", "B", "C"]
}

model.items.append("D")         // in-place mutation -> notifies
model.items.sort()              // in-place mutation -> notifies
model.items = model.items       // full assignment -> may *not* notify if Equatable
```

This is why “mutate collections directly” can cause broad invalidations in large trees.

## Choose value vs reference semantics in collections

The element type of a collection materially changes update granularity:

- **Value elements (structs)**: mutating an element often mutates the whole collection value → broader notification.
- **Reference elements (`@Observable` classes)**: mutating a property on one element can localize updates to views that read that element’s properties.

Use reference semantics for list entities when you want “row-level” updates.

## Version counters for large structures

When a collection is large or deeply nested, observing the full structure can be expensive.

A common pattern is:

- keep the structure in a non-public store
- expose a cheap `itemsVersion` counter that increments on mutation

```swift
@Observable
final class Store {
    private var items: [Item] = []
    var itemsVersion: UInt64 = 0

    func add(_ item: Item) {
        items.append(item)
        itemsVersion &+= 1
    }

    func snapshot() -> [Item] { items }
}

struct ItemsView: View {
    @Environment(\.store) private var store

    var body: some View {
        let _ = store.itemsVersion // dependency
        let items = store.snapshot()
        return List(items) { ItemRow(item: $0) }
    }
}
```

This trades “fine grained change tracking” for explicit invalidation boundaries.

## `@ObservationIgnored`

Mark properties that should not participate in observation:

- internal indices and caches
- callbacks and closures
- bookkeeping state

```swift
@Observable
final class Manager {
    var visibleItems: [Item] = []

    @ObservationIgnored
    private var index: [Item.ID: Item] = [:]

    @ObservationIgnored
    var onRemoval: ((Item.ID) -> Void)?
}
```

## Observation outside SwiftUI

### `withObservationTracking` (OS 17+ era)

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

### `Observations` async sequence (OS 26+)

On macOS 26+, `Observations` provides an `AsyncSequence` of **transactional** updates.

```swift
import Observation

@Observable
final class Counter {
    var count = 0
}

@MainActor
func printChanges(counter: Counter) async {
    let messages = Observations { "count = \(counter.count)" }
    for await message in messages {
        print(message)
    }
}
```

Prefer `Observations` when:

- you need a long-lived stream of state changes
- you want transactional snapshots (coalesced synchronous mutations)

## Manual tracking for ignored backing stores

The macro instruments stored properties. If you keep data in an ignored store (KVO bridges, throttled values, derived caches), you may need to manually track and notify:

```swift
@Observable
final class Bridge {
    @ObservationIgnored private var _progress: Double = 0

    var progress: Double {
        access(keyPath: \.progress)
        return _progress
    }

    func updateProgress(_ value: Double) {
        guard _progress != value else { return }
        _$observationRegistrar.willSet(self, keyPath: \.progress)
        _progress = value
        _$observationRegistrar.didSet(self, keyPath: \.progress)
    }
}
```

## Further reading

- Apple: `withObservationTracking` and Observation overview
- Swift Evolution: SE-0395 Observability
- Swift 6.2: `Observations` (AsyncSequence)
