import SwiftUI

/// Template for wrapping an AppKit view.
/// Key properties:
/// - makeNSView: create + configure once
/// - updateNSView: idempotent and cheap; gate expensive work
/// - dismantleNSView: cleanup
struct WrappedNSView: NSViewRepresentable {
    struct Configuration: Equatable {
        var isEnabled: Bool
        var title: String
    }

    let configuration: Configuration

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // configure…
        context.coordinator.lastConfig = configuration
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Gate expensive updates:
        if context.coordinator.lastConfig == configuration { return }
        context.coordinator.lastConfig = configuration

        // apply changes…
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        // cleanup…
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastConfig: Configuration?
    }
}
