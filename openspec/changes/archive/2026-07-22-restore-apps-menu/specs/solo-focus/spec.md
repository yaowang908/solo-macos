## ADDED Requirements

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

## MODIFIED Requirements

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
