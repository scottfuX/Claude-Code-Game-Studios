# ADR-0001: Run scene composition and service lifecycle

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — checked against the pinned engine reference and current architecture/GDD contracts; not runtime-validated.

## Decision Makers
Scott (owner; QQ-08 decision supplied for this run) and Devin (authoring agent, including inline godot-specialist review). Scott has not approved this ADR; authoring is not acceptance.

## Summary
Lonefire needs one restart-safe composition root so its eighteen MVP systems cannot retain state or subscriptions from an earlier run. Propose a RunCoordinator-owned scene subtree with explicit dependency injection, owner-only writes, detached value snapshots and tracked subscription teardown instead of gameplay autoloads.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf; GDScript; Jolt |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — 4.7 is post-May-2025 cutoff in VERSION.md; core scheduling integration is MEDIUM in the architecture |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` (paths relative to that folder); no Core module exists |
| **Post-Cutoff APIs Used** | None required; explicitly returned typed overrides and explicit dirty tracking must respect 4.7 semantics |
| **Verification Required** | Compile lifecycle/typed signal adapters on the pin; verify process-mode/pause behavior, teardown during deferred deletion, restart isolation and snapshot alias safety |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — registry and ADR filename scan found no prior ADRs; this establishes composition, not F2/F3 scheduling semantics |
| **Enables** | ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015, ADR-0016 (allocated follow-ons) |
| **Blocks** | Foundation composition implementation and downstream run integration until Accepted; no story files exist under production at authoring |
| **Ordering Note** | Accept this before ADR-0002/0003 implementation; integrated run implementation also requires those and the affected Core ADRs Accepted. No story is unblocked by this document. |

## Context

### Problem Statement
The master architecture assigns shared state to sole owners but needs a concrete lifetime boundary. Scene order, ambient globals or shared mutable Resource assets would otherwise make restart, terminal dispatch and later restoration depend on hidden wiring.

### Constraints
- Preserve all approved MVP design; no new Save/Load implementation, addon, paid tool or platform commitment.
- Foundation/Input/Clock must exist before dependent systems become active. The registry was empty when context gathering began.
- Scott resolved QQ-08: the backpack routes input to UI without pausing simulation/action timers; the explicit pause menu pauses. Device-disconnect safety pause and loading gates remain required.
- QQ-01 profiling defaults (60 fps, 16.6 ms, 500 draws, 2048 MB) are PROPOSED only; QQ-02–07 and QQ-09–10 retain architecture recommendations as PROPOSED, not owner decisions.

### Requirements
- Co-cover the full provisional Input 001–028 and Time 001–029 ranges with ADR-0002/0003; cross-cutting ownership/lifecycle applies to every MVP owner in architecture.md.
- Inject dependencies before any cross-system query; publish a complete initial snapshot before enabling input/time.
- Invalidate all old-run events, callbacks and transactions on restart; expose values, never mutable foreign state.

## Decision

Use a persistent application shell only to mount/unmount a run. Each run has a fresh RunCoordinator and run-owned InputRouter, Clock, RNG adapter, Core/Feature models and Presentation adapters. Gameplay state must not live in autoload singletons. Immutable authoring definitions may be reused; mutable state must be constructed per run. Pure rules can use value/model objects; engine-facing scene nodes remain adapters.

The Coordinator validates definitions using each GDD's reject/default policy, allocates a new run identity and seed, starts Clock gated and Input Locked, constructs Map/Terrain and fixed-kit Inventory, then Character/Thermal/Body/Needs, then ActionRunner/Mishaps/Gathering/Fire/Morale. It injects explicit narrow query/command ports, registers interactables, attaches Camera/Feedback/Audio/HUD and subscriptions, publishes a complete initial snapshot, then enables Gameplay and time last. Empty heat-source/interactable lists are valid; invalid required definitions must never produce a partly playable run.

Shutdown first gates input/time and invalidates the run generation, cancels in-flight work without completion side effects, disconnects tracked subscriptions and clears queues/registrations, then releases the subtree. Deferred node deletion must not leave a window in which stale events can mutate the replacement run. Restart repeats construction with new state; later Save/Load can restore validated DTOs at a quiescent boundary but is not added to MVP.

### Architecture Diagram
`Application shell → RunCoordinator → {InputRouter, Clock, run RNG, Core owners, Feature owners, Presentation adapters}`. Coordinator injects ports; readers receive owner-produced snapshots; commands return to the sole owner. No cross-owner field writes or global gameplay lookup.

### Key Interfaces
- `start_run(config: RunConfig) -> Result`, `stop_run(reason: StringName) -> void` on RunCoordinator; repeated stop is harmless.
- `configure(ports: OwnerPorts) -> Result` before activation; actual owner ports are narrow typed contracts, not a service-locator dictionary.
- `snapshot() -> OwnerSnapshot`: detached value/ID data; nested collections must not alias live owner state. Read-only is a contract, not an assertion that GDScript objects are intrinsically immutable.
- Every command/event/attempt envelope carries `run_id` and monotonic `sequence`; owner commits reject duplicate/stale tokens. Domain payload names remain those in the GDDs.
- Subscription records retain producer, typed signal and Callable for deterministic disconnect; registration tokens are invalid after stop. F2 defines input/pause ports; F3 defines clock/dispatch/RNG ports.

### Implementation Guidelines
- Systems must receive dependencies explicitly and must never search the tree or autoloads for gameplay owners.
- Only the owner must mutate its state; shared Resources must contain definitions, never per-run mutable stacks/timers/counters.
- Initialization must finish wiring before input/time advances. Failed setup must clean up and stay Locked, with a logged error rather than fabricated data.
- Stop/restart must invalidate identity before deferred callbacks or node deletion. Snapshots must be copied at mutable-container boundaries; packed-array edits must explicitly mark dirty state in 4.7.
- Input context must not be used as a proxy for pause. Subscription order must never determine simulation causality; F3 owns dispatch ordering.

## Alternatives Considered

### Alternative 1: Gameplay autoload service singletons
- **Description**: Keep owners in globally reachable persistent nodes.
- **Pros**: Easy lookup and scene transition access.
- **Cons**: Hidden dependencies, state leakage, harder teardown and test isolation.
- **Rejection Reason**: Run lifetime and owner boundaries cannot be guaranteed by scene replacement alone.

### Alternative 2: Self-wiring nodes using tree discovery
- **Description**: Each node locates peers and subscribes during its own ready callback.
- **Pros**: Little explicit composition code; convenient editor scenes.
- **Cons**: Activation order and missing dependencies become incidental; subscriptions are difficult to audit.
- **Rejection Reason**: A complete initial snapshot and reproducible restart require explicit ordered construction.

## Consequences

### Positive
- Run isolation, fake-port tests and later DTO restoration share one explicit ownership boundary.
- Presentation can be replaced without changing gameplay models; no stale owner alias is intentionally exposed.

### Negative
- Composition and subscription bookkeeping add code; detached snapshots require allocation/copy discipline.
- Proposed downstream interfaces still require their own Accepted ADRs; this is not approval to implement every system.

## Risks
- Inline godot-specialist review: idiomatic scene ownership, typed Callable signal connections and instantiate-based construction fit the reference; no deprecated API is required. This is author self-review, not independent sign-off or an executed engine test. TD-ADR skipped — Lean mode.
- Deferred deletion/queued callbacks can outlive a node: gate by run identity before dispatch, disconnect explicitly and test rapid restarts.
- Shallow copies of Resources/collections can leak mutable state: construct per-run models and test nested snapshot mutation; do not assume a generic duplicate operation makes arbitrary data immutable.
- Engine references do not establish the exact application process-mode wiring. Pause propagation and lifecycle signatures remain runtime verification obligations, not verified behavior.
- GDD sync: checked Input and Time names against proposed interfaces; no renamed GDD signal/API/type. Time Rule 8 still conflicts with Scott's QQ-08 backpack exception; pending separate GDD fix, no GDD edited here.
- Autonomous calls: assumptions A (problem, three composition alternatives, no upstream ADR, full Input/Time linkage, Proposed); separate design tabs chose run-owned subtree, explicit ports, detached snapshots and tracked teardown over globals/discovery/shared mutable state; write chose ADR-only because GDD edits are excluded; registry chose append Proposed stances. These are proposals, not approvals. Closing routing after F1 chose requested F2.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [input-and-action-map.md](../../design/gdd/input-and-action-map.md) | Full provisional TR-input-and-action-map-001 … TR-input-and-action-map-028 (ADR Audit: M1/F1), including rules, IN1–IN3, edge cases, dependencies and acceptance/performance | Own and initialize one fresh InputRouter; clear state on lifecycle/context boundaries; inject consumers; preserve every action/binding/timing contract through ADR-0002 rather than claiming this composition record implements the formulas. |
| [time-and-day-cycle.md](../../design/gdd/time-and-day-cycle.md) | Full provisional TR-time-and-day-cycle-001 … TR-time-and-day-cycle-029 (ADR Audit: M2/F1), including T1–T5, boundaries, pause, restoration and subscriber budgets | One run-owned Clock, gated startup/shutdown and explicit subscribers; ADR-0003 supplies complete timing/dispatch semantics. QQ-08 exception is owner-decided; Time Rule 8 text fix remains pending. |

## Performance Implications
- **CPU**: No per-frame service discovery; measure composition and snapshot cost. Time's ≤0.02 ms/tick, combined subscribers ≤0.5 ms/tick and Input ≤0.05 ms/frame remain GDD obligations, not measured results.
- **Memory**: Fresh models and snapshots add bounded live-state copies; verify no growth across restarts. Final device/memory budgets await QQ-01.
- **Load Time**: Validation and wiring occur before first publication; measure startup on owner-nominated devices, no invented loading-time budget.
- **Network**: None; no networking scope added.

## Migration Plan
No production run implementation exists to migrate; prototypes remain untouched. After acceptance, create the composition root and owner adapters incrementally with fake-port tests; do not transplant prototype globals into authoritative run state. Save schema/format decisions remain deferred.

## Validation Criteria
- Derived from Input AC1–9/12 and Time AC1/6/17–18: static raw-input boundary check; one router/clock per run; initial day 1 13:00 Day/normal; no half-wired input/ticks; correct pause/context clearing and one boundary/reset delivery.
- Run 100 start/stop/restart cycles: no growing subscriptions or retained state, no old-run completion/use/roll, no duplicate initial snapshot. Mutating a returned nested snapshot must not alter its owner.
- Empty source/interactable collections must initialize safely. Invalid required dependencies must return failure, keep gameplay gated and release already-created state; GDD-sanctioned Time defaults remain usable.
- Co-coverage is not blanket proof: run the complete Input AC1–15 and Time AC1–20 suites through ADR-0002/0003; retain their device/playtest/presentation evidence requirements. At 120 catch-up ticks, measure the possible ~60 ms subscriber burst rather than infer 16.6 ms frame compliance.

## Related
- [Master architecture](architecture.md), especially Module Ownership, Initialization order, ADR Audit, Required ADRs and QQ-01–10; ranges are provisional, no permanent TR allocation or RTM generated.
- [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md) and [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md), both Proposed downstream decisions.
- Autonomous/standard/balanced run; no owner-only cost/hardware/scope/design call was settled. Acceptance must be explicit via `/architecture-decision accept ADR-0001`.
