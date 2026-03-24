# macOS Platform Patterns

## NSViewRepresentable

### Lifecycle

- `makeNSView(context:)` — called once. Create and configure the AppKit view.
- `updateNSView(_:context:)` — called on every SwiftUI state change that could affect this view. Must be idempotent and efficient.
- `dismantleNSView(_:coordinator:)` — static cleanup method.
- `Coordinator` — for delegates, target-action, and any AppKit → SwiftUI bridging.

### Performance: update gating

SwiftUI may call `updateNSView` frequently. Make updates **idempotent** and cheap; gate expensive work by comparing inputs and early-returning. If the representable is value-typed and `Equatable`, you can also wrap it in `.equatable()` at the call site to skip updates when inputs didn't change:

```swift
struct BlurView: NSViewRepresentable, Equatable {
    let radius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView { ... }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = ...
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.radius == rhs.radius
    }
}
```

Even if your representable is `Equatable`, you generally still need to gate work in `updateNSView`. Wrapping in `.equatable()` can help when the representable’s inputs are stable and comparable.

## Multi-Window State

```
App level
├── @State var appState = AppState()           // Global, shared across all windows
└── WindowGroup {
        WindowRoot()
            .environment(appState)
    }

WindowRoot
├── @State private var windowState = WindowState()  // Per-window, created here
├── .environment(\.windowState, windowState)
└── ContentView()
```

- **Global state** (data model, user settings): create once at app level, inject into `WindowGroup`.
- **Per-window state** (sidebar width, active selection, split position): create with `@State` in the window's root view, inject via environment.
- Prefer value-based `WindowGroup(for:)` to let SwiftUI manage window identity. If you truly need `NSWindow`, capture it via an AppKit bridge (see below) and store a weak reference in per-window state.
- Pages/documents can move between windows — handle ownership transfer explicitly.

## NSHostingView — Embedding SwiftUI in AppKit

The reverse of `NSViewRepresentable`. Use `NSHostingView` to embed SwiftUI views inside AppKit view hierarchies — common in `NSWindowController`, `NSViewController`, toolbar items, or overlay systems.

```swift
final class OverlayHostingView<Content: View>: NSHostingView<Content> {
    let shouldPassThrough: () -> Bool

    init(rootView: Content, shouldPassThrough: @escaping () -> Bool) {
        self.shouldPassThrough = shouldPassThrough
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // Pass through hit tests when overlay is inactive
    override func hitTest(_ point: NSPoint) -> NSView? {
        shouldPassThrough() ? nil : super.hitTest(point)
    }
}
```

**Key patterns:**
- **Subclass for hit-test control** — `NSHostingView` captures all hits by default. Override `hitTest(_:)` to pass through when the SwiftUI content shouldn't intercept clicks (transparent overlays, inactive HUDs).
- **Sizing**: `NSHostingView` uses `intrinsicContentSize` from the SwiftUI view. For views that should fill their container, set `translatesAutoresizingMaskIntoConstraints = false` and pin edges.
- **Environment**: Values set via `.environment()` on the root view work normally. For values that change dynamically, update via `rootView = updatedView` — but prefer `@Observable` objects injected once.
- **Lifecycle**: The hosting view owns the SwiftUI view's lifecycle. Removing the hosting view from the hierarchy triggers `onDisappear` and cancels `.task` modifiers.
- **Cursor management**: If the SwiftUI content sits above views that set cursors (e.g., WebKit), override `cursorUpdate(with:)` and `resetCursorRects()` to control cursor behavior.

## AppKit Bridging

Use AppKit only for capabilities SwiftUI lacks:

| Need | AppKit Approach |
|---|---|
| Window chrome (titlebar, toolbar, styleMask) | `NSWindow` via `NSApp.keyWindow` or tracked reference |
| Drag and drop | `NSDraggingSource` / `NSDraggingDestination` via coordinator |
| System blur effects | `NSVisualEffectView` |
| Text input with special behavior | `NSTextField` subclass via `NSViewRepresentable` |
| Pasteboard operations | `NSPasteboard` in coordinator or manager |

For method swizzling or private API usage: document thoroughly, isolate in dedicated types, and guard with availability checks where possible.

## macOS-Specific Scenes

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        Settings { SettingsView() }                              // Preferences (Cmd+,)
        MenuBarExtra("Status", systemImage: "circle") {
            MenuView()
        }
        Window("Inspector", id: "inspector") { InspectorView() }
    }
}
```

## Programmatic Window Management

Use `@Environment(\.openWindow)` to open windows — not AppKit hacks:

```swift
struct MyView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Inspector") {
            openWindow(id: "inspector")           // By window ID
            openWindow(value: document.id)        // By value (typed)
        }
    }
}
```

Requires a matching `Window` or `WindowGroup` scene declaration. For dismissing, use `@Environment(\.dismissWindow)`.

## App Delegate Integration

Use `@NSApplicationDelegateAdaptor` for app lifecycle events SwiftUI doesn't cover:

```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene { ... }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { ... }
    func application(_ app: NSApplication, open urls: [URL]) { ... }
}
```

Only use for events that have no SwiftUI equivalent (URL handling has `.onOpenURL`, so prefer that).

## macOS-Specific Modifiers

- `.windowStyle(.hiddenTitleBar)`, `.windowToolbarStyle(.unified)`, `.windowToolbarStyle(.unifiedCompact)`
- `.windowResizability(.contentSize)`, `.windowResizability(.contentMinSize)`
- `.defaultSize(width:height:)`, `.frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)`
- `.handlesExternalEvents(matching:)` for deep linking to specific windows
- `.onOpenURL { }` for URL scheme handling

## Interaction Patterns

macOS interactions differ fundamentally from iOS:

- **No 44pt tap targets.** macOS uses precise cursors. Keyboard navigation and focus rings are the equivalent accessibility requirements.
- **Hover states**: `.onHover { isHovered = $0 }` for interactive feedback. Essential for discoverability — users expect visual response on hover.
- **Right-click menus**: `.contextMenu { }` is expected on virtually every interactive element.
- **Keyboard shortcuts**: `.keyboardShortcut("n", modifiers: .command)` for frequent actions.
- **Focus management**: `@FocusState` for keyboard navigation. Tab order must be logical. Test with Full Keyboard Access.
- **Drag and drop**: Expected for reordering, file import, cross-app data transfer. Native `draggable()` / `dropDestination()` for simple cases; AppKit bridging for complex scenarios.


## Capturing NSWindow safely

SwiftUI does not expose a stable “window ID” environment value. If you need access to the backing `NSWindow` (title, style masks, toolbar configuration), capture it via a tiny representable and publish it into per-window state.

```swift
@Observable @MainActor
final class WindowHandle {
    @ObservationIgnored
    weak var window: NSWindow?
}

struct WindowReader: NSViewRepresentable {
    let handle: WindowHandle

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            handle.window = view?.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if handle.window == nil {
            DispatchQueue.main.async { [weak nsView] in
                handle.window = nsView?.window
            }
        }
    }
}
```

Attach it near the window root:

```swift
struct WindowRoot: View {
    @State private var windowHandle = WindowHandle()

    var body: some View {
        ContentView()
            .background(WindowReader(handle: windowHandle))
            .onChange(of: windowHandle.window) { _, w in
                w?.titleVisibility = .hidden
            }
    }
}
```

This approach keeps AppKit usage explicit, testable, and scoped to a single window.
