# Swift concurrency for SwiftUI on macOS

This reference focuses on the concurrency behaviors that most often affect SwiftUI correctness and performance: **actor isolation**, **execution ordering**, and **long-lived tasks**.

## Ordering and scheduling: `Task {}` vs `Task.immediate {}`

Unstructured tasks (`Task { ... }`) do not start synchronously; they enqueue work and may run after the current synchronous scope completes. If you need “run now (until first suspension) when already on the right executor”, use **immediate tasks**:

```swift
print("1")
Task { @MainActor in print("2") }
print("3")
// typical output: 1, 3, 2

#if swift(>=6.2)
print("1")
Task.immediate { @MainActor in print("2") }  // runs inline when already on MainActor
print("3")
// output (when already on MainActor): 1, 2, 3
#endif
```

Use `Task.immediate` when:

- you need predictable ordering on the same executor
- you need Task semantics (cancellation, priority, task locals) but want to avoid an unnecessary hop

Avoid using it as a replacement for `DispatchQueue.sync`.

## Actor isolation in SwiftUI

### Default actor isolation (Swift 6.2)

Swift 6.2 introduces configuration that can make unannotated code default to `@MainActor` (per target/module). This is often desirable for UI-heavy targets, but it changes the meaning of “unannotated” code, and it can make `Task {}` inherit MainActor more frequently than expected.

When reviewing code:

- check whether the target uses default actor isolation
- prefer explicit annotations at boundaries (UI vs background)

### `Task {}` inherits isolation

`Task {}` inherits the caller’s isolation. This is a feature, but it surprises people who treat `Task {}` as “background work”.

If you must break inheritance (CPU-bound work, parsing, hashing), use `Task.detached` or an explicit background mechanism.

### Run work on the main actor

Prefer `await MainActor.run { ... }` when already in async code:

```swift
func load() async {
    let data = try await fetch()
    await MainActor.run {
        model.data = data
    }
}
```

Use `MainActor.assumeIsolated { ... }` only when you have strong evidence you are already on MainActor (e.g., AppKit delegate callbacks guaranteed on main).

## `@concurrent` for “always switch off actor”

Swift introduces `@concurrent` for async functions that must always switch off an actor to run concurrently:

```swift
struct Decoder: Sendable {
    @concurrent
    func decode(_ data: Data) async throws -> Model {
        try JSONDecoder().decode(Model.self, from: data)
    }
}
```

This becomes especially relevant when default actor isolation would otherwise keep an unannotated async function on the caller’s actor.

## `#isolation` and isolation-polymorphic APIs

`#isolation` can be used as the default value for an `isolated (any Actor)?` parameter.

This pattern is useful for libraries/helpers that should “run on the caller’s actor” without forcing `@MainActor`:

```swift
func process(
    isolation: isolated (any Actor)? = #isolation
) async {
    // Runs on the caller’s actor when possible.
}
```

## Sendable friction and escape hatches

### `sending` and `Task` captures

Swift uses `sending` and `Sendable` checking to prevent data races. `Task { ... }` captures values into a concurrent context; when strict checking is enabled, non-Sendable captures will be errors.

Preferred fixes:

- isolate mutable state in an actor
- copy value types into the task
- pass identifiers across actors and refetch on the other side (SwiftData models are not Sendable)

### `DispatchQueue.asyncUnsafe`

When you are intentionally bridging legacy code and you fully understand the risks, `DispatchQueue.asyncUnsafe` can be used to bypass Sendable checking.

Treat this as a last resort: it is opting out of compile-time race protection.

## Long-lived work and cancellation

### Prefer `.task(id:)` for view-driven work

`.task` is cancellation-aware and is tied to view lifetime.

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

`.task(id:)` automatically cancels the previous task when the ID changes and cancels when the view disappears.

### Periodic background work

Avoid polling loops that wake on a fixed cadence when the system can schedule more efficiently.

For macOS background sync, prefer `NSBackgroundActivityScheduler` to let the system coalesce work.

## Isolated `deinit` (Swift 6.2)

Swift supports an isolated synchronous `deinit` for actor-isolated classes so cleanup can safely access isolated state.

Use it for:

- cancelling stored tasks
- removing observers
- closing non-Sendable resources
