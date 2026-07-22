## Why

Solo currently acts on every eligible app: Solo Focus hides everything except the frontmost app, and Smart Restore un-minimizes any app the user activates. Users need a way to protect specific apps from both behaviors — keep a music player or floating timer visible during focus, and stop auto-restore from popping certain apps back open. The PRD (§6.4) calls for an "Ignored Applications list, used by both features"; this change delivers it under the name **Excluded Apps**.

**Ordering**: this change assumes `shortcut-settings` has landed (it extends the Settings window that change introduces) and MUST be applied after it.

## What Changes

- Add a shared **Excluded Apps list** (bundle identifiers, UserDefaults-backed) honored by both features: excluded apps are never hidden by Solo Focus and never auto-restored by Smart Restore.
- Enforcement happens at action time only: an in-flight focus session that already hid an app still restores it on toggle-off; exclusion takes effect from the next session/activation.
- Add an **Excluded Apps submenu** to the status item menu: a quick-add item for the last non-Solo frontmost app at the top, then the current list (click an entry to un-exclude).
- Add an **Excluded Apps section** to the Settings window: entries with app icons/names, remove buttons, and a `+` flow (running-apps picker plus NSOpenPanel for non-running apps).
- Stale entries (uninstalled apps) render by raw bundle identifier with a generic icon and remain removable.
- Terminology is "Excluded Apps" everywhere (not "block list"/"ignore list").

## Capabilities

### New Capabilities

- `excluded-apps`: The shared exclusion list — storage, both enforcement points' semantics, the status-menu submenu, the Settings window section, and stale-entry handling.

### Modified Capabilities

- `solo-focus`: Eligibility exclusions gain "app is on the Excluded Apps list", with the action-time-only rule.
- `smart-restore`: Activation handling gains "excluded apps are never auto-restored".
- `menu-bar-app`: The status item menu gains the Excluded Apps submenu.
- `shortcut-config`: The Settings window requirement widens from "contains the shortcut recorder" to also hosting the Excluded Apps section. (Delta written against the `shortcut-settings` change's spec, which must land first.)

## Impact

- New Swift sources: an `ExcludedApps` store (UserDefaults set of bundle ids) and Settings section view; `StatusItemController` gains the submenu; last-non-Solo-frontmost tracking added to the existing activation observation.
- One new guard each in `FocusSession.activate()` and `SmartRestoreController.handleActivation()` — both behind existing test seams, so enforcement gets unit tests with the existing fakes.
- No new permissions, no new dependencies.
- Spec deltas: 1 new capability, 4 modified.
