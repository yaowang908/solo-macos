import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global hotkey default: ⌃⌥⌘S (menu-bar-app spec). No recorder UI in the prototype.
    static let toggleSoloFocus = Self(
        "toggleSoloFocus",
        default: .init(.s, modifiers: [.control, .option, .command])
    )
}

/// App coordinator: owns the feature objects and wires them together (design D1/D7).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let smartRestoreDefaultsKey = "smartRestoreEnabled"

    private let activationGuard = ActivationGuard()
    private let permissionMonitor = PermissionMonitor()
    private lazy var focusSession = FocusSession(activationGuard: activationGuard)

    private var statusController: StatusItemController!
    private var smartRestore: SmartRestoreController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        // Smart Restore default is enabled (smart-restore + accessibility-permission specs).
        if defaults.object(forKey: Self.smartRestoreDefaultsKey) == nil {
            defaults.set(true, forKey: Self.smartRestoreDefaultsKey)
        }
        let smartRestoreEnabled = defaults.bool(forKey: Self.smartRestoreDefaultsKey)

        smartRestore = SmartRestoreController(
            focusSession: focusSession,
            activationGuard: activationGuard,
            isEnabled: smartRestoreEnabled,
            trustProvider: { [weak self] in self?.permissionMonitor.isTrusted ?? false }
        )

        statusController = StatusItemController()
        statusController.delegate = self

        focusSession.onStateChange = { [weak self] in self?.statusController.refresh() }
        smartRestore.onStateChange = { [weak self] in self?.statusController.refresh() }
        permissionMonitor.onTrustChanged = { [weak self] _ in self?.statusController.refresh() }

        smartRestore.startObserving()

        KeyboardShortcuts.onKeyUp(for: .toggleSoloFocus) { [weak self] in
            self?.toggleSoloFocus()
        }

        // First-launch: if Smart Restore's default would take effect but we're not
        // trusted yet, run the permission flow (accessibility-permission spec).
        if smartRestoreEnabled && !permissionMonitor.isTrusted {
            requestSmartRestorePermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean quit: restore any Solo-hidden apps before exiting (menu-bar-app spec).
        if focusSession.isActive {
            focusSession.deactivate()
        }
        smartRestore?.stopObserving()
        permissionMonitor.stopPolling()
    }

    private func requestSmartRestorePermission() {
        permissionMonitor.presentExplainer()
        if !permissionMonitor.refresh() {
            permissionMonitor.startPolling()
        }
    }
}

// MARK: - StatusItemDelegate

extension AppDelegate: StatusItemDelegate {
    func toggleSoloFocus() {
        focusSession.toggle()
        statusController.refresh()
    }

    func restoreWindows() {
        focusSession.deactivate()
        statusController.refresh()
    }

    func toggleSmartRestore() {
        let newValue = !smartRestore.isEnabled
        UserDefaults.standard.set(newValue, forKey: Self.smartRestoreDefaultsKey)
        smartRestore.setEnabled(newValue)

        if newValue && !permissionMonitor.isTrusted {
            requestSmartRestorePermission()
        } else if !newValue {
            permissionMonitor.stopPolling()
        }
        statusController.refresh()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    var isFocusActive: Bool { focusSession.isActive }
    var isManagingWindows: Bool { focusSession.isManaging }
    var isSmartRestoreEnabled: Bool { smartRestore.isEnabled }
    var smartRestoreNeedsPermission: Bool { !permissionMonitor.isTrusted }
}
