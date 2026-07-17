import AppKit
import ApplicationServices

/// Window inspection for Smart Restore (design D3).
///
/// - Visibility ("does this app have a real window on the current Space?") uses
///   `CGWindowList`, which needs no permission for pid/bounds (we never read names).
/// - Minimized-window enumeration and restore use Accessibility, touched only when
///   a restore is actually plausible.
///
/// Every AX read/write is treated as fallible: any failure becomes a silent no-op.
@MainActor
enum WindowInspector {
    /// Minimum on-screen size to count as a "real" normal window. Tunable (design open question).
    static let minWidth: CGFloat = 100
    static let minHeight: CGFloat = 50

    /// True if `pid` owns a visible, normal-sized, layer-0 window on the current Space.
    static func hasVisibleNormalWindow(pid: pid_t) -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            guard let ownerPid = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  ownerPid == pid else { continue }
            // Layer 0 = normal application windows; higher layers are panels/menus/etc.
            let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? -1
            guard layer == 0 else { continue }
            guard let boundsDict = info[kCGWindowBounds as String] as? NSDictionary else { continue }
            var rect = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &rect) else { continue }
            if rect.width >= minWidth && rect.height >= minHeight {
                return true
            }
        }
        return false
    }

    /// Un-minimize one selected normal window of `pid`, raise it, and focus it.
    /// Returns whether a window was actually restored.
    @discardableResult
    static func restoreMinimizedWindow(pid: pid_t) -> Bool {
        let appElement = AXUIElementCreateApplication(pid)
        guard let windows = axWindows(of: appElement) else { return false }

        let minimized = windows.filter(isStandardMinimized)
        guard let target = selectWindow(minimized) else { return false }

        // De-minimize.
        let unminimized = AXUIElementSetAttributeValue(
            target, kAXMinimizedAttribute as CFString, kCFBooleanFalse) == .success
        guard unminimized else { return false }

        // Raise + focus.
        AXUIElementPerformAction(target, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(target, kAXMainAttribute as CFString, kCFBooleanTrue)
        NSRunningApplication(processIdentifier: pid)?.activate()
        return true
    }

    // MARK: - AX helpers (all failures → nil / false)

    private static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return result == .success ? value : nil
    }

    private static func axWindows(of app: AXUIElement) -> [AXUIElement]? {
        guard let value = copyAttribute(app, kAXWindowsAttribute) else { return nil }
        return value as? [AXUIElement]
    }

    private static func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool {
        guard let value = copyAttribute(element, attribute) else { return false }
        return (value as? Bool) ?? false
    }

    /// A minimized window with the standard window subrole (excludes panels, sheets, dialogs).
    private static func isStandardMinimized(_ window: AXUIElement) -> Bool {
        guard boolAttribute(window, kAXMinimizedAttribute) else { return false }
        guard let subrole = copyAttribute(window, kAXSubroleAttribute) as? String else { return false }
        return subrole == (kAXStandardWindowSubrole as String)
    }

    private static func windowArea(_ window: AXUIElement) -> CGFloat {
        guard let sizeRef = copyAttribute(window, kAXSizeAttribute),
              CFGetTypeID(sizeRef) == AXValueGetTypeID() else { return 0 }
        let axValue = sizeRef as! AXValue
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return 0 }
        return size.width * size.height
    }

    /// Selection priority: main window → largest → any (smart-restore spec).
    private static func selectWindow(_ windows: [AXUIElement]) -> AXUIElement? {
        guard !windows.isEmpty else { return nil }
        if let main = windows.first(where: { boolAttribute($0, kAXMainAttribute) }) {
            return main
        }
        return windows.max(by: { windowArea($0) < windowArea($1) })
    }
}
