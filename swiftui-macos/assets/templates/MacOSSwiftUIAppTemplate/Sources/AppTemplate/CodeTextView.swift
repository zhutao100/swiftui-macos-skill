import AppKit
import SwiftUI

/// An AppKit-backed text view for cases where you need NSTextView/TextKit features.
/// Keep `updateNSView` idempotent and internally diffed.
struct CodeTextView: NSViewRepresentable {
  @Binding var text: String
  var isEditable: Bool = true

  final class Coordinator: NSObject, NSTextViewDelegate {
    var lastAppliedText: String?
    var onTextChange: ((String) -> Void)?

    func textDidChange(_ notification: Notification) {
      guard let tv = notification.object as? NSTextView else { return }
      onTextChange?(tv.string)
    }
  }

  func makeCoordinator() -> Coordinator { .init() }

  func makeNSView(context: Context) -> NSScrollView {
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true

    let textView = NSTextView()
    textView.isRichText = false
    textView.usesFindBar = true
    textView.isEditable = isEditable
    textView.delegate = context.coordinator

    scroll.documentView = textView
    return scroll
  }

  func updateNSView(_ scroll: NSScrollView, context: Context) {
    guard let textView = scroll.documentView as? NSTextView else { return }

    // Bridge AppKit -> SwiftUI.
    context.coordinator.onTextChange = {
      [binding = _text, weak coordinator = context.coordinator] newText in
      coordinator?.lastAppliedText = newText
      if binding.wrappedValue != newText {
        binding.wrappedValue = newText
      }
    }

    // Bridge SwiftUI -> AppKit.
    textView.isEditable = isEditable
    if context.coordinator.lastAppliedText != text {
      context.coordinator.lastAppliedText = text
      textView.string = text
    }
  }

  static func dismantleNSView(_ scroll: NSScrollView, coordinator: Coordinator) {
    (scroll.documentView as? NSTextView)?.delegate = nil
    coordinator.onTextChange = nil
  }
}
