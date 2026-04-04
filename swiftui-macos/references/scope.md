# Scope and platform boundaries: macOS vs iOS SwiftUI

SwiftUI is cross-platform, but a large fraction of online “SwiftUI recipes” are **iOS-first**. This skill is explicitly **macOS-first** (macOS 15+ and macOS Tahoe 26+), so you need to translate (or discard) iOS-only advice.

## Versioning note (avoid OS confusion)

Apple moved to a year-based versioning convention in 2025:

- **macOS 15** is **Sequoia**
- **macOS 26** is **Tahoe**
- **iOS 26** and peers match the same convention

When web results talk about “the latest iOS 26 SwiftUI API”, confirm whether it is **available on macOS** (and at what minimum version) before adopting it.

## Quick translation table

| Topic | iOS-first guidance (avoid) | macOS-first equivalent |
|---|---|---|
| Representables | `UIViewRepresentable` | `NSViewRepresentable` |
| Hosting SwiftUI in platform UI | `UIHostingController` | `NSHostingView` / `NSHostingController` |
| App delegate | `@UIApplicationDelegateAdaptor` | `@NSApplicationDelegateAdaptor` |
| Windowing | `UIWindowScene` / scene sessions | `WindowGroup`, `Window`, `WindowGroup(for:)`, `openWindow`, `dismissWindow` |
| Menus | (often omitted) | `commands { ... }`, `CommandMenu`, keyboard shortcuts |
| Selection-driven layouts | “stack” navigation only | `NavigationSplitView`, `Table`, inspectors |
| Pointer + focus | touch-first assumptions | hover, context menus, focus rings, keyboard navigation |

If you cannot map an iOS-only pattern to macOS, treat it as out of scope.

## macOS windowing: preferred SwiftUI patterns (macOS 14+; used heavily on macOS 15/26)

### 1) Use SwiftUI window actions, not AppKit “window hunting”

Prefer `openWindow` / `dismissWindow` from the environment rather than reaching into `NSApp` to find windows.

```swift
struct ItemRow: View {
    let itemID: UUID

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open in New Window") {
            openWindow(value: itemID)
        }
    }
}
```

### 2) Use `WindowGroup(for:)` for value-identified windows

When each window represents a *specific value* (document ID, item ID, etc.), use a typed `WindowGroup(for:)` and pass the identifier as the presentation value.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { MainView() }

        WindowGroup(for: UUID.self) { $itemID in
            // Prefer lightweight values; refetch actual model data by ID.
            ItemWindow(itemID: itemID)
        }
    }
}
```

Notes (important on macOS):

- The value should be **Hashable** and **Codable** for reuse and state restoration.
- Prefer lightweight IDs over passing full value-type models.

### 3) Use `Window` for single-instance auxiliary windows

If a window represents global app state and should be unique, use `Window`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { MainView() }
        Window("Inspector", id: "inspector") { InspectorView() }
    }
}
```

### 4) macOS-only scenes you should reach for

- `Settings { SettingsView() }` for Preferences (Cmd-,)
- `MenuBarExtra` for status/menu bar utilities

## Toolbars and placements: avoid iOS-only placements

Some toolbar placements are iOS-only or behave differently. For macOS toolbars, prefer cross-platform semantic placements:

- `.primaryAction`, `.secondaryAction`, `.confirmationAction`, `.cancellationAction`
- keep toolbar state explicit and stable (avoid per-render creation of heavy items)

## AppKit bridging: prefer explicit boundaries

If you need AppKit:

- wrap views with `NSViewRepresentable`
- keep `updateNSView` **idempotent** and fast
- use a coordinator to bridge delegate callbacks into SwiftUI state

When embedding SwiftUI in AppKit:

- `NSHostingView(rootView:)` for view hierarchies
- be explicit about constraints and hit-testing behavior (overlays often need `hitTest(_:)` overrides)

## Web search hygiene (macOS-first)

When validating patterns found online:

1. **Reject UIKit-only** sources immediately (or translate to AppKit).
2. **Verify availability on macOS** in primary sources (Apple docs, WWDC sessions, Swift Evolution).
3. Add query bias:
   - include `macOS` or `AppKit` in the query
   - exclude iOS-only terms when needed (example: `-UIKit -UIViewRepresentable -UIHostingController`)

## Compile-checked examples in this repo

- [`PlatformExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/PlatformExamples.swift)
- [`WindowingExamples.swift`](../assets/examples/SwiftUIMacOSPatterns/Sources/Patterns/WindowingExamples.swift)

## Primary sources (for verification)

- WWDC22: multi-window SwiftUI patterns (typed `WindowGroup`, `openWindow`): https://developer.apple.com/videos/play/wwdc2022/10061/
- `openWindow` docs: https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow
