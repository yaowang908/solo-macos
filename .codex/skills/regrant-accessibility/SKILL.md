---
name: regrant-accessibility
description: Fix Smart Restore silently not working after a rebuild — reset stale Accessibility (TCC) grants and re-grant the dev build. Use when Smart Restore is inert, AXIsProcessTrusted() returns false despite the user having granted access, or after any rebuild of Solo.app.
---

# Re-grant Accessibility After Rebuild

## Symptom

Smart Restore stops working (activations do nothing), while Solo Focus still works.
Diagnostics show `trusted=false` on every activation even though System Settings →
Privacy & Security → Accessibility shows a "Solo" entry toggled ON.

## Root cause

Solo is signed **ad-hoc** (`CODE_SIGN_IDENTITY = "-"`). A macOS TCC (Accessibility)
grant is bound to the binary's code signature (cdhash). Every rebuild produces a new
cdhash, so the existing grant silently stops matching the new binary. The Settings
pane still shows the old entry toggled ON — it just points at a dead build. Toggling
it off/on does NOT fix it; the entry must be removed and re-added.

This recurs after **every rebuild**. Only the dev copy is affected: the Homebrew
release copy in `/Applications/Solo.app` keeps its own grant untouched.

## Dev vs release copies

- `/Applications/Solo.app` belongs to **Homebrew** (release build). Never overwrite
  it with a dev build.
- The dev build lives in the repo: `./scripts/dev.sh` builds Debug into `./build`
  and opens `build/Build/Products/Debug/Solo.app`. Solo enforces single-instance:
  the newly launched copy gracefully terminates any other running copy, so opening
  the dev build automatically stops the brew copy (and vice versa).
- Each copy gets its own Accessibility entry; two "Solo" rows in Settings is normal.

## Fix (repeat after each dev rebuild)

1. Clear stale grants (there may be several; the reset also removes the brew
   copy's grant, which the user must then re-add if they use it):

   ```bash
   tccutil reset Accessibility com.solo.Solo
   ```

   To keep the brew copy's grant intact, skip the reset and instead remove only
   the dev entry manually in System Settings (select it, press −).

2. Launch the fresh dev build (it stops any running copy itself):

   ```bash
   ./scripts/dev.sh
   ```

3. Have the user grant fresh (agents cannot do this step):
   - System Settings → Privacy & Security → Accessibility
   - Click **+**, press **⌘⇧G**, paste `<repo>/build/Build/Products/Debug/Solo.app`,
     add it, toggle **ON**.
   - Solo polls `AXIsProcessTrusted()` every ~2 s, so Smart Restore goes live
     within seconds — no relaunch needed.

4. Verify: switch to an app whose only window is minimized; the window should
   restore. Debug builds log to `/tmp/solo-debug.log` — check for `trusted=true`
   and `restore attempted, result=true`.

## Notes

- `tccutil reset Accessibility com.solo.Solo` is the supported way to clear the
  entries; it needs no Full Disk Access and may report success once per stale entry.
- Do not diagnose by launching the raw binary
  (`Solo.app/Contents/MacOS/Solo`) — cross-app calls like
  `NSRunningApplication.hide()` misbehave outside a proper LaunchServices launch.
  Always use `open`.
- Permanent fix would be a stable signing identity, but the user has chosen
  ad-hoc-only signing (no personal identity in build products); this re-grant flow
  is the accepted cost of each dev rebuild.
