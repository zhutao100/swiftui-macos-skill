import SwiftUI

public struct Card<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}

public struct TabDemoView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") {
                Text("Library")
            }

            Tab("Settings", systemImage: "gear") {
                Text("Settings")
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
