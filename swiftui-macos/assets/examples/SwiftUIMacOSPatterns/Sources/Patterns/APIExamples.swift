import SwiftUI

/// Compile-checked examples for modern SwiftUI APIs.
public enum APIExamples {
  /// Demonstrates the `@Animatable` and `@AnimatableIgnored` macros (macOS Tahoe 26+).
  @available(macOS 26.0, *)
  @Animatable
  public struct IntegerView: View {
    public var number: Float

    @AnimatableIgnored
    public var label: String

    public init(number: Float, label: String = "Value") {
      self.number = number
      self.label = label
    }

    public var body: some View {
      Text("\(label): \(number.formatted(.number.precision(.fractionLength(0))))")
    }
  }

  /// Find/Replace presentation for TextEditor (macOS Tahoe 26+).
  @available(macOS 26.0, *)
  public struct FindReplaceEditor: View {
    @State private var text: String = ""
    @State private var findPresented: Bool = false

    public init() {}

    public var body: some View {
      TextEditor(text: $text)
        .findNavigator(isPresented: $findPresented)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $findPresented) {
              Label("Find", systemImage: "magnifyingglass")
            }
          }
        }
    }
  }

  /// Rich text editing with AttributedString (macOS Tahoe 26+).
  @available(macOS 26.0, *)
  public struct RichTextEditor: View {
    @State private var text: AttributedString = "Hello, Tahoe 26"

    public init() {}

    public var body: some View {
      TextEditor(text: $text)
        .frame(minHeight: 240)
    }
  }
}
