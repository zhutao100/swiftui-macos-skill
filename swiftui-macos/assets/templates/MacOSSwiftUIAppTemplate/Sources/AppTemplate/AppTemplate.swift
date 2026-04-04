import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
  struct Item: Identifiable, Hashable, Codable {
    var id: UUID
    var title: String
  }

  var items: [Item] = [
    .init(id: UUID(), title: "First"),
    .init(id: UUID(), title: "Second"),
  ]

  var selectedID: UUID?

  func item(id: UUID) -> Item? { items.first { $0.id == id } }

  func addItem() {
    let new = Item(id: UUID(), title: "Untitled")
    items.append(new)
    selectedID = new.id
  }
}

extension EnvironmentValues {
  @Entry var appModel: AppModel? = nil
}

@main
struct AppTemplate: App {
  @State private var model = AppModel()

  init() {
    // When launched from `swift run`, ensure the app behaves like a regular GUI app.
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.appModel, model)
    }
    .commands {
      AppCommands()
    }

    WindowGroup(for: UUID.self) { $id in
      if let id {
        ItemWindow(itemID: id)
          .environment(\.appModel, model)
      } else {
        Text("Missing item id")
      }
    }

    Settings {
      SettingsView()
        .environment(\.appModel, model)
    }

    #if DEBUG
      Window("Debug", id: "debug") {
        DebugReproView()
          .environment(\.appModel, model)
      }
    #endif
  }
}

struct AppCommands: Commands {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.appModel) private var model

  var body: some Commands {
    CommandMenu("Workspace") {
      Button {
        model?.addItem()
      } label: {
        Label("New Item", systemImage: "plus")
      }
      .keyboardShortcut("n", modifiers: [.command])

      Button {
        if let id = model?.selectedID {
          openWindow(value: id)
        }
      } label: {
        Label("Open Item Window", systemImage: "macwindow")
      }
      .keyboardShortcut("o", modifiers: [.command, .shift])
    }
  }
}
