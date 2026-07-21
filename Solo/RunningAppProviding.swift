import AppKit

/// Seam over NSWorkspace/NSRunningApplication so FocusSession's session logic is
/// unit-testable with fakes. The live implementations are thin pass-throughs.
@MainActor
protocol RunningAppHandle {
    var pid: pid_t { get }
    var bundleID: String? { get }
    var isRegular: Bool { get }
    var isHidden: Bool { get }
    @discardableResult func hide() -> Bool
    @discardableResult func unhide() -> Bool
}

@MainActor
protocol RunningAppProviding {
    var apps: [any RunningAppHandle] { get }
    var frontmostPid: pid_t? { get }
    func app(pid: pid_t) -> (any RunningAppHandle)?
}

@MainActor
struct WorkspaceAppHandle: RunningAppHandle {
    let app: NSRunningApplication

    var pid: pid_t { app.processIdentifier }
    var bundleID: String? { app.bundleIdentifier }
    var isRegular: Bool { app.activationPolicy == .regular }
    var isHidden: Bool { app.isHidden }
    @discardableResult func hide() -> Bool { app.hide() }
    @discardableResult func unhide() -> Bool { app.unhide() }
}

@MainActor
struct WorkspaceAppProvider: RunningAppProviding {
    nonisolated init() {}

    var apps: [any RunningAppHandle] {
        NSWorkspace.shared.runningApplications.map { WorkspaceAppHandle(app: $0) }
    }

    var frontmostPid: pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    func app(pid: pid_t) -> (any RunningAppHandle)? {
        NSRunningApplication(processIdentifier: pid).map { WorkspaceAppHandle(app: $0) }
    }
}
