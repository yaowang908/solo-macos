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
            var rect = CGRect.zero
            if let boundsDict = info[kCGWindowBounds as String] as? NSDictionary {
                CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &rect)
            }
            let counts = layer == 0 && rect.width >= minWidth && rect.height >= minHeight
            DebugLog.write("    vis pid \(pid): layer=\(layer) \(Int(rect.width))x\(Int(rect.height)) -> \(counts ? "VISIBLE" : "ignored")")
            if counts {
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
        guard let windows = axWindows(of: appElement) else {
            DebugLog.write("    ax pid \(pid): kAXWindows unreadable (no AX support?)")
            return false
        }

        // Diagnostic dump: every window's role/subrole/minimized/size, so we can
        // see exactly why nonstandard apps (Catalyst, Electron, Outlook) fail.
        for w in windows {
            let role = copyAttribute(w, kAXRoleAttribute) as? String ?? "nil"
            let subrole = copyAttribute(w, kAXSubroleAttribute) as? String ?? "nil"
            let minimized = boolAttribute(w, kAXMinimizedAttribute)
            DebugLog.write("    ax pid \(pid): role=\(role) subrole=\(subrole) minimized=\(minimized) area=\(Int(windowArea(w)))")
        }

        let minimized = windows.filter(isRestorableMinimized)
        DebugLog.write("    ax pid \(pid): \(windows.count) windows, \(minimized.count) pass the restorable-minimized filter")
        guard let target = selectWindow(minimized) else { return false }

        // De-minimize.
        let unminimized = AXUIElementSetAttributeValue(
            target, kAXMinimizedAttribute as CFString, kCFBooleanFalse) == .success
        guard unminimized else {
            DebugLog.write("    ax pid \(pid): set AXMinimized=false FAILED")
            return false
        }

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

    /// Subroles that must never be restored even if they somehow end up minimized.
    private static let excludedSubroles: Set<String> = [
        kAXSystemDialogSubrole as String,
        kAXFloatingWindowSubrole as String,
        kAXSystemFloatingWindowSubrole as String,
    ]

    /// A minimized window eligible for restore. Minimized-ness is itself the strong
    /// signal — sheets, popovers, and modal dialogs cannot be user-minimized to the
    /// Dock — so this is a blocklist, not an allowlist: requiring
    /// `subrole == AXStandardWindow` wrongly rejects Outlook and Notes, whose
    /// minimized main windows report `AXDialog` on current macOS.
    private static func isRestorableMinimized(_ window: AXUIElement) -> Bool {
        guard boolAttribute(window, kAXMinimizedAttribute) else { return false }
        guard (copyAttribute(window, kAXRoleAttribute) as? String) == (kAXWindowRole as String) else { return false }
        if let subrole = copyAttribute(window, kAXSubroleAttribute) as? String,
           excludedSubroles.contains(subrole) {
            return false
        }
        // Same "real window" size floor as the CGWindowList visibility check.
        return windowArea(window) >= minWidth * minHeight
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
