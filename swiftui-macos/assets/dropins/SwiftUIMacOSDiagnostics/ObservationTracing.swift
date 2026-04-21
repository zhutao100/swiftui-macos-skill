import Foundation
import Observation

/// Helpers for using Swift's Observation system outside of SwiftUI.
public enum ObservationTracing {
  /// Start a classic `withObservationTracking` loop.
  ///
  /// This pattern re-registers tracking after each change. It's the most
  /// broadly-available approach (macOS 14+/Swift 5.9+), but it is not
  /// transactional.
  @MainActor
  @discardableResult
  public static func startLoop(_ body: @escaping () -> Void) -> ObservationLoop {
    let loop = ObservationLoop(body: body)
    loop.start()
    return loop
  }

  /// Start a transactional async sequence using `Observations`.
  ///
  /// `Observations` coalesces synchronous changes into a single update that is
  /// emitted at the next suspension point, so observers see consistent snapshots.
  #if swift(>=6.2)
  @available(macOS 26.0, *)
  public static func streamValues<T: Sendable>(
    _ makeValue: @escaping @Sendable () -> T,
    onValue: @escaping @MainActor (T) -> Void
  ) -> Task<Void, Never> {
    Task { @MainActor in
      let values = Observations { makeValue() }
      for await value in values {
        onValue(value)
      }
    }
  }
  #endif
}

/// A cancellation-aware `withObservationTracking` loop.
///
/// Keep the returned instance alive for as long as you want to observe.
@MainActor
public final class ObservationLoop {
  private let body: () -> Void
  private var isCancelled = false

  public init(body: @escaping () -> Void) {
    self.body = body
  }

  public func cancel() {
    isCancelled = true
  }

  fileprivate func start() {
    runOnce()
  }

  private func runOnce() {
    guard !isCancelled else { return }

    withObservationTracking {
      body()
    } onChange: {
      Task { @MainActor in
        self.runOnce()
      }
    }
  }
}
