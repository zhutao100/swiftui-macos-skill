#if os(macOS)
import AppKit
import SwiftUI

/// Access the containing `NSWindow` from SwiftUI.
///
/// Prefer environment actions like `openWindow` / `dismissWindow` when possible.
/// Use `WindowReader` only when you *must* touch an `NSWindow` API (titlebar,
/// toolbar, tabbing, etc.) that SwiftUI doesn't expose.
public struct WindowReader: NSViewRepresentable {
  public typealias NSViewType = NSView

  public final class Coordinator {
    var lastWindowNumber: Int?
  }

  private let onResolve: @MainActor (NSWindow) -> Void

  public init(onResolve: @escaping @MainActor (NSWindow) -> Void) {
    self.onResolve = onResolve
  }

  public func makeCoordinator() -> Coordinator { .init() }

  public func makeNSView(context: Context) -> NSView {
    let view = NSView(frame: .zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  public func updateNSView(_ nsView: NSView, context: Context) {
    guard let window = nsView.window else { return }

    let windowNumber = window.windowNumber
    if context.coordinator.lastWindowNumber != windowNumber {
      context.coordinator.lastWindowNumber = windowNumber
      Task { @MainActor in
        onResolve(window)
      }
    }
  }
}

public extension View {
  /// Call `handler` when this view becomes associated with an `NSWindow`.
  func onWindowResolved(_ handler: @escaping @MainActor (NSWindow) -> Void) -> some View {
    background(WindowReader(onResolve: handler).frame(width: 0, height: 0))
  }
}
#endif
