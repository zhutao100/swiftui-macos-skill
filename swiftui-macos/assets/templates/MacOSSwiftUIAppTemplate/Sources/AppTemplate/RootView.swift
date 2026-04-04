import SwiftUI

struct RootView: View {
  @Environment(\.appModel) private var model
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    NavigationSplitView {
      sidebar
    } detail: {
      detail
    }
    .frame(minWidth: 760, minHeight: 520)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          model?.addItem()
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
    }
  }

  @ViewBuilder
  private var sidebar: some View {
    if let model {
      List(
        model.items,
        selection: Binding(
          get: {
            model.selectedID
          },
          set: { newValue in
            model.selectedID = newValue
          })
      ) { item in
        Text(item.title)
          .contextMenu {
            Button {
              openWindow(value: item.id)
            } label: {
              Label("Open in New Window", systemImage: "macwindow")
            }
          }
      }
    } else {
      Text("Missing model")
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let model, let id = model.selectedID, let item = model.item(id: id) {
      ItemDetail(item: item)
    } else {
      ContentUnavailableView("Select an item", systemImage: "sidebar.left")
    }
  }
}
