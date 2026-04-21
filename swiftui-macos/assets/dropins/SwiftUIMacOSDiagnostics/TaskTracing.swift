import Foundation
import os

/// Task helpers for SwiftUI debugging and correctness.
///
/// These helpers are intentionally lightweight:
/// - They preserve cancellation.
/// - They log start/end/cancel in DEBUG builds.
public enum TaskTracing {
  private static let logger = Logger(subsystem: "SwiftUIMacOSDiagnostics", category: "TaskTracing")

  /// Run an async operation in a new task with cancellation-aware logging.
  @discardableResult
  public static func run(
    _ label: String,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Void
  ) -> Task<Void, Never> {
    Task(priority: priority) {
      #if DEBUG
      logger.debug("start: \(label, privacy: .public)")
      defer { logger.debug("end: \(label, privacy: .public)") }
      #endif

      await withTaskCancellationHandler {
        await operation()
      } onCancel: {
        #if DEBUG
        logger.debug("cancel: \(label, privacy: .public)")
        #endif
      }
    }
  }

  /// Wrap an async operation to log cancellation.
  ///
  /// Use this inside an existing task (for example inside `.task {}`) when you
  /// want a clear log on cancellation.
  public static func withCancellationLogging<T: Sendable>(
    _ label: String,
    operation: @escaping @Sendable () async throws -> T
  ) async rethrows -> T {
    try await withTaskCancellationHandler {
      try await operation()
    } onCancel: {
      #if DEBUG
      logger.debug("cancel: \(label, privacy: .public)")
      #endif
    }
  }
}
