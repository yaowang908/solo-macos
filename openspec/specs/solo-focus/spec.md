# solo-focus Specification

## Purpose

Hide-others session semantics for Solo Focus: eligibility rules, an exact session record of what Solo hid, idempotent restore of only that set, and correct handling of apps that quit or are manually unhidden mid-session. Works without Accessibility permission.

## Requirements

### Requirement: Activating Solo Focus hides other applications
When Solo Focus is activated while inactive, Solo SHALL determine the frontmost application, keep it untouched, and hide every other eligible application using `NSRunningApplication.hide()`. Solo MUST record exactly the set of applications it hid in this activation (the session record). If no eligible application exists to hide, Solo MUST NOT start a session: no state changes and the icon stays inactive. Solo Focus MUST NOT require Accessibility permission.

#### Scenario: Focus hides everything except the current app
- **WHEN** the user activates Solo Focus with app A frontmost and apps B and C visible
- **THEN** B and C are hidden, A remains exactly as it was, and the session record contains B and C

#### Scenario: Works without Accessibility permission
- **WHEN** Accessibility permission has not been granted and the user activates Solo Focus
- **THEN** the hide and subsequent restore behave identically to the permission-granted case

#### Scenario: Nothing to hide starts no session
- **WHEN** the user activates Solo Focus and every other app is ineligible (background, already hidden, or excluded)
- **THEN** no session starts, the icon stays inactive, and a later activation behaves as a fresh attempt

### Requirement: Eligibility exclusions
Solo Focus SHALL NOT hide: Solo itself, applications that are already hidden, background applications with no user-facing windows (activation policy other than `.regular`), and applications on the Excluded Apps list. The Excluded Apps list SHALL be consulted at activation time only; the session record and deactivation behavior are unaffected by list edits made during a session.

#### Scenario: Already-hidden apps stay out of the session
- **WHEN** app D was hidden by the user (`Command+H`) before Solo Focus is activated
- **THEN** D is not added to the session record and is not unhidden when the session ends

#### Scenario: Background apps are ignored
- **WHEN** menu-bar-only or background agents are running during activation
- **THEN** Solo does not attempt to hide them

#### Scenario: Excluded apps stay visible
- **WHEN** app E is on the Excluded Apps list and the user activates Solo Focus
- **THEN** E is not hidden and is not added to the session record

#### Scenario: Mid-session exclusion does not affect restore
- **WHEN** a session recorded app B before B was added to the Excluded Apps list, and the user deactivates Solo Focus
- **THEN** B is unhidden normally; the exclusion applies from the next activation

### Requirement: Deactivating Solo Focus restores only Solo-hidden apps
When Solo Focus is deactivated, Solo SHALL unhide only the applications in the session record that are still running, then clear the session record and mark Solo Focus inactive. Minimized windows of restored applications MUST remain minimized.

#### Scenario: Round trip restores the original set
- **WHEN** the user deactivates Solo Focus after a session that hid B and C
- **THEN** B and C are unhidden, the session record is cleared, and the icon returns to inactive

#### Scenario: App quit during session
- **WHEN** app B quits while a session that recorded B is active, and the user then deactivates Solo Focus
- **THEN** Solo skips B without error and restores the remaining recorded apps

#### Scenario: Manual unhide during session is respected
- **WHEN** the user manually unhides app C mid-session and then deactivates Solo Focus
- **THEN** C's state is not toggled back; restore is idempotent for already-visible apps

### Requirement: Partial restore prunes the session
Solo SHALL support restoring a single session-hidden application without ending the session. A partial restore MUST unhide that application, activate it (bring it frontmost), remove it from the session record, and leave the remaining recorded apps hidden. Because the menu choice is explicit user intent, when Smart Restore is operational and the restored application has no visible normal window but has minimized ones, Solo SHALL restore one window per the smart-restore selection priority via a direct call (not subject to self-caused-activation suppression). When the last recorded application is restored individually, the session SHALL end exactly as a full restore would (record cleared, Solo Focus inactive). Partial restores MUST be treated as Solo-initiated operations for activation suppression.

#### Scenario: Restore one app mid-session
- **WHEN** a session hides A, B, and C and the user restores B individually
- **THEN** B is unhidden and leaves the session record, A and C stay hidden, and the session remains active

#### Scenario: Restored app is no longer session-ignored
- **WHEN** app B has been individually restored from a session
- **THEN** Smart Restore treats B like any other app again (it is no longer in the session record)

#### Scenario: Restoring the last app ends the session
- **WHEN** only app C remains in the session record and the user restores it individually
- **THEN** the session ends: the record is cleared and the status icon returns to inactive

#### Scenario: Restoring a minimized-only app shows a window
- **WHEN** Smart Restore is operational and the user restores an app from the submenu while all of that app's windows are minimized
- **THEN** the app is activated and one window is un-minimized per the smart-restore selection priority

#### Scenario: Without Accessibility the restore still activates the app
- **WHEN** Accessibility permission is not granted and the user restores a minimized-only app from the submenu
- **THEN** the app is unhidden and activated; its windows stay minimized (recoverable via the Dock)

#### Scenario: Restoring a quit app is a silent no-op
- **WHEN** a recorded app has quit and the user clicks its restore entry
- **THEN** the entry is removed from the record without error and no other state changes

### Requirement: Repeat activation is safe
Toggling Solo Focus repeatedly SHALL be safe: activating while already active toggles the session off, and all operations MUST be repeatable without accumulating state or errors.

#### Scenario: Double toggle returns to baseline
- **WHEN** the user toggles Solo Focus on and then off with no other changes
- **THEN** the set of visible applications is identical to the pre-toggle state
