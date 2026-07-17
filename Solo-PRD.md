# Solo — Product Requirements Document

## 1. Product Summary

**Solo** is a lightweight macOS menu bar utility that makes it easier to focus on one task and recover minimized work. It provides two complementary behaviors:

1. **Solo Focus** — hide all other applications while leaving the currently active application available.
2. **Smart Restore** — when the user activates an application whose windows are all minimized, restore one appropriate window and bring it forward.

Solo should feel native, immediate, and reversible. It does not close windows, move them, or alter a user's workspace beyond hiding or restoring windows it explicitly manages.

## 2. Goals

- Remove visual distractions with one click or shortcut.
- Make switching to an app with only minimized windows useful immediately.
- Preserve users' existing window layouts and manual choices.
- Stay out of the Dock and consume negligible resources while idle.

## 3. Non-goals (MVP)

- Full window tiling, snapping, or layout management.
- Managing windows across Spaces, displays, or full-screen apps beyond safe no-op behavior.
- Creating a new window for an app with no open windows.
- Profiles, Focus mode automation, Shortcuts, and AppleScript support.

## 4. Target Users

People who regularly work across many macOS applications—developers, writers, designers, students, and knowledge workers—and want a fast, low-friction way to reduce desktop clutter.

## 5. Primary User Stories

### Focus the current task

As a user, I can invoke Solo from the menu bar or keyboard so that other applications disappear and I can work without visual clutter.

### Restore my workspace

As a user, I can invoke Solo again to bring back only the applications Solo hid, leaving anything I had already hidden untouched.

### Recover a minimized app while switching

As a user, when I activate an app that has no visible windows but does have minimized windows, I see a useful window restored and focused instead of an empty desktop.

## 6. MVP Requirements

### 6.1 Menu bar application

- Solo runs as an agent-style macOS app: menu bar icon, no Dock icon, no main app window.
- The icon exposes a menu containing:
  - **Toggle Solo Focus**
  - **Restore Windows** (disabled when nothing is managed)
  - **Smart Restore Minimized Windows** (on/off)
  - **Launch at Login** (on/off)
  - **Settings…**
  - **About Solo**
  - **Quit Solo**
- The menu bar icon must clearly convey whether Solo Focus is active.

### 6.2 Solo Focus

**Trigger:** clicking the menu bar icon's primary action or using the global shortcut. Default shortcut: `Control + Option + Command + S`.

**When inactive:**

1. Determine the frontmost application.
2. Keep that application available; do not minimize, hide, move, resize, or close its windows.
3. Hide every other currently visible, eligible application.
4. Record exactly which applications Solo hid in this activation.
5. Mark Solo Focus as active.

**When active (toggle):**

1. Unhide only applications recorded in the active Solo Focus session, provided they are still running.
2. Do not change applications the user hid independently before or during the session.
3. Clear the session record and mark Solo Focus inactive.

**Eligibility / exclusions:**

- Ignore Solo itself, system UI processes, and applications without user-facing windows.
- Do not interfere with the current application's windows.
- Safely skip applications that do not permit Accessibility-based control.
- Default behavior is to preserve minimized windows as minimized; they are not restored by Solo Focus.

### 6.3 Smart Restore Minimized Windows

**Default:** enabled.

Solo observes application-activation events. When an eligible application becomes active:

1. Determine whether the app has a visible, non-minimized normal window on the current workspace.
2. If it does, take no action.
3. If it does not, find the app's minimized normal windows.
4. Restore one selected window, raise it, and return keyboard focus to it.
5. If no suitable window exists or the operation fails, take no disruptive action.

**Window selection priority:**

1. The most recently focused window known to Solo for that application.
2. The app's main or focused document window, if identifiable.
3. The largest minimized normal window.
4. Any eligible minimized normal window.

**Expected behavior:**

| Situation | Result |
| --- | --- |
| User activates VS Code and its only window is minimized | Solo restores and focuses that window. |
| User activates Slack with a visible window | Solo does nothing. |
| Finder has one visible and one minimized window | Solo does nothing. |
| An app has no windows | Solo does nothing. |
| An app is hidden (`Command + H`) | Solo does not automatically unhide it in MVP. |

**Important product constraint:** macOS activation notifications do not reliably state whether activation came specifically from `Command + Tab`, a Dock click, or another method. Therefore MVP Smart Restore applies to eligible app activations generally. A later “only when activated with Command + Tab” preference is conditional on a reliable, privacy-respecting technical implementation.

### 6.4 Settings

MVP settings:

- Smart Restore Minimized Windows (enabled by default)
- Global keyboard shortcut (user-configurable; conflict warning when detectable)
- Launch at Login (disabled by default)
- Ignored Applications list, used by both features
- Restore Solo-managed applications on quit (enabled by default)

## 7. Permissions and Onboarding

Solo requires macOS Accessibility permission to inspect and manage other applications' windows.

On first use of either window-management feature, Solo must:

1. Explain plainly why Accessibility access is needed.
2. Offer to open the macOS Accessibility settings page.
3. Detect a newly granted permission without requiring a relaunch where practical.
4. Remain usable as a menu bar app if permission is denied, while disabling actions that require it and explaining how to enable them.

## 8. Edge Cases

- **Multiple displays / Spaces:** Do not force a Space change. Only operate where the Accessibility APIs make the intended action safe; otherwise no-op.
- **Full-screen apps, modal dialogs, sheets, and floating utility panels:** Do not displace or restore them as the selected normal window unless the platform clearly identifies them as appropriate.
- **App exits during a session:** Remove it from Solo's restore record without error.
- **Manual changes during Solo Focus:** If the user manually unhides an app, restore remains idempotent and must not toggle it back unexpectedly.
- **Sleep / wake:** Clear stale accessibility references and continue safely.
- **Protected or nonstandard apps:** Skip unsupported windows; never crash or repeatedly retry in the foreground.

## 9. Non-functional Requirements

- macOS 14 (Sonoma) and later.
- Apple Silicon required for MVP; Intel support may be evaluated later.
- Menu bar launch target: under 500 ms on typical hardware.
- Focus action target: under 100 ms for a typical set of open applications, excluding OS-controlled animation time.
- Minimal idle CPU use and under 20 MB typical resident memory.
- No window closures, resizing, repositioning, or document-state changes.
- All commands are safe to repeat.

## 10. Success Criteria

- A user can enter and exit Solo Focus with one action and recover the original set of Solo-managed applications.
- Smart Restore successfully restores an eligible minimized window after activating its app, without affecting apps that already expose a visible window.
- Permission-denied and unsupported-app flows are understandable and non-crashing.
- No user-reported loss of window state attributable to Solo.

## 11. Future Opportunities

- Per-context profiles (Writing, Development, Meeting).
- Ignore-list presets and per-feature ignore rules.
- Apple Shortcuts and AppleScript actions.
- Focus mode, monitor, and active-app automation.
- Optional animations and configurable menu bar icons.
- A separately validated Command-Tab-only Smart Restore mode.

