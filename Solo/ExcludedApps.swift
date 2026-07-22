import AppKit
import Combine

/// The shared Excluded Apps list (design D1): bundle identifiers persisted in
/// UserDefaults, honored by both Solo Focus (never hidden) and Smart Restore
/// (never auto-restored). ObservableObject so the Settings section re-renders;
/// the status menu needs no notification because it rebuilds on every open.
@MainActor
final class ExcludedApps: ObservableObject {
    private static let defaultsKey = "excludedBundleIds"

    @Published private(set) var bundleIds: Set<String>

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bundleIds = Set(defaults.stringArray(forKey: Self.defaultsKey) ?? [])
    }

    func contains(_ bundleId: String?) -> Bool {
        guard let bundleId else { return false } // bundle-id-less apps can't be excluded (D1)
        return bundleIds.contains(bundleId)
    }

    func add(_ bundleId: String) {
        bundleIds.insert(bundleId)
        persist()
    }

    func remove(_ bundleId: String) {
        bundleIds.remove(bundleId)
        persist()
    }

    private func persist() {
        defaults.set(bundleIds.sorted(), forKey: Self.defaultsKey)
    }

    // MARK: - Display helpers (shared by menu and Settings)

    /// Resolved display info for a listed bundle id. Stale entries (uninstalled
    /// apps) fall back to the raw bundle id and a generic icon.
    static func displayInfo(for bundleId: String) -> (name: String, icon: NSImage?) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return (bundleId, nil)
        }
        let name = FileManager.default.displayName(atPath: url.path)
        return (name, NSWorkspace.shared.icon(forFile: url.path))
    }
}
