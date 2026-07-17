## Why

Solo currently exists only as a PRD ([Solo-PRD.md](../../../Solo-PRD.md)) — there is no code. Before investing in settings UI, distribution, and polish, we need a minimal working prototype that proves the two core behaviors (Solo Focus and Smart Restore) feel native, immediate, and reversible on real macOS, and that validates the riskiest technical bets: Accessibility-based window de-minimization and the interaction between the two features.

## What Changes

- Create the Xcode project: a Swift/AppKit agent-style app (menu bar icon, no Dock icon, no main window), macOS 14+, Apple Silicon, local unsigned builds.
- Add a menu bar item whose icon reflects Solo Focus state, with menu actions: Toggle Solo Focus, Restore Windows, Smart Restore on/off, Quit.
- Implement **Solo Focus**: hide all other eligible apps via `NSRunningApplication.hide()`, record exactly which apps Solo hid, and unhide only those on toggle-off. Works without any permissions.
- Implement a global hotkey (default `⌃⌥⌘S`) via the KeyboardShortcuts package, hardcoded default only (no recorder UI yet).
- Implement **Smart Restore**: observe app activation; when an activated app has no visible normal windows but has minimized ones, un-minimize one (main window → largest → any) via `AXUIElement` and focus it.
- Implement the **Accessibility permission flow** scoped to Smart Restore: explain the need, deep-link to System Settings, detect grant without relaunch, and degrade gracefully (Smart Restore off, Solo Focus unaffected) when denied.
- Implement the **feature interaction guard**: Smart Restore ignores activation events caused by Solo's own hide/unhide operations.

## Capabilities

### New Capabilities

- `menu-bar-app`: Agent-style app lifecycle, status item with state-reflecting icon, and the prototype menu (toggle, restore, smart-restore switch, quit).
- `solo-focus`: Hide-others session semantics — eligibility, session recording, idempotent restore, handling of apps that quit or are manually unhidden mid-session.
- `smart-restore`: Activation observation, visible-window detection, minimized-window selection priority, AX-based restore-and-focus, and the self-caused-activation suppression guard.
- `accessibility-permission`: Feature-scoped permission onboarding, live grant detection, and graceful degradation when not granted.

### Modified Capabilities

_None — this is the first change; no existing specs._

## Impact

- New Xcode project and Swift sources at the repo root (currently empty of code).
- New SPM dependency: `sindresorhus/KeyboardShortcuts`.
- Requires Accessibility permission at runtime for Smart Restore only; no sandbox, no network, no telemetry.
- No existing code or users affected.

## Non-goals

- Settings window, configurable shortcut recorder, conflict warnings.
- Ignored Applications list, Launch at Login, "restore on quit" preference.
- Focus-history tracking for window selection (per-app AX observers) — deferred; prototype uses main → largest → any.
- Signing, notarization, Homebrew tap, GitHub releases, update mechanism.
- Multi-Space/multi-display guarantees beyond safe no-ops; full-screen app handling beyond skipping them.
- App icon, About window, onboarding polish beyond the permission explainer.
