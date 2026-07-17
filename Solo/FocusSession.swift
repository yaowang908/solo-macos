import AppKit

/// Solo Focus state machine (design D2/D7).
///
/// Uses only NSWorkspace/NSRunningApplication — no Accessibility permission.
/// A session records exactly the apps Solo hid so deactivation restores that
/// exact set (and nothing the user hid independently).
@MainActor
final class FocusSession {
    struct HiddenApp {
        let pid: pid_t
        let bundleIdentifier: String?
    }

    /// `nil` means Solo Focus is inactive; non-nil holds this session's record.
    private(set) var hiddenApps: [HiddenApp]?

    private let activationGuard: ActivationGuard

    /// Invoked after any state transition so the UI can re-render.
    var onStateChange: (() -> Void)?

    init(activationGuard: ActivationGuard) {
        self.activationGuard = activationGuard
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

        let workspace = NSWorkspace.shared
        let soloPid = ProcessInfo.processInfo.processIdentifier
        let frontmostPid = workspace.frontmostApplication?.processIdentifier

        var recorded: [HiddenApp] = []
        for app in workspace.runningApplications {
            // Eligibility exclusions (solo-focus spec):
            guard app.activationPolicy == .regular else { continue } // no background/menu-bar-only apps
            guard !app.isHidden else { continue }                    // pre-hidden apps stay out of the session
            guard app.processIdentifier != soloPid else { continue } // never hide Solo itself
            guard app.processIdentifier != frontmostPid else { continue } // keep the current app untouched

            if app.hide() {
                recorded.append(HiddenApp(pid: app.processIdentifier,
                                          bundleIdentifier: app.bundleIdentifier))
            }
        }

        hiddenApps = recorded
        activationGuard.noteSelfOperation()
        onStateChange?()
    }

    /// Unhide only still-running recorded apps, then clear the session.
    func deactivate() {
        guard let apps = hiddenApps else { return }

        activationGuard.noteSelfOperation()

        for entry in apps {
            guard let app = NSRunningApplication(processIdentifier: entry.pid) else {
                continue // app quit mid-session: skip without error
            }
            // Respect a manual unhide during the session; unhide() on a visible
            // app is a no-op, but guarding keeps the intent explicit and idempotent.
            if app.isHidden {
                app.unhide()
            }
        }

        hiddenApps = nil
        activationGuard.noteSelfOperation()
        onStateChange?()
    }
}
