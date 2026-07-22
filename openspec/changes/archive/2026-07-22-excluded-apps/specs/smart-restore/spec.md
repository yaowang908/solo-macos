## MODIFIED Requirements

### Requirement: Restore a minimized window on activation
When Smart Restore is enabled and an eligible application becomes active, Solo SHALL check whether the app has any visible, non-minimized normal window on the current Space. If it has none but has at least one minimized normal window, Solo SHALL un-minimize exactly one selected window, raise it, and give it keyboard focus. If the app has a visible normal window, Solo MUST take no action. Applications on the Excluded Apps list MUST never be acted on: their activations are ignored entirely.

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

#### Scenario: Excluded app is never auto-restored
- **WHEN** an app on the Excluded Apps list becomes active with only minimized windows
- **THEN** Solo takes no action
