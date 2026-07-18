# AGENTS.md — rules for coding agents working on Solo

Solo is a macOS menu bar utility (Swift/AppKit, macOS 14+, Apple Silicon). Read
`README.md` for what the app does. This file is about how to work on it safely.

## Source of truth and docs to maintain

- **Specs**: `openspec/specs/` is the behavioral source of truth. Work flows through
  the OpenSpec skills (propose → apply → sync → archive); completed changes live in
  `openspec/changes/archive/`. If implementation diverges from a spec, update the
  spec in the same session — never leave them contradicting each other.
- **README.md**: human-facing. Update it whenever a feature, menu item, shortcut,
  permission behavior, or limitation changes.
- **AGENTS.md** (this file): update it when a new rule, gotcha, or workflow lesson
  is learned the hard way.

## Hard rules

- **Signing: ad-hoc only (`CODE_SIGN_IDENTITY = "-"`).** The user explicitly
  declined signing with their personal Apple Development certificate. Do not embed
  their identity in build products or change signing settings.
- **Commit only when the user asks.** Keep the tree clean and report what is
  uncommitted; don't commit proactively.
- **Never launch the raw binary** (`Solo.app/Contents/MacOS/Solo`). Cross-app calls
  like `NSRunningApplication.hide()` silently fail outside a proper LaunchServices
  launch. Always `open Solo.app`, and install/run from `/Applications/Solo.app`.
- **Agents cannot grant Accessibility or verify UI behavior.** The human must click
  the Settings toggle and confirm hide/restore behavior on screen. Instrument, hand
  over a short test script, and read the logs afterward.

## The rebuild → permission treadmill

Every rebuild changes the ad-hoc cdhash, which **silently invalidates the
Accessibility (TCC) grant** — Smart Restore goes inert with `trusted=false` while
System Settings still shows a stale entry toggled ON. After each rebuild that needs
Smart Restore testing, follow `.codex/skills/regrant-accessibility/SKILL.md`:
`tccutil reset Accessibility com.solo.Solo`, copy the fresh build to
`/Applications/Solo.app`, `open` it, then have the user re-add it in
Privacy & Security → Accessibility. Batch code changes to minimize rebuilds.

## Platform gotchas (all verified live on this machine, macOS 26)

- `NSRunningApplication.hide()` **can hide the app yet return `false`**. Record the
  Solo Focus session by intent (every app hide was *requested* for), never gate on
  the return value.
- `isHidden` can read stale right after Solo's own `hide()`. Call `unhide()`
  unconditionally on restore — it's idempotent and only ever unhides.
- Minimized windows of some apps (Outlook, Notes) report `subrole = AXDialog`, not
  `AXStandardWindow`. Window eligibility is a **blocklist** (exclude system
  dialogs/floating panels + size floor), not a subrole allowlist. Don't "fix" it
  back.
- `⌘Tab` to the already-active app emits **no system event at all**. Smart Restore
  cannot react to it; this is a documented spec limitation (see
  `openspec/specs/smart-restore/spec.md`), not a bug to chase.
- Treat every AX read/write as fallible; any failure is a silent no-op for that
  activation.

## Build, diagnostics, project file

- Build: `xcodebuild -project Solo.xcodeproj -scheme Solo -configuration Debug build`
  (SourceKit cross-file "Cannot find type" diagnostics in single-file context are
  noise; trust xcodebuild).
- Diagnostics: `DebugLog.write(...)` appends to `/tmp/solo-debug.log` in Debug
  builds only (`#if DEBUG`); it compiles to a no-op in Release. Use it instead of
  `NSLog`/unified logging — those proved unreliable to capture here.
- `Solo.xcodeproj/project.pbxproj` is maintained **by hand** (no Xcode GUI, no
  xcodegen). After editing it, validate with `xcodebuild -project Solo.xcodeproj
  -list` before building. Bracketed build-setting keys (e.g.
  `KEY[sdk=macosx*]`) break the parser unless quoted.
