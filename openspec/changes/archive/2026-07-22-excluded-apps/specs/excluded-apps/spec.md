## ADDED Requirements

### Requirement: Shared exclusion list
Solo SHALL maintain a single Excluded Apps list of bundle identifiers, persisted across relaunches, honored by both Solo Focus and Smart Restore. All user-facing surfaces MUST use the term "Excluded Apps".

#### Scenario: Excluded app is protected from both features
- **WHEN** an app is on the Excluded Apps list
- **THEN** activating Solo Focus does not hide it, and activating it with only minimized windows does not auto-restore them

#### Scenario: List survives relaunch
- **WHEN** the user excludes an app and relaunches Solo
- **THEN** the app is still excluded

### Requirement: Exclusion takes effect at action time
The list SHALL be consulted only when Solo acts (session activation, restore-on-activation). An in-flight Solo Focus session MUST be unaffected by list edits: apps already recorded in the session are restored on toggle-off regardless of the current list.

#### Scenario: Excluding an already-hidden app does not orphan it
- **WHEN** Solo Focus is active with app B hidden and recorded, and the user adds B to the Excluded Apps list
- **THEN** deactivating Solo Focus still unhides B; B stops being hidden from the next session onward

### Requirement: Status menu management
The status item menu SHALL contain an Excluded Apps submenu with, in order: a quick-add item naming the last non-Solo frontmost application ("Exclude “<AppName>”"), then the current excluded apps as checkmarked entries where clicking an entry removes it. When no non-Solo app has been activated yet, the quick-add item MUST be disabled. When the list is empty, a disabled placeholder MUST indicate there are no excluded apps.

#### Scenario: Quick-add excludes the app the user was just in
- **WHEN** the user works in Safari, opens Solo's menu, and chooses Exclude “Safari”
- **THEN** Safari's bundle identifier is added to the list and appears in the submenu

#### Scenario: Clicking a listed entry un-excludes it
- **WHEN** the user clicks an excluded app's entry in the submenu
- **THEN** the app is removed from the list immediately

### Requirement: Settings window management
The Settings window SHALL contain an Excluded Apps section listing entries with app icon and display name, a remove control per entry, and an add flow covering both running applications and apps chosen from disk. Entries whose app cannot be resolved (uninstalled) MUST render with the raw bundle identifier and a generic icon and MUST remain removable.

#### Scenario: Add a non-running app from disk
- **WHEN** the user uses the add flow and picks an application bundle from disk
- **THEN** that app's bundle identifier joins the list without the app needing to run

#### Scenario: Stale entry remains manageable
- **WHEN** a listed app has been uninstalled
- **THEN** its entry shows the bundle identifier with a generic icon and can still be removed
