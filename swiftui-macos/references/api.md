# Modern SwiftUI API quick reference (macOS)

This file is a field guide to newer SwiftUI APIs/macros that commonly show up in modern macOS codebases (macOS 15+ and Tahoe 26+). When adopting anything that is often discussed in an iOS context, explicitly confirm availability on macOS.

## Previews

### `#Preview`

```swift
#Preview("Library") {
    LibraryView()
}
```

### `@Previewable` (stateful previews)

Use `@Previewable` to create dynamic properties (like `@State`) inline in a `#Preview` body.

```swift
#Preview("Search") {
    @Previewable @State var query = ""
    SearchView(query: $query)
}
```

## Environment keys without boilerplate: `@Entry`

`@Entry` generates boilerplate for environment values (and related containers like focused or transaction values).

```swift
extension EnvironmentValues {
    @Entry var tabManager: TabManager? = nil
}
```

Notes:

- `@Entry` is a macro: it expands at compile time and is not inherently OS-version-gated.
- Prefer explicit dependency injection over implicit globals.

## Tabs: `TabView` + `Tab` (macOS 15+)

```swift
@available(macOS 15.0, *)
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") { LibraryView() }
            Tab("Settings", systemImage: "gear") { SettingsView() }
        }
    }
}
```

For older OS targets, use `.tabItem { Label(...) }`.

## Toolbars (macOS)

Prefer cross-platform semantic placements rather than iOS-only “top bar” placements:

```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Button("Refresh", systemImage: "arrow.clockwise") { reload() }
        Button("Add", systemImage: "plus") { add() }
    }
}
```

## Navigation

Prefer newer navigation types:

- `NavigationStack` for linear flows
- `NavigationSplitView` for sidebar-detail apps (common macOS pattern)

Prefer value-based destinations:

```swift
NavigationStack(path: $path) {
    List(items) { item in
        NavigationLink(value: item.id) { Row(item: item) }
    }
    .navigationDestination(for: Item.ID.self) { id in
        DetailView(id: id)
    }
}
```


## Animations

### Completion-aware `withAnimation` (macOS 14+)

SwiftUI provides a completion-aware `withAnimation` overload:

```swift
withAnimation(.spring) {
    isExpanded.toggle()
} completion: {
    // runs when animations are complete
}
```

When targeting older OS versions, avoid coupling logic to animation completion; consider redesigning the flow or using explicit state machines.

## Animation macros (macOS Tahoe 26+)

SwiftUI on Tahoe 26 introduces macros that reduce boilerplate for custom animatable values:

### `@Animatable` + `@AnimatableIgnored`

Mark a view/shape as animatable to synthesize `Animatable` conformance and its `animatableData`.

```swift
@available(macOS 26.0, *)
@Animatable
struct IntegerView: View {
    var number: Float

    @AnimatableIgnored
    var label: String

    var body: some View {
        Text("\(label): \(number.formatted(.number.precision(.fractionLength(0))))")
    }
}
```

Rules of thumb:

- Use `VectorArithmetic`-conforming stored property types (often `Float`, `Double`, `CGFloat`).
- Use `@AnimatableIgnored` for stored properties that must not participate in interpolation.

## WebKit for SwiftUI (macOS Tahoe 26+)

WWDC25 introduced **WebKit for SwiftUI**, including `WebView` and `WebPage`. These APIs live in `WebKit` (not `SwiftUI`). If you need to support macOS 15, keep a `WKWebView`-based `NSViewRepresentable` fallback.

### Minimal `WebView(url:)`

```swift
@available(macOS 26.0, *)
import SwiftUI
import WebKit

@available(macOS 26.0, *)
struct ArticleView: View {
    var url: URL

    var body: some View {
        WebView(url: url)
    }
}
```

### Fallback: `WKWebView` representable (macOS 15+)

```swift
import SwiftUI
import WebKit

struct LegacyWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView { WKWebView() }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
```

## Text editing upgrades (macOS Tahoe 26+)

### Find & Replace in `TextEditor` (`findNavigator`)

On macOS 26, `TextEditor` integrates more directly with the system Find Bar and can be controlled with new modifiers.

```swift
@available(macOS 26.0, *)
struct FindReplaceEditor: View {
    @State private var text: String = ""
    @State private var findPresented: Bool = false

    var body: some View {
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
```

Also consider `findDisabled(_:)` / `replaceDisabled(_:)` when you want to suppress Find/Replace in specific editor contexts.

### Rich text with `AttributedString`

On macOS 26, `TextEditor` supports binding to `AttributedString` for first-class rich text editing.

```swift
@available(macOS 26.0, *)
struct RichTextEditor: View {
    @State private var text: AttributedString = "Hello, Tahoe 26"

    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: 240)
    }
}
```

If you need cross-version support, plan an AppKit fallback (`NSTextView` / TextKit) behind `NSViewRepresentable`.

## Compile-checked examples in this repo

- [`APIExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/APIExamples.swift)
- [`WebViewExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/WebViewExamples.swift)

## Primary sources (for verification)

- `@Entry` macro: https://developer.apple.com/documentation/swiftui/entry%28%29
- `@Previewable` macro: https://developer.apple.com/documentation/SwiftUI/Previewable%28%29
- WWDC25: What’s new in SwiftUI: https://developer.apple.com/videos/play/wwdc2025/256/
- WWDC25: Meet WebKit for SwiftUI: https://developer.apple.com/videos/play/wwdc2025/231/
- Swift with Majid: Animatable macro overview: https://swiftwithmajid.com/2025/07/08/introducing-animatable-macro-in-swiftui/
