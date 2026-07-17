## ADDED Requirements

### Requirement: Activating Solo Focus hides other applications
When Solo Focus is activated while inactive, Solo SHALL determine the frontmost application, keep it untouched, and hide every other eligible application using `NSRunningApplication.hide()`. Solo MUST record exactly the set of applications it hid in this activation (the session record). Solo Focus MUST NOT require Accessibility permission.

#### Scenario: Focus hides everything except the current app
- **WHEN** the user activates Solo Focus with app A frontmost and apps B and C visible
- **THEN** B and C are hidden, A remains exactly as it was, and the session record contains B and C

#### Scenario: Works without Accessibility permission
- **WHEN** Accessibility permission has not been granted and the user activates Solo Focus
- **THEN** the hide and subsequent restore behave identically to the permission-granted case

### Requirement: Eligibility exclusions
Solo Focus SHALL NOT hide: Solo itself, applications that are already hidden, and background applications with no user-facing windows (activation policy other than `.regular`).

#### Scenario: Already-hidden apps stay out of the session
- **WHEN** app D was hidden by the user (`Command+H`) before Solo Focus is activated
- **THEN** D is not added to the session record and is not unhidden when the session ends

#### Scenario: Background apps are ignored
- **WHEN** menu-bar-only or background agents are running during activation
- **THEN** Solo does not attempt to hide them

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

### Requirement: Repeat activation is safe
Toggling Solo Focus repeatedly SHALL be safe: activating while already active toggles the session off, and all operations MUST be repeatable without accumulating state or errors.

#### Scenario: Double toggle returns to baseline
- **WHEN** the user toggles Solo Focus on and then off with no other changes
- **THEN** the set of visible applications is identical to the pre-toggle state
