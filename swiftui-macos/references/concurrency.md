# Swift concurrency for SwiftUI on macOS (Swift 6.x)

This reference focuses on concurrency behaviors that most often affect SwiftUI correctness and performance on macOS: **actor isolation**, **execution ordering**, and **long-lived tasks**.

> macOS note: “Main thread” and “MainActor” are related but not identical concepts. Treat UI mutations as **MainActor-only** unless you have a proven exception.

## Ordering and scheduling: `Task {}` vs `Task.immediate {}` (Swift 6.2)

Unstructured tasks (`Task { ... }`) enqueue work and may run after the current synchronous scope completes.

Swift 6.2 adds **immediate tasks** (`Task.immediate`) to start executing immediately (until the first suspension point) when already on a suitable executor (motivated by SE-0472).

```swift
@MainActor
func demo(log: (String) -> Void) {
    log("1")
    Task { @MainActor in log("2") }
    log("3")
    // typical: 1, 3, 2

    #if swift(>=6.2)
    log("A")
    Task.immediate { @MainActor in log("B") }
    log("C")
    // when already on MainActor: A, B, C
    #endif
}
```

Use `Task.immediate` when you need predictable ordering on the *current* executor and want Task semantics (cancellation, priority, task locals) without an extra hop.

## Swift 6.2 isolation spellings: `nonisolated(nonsending)` vs `@concurrent`

Swift 6.2 accepted SE-0461 (with modifications) and introduces explicit spellings for two behaviors you care about:

- `nonisolated(nonsending)`: **stay on the caller’s actor** (useful for UI-adjacent helpers that touch non-Sendable state)
- `@concurrent`: **always switch off an actor** (useful for CPU-bound work you want to run concurrently)

```swift
// Caller-actor behavior (good for UI code paths that must not hop unexpectedly)
#if swift(>=6.2)
nonisolated(nonsending)
#endif
func updateCache() async { /* ... */ }

// Always switch off actor behavior (good for CPU-bound work)
#if swift(>=6.2)
@concurrent
#endif
func hashLargeFile() async -> Digest { /* ... */ }
```

Practical rule:

- If calling an async helper from a SwiftUI view or a `@MainActor` model, assume you are on MainActor and be deliberate about whether the helper should *inherit* that isolation or *escape* it.

## Default Actor Isolation (Xcode / SwiftPM)

Modern toolchains can set **Default Actor Isolation = MainActor** for UI targets. This means many unannotated declarations are implicitly MainActor-isolated unless you opt out.

### SwiftPM: `SwiftSetting.defaultIsolation`

For packages, SwiftPM exposes a setting to configure default isolation:

```swift
// Package.swift
.target(
  name: "MyPackage",
  swiftSettings: [
    .defaultIsolation(MainActor.self)
  ]
)
```

Always validate behavior against your toolchain’s diagnostics; default isolation interacts with compiler upcoming features and project settings.

## `Task {}` inherits isolation (do not assume background)

`Task {}` inherits the caller’s isolation. If you create a task inside MainActor code, it will typically start on MainActor.

If you need to ensure work runs concurrently/off the actor, use either:

- `Task.detached { ... }` (does not inherit; be strict about Sendable captures)
- `@concurrent` async helpers (preferred API design surface)

## Sendable friction and escape hatches

When strict checking is enabled, captures into concurrent contexts can produce errors for non-Sendable values.

Preferred fixes:

- isolate mutable state in an actor
- copy value types into a task
- pass identifiers across actors and refetch on the receiving actor (SwiftData models are not Sendable)

### Bridging legacy code: `DispatchQueue.asyncUnsafe`

When intentionally bridging pre-concurrency code and you fully understand the risk, `DispatchQueue.asyncUnsafe` can bypass Sendable checking for a closure dispatched to a queue.

Treat this as a last resort: it opts out of compile-time data-race safety.

## Long-lived work and cancellation

### Prefer `.task(id:)` for view-driven work

`.task(id:)` is cancellation-aware and tied to view lifetime:

```swift
struct ProfileView: View {
    let userID: User.ID

    var body: some View {
        content
            .task(id: userID) {
                await model.load(userID: userID)
            }
    }
}
```

The system cancels the prior task when the ID changes and cancels when the view disappears.

### Periodic background work (macOS)

Avoid tight polling loops when the system can coalesce work. For background sync, prefer `NSBackgroundActivityScheduler` when it fits your use case.

## Compile-checked examples in this repo

- [`ConcurrencyExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/ConcurrencyExamples.swift)

## Primary sources (for verification)

- Swift 6.2 release notes: https://swift.org/blog/swift-6.2-released/
- SE-0461: async function isolation: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
- Compiler docs: `nonisolated(nonsending)` by default: https://docs.swift.org/compiler/documentation/diagnostics/nonisolated-nonsending-by-default/
- SE-0472: starting tasks synchronously: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md
- `DispatchQueue.asyncUnsafe`: https://developer.apple.com/documentation/dispatch/dispatchqueue/asyncunsafe%28group%3Aqos%3Aflags%3Aexecute%3A%29
