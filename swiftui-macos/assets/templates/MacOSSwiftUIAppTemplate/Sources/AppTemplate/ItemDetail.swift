import SwiftUI

struct ItemDetail: View {
  var item: AppModel.Item

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(item.title)
        .font(.title2)

      Group {
        if #available(macOS 26.0, *) {
          TahoeRichTextDemo()
        } else {
          LegacyTextDemo()
        }
      }
      .padding(.top, 8)
    }
    .padding()
  }
}

@available(macOS 26.0, *)
private struct TahoeRichTextDemo: View {
  @State private var text: AttributedString = "Rich text (AttributedString) on macOS 26"

  var body: some View {
    TextEditor(text: $text)
      .frame(minHeight: 220)
      .border(.separator)
  }
}

private struct LegacyTextDemo: View {
  @State private var text: String = "Plain text fallback on macOS 15"

  var body: some View {
    TextEditor(text: $text)
      .frame(minHeight: 220)
      .border(.separator)
  }
}
