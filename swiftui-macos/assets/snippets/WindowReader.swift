import SwiftUI
import AppKit
import Observation

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
