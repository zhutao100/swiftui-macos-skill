import SwiftUI

struct ItemWindow: View {
  @Environment(\.appModel) private var model
  var itemID: UUID

  var body: some View {
    if let item = model?.item(id: itemID) {
      ItemDetail(item: item)
    } else {
      ContentUnavailableView("Missing item", systemImage: "questionmark.folder")
    }
  }
}
