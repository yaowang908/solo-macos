## 1. Store and enforcement

- [x] 1.1 Implement the `ExcludedApps` store: UserDefaults-backed set of bundle identifiers with add/remove and a change callback; add the source to the pbxproj (hand-edit per AGENTS.md, validate with `xcodebuild -list`)
- [x] 1.2 Add the exclusion guard to `FocusSession.activate()` (injected store) and unit-test with the existing fakes: excluded app not hidden/not recorded, mid-session exclusion still restored on deactivate
- [x] 1.3 Add the exclusion guard to `SmartRestoreController.handleActivation()` and verify by hand: an excluded app with only minimized windows is not auto-restored
- [x] 1.4 Run the full test suite (`xcodebuild test`) and confirm green

## 2. Status menu submenu

- [x] 2.1 Track the last non-Solo frontmost app from the existing activation observation (no second NSWorkspace subscription) and expose it to the menu layer
- [x] 2.2 Build the Excluded Apps submenu in `StatusItemController` (`menuNeedsUpdate` rebuild): quick-add item (disabled when no candidate), separator, checkmarked entries that un-exclude on click, empty-state placeholder; verify all states by hand

## 3. Settings section

- [x] 3.1 Build the Excluded Apps SwiftUI section in the Settings window (lands after `shortcut-settings`): rows with icon + display name resolved from bundle id, per-row remove, stale entries shown by raw bundle id with generic icon
- [x] 3.2 Implement the add flow: running-apps picker plus NSOpenPanel for non-running apps (read the chosen bundle's identifier); verify both paths and stale-entry removal by hand

## 4. Validation and docs

- [x] 4.1 End-to-end pass: exclude via quick-add, via settings, un-exclude via both surfaces, relaunch persistence, both-feature enforcement, and the mid-session exclusion rule
- [x] 4.2 Update README (feature, menu table) and AGENTS.md if new lessons emerge; sync specs on completion (rebase deltas if `shortcut-settings` hasn't synced yet)
