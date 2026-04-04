import SwiftUI

/// Compile-checked window-management patterns for macOS SwiftUI.
///
/// Notes:
/// - `openWindow`/`dismissWindow` are environment actions.
/// - The value-based overloads require a `WindowGroup(for:)` scene.
public enum WindowingExamples {
  public enum WindowID {
    public static let inspector = "inspector"
  }

  public struct OpenCloseByIDDemoView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    public init() {}

    public var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Button("Open Inspector Window") {
          openWindow(id: WindowID.inspector)
        }

        Button("Close Inspector Window") {
          dismissWindow(id: WindowID.inspector)
        }
      }
      .padding()
    }
  }
}
