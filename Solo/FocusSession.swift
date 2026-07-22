import AppKit

/// Solo Focus state machine (design D2/D7).
///
/// Uses only NSWorkspace/NSRunningApplication (via RunningAppProviding) — no
/// Accessibility permission. A session records exactly the apps Solo asked to
/// hide so deactivation restores that exact set (and nothing the user hid
/// independently).
@MainActor
final class FocusSession {
    struct HiddenApp {
        let pid: pid_t
        let bundleIdentifier: String?
    }

    /// `nil` means Solo Focus is inactive; non-nil holds this session's record.
    private(set) var hiddenApps: [HiddenApp]?

    private let activationGuard: ActivationGuard
    private let provider: any RunningAppProviding
    private let soloPid: pid_t
    /// Bundle ids protected from hiding (the Excluded Apps list), read at
    /// activation time only — session records are unaffected by later edits.
    private let excludedBundleIds: () -> Set<String>

    /// Invoked after any state transition so the UI can re-render.
    var onStateChange: (() -> Void)?

    init(activationGuard: ActivationGuard,
         provider: any RunningAppProviding = WorkspaceAppProvider(),
         soloPid: pid_t = ProcessInfo.processInfo.processIdentifier,
         excludedBundleIds: @escaping () -> Set<String> = { [] }) {
        self.activationGuard = activationGuard
        self.provider = provider
        self.soloPid = soloPid
        self.excludedBundleIds = excludedBundleIds
    }

    var isActive: Bool { hiddenApps != nil }

    /// True when Solo is currently hiding at least one app (drives Restore Windows enablement).
    var isManaging: Bool { !(hiddenApps?.isEmpty ?? true) }

    /// pids currently in the session — Smart Restore ignores these unconditionally.
    var sessionPids: Set<pid_t> {
        Set((hiddenApps ?? []).map(\.pid))
    }

    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    /// Hide every eligible app except the frontmost one; record what we hid.
    func activate() {
        guard hiddenApps == nil else { return }

        activationGuard.noteSelfOperation()

        let frontmostPid = provider.frontmostPid
        let excluded = excludedBundleIds()

        var recorded: [HiddenApp] = []
        for app in provider.apps {
            // Eligibility exclusions (solo-focus spec):
            guard app.isRegular else { continue }          // no background/menu-bar-only apps
            guard !app.isHidden else { continue }          // pre-hidden apps stay out of the session
            guard app.pid != soloPid else { continue }     // never hide Solo itself
            guard app.pid != frontmostPid else { continue } // keep the current app untouched
            if let bundleId = app.bundleID, excluded.contains(bundleId) { continue } // excluded apps stay visible

            // Record intent, not the return value: `NSRunningApplication.hide()`
            // is documented to return whether the request "succeeded", but on
            // current macOS it can hide the app visually while still returning
            // false. Gating the session record on that boolean loses the app and
            // makes restore impossible. Since `unhide()` is idempotent, recording
            // every app we asked to hide is both correct and safe.
            app.hide()
            recorded.append(HiddenApp(pid: app.pid, bundleIdentifier: app.bundleID))
        }

        // Nothing to hide → no session: "active" always implies at least one
        // app is Solo-hidden (restore-apps-menu spec).
        hiddenApps = recorded.isEmpty ? nil : recorded
        activationGuard.noteSelfOperation()
        onStateChange?()
    }

    /// Restore a single recorded app without ending the session (partial
    /// restore). Pruning the record keeps every consumer consistent: the menu
    /// list shrinks, Restore All handles only the remainder, and Smart Restore
    /// stops ignoring the app. When the record empties, the session ends
    /// exactly as deactivate() would. Unknown pids are a no-op; a recorded app
    /// that has quit is pruned silently.
    func restore(pid: pid_t) {
        guard var apps = hiddenApps,
              let index = apps.firstIndex(where: { $0.pid == pid }) else { return }

        activationGuard.noteSelfOperation()
        provider.app(pid: pid)?.unhide()
        apps.remove(at: index)
        hiddenApps = apps.isEmpty ? nil : apps
        activationGuard.noteSelfOperation()
        onStateChange?()
    }

    /// Unhide only still-running recorded apps, then clear the session.
    func deactivate() {
        guard let apps = hiddenApps else { return }

        activationGuard.noteSelfOperation()

        for entry in apps {
            guard let app = provider.app(pid: entry.pid) else {
                continue // app quit mid-session: skip without error
            }
            // Unhide unconditionally. `unhide()` only ever unhides, so it is a
            // harmless no-op for an app the user manually unhid mid-session
            // (idempotent restore). We must NOT gate on `isHidden`: that KVO
            // value can read stale right after our own `hide()`, which would
            // skip the unhide and leave the app hidden for good.
            app.unhide()
        }

        hiddenApps = nil
        activationGuard.noteSelfOperation()
        onStateChange?()
    }
}
