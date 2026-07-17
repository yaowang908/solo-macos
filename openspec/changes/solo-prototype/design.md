## Context

Greenfield: only the PRD exists. The prototype must prove two behaviors on real macOS — hide-others with exact-set restore (Solo Focus) and un-minimize-on-activation (Smart Restore) — plus their interaction. Constraints: macOS 14+, Apple Silicon, Swift/AppKit, unsigned local builds, no sandbox (Accessibility control is incompatible with sandboxing), no network/telemetry.

## Goals / Non-Goals

**Goals:**
- A runnable app the developer can use daily to validate feel and reliability.
- Exercise the risky machinery end-to-end: AX window inspection/de-minimization, activation observation, self-caused-event suppression, live permission-grant detection.
- Keep boundaries clean enough that settings/ignore-list/etc. can be added later without restructuring.

**Non-Goals:**
- Settings UI, configurable shortcut, ignore list, launch-at-login, distribution, focus-history window tracking (see proposal Non-goals).

## Decisions

### D1: Project layout — Xcode app target, small single-responsibility types
One app target, no framework split. Suggested source layout:

```
Solo/
├── SoloApp.swift            // @main NSApplicationDelegate wiring, LSUIElement
├── StatusItemController.swift  // NSStatusItem, menu, icon state
├── FocusSession.swift       // Solo Focus state machine + session record
├── SmartRestoreController.swift // activation observer + restore policy
├── WindowInspector.swift    // AX wrappers: visible/minimized windows, de-minimize
├── PermissionMonitor.swift  // AXIsProcessTrusted polling + explainer trigger
└── ActivationGuard.swift    // suppression window for self-caused activations
```

Agent behavior via `LSUIElement = YES` in Info.plist (no `NSApp.setActivationPolicy` juggling needed for the prototype).

### D2: Solo Focus uses NSWorkspace/NSRunningApplication only — no AX
`NSWorkspace.shared.runningApplications` filtered to `activationPolicy == .regular`, not `isHidden`, not Solo, not frontmost → call `hide()` on each; store `[pid_t]` (plus bundle id for logging) as the session record. Restore = `unhide()` for still-running recorded pids. Rationale: zero permissions, atomic per-app, macOS animates it natively. Alternative rejected: AX-based per-window hiding — more power than needed, drags the permission requirement into the feature that was chosen specifically to avoid it.

Session record is in-memory only. If Solo crashes mid-session, hidden apps remain hidden but are recoverable by the user (Dock/Cmd+Tab) — acceptable for a prototype.

### D3: Smart Restore visibility check — CGWindowList first, AX second
Deciding "does this app have a visible normal window on the current Space?" uses `CGWindowListCopyWindowInfo(.optionOnScreenOnly)` filtered by owner pid, layer 0, and reasonable size — no permission needed for bounds/pid (window *names* would need Screen Recording; we never read names). Enumerating and restoring minimized windows then uses AX: `AXUIElementCreateApplication(pid)` → `kAXWindowsAttribute` → windows with `kAXMinimizedAttribute == true` and `kAXSubroleAttribute == kAXStandardWindowSubrole`. Restore = set `AXMinimized = false`, then `kAXRaiseAction` and re-activate the app.

Rationale: CGWindowList is cheap and Space-aware for the "do nothing" fast path (the common case); AX is only touched when a restore is actually plausible. Alternative rejected: AX-only — cannot tell current-Space visibility reliably and touches every activation.

Selection priority maps to: `kAXMainAttribute == true` among minimized windows → largest by AX size → first eligible.

### D4: Activation observation and the suppression guard
Subscribe to `NSWorkspace.didActivateApplicationNotification`. The guard is a short suppression window: when Solo initiates hide/unhide/raise operations, `ActivationGuard` records "self-operation in flight" and ignores activation events until a quiet period (~500 ms after the last Solo-initiated call) elapses. Also unconditionally ignore activations of Solo itself and any app currently in the Focus session record.

Rationale: macOS provides no causality on activation events, so time-based suppression is the honest tool. The window is short enough that a real user activation half a second later still works. Alternative rejected: diffing expected-vs-actual activation sequences — brittle, no better guarantees.

### D5: Permission detection — poll `AXIsProcessTrusted()`
`AXIsProcessTrustedWithOptions` without the system prompt for checks; Solo's own explainer (an alert or lightweight window) fronts the ask and deep-links via `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`. While Smart Restore is enabled but untrusted, poll `AXIsProcessTrusted()` every ~2 s; stop polling once granted or when the feature is toggled off. Rationale: there is no notification API for TCC grants; low-frequency polling is the standard, cheap approach. `kAXTrustedCheckOptionPrompt` is avoided so the system prompt never appears for Solo Focus-only users.

### D6: Hotkey — KeyboardShortcuts package with a hardcoded default
Register `KeyboardShortcuts.Name("toggleSoloFocus")` with default `⌃⌥⌘S`; no recorder UI. Rationale: gets reliable global registration on modern macOS for one dependency; the recorder UI comes free later when a settings window exists. Alternative rejected for prototype: Carbon `RegisterEventHotKey` by hand — works, but is throwaway fiddly code.

### D7: State model
Two independent pieces of state, both owned on the main actor:
- `FocusSession?` — nil when inactive; non-nil holds the hidden-pid set.
- `smartRestoreEnabled: Bool` (UserDefaults-backed) + derived `operational = enabled && trusted`.

Menu and icon render purely from these. No persistence of the focus session (D2).

## Risks / Trade-offs

- [Time-based suppression misses or over-suppresses] → 500 ms window tuned during prototyping; log every suppressed event in debug builds to verify it only fires around Solo-initiated operations.
- [Dock's own un-minimize races with Smart Restore on Dock clicks] → visibility check runs at event time; if the Dock already restored a window, the fast path sees a visible window and no-ops. Residual double-restore risk is cosmetic.
- [AX attributes vary across apps (Electron, Java, Catalyst)] → treat every AX read/write as fallible; any nil/error → no-op for that activation. Test against Finder, Safari, VS Code (Electron), and a Catalyst app early.
- [CGWindowList visibility heuristics misclassify odd windows (small panels at layer 0)] → size floor + standard-subrole cross-check via AX before deciding to restore; when unsure, do nothing (PRD demands no-op on ambiguity).
- [Unsigned build loses Accessibility trust on every rebuild] → known macOS behavior (TCC keys off code signature); mitigate during development with ad-hoc signing and a stable signing identity, or re-grant after rebuilds. Annoying but prototype-acceptable.

## Open Questions

- Does `hide()` on many apps in a tight loop cause visible focus flicker, and does the activation burst stay inside the 500 ms guard on slower machines? (Measure in task 1 of Smart Restore integration.)
- Minimum window size floor for "real window" in the CGWindowList check — start at 100×50 and adjust empirically.
