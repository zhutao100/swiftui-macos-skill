# Data flow and state management (macOS SwiftUI)

## Architecture: environment-injected managers

A pragmatic macOS SwiftUI pattern:

- **manager objects** own logic and long-lived state
- views are projection + event routing
- managers are injected via the SwiftUI environment

```swift
import Observation
import SwiftUI

@MainActor
@Observable
final class TabManager {
    private(set) var tabs: [TabModel] = []
    var activeTabID: TabModel.ID?

    func createTab(url: URL?) { /* ... */ }
    func closeTab(_ id: TabModel.ID) { /* ... */ }
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
```

Notes:

- Using an optional environment value makes dependency wiring explicit.
- For multi-window apps, decide whether a manager is global (shared) or per-window (instantiate in the window root view).

## Property wrapper decision rules

| Wrapper | Owns storage? | Use when |
|---|---:|---|
| `@State` | Yes | view-local, ephemeral UI state; gestures; lightweight reference state you want SwiftUI to own |
| `@Binding` | No | child view edits parent-owned state |
| `@Bindable` | No | need bindings into an `@Observable` reference (e.g., toggles/text fields) |
| `@Environment` | No | dependency injection (managers, settings, system values) |
| `@Entry` | N/A | define custom environment/focused/transaction keys without boilerplate |

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
final class TabModel {
    var title: String = ""
    var url: URL?

    @Relationship(deleteRule: .cascade)
    var pages: [Page] = []

    @Transient
    var runtimeState: RuntimeState?
}
```

Guidelines:

- Use `@Transient` for runtime-only properties.
- Be explicit about delete rules and inverses.

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
- Pass `PersistentIdentifier`/IDs and refetch on the receiving actor.

### CloudKit sync constraints (SwiftData + iCloud)

CloudKit sync has model constraints that are easy to violate:

- **Unique constraints aren’t enforceable** across devices when CloudKit sync runs concurrently.
- **All attributes must be optional or have defaults.**
- **Relationships must be optional** and have inverses; CloudKit may not save relationship changes atomically.

If you enable CloudKit sync, validate the model design early; retrofitting later is painful.

## `@AppStorage`

`@AppStorage` is a SwiftUI dynamic property. Use it in `View` types.

For manager objects, prefer:

- a persistence layer (SwiftData) for complex settings
- or a small settings wrapper that reads/writes `UserDefaults` explicitly

## Primary sources (for verification)

- SwiftData + CloudKit sync: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- Core Data + CloudKit model rules: https://developer.apple.com/documentation/CoreData/creating-a-core-data-model-for-cloudkit
