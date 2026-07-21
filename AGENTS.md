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
- **Use semantic (Conventional Commits) messages**: `<type>: <summary>` with types
  `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`. Optional scope, e.g.
  `fix(smart-restore): accept AXDialog minimized windows`. Body explains the why;
  imperative mood; summary lowercase after the colon.
- **Never launch the raw binary** (`Solo.app/Contents/MacOS/Solo`). Cross-app calls
  like `NSRunningApplication.hide()` silently fail outside a proper LaunchServices
  launch. Always `open Solo.app`.
- **`/Applications/Solo.app` belongs to Homebrew.** Dev builds live in the repo:
  `./scripts/dev.sh` builds Debug into `./build` (gitignored) and opens
  `build/Build/Products/Debug/Solo.app`. Never copy a dev build over the brew
  install. Solo is single-instance (newest launch gracefully terminates other
  running copies), so opening a dev build stops the brew copy automatically — no
  manual pkill needed.
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

## Testing

- Run `xcodebuild test -project Solo.xcodeproj -scheme Solo -destination
  'platform=macOS' -derivedDataPath build` before committing code changes; CI
  (`.github/workflows/ci.yml`) runs the same on every push/PR.
- Tests live in `SoloTests/` (Swift Testing, `import Testing`). The `SoloTests`
  target has **no TEST_HOST**: it compiles the tested sources directly
  (ActivationGuard, FocusSession, RunningAppProviding, WindowInspector, DebugLog),
  so tests never launch the app or trip its permission prompts. If a tested file
  gains a new source-file dependency, add that file to the SoloTests sources phase
  in the pbxproj too.
- Testable-by-design seams: `ActivationGuard` takes an injectable clock;
  `FocusSession` takes a `RunningAppProviding` (fakes in FocusSessionTests);
  `WindowInspector.isRestorable`/`selectIndex` are pure. Keep policy decisions in
  those pure/seamed layers — anything touching live AX or TCC is untestable in CI
  and stays manual (see the regrant-accessibility skill).
- The regression tests encode hard-won platform lessons (hide() returning false,
  AXDialog minimized subroles). If one fails after a "cleanup", the cleanup is
  wrong — see Platform gotchas above.

## Build, diagnostics, project file

- Build + run dev: `./scripts/dev.sh` (or `xcodebuild -project Solo.xcodeproj
  -scheme Solo -configuration Debug -derivedDataPath build build`). SourceKit
  cross-file "Cannot find type" diagnostics in single-file context are noise;
  trust xcodebuild.
- Diagnostics: `DebugLog.write(...)` appends to `/tmp/solo-debug.log` in Debug
  builds only (`#if DEBUG`); it compiles to a no-op in Release. Use it instead of
  `NSLog`/unified logging — those proved unreliable to capture here.
- `Solo.xcodeproj/project.pbxproj` is maintained **by hand** (no Xcode GUI, no
  xcodegen). After editing it, validate with `xcodebuild -project Solo.xcodeproj
  -list` before building. Bracketed build-setting keys (e.g.
  `KEY[sdk=macosx*]`) break the parser unless quoted.

## Releases

- Publishing a release = pushing a semantic tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
  `.github/workflows/release.yml` then builds Release on a macOS runner, zips
  `Solo.app`, and publishes a GitHub Release with generated notes. Only tag when
  the user asks for a release.
- Before tagging, bump `MARKETING_VERSION` in the pbxproj (both configurations) to
  match the tag, and make sure `README.md` reflects any behavior changes.
- Release builds stay **ad-hoc signed and un-notarized** (see signing rule above);
  the README documents the `xattr -cr` quarantine-clearing step for users.
- **Homebrew tap**: `github.com/yaowang908/homebrew-tap` hosts `Casks/solo.rb`
  (install: `brew install --cask --no-quarantine yaowang908/tap/solo`). Cask
  updates are fully automated, two layers:
  1. **Instant**: the release workflow's "Update Homebrew tap" step bumps
     version + sha256 and pushes to the tap, authenticated by the
     `TAP_GITHUB_TOKEN` secret (fine-grained PAT, Contents read/write on
     homebrew-tap only). If that step starts failing while the release itself
     succeeds, the PAT has likely expired — ask the user to rotate it and
     re-run `gh secret set TAP_GITHUB_TOKEN -R yaowang908/solo-macos`.
  2. **Backstop**: the tap's own `update-cask.yml` (daily cron + manual
     dispatch) self-heals from the latest release with no cross-repo token.
  After a release, verify with `brew fetch --cask yaowang908/tap/solo`.
