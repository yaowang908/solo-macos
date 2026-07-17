import AppKit

/// Entry point. Solo is an agent-style app (see Info.plist `LSUIElement`), so we
/// build the AppKit app by hand rather than relying on a storyboard/main nib.
@main
enum SoloApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Belt-and-suspenders with LSUIElement: never show a Dock icon.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
