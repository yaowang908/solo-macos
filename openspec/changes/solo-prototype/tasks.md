## 1. Project scaffold

- [x] 1.1 Create the Xcode project (Swift, AppKit app target "Solo", macOS 14 deployment, Apple Silicon) with `LSUIElement = YES`; verify launching shows no Dock icon and no window
- [x] 1.2 Add the `sindresorhus/KeyboardShortcuts` SPM dependency and confirm the project builds
- [x] 1.3 Add `.gitignore` for Xcode and commit the scaffold

## 2. Menu bar shell

- [x] 2.1 Implement `StatusItemController` with a status item, template icon, and menu: Toggle Solo Focus, Restore Windows (disabled), Smart Restore Minimized Windows (checkable), Quit Solo; verify by opening the menu
- [x] 2.2 Wire icon active/inactive appearances driven by a stub focus state; verify the icon flips when the state flips

## 3. Solo Focus

- [x] 3.1 Implement `FocusSession` activation: enumerate `.regular`, non-hidden, non-Solo, non-frontmost apps, `hide()` each, record hidden pids; verify other apps hide while the current app stays put
- [x] 3.2 Implement deactivation: `unhide()` still-running recorded apps only, clear the record; verify round trip restores exactly the original set and skips a quit app without error
- [x] 3.3 Handle edge behaviors: pre-hidden apps excluded from the session, manual unhide mid-session not toggled back, repeated toggling idempotent; verify each by hand
- [x] 3.4 Connect Toggle Solo Focus menu item, Restore Windows enablement, and icon state to `FocusSession`; verify the full menu flow
- [x] 3.5 Register the global hotkey `⌃⌥⌘S` via KeyboardShortcuts and bind it to the toggle; verify it works while a third-party app is frontmost
- [x] 3.6 Unhide session apps on Quit; verify quitting mid-session restores hidden apps

## 4. Accessibility permission flow

- [x] 4.1 Implement `PermissionMonitor`: non-prompting `AXIsProcessTrusted()` checks, ~2 s polling while Smart Restore is enabled-but-untrusted, stop on grant/disable; verify grant is detected live without relaunch
- [x] 4.2 Implement the permission explainer (plain-language alert with an "Open System Settings" button deep-linking to the Accessibility pane), triggered when Smart Restore needs an absent permission; verify the link lands on the right pane
- [x] 4.3 Reflect the blocked state in the menu (Smart Restore item indicates permission is required) and confirm Solo Focus is unaffected while permission is denied

## 5. Smart Restore

- [x] 5.1 Implement `WindowInspector` visibility check via `CGWindowListCopyWindowInfo(.optionOnScreenOnly)` (owner pid, layer 0, size floor); verify it correctly answers "has visible window" for Finder and Safari
- [x] 5.2 Implement AX minimized-window enumeration and selection (standard subrole; main → largest → any) plus de-minimize + raise + focus; verify against a manually minimized Safari window
- [x] 5.3 Implement `SmartRestoreController`: subscribe to `didActivateApplicationNotification`, gate on toggle + trust, fast-path no-op when a visible window exists; verify the PRD behavior table (only-minimized restores; visible window no-op; no windows no-op; Cmd+H app stays hidden)
- [x] 5.4 Implement `ActivationGuard` time-based suppression around Solo-initiated hide/unhide/raise, plus unconditional ignore of Solo itself and in-session apps; verify toggling Solo Focus never un-minimizes anything
- [x] 5.5 Make all AX failures silent no-ops and test against a hostile set: VS Code (Electron), a Catalyst app, and an app with only a panel window
- [x] 5.6 Wire the Smart Restore menu checkbox to a UserDefaults-backed setting; verify toggling off makes activations inert immediately

## 6. Prototype validation

- [ ] 6.1 Run the PRD §6.3 behavior table end-to-end plus the feature-interaction scenario (Solo Focus toggle with minimized windows present) and fix anything that violates a spec scenario
- [ ] 6.2 Sanity-check idle footprint (Activity Monitor: negligible CPU when idle, resident memory in the tens of MB) and tune the ActivationGuard window if suppression logs show gaps
