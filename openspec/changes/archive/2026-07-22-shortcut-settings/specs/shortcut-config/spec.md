## ADDED Requirements

### Requirement: Settings window
Solo SHALL provide a Settings window, opened from the status item menu, containing the Toggle Solo Focus shortcut recorder. Opening it MUST bring the window to the front and give it key focus even though Solo is an agent-style app. Reopening while already open MUST front the existing window rather than creating another.

#### Scenario: Open from the menu
- **WHEN** the user chooses Settings… from the status item menu
- **THEN** the Settings window appears frontmost with key focus and shows the shortcut recorder

#### Scenario: Reopen fronts the same window
- **WHEN** the Settings window is already open and the user chooses Settings… again
- **THEN** the existing window comes to the front and no second window is created

### Requirement: Rebinding the Toggle Solo Focus shortcut
The Settings window SHALL let the user record a new keyboard shortcut for Toggle Solo Focus. A newly recorded shortcut MUST take effect immediately (no relaunch) and MUST persist across app relaunches.

#### Scenario: Recorded shortcut works immediately
- **WHEN** the user records a new combination in the recorder
- **THEN** pressing the new combination toggles Solo Focus from any app, and the previous combination no longer does

#### Scenario: Shortcut survives relaunch
- **WHEN** the user records a custom shortcut and relaunches Solo
- **THEN** the custom shortcut still toggles Solo Focus

### Requirement: Detectable conflicts are warned
While recording, Solo SHALL warn about combinations already used by macOS system shortcuts or by Solo's own menus, and MUST NOT require any additional permission to do so. Conflicts with other applications' global hotkeys are explicitly out of detection scope; the Settings window SHALL display guidance telling the user that an unresponsive shortcut may be owned by another app and to record a different one.

#### Scenario: System shortcut is rejected with a warning
- **WHEN** the user attempts to record a combination reserved by a macOS system shortcut
- **THEN** the recorder warns about the conflict and the combination is not saved

#### Scenario: Undetectable-conflict guidance is visible
- **WHEN** the user views the shortcut setting
- **THEN** guidance is visible explaining that an unresponsive shortcut may be in use by another app and a different combination should be recorded

### Requirement: Cleared state means no shortcut
Clearing the recorder SHALL disable the global shortcut entirely: no combination toggles Solo Focus and the menu toggle remains the only trigger. The cleared state MUST persist across relaunches (it is distinct from "never customized", which uses the default). While cleared, the empty recorder MUST communicate the default combination (`⌃⌥⌘S`) as a hint of what can be re-recorded, without implying it is active.

#### Scenario: Clearing disables the hotkey
- **WHEN** the user clears the recorder
- **THEN** pressing the previous combination (and the default) does nothing, while the menu Toggle Solo Focus still works

#### Scenario: Cleared state survives relaunch
- **WHEN** the user clears the shortcut and relaunches Solo
- **THEN** no global shortcut is registered and the recorder still shows the cleared state with the default hint

#### Scenario: Default hint shown while cleared
- **WHEN** the recorder is empty because the user cleared it
- **THEN** the default combination is displayed as a hint (e.g. grayed placeholder or caption), clearly not presented as the active shortcut
