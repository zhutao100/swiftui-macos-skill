import Observation

/// Examples for Swift's Observation system used by SwiftUI.
public enum ObservationExamples {
  @Observable
  public final class Counter {
    public var count: Int = 0
    public init() {}
  }

  /// A classic OS-17-era pattern: re-run work when observed properties change.
  public static func printOnChange(counter: Counter, onLog: @escaping (String) -> Void) {
    withObservationTracking {
      onLog("count=\(counter.count)")
    } onChange: {
      Task { printOnChange(counter: counter, onLog: onLog) }
    }
  }

  /// OS-26-era pattern: long-lived transactional async sequence.
  @available(macOS 26.0, *)
  public static func streamMessages(
    counter: Counter,
    onLog: @escaping @Sendable (String) -> Void
  ) async {
    let messages = Observations { "count=\(counter.count)" }
    for await message in messages {
      onLog(message)
    }
  }
}
