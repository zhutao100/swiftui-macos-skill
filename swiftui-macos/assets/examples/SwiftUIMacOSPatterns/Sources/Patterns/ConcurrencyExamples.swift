import Foundation

public enum ConcurrencyExamples {
    /// Demonstrates the ordering difference between Task and Task.immediate.
    @MainActor
    public static func orderingDemo(log: @escaping (String) -> Void) {
        log("1")
        Task { @MainActor in log("2") }
        log("3")

        #if swift(>=6.2)
        log("A")
        Task.immediate { @MainActor in log("B") }
        log("C")
        #endif
    }

    /// A CPU-bound function that should not inherit MainActor isolation.
    public struct Decoder: Sendable {
        public init() {}

        #if swift(>=6.2)
        @concurrent
        #endif
        public func decode(_ data: Data) async throws -> [String: Int] {
            try JSONSerialization.jsonObject(with: data) as? [String: Int] ?? [:]
        }
    }
}
