import AppKit

/// Actions and state the status item renders from. Implemented by the app coordinator.
@MainActor
protocol StatusItemDelegate: AnyObject {
    func toggleSoloFocus()
    func restoreWindows()
    func toggleSmartRestore()
    func openSettings()
    func quit()
    func excludeApp(bundleId: String)
    func unexcludeApp(bundleId: String)
    func restoreApp(pid: pid_t)

    var isFocusActive: Bool { get }
    var isManagingWindows: Bool { get }
    var isSmartRestoreEnabled: Bool { get }
    var smartRestoreNeedsPermission: Bool { get }
    /// Sorted display entries for the Excluded Apps submenu.
    var excludedAppEntries: [(bundleId: String, name: String, icon: NSImage?)] { get }
    /// The last non-Solo frontmost app — target of the quick-add item; nil disables it.
    var quickAddCandidate: (bundleId: String, name: String)? { get }
    /// Session-hidden apps in recorded order, for the Restore Apps submenu.
    var sessionAppEntries: [(pid: pid_t, name: String, icon: NSImage?)] { get }
}

/// Owns the `NSStatusItem`, its menu, and the state-reflecting icon (menu-bar-app spec).
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    weak var delegate: StatusItemDelegate?

    private let toggleItem = NSMenuItem(title: "Toggle Solo Focus", action: nil, keyEquivalent: "")
    private let restoreItem = NSMenuItem(title: "Restore Apps", action: nil, keyEquivalent: "")
    private let smartRestoreItem = NSMenuItem(title: "Smart Restore Minimized Windows", action: nil, keyEquivalent: "")
    private let excludedItem = NSMenuItem(title: "Excluded Apps", action: nil, keyEquivalent: "")
    // Deliberately no key equivalent (consistent with the no-⌘Q rule).
    private let settingsItem = NSMenuItem(title: "Settings…", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Solo", action: nil, keyEquivalent: "")

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
        refresh()
    }

    private func configureMenu() {
        toggleItem.target = self; toggleItem.action = #selector(onToggle)
        smartRestoreItem.target = self; smartRestoreItem.action = #selector(onSmartRestore)
        settingsItem.target = self; settingsItem.action = #selector(onSettings)
        quitItem.target = self; quitItem.action = #selector(onQuit)

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false // we manage `isEnabled` ourselves
        // Restore Apps holds a submenu (Restore All + per-app entries), so it
        // has no action of its own.
        restoreItem.submenu = NSMenu()
        excludedItem.submenu = NSMenu()

        menu.addItem(toggleItem)
        menu.addItem(restoreItem)
        menu.addItem(.separator())
        menu.addItem(smartRestoreItem)
        menu.addItem(excludedItem)
        menu.addItem(.separator())
        menu.addItem(settingsItem)
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
        rebuildExcludedSubmenu()
        rebuildRestoreSubmenu()
    }

    /// Restore Apps submenu (restore-apps-menu spec): Restore All, then one
    /// entry per session-recorded app in recorded order; choosing an entry
    /// partially restores that app. Rebuilt on every menu open.
    private func rebuildRestoreSubmenu() {
        guard let delegate, let submenu = restoreItem.submenu else { return }
        submenu.removeAllItems()
        submenu.autoenablesItems = false

        let restoreAll = NSMenuItem(title: "Restore All", action: #selector(onRestore), keyEquivalent: "")
        restoreAll.target = self
        submenu.addItem(restoreAll)
        submenu.addItem(.separator())

        for entry in delegate.sessionAppEntries {
            let item = NSMenuItem(title: entry.name, action: #selector(onRestoreOne(_:)), keyEquivalent: "")
            item.representedObject = NSNumber(value: entry.pid)
            if let icon = entry.icon {
                let small = icon.copy() as! NSImage
                small.size = NSSize(width: 16, height: 16)
                item.image = small
            }
            item.target = self
            submenu.addItem(item)
        }
    }

    /// Excluded Apps submenu (excluded-apps spec): quick-add on top, then the
    /// current list as checkmarked entries (click to un-exclude). Rebuilt on
    /// every menu open, rendered straight from the delegate's data.
    private func rebuildExcludedSubmenu() {
        guard let delegate, let submenu = excludedItem.submenu else { return }
        submenu.removeAllItems()
        submenu.autoenablesItems = false

        let excluded = delegate.excludedAppEntries
        let candidate = delegate.quickAddCandidate

        let quickAdd: NSMenuItem
        if let candidate, !excluded.contains(where: { $0.bundleId == candidate.bundleId }) {
            quickAdd = NSMenuItem(title: "Exclude “\(candidate.name)”", action: #selector(onQuickAddExclusion(_:)), keyEquivalent: "")
            quickAdd.representedObject = candidate.bundleId
            quickAdd.target = self
        } else {
            quickAdd = NSMenuItem(title: "Exclude Current App", action: nil, keyEquivalent: "")
            quickAdd.isEnabled = false
        }
        submenu.addItem(quickAdd)
        submenu.addItem(.separator())

        if excluded.isEmpty {
            let placeholder = NSMenuItem(title: "No Excluded Apps", action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            submenu.addItem(placeholder)
        } else {
            for entry in excluded {
                let item = NSMenuItem(title: entry.name, action: #selector(onRemoveExclusion(_:)), keyEquivalent: "")
                item.state = .on
                item.representedObject = entry.bundleId
                if let icon = entry.icon {
                    let small = icon.copy() as! NSImage
                    small.size = NSSize(width: 16, height: 16)
                    item.image = small
                }
                item.target = self
                submenu.addItem(item)
            }
        }
    }

    // MARK: - Actions

    @objc private func onToggle() { delegate?.toggleSoloFocus() }
    @objc private func onRestore() { delegate?.restoreWindows() }
    @objc private func onSmartRestore() { delegate?.toggleSmartRestore() }
    @objc private func onSettings() { delegate?.openSettings() }
    @objc private func onQuit() { delegate?.quit() }

    @objc private func onRestoreOne(_ sender: NSMenuItem) {
        guard let pid = (sender.representedObject as? NSNumber)?.int32Value else { return }
        delegate?.restoreApp(pid: pid)
    }

    @objc private func onQuickAddExclusion(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else { return }
        delegate?.excludeApp(bundleId: bundleId)
    }

    @objc private func onRemoveExclusion(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else { return }
        delegate?.unexcludeApp(bundleId: bundleId)
    }
}
