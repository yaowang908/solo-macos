## Why

The Solo Focus hotkey is hardcoded to `⌃⌥⌘S`. Users whose workflows collide with that combo (or who want no global hotkey at all) have no recourse, and the PRD (§6.4) has always called for a user-configurable shortcut with a conflict warning when detectable. This is the first slice of the Settings surface, deliberately scoped to just shortcut configuration.

## What Changes

- Add a **Settings window** (SwiftUI content hosted in an AppKit window; the app has no SwiftUI lifecycle) containing exactly one setting: a shortcut recorder for **Toggle Solo Focus**.
- Use `KeyboardShortcuts.Recorder`, which provides built-in conflict warnings for the two detectable conflict classes: macOS system shortcuts (via symbolic hotkeys) and Solo's own menus. No new permissions are required.
- Conflicts with **other apps' global hotkeys are undetectable on macOS at any permission level**; mitigate with one line of helper copy under the recorder ("If the shortcut doesn't respond, another app may already be using it — record a different one").
- Clear (⊗) semantics: clearing the recorder means **no shortcut** — the global hotkey is fully disabled and the menu toggle becomes the only trigger. The empty field shows the default combo (`⌃⌥⌘S`) as a grayed placeholder hint; restoring it means recording it again.
- The chosen shortcut (or the explicitly-cleared state) persists across relaunches; rebinding takes effect immediately without relaunching.
- Add a **Settings…** item to the status item menu.

## Capabilities

### New Capabilities

- `shortcut-config`: The Settings window, the Toggle Solo Focus shortcut recorder, detectable-conflict warnings, the no-shortcut cleared state with default-hint placeholder, persistence, and live rebinding.

### Modified Capabilities

- `menu-bar-app`: The status item menu gains a **Settings…** item that opens the Settings window.

## Impact

- New Swift sources: a settings window controller (AppKit host) and a SwiftUI settings view; `StatusItemController` gains the menu item; `AppDelegate` wires window presentation.
- Uses the existing `sindresorhus/KeyboardShortcuts` dependency (its recorder + persistence); the hardcoded default in the `KeyboardShortcuts.Name` extension remains as the default.
- No new permissions, no new dependencies, no changes to Solo Focus or Smart Restore behavior.
- Spec deltas: new `shortcut-config` spec; delta to `menu-bar-app` for the menu item.
