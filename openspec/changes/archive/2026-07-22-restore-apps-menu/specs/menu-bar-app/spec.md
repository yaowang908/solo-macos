## MODIFIED Requirements

### Requirement: Status item menu
The status item SHALL expose a menu containing, in order: **Toggle Solo Focus**, **Restore Apps** (submenu), **Smart Restore Minimized Windows** (checkable), **Excluded Apps** (submenu per the excluded-apps capability), **Settings…**, and **Quit Solo**. **Restore Apps** MUST be disabled when no Solo Focus session is active. While a session is active, its submenu SHALL contain, in order: **Restore All**, then one entry per session-recorded application (display name and icon where resolvable, bundle identifier as fallback); choosing an entry performs a partial restore of that app per the solo-focus capability, and **Restore All** ends the session restoring all recorded apps. **Settings…** SHALL open the Settings window.

_Note: this delta assumes the `shortcut-settings` and `excluded-apps` changes have been applied and synced first; it renames the former **Restore Windows** item._

#### Scenario: Menu contents when idle
- **WHEN** the user opens the status item menu and no Solo Focus session is active
- **THEN** the menu shows Toggle Solo Focus, Restore Apps (disabled), Smart Restore Minimized Windows with a checkmark reflecting its enabled state, Excluded Apps, Settings…, and Quit Solo

#### Scenario: Submenu lists the hidden apps during a session
- **WHEN** a session is hiding apps B and C and the user opens the Restore Apps submenu
- **THEN** it shows Restore All followed by entries for B and C

#### Scenario: Choosing an entry restores just that app
- **WHEN** the user chooses B from the Restore Apps submenu
- **THEN** B is unhidden and disappears from the submenu while the session continues with C

#### Scenario: Restore All ends the session
- **WHEN** the user chooses Restore All during a session
- **THEN** all recorded apps are unhidden and the session ends

#### Scenario: Settings opens the Settings window
- **WHEN** the user chooses Settings… from the menu
- **THEN** the Settings window opens per the shortcut-config capability
