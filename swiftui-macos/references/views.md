# View composition and navigation (macOS SwiftUI)

This reference covers patterns that affect **SwiftUI view identity**, lifecycle, and correctness on macOS, with an emphasis on macOS-native navigation and layout idioms.

## Decomposition strategy

Not all decomposition requires separate `View` structs. Choose based on lifecycle/identity needs:

| Extract into a `View` type | A computed property is fine |
|---|---|
| needs its own `@State` / `@FocusState` | purely readability split |
| needs independent identity (transitions, tasks) | shares parent lifecycle |
| reused across files/modules | used once, tightly coupled |
| `ForEach` row bodies | simple conditional content |

For large views, use extension-based decomposition by domain:

```swift
extension MyView {
    var sidebarContent: some View { /* ... */ }
    var toolbarContent: some ToolbarContent { /* ... */ }
}
```

## Storing view-builder content correctly

Avoid storing escaping view-builder closures on `View` types. Instead, evaluate the builder in `init` and store the built value:

```swift
struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) { content }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 12))
    }
}
```

## `.task(id:)` for reactive async work

When async work should restart as a value changes, prefer `.task(id:)` over `onChange` + manual cancellation:

```swift
struct ProfileView: View {
    let userID: User.ID

    var body: some View {
        content
            .task(id: userID) {
                await model.load(userID: userID)
            }
    }
}
```

## macOS navigation: `NavigationSplitView` (sidebar-detail)

For macOS apps with a sidebar + detail layout, prefer `NavigationSplitView` over “stack-only” navigation.

Heuristics:

- Keep selection in a lightweight value (`ID`), not in a heavy model object.
- Put per-window navigation state in the window root view.
- For multi-window apps, key navigation state off the `WindowGroup(for:)` value.

## Tables (macOS)

macOS users expect tables for dense data. Prefer `Table` when list rows become grid-like.

Heuristics:

- Use `TableColumn` for stable columns.
- Use `SortDescriptor` arrays for explicit sorting.
- Keep row identity stable (avoid ad-hoc `UUID()`).

## Inspectors

The macOS “Inspector” panel is a common pattern. Prefer SwiftUI inspector APIs when available and fall back to a dedicated `Window` when you need a separate lifecycle boundary.

## Custom layout protocol

Use the `Layout` protocol when your goal is arranging subviews (not reading sizes for other purposes). `Layout` participates in layout negotiation and avoids the “greedy” behavior of `GeometryReader`.

## Compile-checked examples in this repo

- [`SwiftUIExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/SwiftUIExamples.swift)
