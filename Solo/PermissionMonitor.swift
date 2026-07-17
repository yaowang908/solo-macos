import AppKit
import ApplicationServices

/// Accessibility permission tracking, scoped to Smart Restore (design D5).
///
/// Uses the non-prompting `AXIsProcessTrusted()` for checks so the system prompt
/// never appears for Solo Focus-only users. While Smart Restore is enabled but
/// untrusted, polls at low frequency to detect a grant without relaunch.
@MainActor
final class PermissionMonitor {
    private(set) var isTrusted: Bool = AXIsProcessTrusted()
    private var timer: Timer?

    /// Called whenever trust flips (e.g. granted while running).
    var onTrustChanged: ((Bool) -> Void)?

    /// Re-read trust and notify if it changed.
    @discardableResult
    func refresh() -> Bool {
        let now = AXIsProcessTrusted()
        if now != isTrusted {
            isTrusted = now
            onTrustChanged?(now)
        }
        return isTrusted
    }

    /// Begin ~2s polling until permission is granted or `stopPolling()` is called.
    func startPolling() {
        guard timer == nil, !isTrusted else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        self.timer = timer
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        refresh()
        if isTrusted {
            stopPolling()
        }
    }

    /// Plain-language explainer with a deep link to the Accessibility settings pane.
    /// Returns `true` if the user chose to proceed (opened Settings), `false` if
    /// they declined ("Not Now").
    @discardableResult
    func presentExplainer() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Smart Restore needs Accessibility access"
        alert.informativeText = """
        Solo uses macOS Accessibility to detect and un-minimize other apps' windows \
        when you switch to them. Solo Focus works without it.

        Grant access in System Settings → Privacy & Security → Accessibility, then \
        Smart Restore turns on automatically.
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")

        NSApp.activate()
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
            return true
        }
        return false
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
