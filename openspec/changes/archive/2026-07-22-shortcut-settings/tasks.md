## 1. Settings window shell

- [x] 1.1 Implement `SettingsWindowController`: lazily created, reused `NSWindow` with an `NSHostingView` root; opening activates the app (`NSApp.activate`), fronts the window, and makes it key; verify it fronts from the agent app and reopening reuses the window
- [x] 1.2 Add **Settings…** to the status item menu (after Smart Restore, separated, before Quit Solo, no key equivalent) wired to the window controller; verify menu order and that the window opens

## 2. Shortcut recorder

- [x] 2.1 Build the SwiftUI settings view with `KeyboardShortcuts.Recorder(for: .toggleSoloFocus)` plus the undetectable-conflict guidance caption; verify recording a new combo toggles Solo Focus immediately and the old combo stops working
- [x] 2.2 Verify the built-in conflict warning fires when recording a reserved macOS system shortcut (e.g. a Mission Control combo) and the combination is not saved
- [x] 2.3 Implement the cleared state: clear (⊗) disables the hotkey entirely while the menu toggle keeps working; empty state communicates the default `⌃⌥⌘S` as a hint (placeholder overlay, or fall back to a caption per design D3 risk note); verify by hand
- [x] 2.4 Verify persistence across relaunch for both states: a custom recorded shortcut still works, and an explicitly cleared shortcut stays cleared (no hotkey registered)

## 3. Tests and docs

- [x] 3.1 Add the settings view/window sources to the Xcode project (pbxproj by hand per AGENTS.md; validate with `xcodebuild -list`) and confirm `xcodebuild test` still passes
- [x] 3.2 Update README (feature + menu table + limitations if wording changes) and AGENTS.md if new workflow lessons emerge; sync specs on completion
