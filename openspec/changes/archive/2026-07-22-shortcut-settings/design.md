## Context

Solo is a programmatic AppKit agent app (LSUIElement, `NSApplicationDelegate`-based, no storyboard, no SwiftUI lifecycle). The Toggle Solo Focus hotkey is registered via `KeyboardShortcuts.onKeyUp(for: .toggleSoloFocus)` with a hardcoded default `⌃⌥⌘S` defined on `KeyboardShortcuts.Name.toggleSoloFocus`. There is no settings UI. This change was explored in depth (conflict-class analysis) before proposal; decisions below record the outcomes.

## Goals / Non-Goals

**Goals:**
- User-configurable Toggle Solo Focus shortcut with immediate effect and persistence.
- Conflict warnings for the detectable classes: macOS system shortcuts and Solo's own menus.
- A deliberate "no shortcut" state (hotkey disabled; menu-only operation).
- Keep the Settings window shell minimal but extensible for future settings.

**Non-Goals:**
- Other settings (Launch at Login, Ignored Apps, restore-on-quit, Smart Restore relocation) — later changes.
- Detecting other apps' global hotkeys (impossible via public API at any permission level) or other apps' in-app menu shortcuts via AX (possible but deferred).
- A "test your shortcut" indicator — pressing the hotkey visibly toggles Focus (menu bar icon + apps hiding), which is sufficient feedback.

## Decisions

### D1: SwiftUI content in a hand-rolled AppKit window
A `SettingsWindowController` owning an `NSWindow` with an `NSHostingView` root. Rationale: the app has no SwiftUI `App`/`Settings` scene to hang a settings window on, and the KeyboardShortcuts SwiftUI `Recorder` is the preferred control per exploration. The window is created lazily, reused (front-and-center on reopen), released never (one window, trivial memory). As an agent app, opening must call `NSApp.activate(ignoringOtherApps: true)` so the window actually fronts.

### D2: Recorder = `KeyboardShortcuts.Recorder(for: .toggleSoloFocus)`
The library's recorder gives recording UX, persistence to UserDefaults under the Name, live re-registration of the hotkey (the existing `onKeyUp` binding keeps working), and built-in warnings for system-shortcut and own-menu conflicts. No custom detection code.

### D3: Clear (⊗) means "no shortcut", placeholder shows the default
Explicit clear stores the library's disabled state (distinct from "unset falls back to default" — the library persists these differently; the spec requires the distinction to survive relaunch). While empty, the field shows `⌃⌥⌘S` as grayed placeholder text — a hint of what re-recording the default looks like, NOT an indication that it is active. The stock recorder's placeholder says "Record Shortcut"; rendering the default combo instead is a small custom overlay/label arrangement around the recorder.

### D4: Undetectable-conflict mitigation is copy, not code
One caption line under the recorder: if the shortcut doesn't respond, another app may already own it — record a different combination. Rationale from exploration: macOS offers no API to enumerate other processes' global hotkeys; registration doesn't fail on duplicates; no permission changes this. The settings window itself is the recovery loop.

### D5: Menu placement
**Settings…** goes after "Smart Restore Minimized Windows" and before "Quit Solo", separated (matching the PRD §6.1 menu sketch order). No key equivalent (consistent with the deliberate no-⌘Q rule).

## Risks / Trade-offs

- [Recorder focus in an agent app] The recorder needs key focus to capture combos; LSUIElement apps sometimes fight for key window status → mitigated by `NSApp.activate` + making the settings window key on open; verify by hand.
- [Placeholder customization fights the library] If overlaying placeholder text on the SwiftUI `Recorder` proves brittle, fall back to a caption under the field ("Default: ⌃⌥⌘S — currently no shortcut") rather than forking the recorder. The spec requires communicating the default in the empty state, not a specific rendering.
- [User records a combo owned by an invisible app] Accepted residual risk; D4 copy is the mitigation. The moon icon/app-hiding provides immediate proof-of-life when testing.
- [Settings window lifecycle in single-instance takeovers] New instances terminate old ones (existing behavior); the window is transient UI with no unsaved state, so takeover mid-edit loses nothing.
