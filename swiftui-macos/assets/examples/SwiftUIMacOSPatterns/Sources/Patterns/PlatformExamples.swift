import AppKit
import SwiftUI

/// Compile-checked AppKit integration patterns for macOS SwiftUI.
public enum PlatformExamples {
  /// A simple blur/material background using NSVisualEffectView.
  public struct VisualEffectBlur: NSViewRepresentable {
    public enum Material {
      case sidebar, windowBackground, hud

      var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .sidebar: return .sidebar
        case .windowBackground: return .windowBackground
        case .hud: return .hudWindow
        }
      }
    }

    public var material: Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public init(
      material: Material = .windowBackground,
      blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
      self.material = material
      self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
      let view = NSVisualEffectView()
      view.state = .active
      view.material = material.nsMaterial
      view.blendingMode = blendingMode
      return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
      nsView.material = material.nsMaterial
      nsView.blendingMode = blendingMode
    }
  }

  /// A minimal NSTextView wrapper with internal diffing in updateNSView.
  ///
  /// Key points:
  /// - `updateNSView` can run frequently; keep it idempotent and fast.
  /// - Use coordinator state (`lastAppliedText`) to avoid redundant assignments.
  /// - Use the coordinator delegate callback to propagate AppKit edits back into the SwiftUI binding.
  public struct CodeTextView: NSViewRepresentable {
    @Binding public var text: String
    public var isEditable: Bool

    public init(text: Binding<String>, isEditable: Bool = true) {
      self._text = text
      self.isEditable = isEditable
    }

    public final class Coordinator: NSObject, NSTextViewDelegate {
      var lastAppliedText: String?
      var onTextChange: ((String) -> Void)?

      public func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView else { return }
        onTextChange?(tv.string)
      }
    }

    public func makeCoordinator() -> Coordinator { .init() }

    public func makeNSView(context: Context) -> NSScrollView {
      let scroll = NSScrollView()
      scroll.hasVerticalScroller = true
      scroll.hasHorizontalScroller = false

      let textView = NSTextView()
      textView.isEditable = isEditable
      textView.isRichText = false
      textView.usesFindBar = true
      textView.delegate = context.coordinator

      scroll.documentView = textView
      return scroll
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
      guard let textView = nsView.documentView as? NSTextView else { return }

      // Bridge AppKit -> SwiftUI
      context.coordinator.onTextChange = {
        [binding = _text, weak coordinator = context.coordinator] newText in
        coordinator?.lastAppliedText = newText
        if binding.wrappedValue != newText {
          binding.wrappedValue = newText
        }
      }

      // Bridge SwiftUI -> AppKit
      textView.isEditable = isEditable
      if context.coordinator.lastAppliedText != text {
        context.coordinator.lastAppliedText = text
        textView.string = text
      }
    }

    public static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
      (nsView.documentView as? NSTextView)?.delegate = nil
      coordinator.onTextChange = nil
    }
  }

  /// A hosting view that can optionally pass mouse clicks through to views behind it.
  public final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    public var shouldPassThrough: () -> Bool = { false }

    public override func hitTest(_ point: NSPoint) -> NSView? {
      shouldPassThrough() ? nil : super.hitTest(point)
    }
  }
}
