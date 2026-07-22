## Context

`FocusSession` owns the session record (`[HiddenApp]` of pid + bundle id); `deactivate()` restores the whole set. `StatusItemController` already rebuilds dynamic menu state in `menuNeedsUpdate`. Both are covered by the unit-test seams (`RunningAppProviding` fakes). Today "Restore Windows" simply calls `deactivate()` — fully redundant with the toggle while a session is active. Exploration settled the semantics; decisions below record them. This change is queued third, behind `shortcut-settings` and `excluded-apps`.

## Goals / Non-Goals

**Goals:**
- Selective, one-app-at-a-time restore during a session, from the status menu.
- Session record as the single source of truth for the submenu.
- Clean session lifecycle: no empty "zombie" sessions.

**Non-Goals:**
- Window-level restore granularity (hiding is app-level on macOS; entries are apps).
- Any change to Smart Restore behavior beyond the natural consequence of record pruning.
- Hotkey or Settings surface for selective restore — menu only.

## Decisions

### D1: Partial restore prunes the record
`FocusSession` gains `restore(pid:)`: unhide that app (activation-guard bracketed, unconditional `unhide()` per the established rule), remove it from `hiddenApps`, fire `onStateChange`. Pruning keeps every consumer consistent for free: the submenu (rendered from the record) drops the entry, Restore All / toggle-off handles only the remainder, and Smart Restore's in-session ignore stops applying (`sessionPids` shrinks). If the pid is not in the record, the call is a no-op.

### D2: Empty record ends the session
When `restore(pid:)` removes the last entry, the session ends exactly as `deactivate()` would (record nil, state change fired, icon inactive). Corollary folded in for consistency: `activate()` that finds nothing to hide does **not** start a session (no state flip, icon stays inactive). "Session active" now always implies "at least one app is Solo-hidden", which also simplifies the Restore Apps enablement rule (enabled ⇔ session exists).

### D3: Submenu shape and naming
**Restore Apps ▸** (renamed from Restore Windows; app-level grain, honest naming). Disabled when no session. Submenu: **Restore All** (calls `deactivate()`), separator, one item per recorded app ordered as recorded, titled with app display name (resolved from bundle id; fallback to bundle id string), with app icon where resolvable. Built fresh in `menuNeedsUpdate`.

### D4: Quit apps are tolerated, not surgically pruned
An app that quit mid-session may still sit in the record. Menu build renders it if it resolves; clicking an entry whose process is gone removes it from the record without error (same tolerance `deactivate()` already has). No proactive record-pruning on app termination — the record is only touched by user actions, keeping the state machine simple.

## Risks / Trade-offs

- [Auto-end surprises a user who wanted the session shell kept] → accepted: an empty session has no observable purpose; ending matches Restore All equivalence.
- [Menu item name change breaks user habit] → "Restore All" at the top of the submenu preserves the old one-click full restore, one level deeper.
- [Unhide alone shows nothing for minimized-only apps] → resolved during implementation (found live with Tailscale): a partial restore additionally activates the app and, when Smart Restore is operational, directly restores one minimized window (bypassing the activation observer, whose suppression bracket would otherwise swallow the event). Without Accessibility, it degrades to unhide+activate. The direct call lives in the coordinator (AppDelegate) so FocusSession stays permission-free.
- [Behavior change: empty activation no longer flips the icon] → this is the folded consistency fix; spec scenario updated deliberately (previously an active-but-empty session existed with `isManaging == false`).
