---
name: regrant-accessibility
description: Fix Smart Restore silently not working after a rebuild — reset stale Accessibility (TCC) grants and re-grant against a stable install path. Use when Smart Restore is inert, AXIsProcessTrusted() returns false despite the user having granted access, or after any rebuild of Solo.app.
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

This will recur after **every rebuild** until the project signs with a stable
identity (e.g. an Apple Development certificate), which requires an Xcode account
to be configured.

## Fix (repeat after each rebuild)

1. Quit Solo and wipe all stale grants (there may be several):

   ```bash
   pkill -x Solo
   tccutil reset Accessibility com.solo.Solo
   ```

2. Install the fresh build to a stable path and launch it from there:

   ```bash
   rm -rf /Applications/Solo.app
   cp -R "$(xcodebuild -project Solo.xcodeproj -scheme Solo -configuration Debug -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR/{print $3}')/Solo.app" /Applications/Solo.app
   open /Applications/Solo.app
   ```

3. Have the user grant fresh (agents cannot do this step):
   - System Settings → Privacy & Security → Accessibility
   - Solo should be absent (the reset removed it). Click **+**, press **⌘⇧G**,
     enter `/Applications/Solo.app`, add it, toggle **ON**.
   - Solo polls `AXIsProcessTrusted()` every ~2 s, so Smart Restore goes live
     within seconds — no relaunch needed.

4. Verify: switch to an app whose only window is minimized; the window should
   restore. (If debug logging is compiled in, check `/tmp/solo-debug.log` for
   `trusted=true` and `restore attempted, result=true`.)

## Notes

- `tccutil reset Accessibility com.solo.Solo` is the supported way to clear the
  entries; it needs no Full Disk Access and may report success once per stale entry.
- Do not diagnose by launching the raw binary
  (`Solo.app/Contents/MacOS/Solo`) — cross-app calls like
  `NSRunningApplication.hide()` misbehave outside a proper LaunchServices launch.
  Always use `open`.
- Permanent fix: switch `CODE_SIGN_STYLE`/`CODE_SIGN_IDENTITY` to a stable signing
  identity once an Xcode account for the team is signed in (Settings → Accounts).
  Until then, this re-grant flow is the cost of every rebuild.
