import SwiftUI

/// Compile-checked demos for view identity behavior on macOS SwiftUI.
public enum IdentityExamples {
  /// Demonstrates that structural conditionals (`if`/`else`) change identity,
  /// while changing modifier values preserves identity.
  public struct ConditionalIdentityDemoView: View {
    @State private var isVisible: Bool = true

    public init() {}

    public var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Visible", isOn: $isVisible)

        // Identity preserved: same view, different modifier value.
        Text("Opacity toggled (identity preserved)")
          .opacity(isVisible ? 1 : 0)

        // Identity changes: conditional subtree switches.
        if isVisible {
          Text("Conditional branch A (different identity)")
        } else {
          Text("Conditional branch B (different identity)")
        }
      }
      .padding()
    }
  }

  /// Demonstrates `.id(...)` as an intentional reset boundary.
  public struct IDResetDemoView: View {
    @State private var selection: Int = 0

    public init() {}

    public var body: some View {
      VStack(spacing: 12) {
        Stepper("Selection: \(selection)", value: $selection)

        DetailPane(selection: selection)
          .id(selection)  // resets DetailPane state when selection changes
          .border(.separator)
      }
      .padding()
    }
  }

  private struct DetailPane: View {
    let selection: Int
    @State private var counter: Int = 0

    var body: some View {
      VStack(spacing: 8) {
        Text("Detail for \(selection)")
        Button("Increment local state: \(counter)") { counter += 1 }
      }
      .padding()
    }
  }
}
