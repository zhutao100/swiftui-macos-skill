import Observation

@Observable
final class SettingsModel {
    var sortOrder: Int = 0
    var query: String = ""
}

/// macOS 26+: Observe transactional changes with `Observations`.
/// For older deployment targets, use `withObservationTracking` (see fallback below).
func observeChanges(settings: SettingsModel) -> Task<Void, Never> {
    Task {
        // Emits whenever any property read in the closure changes.
        for await snapshot in Observations {
            (settings.sortOrder, settings.query)
        } {
            // React to the latest consistent snapshot.
            print("sortOrder=\(snapshot.0), query=\(snapshot.1)")
        }
    }
}

// Fallback idea (pre-OS-26):
// withObservationTracking({
//     _ = settings.sortOrder
//     _ = settings.query
// }, onChange: {
//     // Re-register by calling withObservationTracking again.
// })
