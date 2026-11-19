# ADR-0002: Input routing, contexts and UI pause requests

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — reference/design review only; device and runtime checks remain outstanding.

## Decision Makers
Scott (owner; explicitly decided QQ-08) and Devin (authoring agent and inline godot-specialist reviewer). Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Lonefire needs a single input boundary that prevents gameplay leakage through UI while preserving real-time press timing and disconnect recovery. Propose one run-owned InputRouter with validated named actions, exclusive Gameplay/UI/Locked contexts and separate UI-context versus pause requests; Scott's QQ-08 decision keeps backpack simulation and action timers running.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf; GDScript; Jolt |
| **Domain** | Input / UI |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — VERSION.md post-cutoff 4.7; Input HIGH, UI MEDIUM integration |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/input.md`, `modules/ui.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | 4.7 input device semantics: identify event types, never assume keyboard/mouse device 0; 4.6 separate mouse versus keyboard/gamepad focus and SDL3 gamepad behavior |
| **Verification Required** | Compile router and pause adapters on pin; exercise SDL3 disconnect/recovery on macOS/Windows, dual-focus, input while paused, suppression of held input across UI closure, and no double UI delivery |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted; must be Accepted before implementation) |
| **Enables** | ADR-0005, ADR-0007, ADR-0013, ADR-0016; deferred screen/settings input adapters |
| **Blocks** | Input/context/pause adapter implementation until Accepted; no story files found under production |
| **Ordering Note** | No dependency on ADR-0003: this defines abstract pause/context requests, not clock implementation. Integrated pause tests require ADR-0003; QQ-08 is resolved by Scott and checked consistent with updated Time Rule 8. |

## Context

### Problem Statement
The Input GDD requires named-action routing, exclusive contexts and real-second timings. Opening a backpack must suppress new gameplay input without cancelling an action or freezing survival time; treating every UI context as a pause would violate Scott's decision and Interaction's explicit edge case.

### Constraints
- InputMap action names and default keyboard/mouse/gamepad bindings in Input Rules 2–3 are unchanged and authored in project.godot, not invented at runtime.
- Radio/diary routing contracts remain available for their deferred phases; this ADR does not add tap-out, diary, a remap screen or settings scope to MVP.
- Active-pad disconnect during Gameplay must pause; reconnect must never auto-resume. Loading/Locked lifecycle gates remain distinct from user menus.
- QQ-01–07/09–10 recommendations stay PROPOSED: no final hardware, spend, tuning, camera, scope or HUD design decisions.

### Requirements
- Full provisional TR-input-and-action-map-001–028, including IN1 radial deadzone, IN2 classification, IN3 buffers and all acceptance/performance obligations.
- Exactly one active context; context changes clear holds/buffers and require release before a still-held action can be rearmed.
- Only the input layer may inspect raw keys/buttons/axes; UI and gameplay consume routed named actions, not parallel raw-event handlers.

## Decision

InputRouter is the sole application raw-event reader and named-action sampler. Its engine adapter classifies InputEventKey/Mouse/Joypad types, resolves authored InputMap actions and publishes typed snapshots/edges. UI adapters consume routed `ui_*` actions and pointer intents; any built-in Control input bridge must be contained within this input boundary and must prevent duplicate delivery. Gameplay consumers must not poll Input directly. Native UI focus behavior must be proven in an adapter spike, not assumed from a diagram.

Validate each binding in its effective context, retaining the old binding and rejecting/logging the newer conflicting one. Gameplay/UI overlap is allowed only because they are exclusive; within UI, built-in navigation and closing actions must still have one meaning per event. Preserve all defaults, including C/right mouse cancel, Q/R turns and optional zoom. Apply IN1 once with default deadzone 0.2 and normalized diagonals; choose the larger-magnitude keyboard/gamepad move vector, while the most recent meaningful event selects glyph device. Drift under deadzone must not switch device.

InputRouter owns IN2 real-second timing: tap below 0.25 s, hold from 0.35 s, intermediate release ignored, irreversible confirm at 1.5 s with early-release cancellation. IN3 stores one press per interact/secondary/cancel action for 0.15 real seconds; newer replaces older, ready delivery consumes it once, expiry drops it. Zero buffer disables buffering. Validate timing ranges, deadzone <1 and hold_min_s ≥ tap_max_s before activation. Input timing remains real-time under sleep and pause; it does not imply gameplay timers run while explicitly paused.

UI requests context through a Coordinator port, with Locked taking precedence over UI, then Gameplay. The router alone applies transitions. Closing the top UI layer recomputes context from remaining layers, never blindly returns to Gameplay. Locked admits only pause_menu; UI admits ui_*, backpack-close, pause/back and deferred radio. Each transition clears holds/buffers; a physical key still down must be released before re-press, not reclassified as a fresh press on close.

Backpack open requests UI only. It must never acquire a pause token, cancel active work or freeze ActionRunner's unpaused-real-second duration. The explicit pause menu requests UI plus a pause token; all simulation and action timers stop until released. Loading and active-gamepad-disconnect safety gates also stop simulation. Reconnecting the active pad leaves the reconnect prompt/pause active until deliberate resume; keyboard remains usable to recover. Inactive-pad disconnect does nothing. These safety gates are not new menu design or exceptions allowing arbitrary UI to pause.

### Architecture Diagram
`InputMap/raw events → InputRouter → InputSnapshot → Character / ActionRunner / Camera / UI bridge`; `UI → Coordinator context/pause request port → InputRouter context + Clock/action gate`. Context and pause are orthogonal, never inferred from one another.

### Key Interfaces
- `sample_actions(real_delta_s: float) -> InputSnapshot`, `set_context(context: InputContext) -> void` retain architecture names; snapshot contains move_vector, move_hurry, named press/release/classification/held_seconds, active_device and run/sequence identity.
- `device_changed(active_device: StringName)` and `active_gamepad_disconnected()` are typed notifications; UI glyphs consume the former, Coordinator handles recovery on the latter.
- `request_ui_context(source: StringName, open: bool) -> void` is an idempotent Coordinator command; tracked sources must be cleared on teardown.
- `request_pause(source: StringName) -> PauseToken`, `release_pause(token: PauseToken) -> void` are Coordinator ports; source/run-tagged tokens prevent one overlay releasing another's pause. Backpack is forbidden as a pause source.
- Binding validation returns a Result/reason, preserves the accepted table on conflict and logs the rejected binding. All existing GDD action and field names are preserved; these Coordinator ports are new internal interfaces, not renames.

### Implementation Guidelines
- Input must use named authored actions; gameplay/UI scripts must never read raw keycodes/buttons/axes or bypass InputRouter.
- Router must process real timing while paused; simulation/ActionRunner must use a separate pause gate. Process-mode wiring must not let an always-running input parent accidentally unpause gameplay children.
- Context transitions must clear state and suppress held-until-release actions; buffer delivery must be once-only and run-scoped.
- UI must never call SceneTree pause directly; only Coordinator may apply pause policy. Backpack must leave clock and in-progress work running, even while gameplay input is blocked.
- Active device must be selected by meaningful event type/time, never device==0; UI focus and glyphs must support mouse and keyboard/gamepad independently.

## Alternatives Considered

### Alternative 1: Per-screen unhandled-input handlers
- **Description**: Each gameplay/screen node reads events and consumes those it recognizes.
- **Pros**: Fits simple local Godot scenes with little infrastructure.
- **Cons**: Duplicates timing and context logic; GUI propagation order can leak or swallow gameplay actions.
- **Rejection Reason**: Sole raw ownership and release/buffer invariants need one auditable boundary.

### Alternative 2: Automatically pause whenever context is UI
- **Description**: Couple context changes directly to global simulation pause.
- **Pros**: Simple menu implementation.
- **Cons**: Backpack freezes actions/survival; conflates reconnect/loading policy with focus.
- **Rejection Reason**: Contradicts Scott's QQ-08 decision and Interaction's backpack edge case.

## Consequences

### Positive
- Context isolation and consistent real-time classification apply to all consumers.
- Backpack can remain dangerous in real time without allowing unintended movement/interactions; explicit pause remains reliable.

### Negative
- A routed Control bridge needs focused engineering/testing; native GUI input cannot be allowed to double-dispatch actions.
- Pause tokens/context sources need cleanup and keyboard recovery tests in addition to ordinary input tests.

## Risks
- Inline godot-specialist review: InputMap/InputEvent typed dispatch and typed signals fit modules/input.md; avoid device-zero detection. UI dual-focus/SDL3 changes require platform tests. No deprecated API required. This is inline author review only, not runtime or independent approval. TD-ADR skipped — Lean mode.
- The reference examples do not prove a centralized Control bridge, disconnect callback signature or exact process-mode setup; compile/test those adapters on 4.7.2 before implementation acceptance evidence is claimed.
- GDD sync: checked Input, Interaction and updated Time Rule 8 after merging origin/main; consistent with QQ-08 (backpack does not pause time/actions; explicit pause does), with no renamed API/signal/type.
- Autonomous calls: assumptions A (single router versus per-screen handling versus UI-implies-pause; Input linkage, ADR-0001 dependency, Proposed); separate design tabs chose validated action table/one-event meaning, exclusive clearing contexts, real-time IN1–IN3 and orthogonal tokenized pause. QQ-08 was supplied by Scott, not auto-decided. Write chose ADR only; registry chose append Proposed stances; closing chose requested F3.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [input-and-action-map.md](../../design/gdd/input-and-action-map.md) | Full provisional TR-input-and-action-map-001 … TR-input-and-action-map-028, co-covered with F1; every Core Rule, IN1–IN3, edge case, dependency and AC/performance criterion | Sole input ownership; unchanged named action/default binding contract; validated remaps; Gameplay/UI/Locked; real-time timing/buffers; device glyphs and disconnect recovery. Deferred actions remain contracts, not new MVP features. |
| [interaction-and-timed-actions.md](../../design/gdd/interaction-and-timed-actions.md) | Edge Cases: backpack opening does not cancel/pause work; pause menu pauses everything; Dependencies: taps/cancel routed from Input | Separate context and pause ports retain ongoing work under backpack; reject new gameplay input; explicit pause gates ActionRunner. C4 still owns the full Interaction TR range. |
| [time-and-day-cycle.md](../../design/gdd/time-and-day-cycle.md) | Rule 8 pause / resolved QQ-08; AC6 pause freezes game time | Backpack is UI-only; explicit pause/menu and safety gates freeze simulation without disabling recovery input. ADR-0003 owns full Time co-coverage. |

## Performance Implications
- **CPU**: Input ≤0.05 ms/frame and next-rendered-frame movement ≤16.6 ms are GDD obligations; measure, not claimed achieved. No repeated binding-table validation in hot path.
- **Memory**: One hold/buffer record per named action and tracked UI/pause sources, cleared per run; no unbounded raw-event history.
- **Load Time**: Validate bindings before Gameplay activation; invalid new bindings cannot corrupt the accepted table.
- **Network**: None.

## Migration Plan
No production input layer exists. After acceptance, author existing defaults in project.godot and implement the router/Control bridge behind fake consumers; leave prototypes and approved GDDs untouched. Alpha settings UI remains deferred; only the validation boundary is established now.

## Validation Criteria
- Execute Input AC1–15, preserving automated and playtest distinction: static raw-read search; valid defaults/conflicting F remap rejection; backpack E/W suppression and no held-E on close; Locked E drop with pause still available; pad/drift glyph changes; active disconnect prompt; real-time timings during pause/sleep; radio hold reset and future Critical accessibility contract.
- IN1: stick 0.15→0, 0.6→0.5±0.001, W+D length 1±0.001; dz=1 rejected. IN2: 0.2 s tap, 0.3 s neither, hold at 0.35 s, 1.4 s radio release no confirm and 1.5 s confirm. IN3: 0.1 s queued delivery once, 0.2 s expiry, repeated press one delivery, zero buffer valid.
- Empty input snapshot must be neutral. Invalid timing/binding data must reject/log without delivering an action; inactive disconnect must do nothing; reconnect must not auto-resume. Restart/context/pause overlap must never release another source's pause or resurrect a held key.
- QQ-08 integration: open backpack mid-chop and across a minute boundary; action progress and survival ticks continue, no new gameplay input. Explicit pause stops both for 10 real minutes with no catch-up from paused wall time; close one of nested overlays without leaking Gameplay.
- Preserve Input AC14 two-device novice five-minute task evidence, AC15 frame capture and ≤0.05 ms/frame measurement. Test both focus paths and recovery on macOS/Windows. These checks are required, not performed by this documentation run.

## Related
- [ADR-0001](adr-0001-run-scene-composition-and-service-lifecycle.md) upstream, Proposed; [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) pause/clock consumer, Proposed.
- [Master architecture](architecture.md), F2, ADR Audit and QQ-01–10; Scott's QQ-08 clarification supersedes the open-question status for this owner choice, not the GDD text by stealth.
- Acceptance route: `/architecture-decision accept ADR-0002`; no stories unblocked here.
