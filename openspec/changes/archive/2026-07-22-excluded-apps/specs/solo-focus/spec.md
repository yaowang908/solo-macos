## MODIFIED Requirements

### Requirement: Eligibility exclusions
Solo Focus SHALL NOT hide: Solo itself, applications that are already hidden, background applications with no user-facing windows (activation policy other than `.regular`), and applications on the Excluded Apps list. The Excluded Apps list SHALL be consulted at activation time only; the session record and deactivation behavior are unaffected by list edits made during a session.

#### Scenario: Already-hidden apps stay out of the session
- **WHEN** app D was hidden by the user (`Command+H`) before Solo Focus is activated
- **THEN** D is not added to the session record and is not unhidden when the session ends

#### Scenario: Background apps are ignored
- **WHEN** menu-bar-only or background agents are running during activation
- **THEN** Solo does not attempt to hide them

#### Scenario: Excluded apps stay visible
- **WHEN** app E is on the Excluded Apps list and the user activates Solo Focus
- **THEN** E is not hidden and is not added to the session record

#### Scenario: Mid-session exclusion does not affect restore
- **WHEN** a session recorded app B before B was added to the Excluded Apps list, and the user deactivates Solo Focus
- **THEN** B is unhidden normally; the exclusion applies from the next activation
