# Solo

Solo is a lightweight macOS menu bar utility that helps you focus on one thing at a time — and quickly recover minimized windows when you come back to an app.

It lives entirely in the menu bar: no Dock icon, no windows, negligible resource use.

## What it does

### 🌙 Solo Focus — hide everything else

One shortcut (`⌃⌥⌘S`) or one menu click hides every other app, leaving only the app you're working in. Toggle again and **exactly** the apps Solo hid come back — nothing more, nothing less:

- Apps you had already hidden yourself (`⌘H`) stay hidden.
- Apps you manually unhide mid-session aren't touched on restore.
- Apps that quit during the session are skipped silently.
- Minimized windows stay minimized through the round trip.
- Quitting Solo mid-session restores the hidden apps first.

Solo Focus needs **no permissions** — it uses only standard macOS app hiding, which the system animates natively.

### 🪟 Smart Restore — un-minimize on switch

macOS has a long-standing annoyance: `⌘Tab` to an app whose windows are all minimized, and… nothing appears. With Smart Restore on, Solo notices the switch and restores one window for you — raised and focused.

- If the app already has a visible window, Solo does nothing.
- If the app has no windows at all, Solo does nothing (it never creates windows).
- Apps hidden with `⌘H` are left alone.
- When several windows are minimized, Solo picks the main window, else the largest.
- Works with nonstandard apps (Outlook, Notes, Electron apps like VS Code).

Smart Restore requires macOS **Accessibility** permission (it's the API for reading and un-minimizing other apps' windows). Solo asks only when Smart Restore needs it, explains why, and deep-links to the right Settings pane. Decline and Smart Restore simply switches off — Solo Focus is unaffected. Grant it later and it goes live within seconds, no relaunch needed.

## The menu

| Item | What it does |
| --- | --- |
| **Toggle Solo Focus** | Enter/exit focus (same as `⌃⌥⌘S`) |
| **Restore Windows** | Exit focus explicitly (enabled only during a session) |
| **Smart Restore Minimized Windows** | On/off checkbox; notes when permission is missing |
| **Quit Solo** | Quits (restoring any hidden apps first). Deliberately has no ⌘Q shortcut |

The menu bar icon shows a filled moon while Solo Focus is active.

## Known limitations

- **`⌘Tab` back to the app you're already in does nothing.** If you minimize a window and the app *stays active* (its name still in the menu bar), re-selecting it with `⌘Tab` produces no system event at all, so Solo cannot react. This is a macOS platform constraint on activation-based observation, not a bug. **Workaround:** click the app's Dock icon (macOS restores the window natively), or switch to another app and back.
- **Rebuilding invalidates the Accessibility grant.** Local builds are ad-hoc signed, and macOS ties the permission to the exact binary. After every rebuild the grant must be redone — see the `regrant-accessibility` skill (`.codex/skills/regrant-accessibility/SKILL.md`) for the exact steps.
- **The focus session lives in memory.** If Solo crashes mid-session, hidden apps stay hidden (recover them via Dock or `⌘Tab`).
- **Prototype scope:** no settings window, no shortcut recorder, no ignore list, no launch-at-login, unsigned local builds only.

## Building and running

Requirements: macOS 14+, Apple Silicon, Xcode 16.

```bash
xcodebuild -project Solo.xcodeproj -scheme Solo -configuration Debug build
```

Install the built app to a stable path and launch it from there (important for the Accessibility grant):

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/Solo-*/Build/Products/Debug/Solo.app /Applications/
open /Applications/Solo.app
```

Debug builds write diagnostics to `/tmp/solo-debug.log`; Release builds log nothing.

## Project layout

Specs and design live under `openspec/` (source of truth in `openspec/specs/`). The Swift sources are small single-responsibility types under `Solo/` — `FocusSession` (Solo Focus), `SmartRestoreController` + `WindowInspector` (Smart Restore), `PermissionMonitor` (Accessibility flow), `ActivationGuard` (suppresses Solo's own activation side effects), `StatusItemController` (menu bar UI).
