# macOS platform patterns (SwiftUI + AppKit)

This reference covers macOS-specific platform integration patterns: `NSViewRepresentable`, windowing, AppKit bridging, and commands/menus.

> Scope: macOS 15+ (AppKit). For iOS-only counterparts, see `references/scope.md`.

## NSViewRepresentable

### Lifecycle

- `makeNSView(context:)` — called once. Create and configure the AppKit view.
- `updateNSView(_:context:)` — called when SwiftUI thinks the representable needs updating. Must be idempotent and fast.
- `dismantleNSView(_:coordinator:)` — static cleanup hook.
- `Coordinator` — delegates, target-action, AppKit → SwiftUI bridging, and “last applied” caching.

### Performance: internal diffing (recommended)

Do not assume SwiftUI will suppress `updateNSView` calls. Instead, make updates conditional.

```swift
struct CodeTextView: NSViewRepresentable {
    @Binding var text: String

    final class Coordinator: NSObject, NSTextViewDelegate {
        var lastAppliedText: String?
    }

    func makeCoordinator() -> Coordinator { .init() }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        let textView = NSTextView()
        textView.delegate = context.coordinator
        scroll.documentView = textView
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if context.coordinator.lastAppliedText != text {
            context.coordinator.lastAppliedText = text
            textView.string = text
        }
    }
}
```

See the compile-checked example:

- [`PlatformExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/PlatformExamples.swift)

## Multi-window scene patterns (macOS)

### Prefer `openWindow` / `dismissWindow`

Use environment actions rather than “find the NSWindow”.

```swift
struct MainView: View {
    let itemID: UUID
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Item Window") { openWindow(value: itemID) }
    }
}
```

### Use `WindowGroup(for:)` for value-identified windows

When each window corresponds to a particular value (document ID, item ID), declare a typed window group.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { RootView() }

        WindowGroup(for: UUID.self) { $itemID in
            ItemWindow(itemID: itemID)
        }
    }
}
```

**Important:**

- Prefer passing lightweight identifiers (not large value models).
- The value should be **Hashable** and **Codable** for reuse and state restoration.

### Use `Window` for single-instance windows

If a window should exist at most once (global inspector), use `Window`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
        Window("Inspector", id: "inspector") { InspectorView() }
    }
}
```

### Per-window vs shared state

- **Global state** (data model, settings): create once at app level, inject into `WindowGroup`.
- **Per-window state** (selection, split positions): create at the window root view with `@State`, inject via environment.

Prefer keying state to the **window value** (from `WindowGroup(for:)`) rather than trying to fetch a window identifier from the environment.

## Commands, menus, and shortcuts (macOS)

macOS users expect menu items and keyboard shortcuts for core actions. Prefer SwiftUI `commands` over ad-hoc AppKit menu manipulation.

```swift
struct AppCommands: Commands {
    var body: some Commands {
        CommandMenu("Workspace") {
            Button {
                // perform action
            } label: {
                Label("New Window", systemImage: "macwindow")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
    }
}
```

Notes:

- On macOS Tahoe 26, menu items can show icons more consistently; using `Label` is the forward-compatible approach.
- Keep command state narrow (avoid reading a broad `@Observable` manager inside the command tree).

See:

- [`MenuCommandExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/MenuCommandExamples.swift)

## NSHostingView — embedding SwiftUI in AppKit

Use `NSHostingView` to embed SwiftUI in AppKit view hierarchies (`NSWindowController`, `NSToolbarItem`, overlays).

```swift
final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    var shouldPassThrough: () -> Bool = { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        shouldPassThrough() ? nil : super.hitTest(point)
    }
}
```

Patterns:

- Override `hitTest(_:)` for transparent overlays that shouldn’t intercept clicks.
- Use Auto Layout constraints to pin edges when the hosting view should fill its container.
- Prefer injecting `@Observable` environment objects once (avoid rebuilding the root view every update).

## App delegate integration (macOS)

Use `@NSApplicationDelegateAdaptor` only for lifecycle events without a SwiftUI equivalent.

```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { WindowGroup { ContentView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { /* ... */ }
}
```

Prefer SwiftUI equivalents when available (`.onOpenURL`, `.commands`, scene configuration).

## macOS-specific interaction expectations

macOS interaction differs fundamentally from touch-first UX:

- **Hover**: `.onHover { ... }` for discoverability.
- **Context menus**: `.contextMenu { ... }` are expected.
- **Keyboard shortcuts**: `.keyboardShortcut(...)` for core actions.
- **Focus navigation**: `@FocusState` + test with Full Keyboard Access.

## Compile-checked examples in this repo

- [`PlatformExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/PlatformExamples.swift)
- [`WindowingExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/WindowingExamples.swift)
- [`MenuCommandExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/MenuCommandExamples.swift)

## Primary sources (for verification)

- WWDC22: multi-window SwiftUI patterns: https://developer.apple.com/videos/play/wwdc2022/10061/
