import Foundation

// SE-0472 / OS 26+: Immediate tasks begin executing on the caller's executor
// and only yield when they hit the first suspension point.
func kickOffUIWorkNow(_ work: @MainActor @Sendable () async -> Void) {
    Task.immediate { @MainActor in
        await work()
    }
}

// Compare with a deferred Task (may run later):
func kickOffUIDeferred(_ work: @MainActor @Sendable () async -> Void) {
    Task { @MainActor in
        await work()
    }
}
