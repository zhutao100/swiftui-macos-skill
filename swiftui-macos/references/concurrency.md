# Swift concurrency for SwiftUI on macOS (Swift 6.x)

This reference focuses on concurrency behaviors that most often affect SwiftUI correctness and performance on macOS: **actor isolation**, **execution ordering**, and **view-tied task lifetimes**.

## SwiftUI’s defaults (practical)

- Treat UI mutations as **MainActor-only**.
- In SwiftUI, many APIs are MainActor-isolated by design; assume “main-actor default” unless you’ve verified otherwise.
- Prefer `await` to yield rather than “hop to a queue”.

Drop-in helpers (optional):

- `assets/dropins/SwiftUIMacOSDiagnostics/MainActorChecks.swift`
- `assets/dropins/SwiftUIMacOSDiagnostics/TaskTracing.swift`

## View-tied tasks: `.task` and `.task(id:)`

### Prefer `.task` over `onAppear` for async work

`.task {}` starts at the beginning of the view’s lifetime and is async by default.

### Cancellation semantics

- SwiftUI can cancel a task when the view disappears.
- With `.task(id:)`, SwiftUI cancels and restarts the task when the `id` changes.

Practical pattern:

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

Rules:

- Prefer `.task(id:)` when the work is parameterized (selection, route, document ID).
- Keep `id` stable and meaningful; an unstable `id` is an implicit restart loop.

## Task inheritance

`Task {}` inherits the caller’s actor isolation. If you create a task inside MainActor code, it will typically start on MainActor.

If you need to ensure work runs off the actor, prefer:

- explicit actors (domain isolation)
- `@concurrent` helpers (Swift 6.2)
- `Task.detached` only when you can satisfy `Sendable` captures

## Ordering and scheduling

### `Task {}` vs `Task.immediate {}` (Swift 6.2)

Unstructured tasks (`Task { ... }`) enqueue work and may run after the current synchronous scope completes.

Swift 6.2 adds **immediate tasks** (`Task.immediate`) to start executing immediately (until the first suspension point) when already on a suitable executor.

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

Use `Task.immediate` when you need predictable ordering on the current executor and want Task semantics (cancellation, priority, task locals) without an extra hop.

## Swift 6.2 isolation spellings: `nonisolated(nonsending)` vs `@concurrent`

Swift 6.2 introduces explicit spellings for two behaviors:

- `nonisolated(nonsending)`: **stay on the caller’s actor**
- `@concurrent`: **always switch off an actor**

```swift
#if swift(>=6.2)
nonisolated(nonsending)
#endif
func updateCache() async { /* stays on caller’s actor */ }

#if swift(>=6.2)
@concurrent
#endif
func hashLargeFile() async -> Digest { /* offloads */ }
```

Practical rule:

- If calling an async helper from a SwiftUI view or a `@MainActor` model, be deliberate about whether the helper should *inherit* MainActor isolation or *escape* it.

## Default Actor Isolation (Xcode / SwiftPM)

Modern toolchains can set **Default Actor Isolation = MainActor** for UI targets. This means many unannotated declarations are implicitly MainActor-isolated unless you opt out.

### SwiftPM: `SwiftSetting.defaultIsolation`

```swift
// Package.swift
.target(
  name: "MyPackage",
  swiftSettings: [
    .defaultIsolation(MainActor.self)
  ]
)
```

## Sendable friction and escape hatches

Preferred fixes:

- isolate mutable state in an actor
- copy value types into tasks
- pass identifiers across actors and refetch on the receiving actor (SwiftData models are not Sendable)

### Bridging legacy code: `DispatchQueue.asyncUnsafe`

When intentionally bridging pre-concurrency code and you fully understand the risk, `DispatchQueue.asyncUnsafe` can bypass Sendable checking for a closure dispatched to a queue.

Treat this as a last resort.

## Long-lived background work on macOS

Avoid tight polling loops when the system can coalesce work. For background sync, prefer `NSBackgroundActivityScheduler` when it fits your use case.

## Compile-checked examples in this repo

- [`ConcurrencyExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/ConcurrencyExamples.swift)

## Primary sources (for verification)

- WWDC25: Explore concurrency in SwiftUI: https://developer.apple.com/videos/play/wwdc2025/266/
- WWDC21: Discover concurrency in SwiftUI (`.task` lifetime/cancellation): https://developer.apple.com/videos/play/wwdc2021/10019/
- Swift 6.2 release notes: https://swift.org/blog/swift-6.2-released/
- Compiler docs: `nonisolated(nonsending)` by default: https://docs.swift.org/compiler/documentation/diagnostics/nonisolated-nonsending-by-default/
- SE-0461: async function isolation: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
- SE-0472: starting tasks synchronously: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0472-task-start-synchronously-on-caller-context.md
- `DispatchQueue.asyncUnsafe`: https://developer.apple.com/documentation/dispatch/dispatchqueue/asyncunsafe%28group%3Aqos%3Aflags%3Aexecute%3A%29
