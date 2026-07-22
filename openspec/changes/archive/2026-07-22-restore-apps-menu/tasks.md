## 1. Session semantics

- [x] 1.1 Implement `FocusSession.restore(pid:)`: activation-guard bracketed unconditional unhide, prune from the record, no-op for unknown pids, auto-end (record nil + state change) when the record empties
- [x] 1.2 Implement the nothing-to-hide rule: `activate()` that records zero apps does not start a session (no state flip)
- [x] 1.3 Unit-test both with the existing fakes: partial restore keeps others hidden, pruned app leaves `sessionPids`, last-app restore ends the session, quit-app restore is a silent no-op, empty activation starts no session; run the full suite green

## 2. Menu

- [x] 2.1 Rename Restore Windows to **Restore Apps** and build the submenu in `menuNeedsUpdate`: Restore All, separator, one entry per recorded app (display name + icon from bundle id, bundle-id fallback), disabled item when no session; wire entries to `restore(pid:)` and Restore All to `deactivate()`
- [x] 2.2 Verify by hand: submenu contents during a session, entry click restores only that app and shrinks the list, last-entry click flips the icon inactive, Restore All still works, and toggling Solo Focus with nothing eligible to hide leaves the icon inactive

## 3. Validation and docs

- [x] 3.1 Verify the feature interaction: a partially-restored app becomes Smart Restore-eligible again (activate it with only minimized windows → restore fires)
- [x] 3.2 Update README (menu table, feature description) and sync specs on completion (rebase the menu delta if earlier queued changes have not synced yet)
