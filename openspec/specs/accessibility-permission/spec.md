# accessibility-permission Specification

## Purpose

Feature-scoped Accessibility onboarding for Smart Restore: prompt only when Smart Restore needs the permission, re-check live before prompting, detect a grant without relaunch, disable Smart Restore if the user declines, and keep Solo Focus fully usable regardless of permission state.

## Requirements

### Requirement: Permission is scoped to Smart Restore
Solo SHALL NOT request Accessibility permission at launch or for Solo Focus. The permission flow SHALL be triggered only when Smart Restore needs it: at first launch when the Smart Restore default would take effect, or when the user enables the Smart Restore toggle while permission is not granted. Before presenting the explainer, Solo SHALL re-check current permission live and skip the prompt if access is already granted.

#### Scenario: Launch without permission does not prompt
- **WHEN** Solo launches on a machine without Accessibility permission and the user only uses Solo Focus
- **THEN** Solo never presents a system Accessibility prompt for those actions

#### Scenario: Enabling Smart Restore triggers the flow
- **WHEN** the user enables Smart Restore while permission is not granted
- **THEN** Solo presents its permission explainer

#### Scenario: Already-granted permission is not re-prompted
- **WHEN** the permission flow would be triggered but Accessibility access is already granted
- **THEN** Solo skips the explainer and Smart Restore becomes operational without a prompt

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

### Requirement: Declining the permission flow disables Smart Restore
If the user dismisses the permission flow without granting access, Solo SHALL turn the Smart Restore setting off (rather than leaving it enabled-but-inert). Re-enabling Smart Restore later SHALL re-trigger the permission flow. Solo Focus MUST remain fully usable throughout.

#### Scenario: Declining turns Smart Restore off
- **WHEN** the user dismisses the permission explainer without granting access
- **THEN** the Smart Restore setting is turned off and Solo Focus continues to work normally

#### Scenario: Re-enabling after declining re-prompts
- **WHEN** the user re-enables Smart Restore while permission is still not granted
- **THEN** Solo presents the permission explainer again

### Requirement: Graceful degradation while enabled but untrusted
While Smart Restore is enabled but permission is not granted (for example, access was revoked after being granted), Solo SHALL keep Smart Restore inert and the menu SHALL indicate that it is waiting on Accessibility permission. Solo Focus MUST work normally.

#### Scenario: Menu communicates the blocked state
- **WHEN** Smart Restore is enabled but permission is not granted
- **THEN** the status item menu conveys that Smart Restore requires Accessibility permission
- **AND** Smart Restore performs no window operations
