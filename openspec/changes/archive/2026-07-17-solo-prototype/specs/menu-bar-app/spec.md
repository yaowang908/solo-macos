## ADDED Requirements

### Requirement: Agent-style app lifecycle
Solo SHALL run as an agent-style macOS application: it MUST show a menu bar status item, MUST NOT show a Dock icon, and MUST NOT open a main application window at launch.

#### Scenario: Launch presents only a status item
- **WHEN** the user launches Solo
- **THEN** a status item appears in the menu bar
- **AND** no Dock icon appears
- **AND** no window opens

### Requirement: Status item menu
The status item SHALL expose a menu containing, in order: **Toggle Solo Focus**, **Restore Windows**, **Smart Restore Minimized Windows** (checkable), and **Quit Solo**. **Restore Windows** MUST be disabled when Solo is not managing any hidden applications.

#### Scenario: Menu contents when idle
- **WHEN** the user opens the status item menu and no Solo Focus session is active
- **THEN** the menu shows Toggle Solo Focus, Restore Windows (disabled), Smart Restore Minimized Windows with a checkmark reflecting its enabled state, and Quit Solo

#### Scenario: Restore Windows enabled during a session
- **WHEN** a Solo Focus session is active and at least one app is Solo-managed
- **THEN** the Restore Windows menu item is enabled

### Requirement: Icon reflects Solo Focus state
The status item icon SHALL visually distinguish Solo Focus active from inactive.

#### Scenario: Icon changes on toggle
- **WHEN** the user toggles Solo Focus on
- **THEN** the status item icon switches to the active appearance
- **AND** toggling Solo Focus off returns it to the inactive appearance

### Requirement: Global hotkey toggles Solo Focus
Solo SHALL register a global keyboard shortcut, defaulting to `Control+Option+Command+S`, that toggles Solo Focus. The shortcut MUST work while any application is frontmost. (Recorder UI for changing the shortcut is out of scope for the prototype.)

#### Scenario: Hotkey works from another app
- **WHEN** a third-party app is frontmost and the user presses `Control+Option+Command+S`
- **THEN** Solo Focus toggles exactly as if triggered from the menu

### Requirement: Quit is clean
**Quit Solo** SHALL terminate the app. If a Solo Focus session is active at quit, Solo MUST first unhide the applications recorded in that session.

#### Scenario: Quit during an active session restores apps
- **WHEN** the user quits Solo while a Solo Focus session is active
- **THEN** the Solo-hidden applications are unhidden before the app exits
