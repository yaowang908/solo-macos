## Why

During a focus session, the **Restore Windows** menu item duplicates **Toggle Solo Focus** — both fully deactivate the session. The menu slot can do something the toggle cannot: selective restore. The session record already knows exactly which apps Solo hid, so users should be able to bring back one app at a time without ending focus.

**Ordering**: this is queue change #3 — apply after `shortcut-settings` and `excluded-apps`; its menu delta assumes both have landed.

## What Changes

- Rename **Restore Windows** to **Restore Apps** and turn it into a submenu (enabled only during a session): **Restore All** at the top, then one entry per session-hidden app; clicking an entry unhides just that app.
- Restoring an app via its individual entry **removes it from the session record**: the submenu shrinks, later Restore All / toggle-off restores only the remainder, and Smart Restore stops ignoring it.
- When the last recorded app is restored individually, the session **auto-ends** (icon inactive, record cleared) — indistinguishable from Restore All.
- Consistency fix folded in: activating Solo Focus when there is **nothing to hide no longer starts a session** (previously created an active-but-empty session).
- Apps that quit mid-session are tolerated in the submenu (pruned at menu build or a silent no-op on click).
- Menu-driven unhides are bracketed with the activation guard like every other Solo-initiated operation.

## Capabilities

### New Capabilities

_None — this refines existing capabilities._

### Modified Capabilities

- `solo-focus`: Deactivation/restore requirement gains partial-restore semantics (record pruning, auto-end on empty), and activation gains the nothing-to-hide rule.
- `menu-bar-app`: The **Restore Windows** menu item becomes the **Restore Apps** submenu. (Delta written assuming `shortcut-settings` and `excluded-apps` have landed.)

## Impact

- `FocusSession` gains a `restore(pid:)` (partial restore) operation and the empty-activation guard — all behind the existing `RunningAppProviding` seam, so the semantics get unit tests with the existing fakes.
- `StatusItemController` builds the submenu from the session record in `menuNeedsUpdate` (existing dynamic-menu pattern).
- No new permissions, dependencies, or storage.
