import Foundation

/// Debug-only assertions for actor isolation.
///
/// Use these checks to validate assumptions about running on the main actor.
/// They intentionally crash in debug builds when violated.
public enum MainActorChecks {
  /// Stops program execution (debug) if the current task isn't executing on MainActor.
  @inline(__always)
  public static func assertIsolated(
    _ message: @autoclosure () -> String = "Expected MainActor isolation",
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    #if DEBUG
    MainActor.assertIsolated(message(), file: file, line: line)
    #else
    _ = message
    #endif
  }

  /// Stops program execution (debug) if the current task isn't executing on MainActor.
  ///
  /// Prefer this when isolation is a correctness requirement (not just a debug check).
  @inline(__always)
  public static func preconditionIsolated(
    _ message: @autoclosure () -> String = "Expected MainActor isolation",
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    MainActor.preconditionIsolated(message(), file: file, line: line)
  }

  /// Run synchronous code while asserting we're isolated to MainActor.
  ///
  /// Useful when bridging legacy APIs that are *documented* to run on the main thread.
  @inline(__always)
  public static func assumeIsolated<T: Sendable>(
    file: StaticString = #fileID,
    line: UInt = #line,
    _ body: () throws -> T
  ) rethrows -> T {
    try MainActor.assumeIsolated(body, file: file, line: line)
  }
}
