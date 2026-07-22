import AppKit

/// Smart Restore: observe app activations and restore a minimized window when the
/// activated app has none visible (design D3/D4, smart-restore spec).
@MainActor
final class SmartRestoreController {
    private let focusSession: FocusSession
    private let activationGuard: ActivationGuard
    private let trustProvider: () -> Bool
    /// Bundle ids whose activations are ignored entirely (the Excluded Apps list).
    private let excludedBundleIds: () -> Set<String>
    private let soloPid = ProcessInfo.processInfo.processIdentifier

    private(set) var isEnabled: Bool
    private var observer: NSObjectProtocol?

    /// The most recently activated non-Solo app with a bundle id — the target of
    /// the Excluded Apps quick-add (design D3). Best-effort by nature; tracked
    /// regardless of Smart Restore's enabled/trusted state.
    private(set) var lastActiveApp: (bundleId: String, name: String)?

    /// Called when the enabled flag changes so the UI can re-render.
    var onStateChange: (() -> Void)?

    init(focusSession: FocusSession,
         activationGuard: ActivationGuard,
         isEnabled: Bool,
         trustProvider: @escaping () -> Bool,
         excludedBundleIds: @escaping () -> Set<String> = { [] }) {
        self.focusSession = focusSession
        self.activationGuard = activationGuard
        self.isEnabled = isEnabled
        self.trustProvider = trustProvider
        self.excludedBundleIds = excludedBundleIds
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

    /// Explicit, user-initiated restore (the Restore Apps menu): if operational
    /// and the app has no visible normal window but minimized ones, restore one.
    /// Deliberately a direct call rather than the activation-observer path — the
    /// user's intent is unambiguous, so the self-caused-activation suppression
    /// window must not swallow it.
    func restoreWindowIfOnlyMinimized(pid: pid_t) {
        guard isOperational else { return }
        guard !WindowInspector.hasVisibleNormalWindow(pid: pid) else { return }
        activationGuard.noteSelfOperation()
        let restored = WindowInspector.restoreMinimizedWindow(pid: pid)
        activationGuard.noteSelfOperation()
        DebugLog.write("explicit restore pid \(pid): result=\(restored)")
    }

    private func handleActivation(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        let pid = app.processIdentifier

        // Unconditionally ignore Solo itself (also keeps it out of quick-add).
        guard pid != soloPid else { return }

        // Track the quick-add candidate before any feature gating: the Excluded
        // Apps menu must work even while Smart Restore is disabled or untrusted.
        if let bundleId = app.bundleIdentifier {
            lastActiveApp = (bundleId, app.localizedName ?? bundleId)
        }

        DebugLog.write("activation \(app.bundleIdentifier ?? "?"): enabled=\(isEnabled) trusted=\(trustProvider()) suppressing=\(activationGuard.isSuppressing)")
        guard isOperational else { DebugLog.write("  -> skip: not operational"); return }
        // Ignore activations caused by Solo's own hide/unhide/raise.
        guard !activationGuard.isSuppressing else { DebugLog.write("  -> skip: suppressing"); return }

        // Excluded apps are never acted on (excluded-apps spec).
        guard !excludedBundleIds().contains(app.bundleIdentifier ?? "") else { DebugLog.write("  -> skip: excluded"); return }

        guard !focusSession.sessionPids.contains(pid) else { DebugLog.write("  -> skip: in focus session"); return }
        // A Cmd+H hidden app must not be unhidden by Smart Restore.
        guard !app.isHidden else { DebugLog.write("  -> skip: app hidden (Cmd+H)"); return }

        // Fast path: a visible normal window already exists → do nothing (common case).
        guard !WindowInspector.hasVisibleNormalWindow(pid: pid) else { DebugLog.write("  -> skip: has visible window"); return }

        // Restore is a self-operation: bracket it so the resulting activation is suppressed.
        activationGuard.noteSelfOperation()
        let restored = WindowInspector.restoreMinimizedWindow(pid: pid)
        activationGuard.noteSelfOperation()
        DebugLog.write("  -> restore attempted, result=\(restored)")
    }
}
