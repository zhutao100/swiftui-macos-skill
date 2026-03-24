# View composition and animation

This reference covers patterns that affect **SwiftUI view identity**, lifecycle, and correctness on macOS.

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
    var sidebarContent: some View { ... }
    var toolbarContent: some ToolbarContent { ... }
}
```

## Storing view-builder content correctly

Avoid storing escaping view-builder closures on `View` types. Instead, **evaluate the builder in `init`** and store the built value:

```swift
struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

This keeps the type purely a value container, avoids unexpected captures, and plays well with SwiftUI’s diffing.

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

`.task(id:)` cancels the previous task when the ID changes, and cancels when the view disappears.

## Preference keys for child-to-parent flow

Use `PreferenceKey` for “reverse environment” data flow (size reporting, anchors, etc.):

```swift
struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

ChildView()
    .background(GeometryReader { geo in
        Color.clear.preference(key: SizeKey.self, value: geo.size)
    })

.onPreferenceChange(SizeKey.self) { size in
    self.childSize = size
}
```

## Navigation on macOS

- Prefer `NavigationSplitView` for sidebar-detail apps (common macOS pattern).
- Prefer `NavigationStack` for linear flows.
- Prefer value-based navigation (`navigationDestination(for:)`) over older destination-in-link initializers.

## Tabs

Modern `TabView` uses explicit `Tab` values:

```swift
TabView {
    Tab("Library", systemImage: "books.vertical") {
        LibraryView()
    }

    Tab("Settings", systemImage: "gear") {
        SettingsView()
    }
}
```

## Animation rules

### Avoid global implicit animation

Never use `.animation(_:)` without a `value:` parameter; it can produce surprising, broad animations.

Prefer:

```swift
.animation(.spring, value: isExpanded)
```

### Sequencing animations

When you need to chain animations, use the completion-capable `withAnimation` API (where available):

```swift
withAnimation(.spring) {
    scale = 2
} completion: {
    withAnimation(.spring) {
        scale = 1
    }
}
```

### Gesture-driven values belong in `@State`

Continuous gestures can update at display refresh rates; store gesture-driven values (`offset`, `scale`, `rotation`) in `@State` to avoid routing every frame through observation.

See `references/performance.md` for details.

## Custom layout protocol

Use the `Layout` protocol when your goal is arranging subviews (not reading sizes for other purposes). `Layout` participates in the layout negotiation and avoids the “greedy” behavior of `GeometryReader`.
