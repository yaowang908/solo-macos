# smart-restore Specification

## Purpose

Activation-driven window recovery: when an activated app has no visible normal window but does have minimized ones, Solo un-minimizes one selected window (main → largest → any), raises it, and focuses it. Includes visible-window detection, the self-caused-activation suppression guard, silent failure, and gating on the toggle plus Accessibility permission.

## Requirements

### Requirement: Restore a minimized window on activation
When Smart Restore is enabled and an eligible application becomes active, Solo SHALL check whether the app has any visible, non-minimized normal window on the current Space. If it has none but has at least one minimized normal window, Solo SHALL un-minimize exactly one selected window, raise it, and give it keyboard focus. If the app has a visible normal window, Solo MUST take no action.

#### Scenario: Only window is minimized
- **WHEN** the user activates an app whose only normal window is minimized
- **THEN** Solo restores that window, raises it, and focuses it

#### Scenario: App already has a visible window
- **WHEN** the user activates an app with one visible and one minimized window
- **THEN** Solo takes no action

#### Scenario: App has no windows
- **WHEN** the user activates an app with no windows at all
- **THEN** Solo takes no action and does not create a window

#### Scenario: Hidden app is not unhidden
- **WHEN** an app hidden with `Command+H` becomes active
- **THEN** Solo does not unhide it as part of Smart Restore

#### Scenario: Re-selecting the already-active app is out of scope
- **WHEN** the active app's windows are all minimized and the user re-selects that same app (e.g. `Command+Tab` back to it) without focus ever leaving it
- **THEN** Solo takes no action, because macOS emits no activation event for re-selecting the active app (verified limitation of activation-based observation; a Dock icon click on that app is handled natively by macOS itself)

### Requirement: Window selection priority
When multiple minimized normal windows exist, Solo SHALL select in this order: (1) the app's main or focused document window if identifiable, (2) the largest minimized normal window, (3) any eligible minimized normal window. Non-normal windows (panels, sheets, modal dialogs, full-screen windows) MUST NOT be selected.

#### Scenario: Main window preferred
- **WHEN** an activated app has a minimized main window and a smaller minimized auxiliary document window
- **THEN** Solo restores the main window

#### Scenario: Fallback to largest
- **WHEN** no main window is identifiable among several minimized normal windows
- **THEN** Solo restores the largest one

### Requirement: Self-caused activation suppression
Smart Restore SHALL ignore application-activation events caused by Solo's own operations, including activations occurring during Solo Focus hide and restore transitions.

#### Scenario: Solo Focus toggle does not trigger restores
- **WHEN** the user toggles Solo Focus on or off, causing focus to shift between apps
- **THEN** no minimized windows are un-minimized as a side effect

### Requirement: Failure is silent and non-disruptive
If window inspection or restore fails for an app (Accessibility unsupported, stale references, protected app), Solo SHALL take no action for that activation, MUST NOT retry in a loop, and MUST NOT crash or show intrusive UI.

#### Scenario: Unsupported app
- **WHEN** the user activates an app whose windows cannot be read via Accessibility
- **THEN** nothing visible happens and Solo continues operating normally

### Requirement: Feature gating
Smart Restore SHALL operate only when both (a) the user-facing toggle is enabled and (b) Accessibility permission is granted. The toggle default is enabled, taking effect once permission is granted.

#### Scenario: Toggle off stops observation effects
- **WHEN** the user unchecks Smart Restore and then activates an app with only minimized windows
- **THEN** Solo takes no action
