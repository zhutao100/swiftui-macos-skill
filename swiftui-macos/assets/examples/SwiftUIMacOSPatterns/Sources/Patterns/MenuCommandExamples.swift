import SwiftUI

/// Compile-checked macOS command/menu patterns.
public enum MenuCommandExamples {
  /// A reusable Commands bundle you can attach to an App scene.
  public struct AppCommands: Commands {
    public init() {}

    public var body: some Commands {
      CommandMenu("Workspace") {
        Button { /* wire action */
        } label: {
          Label("New Window", systemImage: "macwindow")
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])

        Divider()

        Button { /* wire action */
        } label: {
          Label("Toggle Sidebar", systemImage: "sidebar.left")
        }
        .keyboardShortcut("s", modifiers: [.command, .option])
      }
    }
  }
}
