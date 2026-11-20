# ADR-0018: Shell navigation, end shot and run checkpoint

## Status
Accepted

Accepted on 2026-11-20 under Scott's explicit delegation for PR #28. Reversible defaults remain revisable, but acceptance is no longer pending. This record explicitly amends earlier Accepted constraints only for the bounded menu/checkpoint slice: terminal skip after one second, checkpoint persistence in MVP, and reset of footprint/trail visuals.

## Date
2026-11-20

## Last Verified
2026-11-20 — code/document survey; no runtime or platform verification.

## Decision Makers
Scott (owner direction); Devin (autonomous reversible defaults).

## Summary
Keep the shell persistent and gameplay run-scoped while adding deliberate navigation and one validated checkpoint. The coordinator owns quiescence, terminal precedence and a pausable end-shot timer; shell-owned SaveStore owns files, never live gameplay state.

## Engine Compatibility
| Field | Value |
|---|---|
| Engine | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| Domain / layer | Core lifecycle / Foundation and Presentation |
| References | ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0008; pinned docs/engine-reference/godot/VERSION.md |
| Post-cutoff APIs | No new native API signature asserted; FileAccess/DirAccess adapter must be checked on pin |
| Verification required | Atomic overwrite/flush behavior on macOS/Windows; pause/process wiring, owner restore and teardown |

## ADR Dependencies
| Field | Value |
|---|---|
| **Depends On** | ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0008 |
| **Enables** | Title, terminal navigation and bounded run checkpoint implementation |
| **Blocks** | Production handoff without owner DTO, lifecycle, input and filesystem verification |
| **Ordering Note** | Compose owners first, then DTO validation/restore, then navigation; no ranges in dependency IDs |

## Context
### Problem Statement
Current shell mounts immediately; pause directly quits and terminal HUD offers restart. No start/quit result port, results navigation, checkpoint validation or terminal pause-clock policy exists.
### Constraints
No gameplay-state autoloads. Preserve owner writes, detached data, run identity and ordered terminal arbitration. Defaults may narrow future scope but cannot silently claim compliance with incompatible Accepted records.
### Requirements
Cover TR-screens-and-menus-001 through TR-screens-and-menus-007 and TR-save-load-001 through TR-save-load-007, each explicitly registered in the traceability matrix.

## Decision
Use BOOT → TITLE → RUN(playing/paused) → END_SHOT → RESULTS → TITLE/new RUN. CLI three-day/demo bypass title. Shell owns SaveStore and run mount/unmount; coordinator owns gameplay and presentation-time gates. Bootstrap receives profile, seed and optional restore DTO. A failed start never enables a partial world and returns a localized retryable title error.

SaveStore is an injected non-autoload file adapter. It probes/validates/quarantines one versioned JSON slot at user://saves/run_checkpoint.json, writes temp+atomic rename and deletes on terminal. It holds detached values, not live owner references. Coordinator alone chooses quiescent export boundaries: nonterminal sunrise after terminal arbitration (defer during active action), manual save after forced action cancellation, never during ordered dispatch/commit. No action or transaction token is serialized.

Restore validates every field in staged owners, restores deterministic RNG state as well as seed, rebuilds owner registrations and publishes initial snapshot before activation. All required profile owners must participate; optional reset declarations are explicit. Clock, Body, Needs, Inventory, Fire, Gathering and survivor state are required; snow marks and transient feedback reset per save GDD exception. Enabled Shelter/snare/physical Terrain state requires adapters before that profile can Continue.

Terminal closes gameplay UI, cancels save admission, invalidates/deletes checkpoint, locks simulation and starts coordinator-owned END_SHOT. Timer advances with finite real delta only when router pause gates are clear. Camera holds and authored death fade/silence remains. Esc acquires the run's explicit pause token for terminal pause; Resume Shot releases only that token, never clears terminal. After one unpaused second, route a fresh semantic confirm/interact skip intent to coordinator; complete at eight unpaused seconds otherwise. Terminal presentation is not a second outcome event.

### Architecture Diagram
`Shell {navigation, SaveStore} → fresh RunCoordinator {router, clock/RNG, owners, shot timer, UI adapters}`
`owners → detached DTOs → validator → SaveStore`; `UI intents → shell/coordinator → owner result`.

### Key Interfaces
| Boundary | Application port |
|---|---|
| Shell | start_run(config: RunConfig) -> Result; stop_run(reason: StringName) -> void; return_to_title() -> Result |
| RunConfig | profile, seed, restore DTO or null; validated before mount |
| Coordinator | request_checkpoint(reason) -> Result; export only after quiescence; manual save retains pause until result |
| Each stateful owner | export_state() -> detached DTO; restore_state(dto) -> bool; validation staged before active state mutation |
| SaveStore | probe() -> checkpoint result; write_checkpoint(dto) -> Result; invalidate_terminal() -> Result |
| Terminal presentation | request_skip_end_shot(run_id, terminal_id); completion notification bound to same identities |
Results contain accepted/reason and run/sequence identity where run-bound. stop_run is idempotent; return_to_title saves only for a live run and tears down only on successful save. Terminal return never saves.

### Implementation Guidelines
- Serialize shell commands; reject duplicates/stale callbacks; invalidate run identity before deferred deletion.
- start_run initializes locked/gated per ADR-0001; on restore failure dispose staged world and remain title.
- Direct owner DTO restoration must not publish minute events, consume items, roll RNG or complete work.
- Loading fade owns a fresh pause gate for one second; no open pause menu; release only loading token afterward.
- Explicit pause uses UI source plus run-tagged token through coordinator ports. Router continues real-time input; no SceneTree pause in UI.
- Terminal skip is a narrow Accepted exception to Locked-only-pause, not permission to route arbitrary gameplay actions.
- Quiesce/copy on main ownership boundary before I/O; terminal cancels pending save and wins before replacement admission.
- Manual save errors retain paused run; autosave errors preserve prior slot and warn. Invalid load quarantines and hides Continue.
- Terminal deletion failure blocks navigation/close behind Retry. Crash/OS-kill during failed invalidation remains a documented limitation, not a one-life guarantee.
- No full generic object serializer, mutable Resource reuse, file I/O in HUD or cross-owner writes.

## Alternatives Considered
### Alternative 1: Save/gameplay autoload
Rejected: hidden lifetime and scene aliases violate ADR-0001.
### Alternative 2: Serialize presentation snapshots or scene nodes
Rejected: incomplete owner/RNG state, mutable aliases and transient transaction replay.
### Alternative 3: Never skip terminal shot
Preserves earlier UX/Emotional Feedback but conflicts with requested optional skip; the accepted one-second floor retains a brief protected arrival.

## Consequences
### Positive
Explicit mount/stop results, honest Continue and isolated restores; no run-state singleton.
### Negative
Owner adapters, staged validation and filesystem error UX add scope; no settings persistence. Strict terminal deletion failure can strand navigation until storage recovers.

## Risks
Accepted bounded amendments: early skip narrows Emotional Feedback's eight-second authored shot and prior death UX no-skip rule; ADR-0002 admits only the terminal skip exception. ADR-0001/ADR-0016 MVP boundaries now include this checkpoint slice. Terrain exact footprint/trail-visual restore is intentionally narrowed; physical Terrain and other enabled finite-resource owners still require adapters. These amendments do not authorize wider mechanics. Full Tap-out/Run Results design remains deferred; filesystem platform verification remains an implementation obligation.

## GDD Requirements Addressed
| GDD | Requirements | Coverage |
|---|---|---|
| screens-and-menus.md | TR-screens-and-menus-001, TR-screens-and-menus-002, TR-screens-and-menus-003, TR-screens-and-menus-004, TR-screens-and-menus-005, TR-screens-and-menus-006, TR-screens-and-menus-007 | Shell, CLI, pause/quit, shot, results and accessible routed UI |
| save-load.md | TR-save-load-001, TR-save-load-002, TR-save-load-003, TR-save-load-004, TR-save-load-005, TR-save-load-006, TR-save-load-007 | Slot/schema, quiescence, atomic I/O, validation, terminal deletion, restore gate and DTO extension |

## Performance Implications
No invented hardware budget. Measure save/export/validation latency and memory on nominated devices; file I/O must not cause an unbounded active-play stall. UI exposes pending states and prevents duplicate requests. Atomic persistence and identity safety outrank cosmetic transition timing.

## Migration Plan
1. Record Scott's delegated acceptance and compile these bounded amendments in the control manifest.
2. Add shell result ports and coordinator gates; implement owner adapters/SaveStore and fake-I/O tests.
3. Implement title/pause/results and localized strings; retain CLI routes.
4. Verify normal/empty/error paths, pause timing and platform replacement; no schema migration beyond rejection in v1.

## Validation Criteria
- Fresh starts and restores cannot leak old run state/callbacks; bad owner DTO fails whole mount.
- Verify cold/dehydration/dawn precedence, one terminal result, no terminal save, failed deletion recovery.
- Fake clock confirms first-second lock, later skip, eight-second timeout, pause/disconnect freeze.
- Fake filesystem confirms missing/corrupt/unknown-schema, temp interruption, write/rename/quarantine errors.
- Round-trip all profile owners and RNG, cancel manual actions without outcome/use/draw, defer sunrise save.
- Keyboard/pad/mouse visual/focus/contrast/expansion evidence retained; no runtime evidence claimed here.

## Related
[Screens](../../design/gdd/screens-and-menus.md), [Save/Load](../../design/gdd/save-load.md), [main menu](../../design/ux/main-menu.md), [death](../../design/ux/death-screen.md), [pause](../../design/ux/pause-menu.md).
Control manifest includes this Accepted record; acceptance does not itself establish runtime or platform verification.
