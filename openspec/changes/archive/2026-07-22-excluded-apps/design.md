## Context

Solo Focus eligibility lives in `FocusSession.activate()` (guard chain over `RunningAppProviding`), Smart Restore gating in `SmartRestoreController.handleActivation()`. Both are unit-testable via the seams added in the testing change (`RunningAppProviding` fakes; controller guards). The Settings window shell arrives with the parked `shortcut-settings` change — this change extends it and MUST be applied after it. Decisions below were made in exploration.

## Goals / Non-Goals

**Goals:**
- One shared list protecting apps from both features, with two management surfaces (menu submenu, Settings section).
- Enforcement that is trivially unit-tested and consulted only at action time.
- Sensible rendering of stale (uninstalled) entries.

**Non-Goals:**
- Per-feature exclusion lists (a later refinement if ever requested).
- Excluding apps from the single-instance takeover or the permission flow (unrelated mechanisms).
- Wildcards/patterns; the list is exact bundle identifiers.

## Decisions

### D1: Storage — UserDefaults set of bundle identifiers
A dedicated `ExcludedApps` store type owning a `[String]` (bundle ids) under one UserDefaults key, exposed as a `Set<String>` with add/remove and a change callback for UI refresh. Bundle identifier is the only stable app identity (names collide, paths move). Apps without a bundle id (rare, unidentifiable) cannot be excluded and are silently ineligible for quick-add.

### D2: Enforcement — one guard per feature, action-time only
- `FocusSession.activate()`: skip apps whose bundle id is in the set (alongside the existing isRegular/isHidden/solo/frontmost guards). The session record is untouched by later list edits: deactivation restores exactly what was recorded, so an app excluded mid-session is still restored on toggle-off. The list takes effect at the next activation.
- `SmartRestoreController.handleActivation()`: return early when the activated app's bundle id is in the set.
Both guards receive the set via the store (injected), keeping fakes trivial.

### D3: Quick-add targets the last non-Solo frontmost app
By menu-open time, Solo is the active app, so the submenu cannot read "current frontmost". Track the last activated non-Solo application from the existing `didActivateApplicationNotification` subscription (extend `SmartRestoreController`'s observation or a tiny shared observer — implementer's choice, but do not add a second NSWorkspace subscription if avoidable). If no candidate exists yet (fresh launch, nothing activated), the quick-add item is disabled with a neutral title ("Exclude Current App").

### D4: Menu surface — Excluded Apps submenu
Status menu gains **Excluded Apps ▸** (between Smart Restore and Settings…, separated per existing menu grouping). Submenu contents, top to bottom: quick-add item ("Exclude “Safari”"), separator, one item per excluded app (checkmarked; clicking un-excludes), or a disabled "No Excluded Apps" placeholder when empty. Rebuilt in `menuNeedsUpdate` (the existing dynamic-menu pattern).

### D5: Settings surface — list section under the shortcut section
SwiftUI section in the existing Settings window: rows of app icon + display name (resolved via `NSWorkspace.urlForApplication(withBundleIdentifier:)`), a remove button per row, and a `+` control offering the running-apps picker and an NSOpenPanel fallback for non-running apps (reading the chosen bundle's identifier). Stale entries (no resolvable app) render the raw bundle id with a generic icon and remain removable.

### D6: Terminology
"Excluded Apps" in every user-facing string, spec, and type name (`ExcludedApps` store). Never "block list"/"ignore list"; PRD's "Ignored Applications" is superseded by this naming.

## Risks / Trade-offs

- [Two management surfaces can drift] → both render from the single store with a change callback; no cached copies.
- [Quick-add tracking races activation events] → "last non-Solo activated app" is inherently best-effort; worst case the item names the wrong recent app and the user uses the Settings picker instead. Accepted.
- [Bundle-id-less apps] → cannot be excluded (D1); Solo Focus will continue to hide them. Edge accepted for the prototype.
- [Delta against an unlanded spec] → the `shortcut-config` delta assumes `shortcut-settings` has synced to main specs; if application order is violated, the delta will not match and must be rebased. Mitigated by the ordering note in the proposal.
