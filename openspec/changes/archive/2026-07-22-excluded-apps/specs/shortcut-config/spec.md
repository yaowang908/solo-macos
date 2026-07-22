## MODIFIED Requirements

### Requirement: Settings window
Solo SHALL provide a Settings window, opened from the status item menu, containing the Toggle Solo Focus shortcut recorder and the Excluded Apps section (per the excluded-apps capability). Opening it MUST bring the window to the front and give it key focus even though Solo is an agent-style app. Reopening while already open MUST front the existing window rather than creating another.

_Note: this delta modifies the Settings window requirement introduced by the `shortcut-settings` change, which must be applied and synced first._

#### Scenario: Open from the menu
- **WHEN** the user chooses Settings… from the status item menu
- **THEN** the Settings window appears frontmost with key focus and shows the shortcut recorder and the Excluded Apps section

#### Scenario: Reopen fronts the same window
- **WHEN** the Settings window is already open and the user chooses Settings… again
- **THEN** the existing window comes to the front and no second window is created
