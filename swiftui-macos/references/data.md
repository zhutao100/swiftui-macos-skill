# Data flow and state management

## Architecture: environment-injected managers

For macOS SwiftUI apps, a pragmatic pattern is:

- **manager objects** own logic and long-lived state
- views are mostly projection + event routing
- managers are injected via the SwiftUI environment

```swift
import Observation
import SwiftUI

@Observable @MainActor
final class TabManager {
    private(set) var tabs: [Tab] = []
    var activeTabID: Tab.ID?

    func createTab(url: URL) { /* ... */ }
    func closeTab(_ id: Tab.ID) { /* ... */ }
}

extension EnvironmentValues {
    @Entry var tabManager: TabManager? = nil
}

@main
struct MyApp: App {
    @State private var tabManager = TabManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.tabManager, tabManager)
        }
    }
}

struct TabBar: View {
    @Environment(\.tabManager) private var tabManager

    var body: some View {
        if let tabManager {
            /* ... */
        } else {
            Text("Missing TabManager")
        }
    }
}
```

Notes:

- Using an optional environment value makes dependency wiring explicit.
- For multi-window apps, decide whether a manager is global (shared) or per-window (instantiate in the window root).

## Property wrapper decision rules

| Wrapper | Owns storage? | Use when |
|---|---:|---|
| `@State` | Yes | view-local, ephemeral UI state; gestures; transient input |
| `@Binding` | No | child view edits parent-owned state |
| `@Bindable` | No | need bindings into an `@Observable` reference not owned by `@State` |
| `@Environment` | No | dependency injection (managers, settings, system values) |
| `@Entry` | N/A | define custom environment/focus/transaction keys without boilerplate |

### `@Bindable` example

```swift
@Observable
final class Settings {
    var reduceMotion = false
}

extension EnvironmentValues {
    @Entry var settings: Settings? = nil
}

struct SettingsView: View {
    @Environment(\.settings) private var settings

    var body: some View {
        guard let settings else { return Text("Missing Settings") }

        @Bindable var settings = settings
        Toggle("Reduce Motion", isOn: $settings.reduceMotion)
    }
}
```

## Avoid “manual bindings” in hot code paths

Prefer direct bindings plus explicit invalidation:

```swift
TextField("Name", text: $model.name)
    .onSubmit { model.save() }
    .onChange(of: model.name) { _, _ in model.scheduleSave() }
```

Avoid `Binding(get:set:)` in `body` unless the transformation is trivial.

## SwiftData

### Model design

```swift
import SwiftData

@Model
final class Tab {
    var title: String = ""
    var url: URL?

    @Relationship(deleteRule: .cascade, inverse: \Page.tab)
    var pages: [Page] = []

    @Transient
    var runtimeState: RuntimeState?
}
```

Guidelines:

- Use `@Transient` for runtime-only properties.
- Be explicit about delete rules.

### Background operations with `@ModelActor`

Use `@ModelActor` for batch imports, pruning, and work that should not block the UI.

```swift
import SwiftData

@ModelActor
actor DataImporter {
    func importItems(_ dtos: [ItemDTO]) throws {
        for dto in dtos {
            modelContext.insert(Item(title: dto.title))
        }
        try modelContext.save()
    }
}
```

Rules:

- Don’t pass model objects across actors (models are not `Sendable`).
- Pass `PersistentIdentifier`/IDs, then refetch on the receiving actor.

### CloudKit syncing constraints (when enabled)

When you enable CloudKit sync for SwiftData, CloudKit imposes modeling constraints. Common practical rules:

- avoid uniqueness constraints (`@Attribute(.unique)`, `#Unique`) for synced models
- ensure **attributes are optional or have default values**
- ensure **relationships are optional** (CloudKit doesn’t guarantee atomic relationship updates)

Treat these as “hard requirements”: violating them commonly surfaces as build-time or runtime model validation errors.

## `@AppStorage`

`@AppStorage` is a SwiftUI dynamic property. Use it in `View` types.

For manager objects, prefer:

- a persistence layer (SwiftData) for complex settings
- or a small settings wrapper that reads/writes `UserDefaults` explicitly
