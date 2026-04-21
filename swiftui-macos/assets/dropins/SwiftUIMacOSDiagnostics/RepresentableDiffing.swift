/// Micro-helpers for building fast, idempotent representables.
///
/// SwiftUI may call `updateNSView` more often than you expect.
/// Assume updates can be frequent and make them cheap.
public enum RepresentableDiffing {
  /// Apply `apply` only when `newValue` differs from `cache`.
  @inline(__always)
  public static func applyIfChanged<T: Equatable>(
    _ newValue: T,
    cache: inout T?,
    apply: (T) -> Void
  ) {
    guard cache != newValue else { return }
    cache = newValue
    apply(newValue)
  }

  /// Apply `apply` only when `newValue` differs from `cache`.
  ///
  /// Use this overload when the cached value should be reset explicitly.
  @inline(__always)
  public static func applyIfChanged<T: Equatable>(
    _ newValue: T,
    cache: inout T,
    apply: (T) -> Void
  ) {
    guard cache != newValue else { return }
    cache = newValue
    apply(newValue)
  }
}
