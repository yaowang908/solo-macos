## MODIFIED Requirements

### Requirement: Status item menu
The status item SHALL expose a menu containing, in order: **Toggle Solo Focus**, **Restore Windows**, **Smart Restore Minimized Windows** (checkable), **Settings…**, and **Quit Solo**. **Restore Windows** MUST be disabled when Solo is not managing any hidden applications. **Settings…** SHALL open the Settings window.

#### Scenario: Menu contents when idle
- **WHEN** the user opens the status item menu and no Solo Focus session is active
- **THEN** the menu shows Toggle Solo Focus, Restore Windows (disabled), Smart Restore Minimized Windows with a checkmark reflecting its enabled state, Settings…, and Quit Solo

#### Scenario: Restore Windows enabled during a session
- **WHEN** a Solo Focus session is active and at least one app is Solo-managed
- **THEN** the Restore Windows menu item is enabled

#### Scenario: Settings opens the Settings window
- **WHEN** the user chooses Settings… from the menu
- **THEN** the Settings window opens per the shortcut-config capability
