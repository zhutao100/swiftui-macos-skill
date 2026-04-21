# macOS platform patterns (SwiftUI + AppKit)

This reference covers macOS-specific platform integration patterns: `NSViewRepresentable`, windowing/scenes, AppKit bridging, and commands/menus.

> Scope: macOS 15+ (AppKit). For iOS-only counterparts, see `references/scope.md`.

## NSViewRepresentable

### Lifecycle

- `makeNSView(context:)` — called once. Create and configure the AppKit view.
- `updateNSView(_:context:)` — called whenever SwiftUI decides the representable needs updating. Must be idempotent and fast.
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

Drop-in helper:

- `assets/dropins/SwiftUIMacOSDiagnostics/RepresentableDiffing.swift`

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

Rules:

- Prefer passing lightweight identifiers (not large models).
- For state restoration, the value should be **Codable**.

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

### State restoration (macOS)

On macOS, state restoration is user-controlled (system setting). By default, SwiftUI respects the system preference.

Use:

- `@SceneStorage` for per-window UI state (selection, split positions)
- `@AppStorage` for global preferences

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

Guidelines:

- Keep command dependencies narrow (avoid reading a broad `@Observable` manager inside the command tree).
- Prefer `Label` for forward-compatible menu items (icons + text).

See:

- [`MenuCommandExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/MenuCommandExamples.swift)

## Menu bar apps: `MenuBarExtra`

Use `MenuBarExtra` when you want functionality available even when your app isn't active (utility/menu bar apps).

Practical notes:

- If you remove the Dock icon (agent-only app), provide a visible “Quit” action.
- Be explicit about what lives in the menu vs a window.

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

## When you must touch `NSWindow`

Prefer scene/environment actions first. If SwiftUI doesn't expose the API you need, use a window reader.

Drop-in helper:

- `assets/dropins/SwiftUIMacOSDiagnostics/WindowReader.swift` (`.onWindowResolved { ... }`)

## Compile-checked examples in this repo

- [`PlatformExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/PlatformExamples.swift)
- [`WindowingExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/WindowingExamples.swift)
- [`MenuCommandExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/MenuCommandExamples.swift)

## Primary sources (for verification)

- Apple docs: `openWindow`: https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow
- Apple docs: state restoration behavior on macOS: https://developer.apple.com/documentation/swiftui/customizing-window-styles-and-state-restoration-behavior-in-macos
- Apple docs: `MenuBarExtra`: https://developer.apple.com/documentation/swiftui/menubarextra
- WWDC22: multi-window SwiftUI patterns: https://developer.apple.com/videos/play/wwdc2022/10061/
