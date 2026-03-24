# Modern SwiftUI API quick reference (macOS)

This file is a **field guide** to newer SwiftUI APIs/macros that commonly show up in modern codebases.

## Previews

### `#Preview` (preferred)

```swift
#Preview("Library") {
    LibraryView()
}
```

### `@Previewable` (stateful previews)

Use `@Previewable` when you want local `@State` in a preview without writing a wrapper view:

```swift
#Preview {
    @Previewable @State var query = ""
    SearchView(query: $query)
}
```

## Environment keys without boilerplate: `@Entry`

`@Entry` generates the boilerplate for environment/focus/transaction/container values.

```swift
extension EnvironmentValues {
    @Entry var tabManager: TabManager? = nil
}
```

## Tabs

`TabView` supports explicit `Tab` elements:

```swift
TabView {
    Tab("Library", systemImage: "books.vertical") { LibraryView() }
    Tab("Settings", systemImage: "gear") { SettingsView() }
}
```

`tabItem` continues to exist; prefer `Tab` syntax when you want clearer structure and selection support.

## Toolbars

Use semantic placements when possible:

```swift
.toolbar {
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Refresh", systemImage: "arrow.clockwise") { reload() }
        Button("Add", systemImage: "plus") { add() }
    }
}
```

On newer OS versions, `ToolbarSpacer` can be used to introduce spacing between items within a placement.

## Navigation

Prefer the newer navigation types:

- `NavigationStack` for linear flows
- `NavigationSplitView` for sidebar-detail

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

### Completion-aware `withAnimation`

```swift
withAnimation(.spring) {
    isExpanded.toggle()
} completion: {
    // called when animations are complete
}
```

When targeting older OS versions where completion callbacks are unavailable, use an `AnimatableModifier` or restructure to avoid completion coupling.
