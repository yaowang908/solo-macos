## ADDED Requirements

### Requirement: Permission is scoped to Smart Restore
Solo SHALL NOT request Accessibility permission at launch or for Solo Focus. The permission flow SHALL be triggered only when Smart Restore needs it: at first launch when the Smart Restore default would take effect, or when the user enables the Smart Restore toggle while permission is not granted.

#### Scenario: Launch without permission does not prompt
- **WHEN** Solo launches on a machine without Accessibility permission and the user only uses Solo Focus
- **THEN** Solo never presents a system Accessibility prompt for those actions

#### Scenario: Enabling Smart Restore triggers the flow
- **WHEN** the user enables Smart Restore while permission is not granted
- **THEN** Solo presents its permission explainer

### Requirement: Permission explainer
The permission flow SHALL plainly explain why Accessibility access is needed (to detect and un-minimize other apps' windows) and SHALL offer a button that opens the macOS Privacy & Security → Accessibility settings pane directly.

#### Scenario: Open settings from explainer
- **WHEN** the user clicks the explainer's open-settings action
- **THEN** System Settings opens to the Accessibility privacy pane

### Requirement: Detect grant without relaunch
Solo SHALL detect that Accessibility permission was granted while Solo is running and activate Smart Restore without requiring an app relaunch.

#### Scenario: Grant while running
- **WHEN** the user grants Accessibility permission in System Settings while Solo is running with Smart Restore enabled
- **THEN** Smart Restore becomes operational within a few seconds, without relaunching Solo

### Requirement: Graceful degradation when denied
While permission is not granted, Solo SHALL remain fully usable as a menu bar app: Solo Focus MUST work normally, Smart Restore MUST be inert, and the menu SHALL indicate that Smart Restore is waiting on Accessibility permission.

#### Scenario: Denied permission leaves Solo Focus working
- **WHEN** the user dismisses the permission flow without granting access
- **THEN** Solo Focus continues to work and Smart Restore performs no window operations

#### Scenario: Menu communicates the blocked state
- **WHEN** Smart Restore is enabled but permission is not granted
- **THEN** the status item menu conveys that Smart Restore requires Accessibility permission
