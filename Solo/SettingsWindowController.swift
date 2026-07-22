import AppKit
import SwiftUI

/// Owns the Settings window (design D1): one lazily created, reused NSWindow
/// hosting the SwiftUI settings view. Solo is an agent app (LSUIElement), so
/// opening must explicitly activate the app for the window to front and
/// become key.
@MainActor
final class SettingsWindowController: NSWindowController {
    convenience init(excludedApps: ExcludedApps) {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Solo Settings"
        window.contentViewController = NSHostingController(rootView: SettingsView(excludedApps: excludedApps))
        // The controller keeps the window alive across close/reopen (reused, never recreated).
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    /// Front the window (creating nothing — the window is reused), making it key.
    func show() {
        guard let window else { return }
        if !window.isVisible {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
