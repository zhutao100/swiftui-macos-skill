import Foundation

public enum ConcurrencyExamples {
  /// Demonstrates the ordering difference between Task and Task.immediate.
  @MainActor
  public static func orderingDemo(log: @escaping @Sendable (String) -> Void) {
    log("1")
    Task { @MainActor in log("2") }
    log("3")

    #if swift(>=6.2)
      log("A")
      if #available(macOS 26.0, *) {
        Task.immediate { @MainActor in log("B") }
      } else {
        Task { @MainActor in log("B") }
      }
      log("C")
    #endif
  }

  /// A CPU-bound function that should not inherit caller isolation (Swift 6.2+).
  public struct Decoder: Sendable {
    public init() {}

    #if swift(>=6.2)
      @concurrent
    #endif
    public func decode(_ data: Data) async throws -> [String: Int] {
      try JSONSerialization.jsonObject(with: data) as? [String: Int] ?? [:]
    }
  }

  /// Small compile-time example showing `nonisolated(nonsending)` spelling (Swift 6.2+).
  public actor Accumulator {
    private var total: Int = 0
    public init() {}

    public func add(_ x: Int) { total += x }
    public func snapshot() -> Int { total }

    #if swift(>=6.2)
      nonisolated(nonsending)
        public func typeName() async -> String
      { "Accumulator" }
    #endif
  }
}
