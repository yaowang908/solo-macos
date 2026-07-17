import AppKit

/// Actions and state the status item renders from. Implemented by the app coordinator.
@MainActor
protocol StatusItemDelegate: AnyObject {
    func toggleSoloFocus()
    func restoreWindows()
    func toggleSmartRestore()
    func quit()

    var isFocusActive: Bool { get }
    var isManagingWindows: Bool { get }
    var isSmartRestoreEnabled: Bool { get }
    var smartRestoreNeedsPermission: Bool { get }
}

/// Owns the `NSStatusItem`, its menu, and the state-reflecting icon (menu-bar-app spec).
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    weak var delegate: StatusItemDelegate?

    private let toggleItem = NSMenuItem(title: "Toggle Solo Focus", action: nil, keyEquivalent: "")
    private let restoreItem = NSMenuItem(title: "Restore Windows", action: nil, keyEquivalent: "")
    private let smartRestoreItem = NSMenuItem(title: "Smart Restore Minimized Windows", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Solo", action: nil, keyEquivalent: "")

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
        refresh()
    }

    private func configureMenu() {
        toggleItem.target = self; toggleItem.action = #selector(onToggle)
        restoreItem.target = self; restoreItem.action = #selector(onRestore)
        smartRestoreItem.target = self; smartRestoreItem.action = #selector(onSmartRestore)
        quitItem.target = self; quitItem.action = #selector(onQuit)

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false // we manage `isEnabled` ourselves
        menu.addItem(toggleItem)
        menu.addItem(restoreItem)
        menu.addItem(.separator())
        menu.addItem(smartRestoreItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    /// Update the menu bar icon to reflect Solo Focus state.
    func refresh() {
        guard let button = statusItem.button else { return }
        let active = delegate?.isFocusActive ?? false
        let symbol = active ? "moon.fill" : "moon"
        let description = active ? "Solo Focus active" : "Solo Focus inactive"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image
        button.toolTip = active ? "Solo Focus: on" : "Solo Focus: off"
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let delegate else { return }
        toggleItem.title = delegate.isFocusActive ? "Turn Off Solo Focus" : "Toggle Solo Focus"
        restoreItem.isEnabled = delegate.isManagingWindows
        smartRestoreItem.state = delegate.isSmartRestoreEnabled ? .on : .off
        if delegate.isSmartRestoreEnabled && delegate.smartRestoreNeedsPermission {
            smartRestoreItem.title = "Smart Restore Minimized Windows (Accessibility permission required)"
        } else {
            smartRestoreItem.title = "Smart Restore Minimized Windows"
        }
    }

    // MARK: - Actions

    @objc private func onToggle() { delegate?.toggleSoloFocus() }
    @objc private func onRestore() { delegate?.restoreWindows() }
    @objc private func onSmartRestore() { delegate?.toggleSmartRestore() }
    @objc private func onQuit() { delegate?.quit() }
}
