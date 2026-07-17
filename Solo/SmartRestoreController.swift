import AppKit

/// Smart Restore: observe app activations and restore a minimized window when the
/// activated app has none visible (design D3/D4, smart-restore spec).
@MainActor
final class SmartRestoreController {
    private let focusSession: FocusSession
    private let activationGuard: ActivationGuard
    private let trustProvider: () -> Bool
    private let soloPid = ProcessInfo.processInfo.processIdentifier

    private(set) var isEnabled: Bool
    private var observer: NSObjectProtocol?

    /// Called when the enabled flag changes so the UI can re-render.
    var onStateChange: (() -> Void)?

    init(focusSession: FocusSession,
         activationGuard: ActivationGuard,
         isEnabled: Bool,
         trustProvider: @escaping () -> Bool) {
        self.focusSession = focusSession
        self.activationGuard = activationGuard
        self.isEnabled = isEnabled
        self.trustProvider = trustProvider
    }

    /// Smart Restore acts only when the toggle is on AND Accessibility is granted.
    var isOperational: Bool { isEnabled && trustProvider() }

    func startObserving() {
        guard observer == nil else { return }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            // Delivered on the main queue because we passed `.main`.
            MainActor.assumeIsolated {
                self?.handleActivation(note)
            }
        }
    }

    func stopObserving() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        onStateChange?()
    }

    private func handleActivation(_ note: Notification) {
        guard isOperational else { return }
        // Ignore activations caused by Solo's own hide/unhide/raise.
        guard !activationGuard.isSuppressing else { return }

        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        let pid = app.processIdentifier

        // Unconditionally ignore Solo itself and any app in the Focus session.
        guard pid != soloPid else { return }
        guard !focusSession.sessionPids.contains(pid) else { return }
        // A Cmd+H hidden app must not be unhidden by Smart Restore.
        guard !app.isHidden else { return }

        // Fast path: a visible normal window already exists → do nothing (common case).
        guard !WindowInspector.hasVisibleNormalWindow(pid: pid) else { return }

        // Restore is a self-operation: bracket it so the resulting activation is suppressed.
        activationGuard.noteSelfOperation()
        WindowInspector.restoreMinimizedWindow(pid: pid)
        activationGuard.noteSelfOperation()
    }
}
