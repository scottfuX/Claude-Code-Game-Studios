# ADR-0003: Ordered clock dispatch, typed events and run randomness

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — engine-reference/design review; no runtime, replay or performance evidence claimed.

## Decision Makers
Scott (owner; QQ-08 exception explicitly supplied) and Devin (authoring agent and inline godot-specialist reviewer). Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Lonefire needs every survival minute, action outcome and random draw to be reproducible without relying on Godot node or signal connection order. Propose a single run Clock feeding staged synchronous Coordinator dispatch, typed run-tagged events and an isolated authoritative RNG stream with restorable state; keep real-time input/action durations distinct from survival time.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf; GDScript; Jolt |
| **Domain** | Core / Scripting |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — VERSION.md post-cutoff 4.7; arithmetic LOW, scheduling integration MEDIUM per architecture |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`; no Core/Scripting module exists |
| **Post-Cutoff APIs Used** | None required; typed-return overrides must explicitly return; packed-array mutation must explicitly mark dirty state in 4.7 |
| **Verification Required** | Compile typed dispatch/DTO adapters; confirm SceneTree pause gate and RandomNumberGenerator seed/state restoration on 4.7.2. Reference library does not verify exact RNG serialization APIs or cross-version sequence stability. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted; must be Accepted before implementation) |
| **Enables** | ADR-0006, ADR-0007, ADR-0008, ADR-0011, ADR-0012; other clock/event consumers |
| **Blocks** | Ordered Clock/event/RNG implementation until Accepted; no story files found under production |
| **Ordering Note** | No ADR-0002 dependency cycle: Coordinator pause port is consumed abstractly. Integrated input/pause needs both records; C4/C5 must pin action/Body/Needs transaction boundaries before those consumers are implemented. |

## Context

### Problem Statement
Every skipped minute must integrate Fire, Body, Needs and Morale, while action timing and input remain meaningful real seconds. Unordered signals, secondary survival clocks and cosmetic RNG draws could change survival or reload outcomes for the same inputs.

### Constraints
- Preserve Time T1–T5 and all approved rates/formulas, no tuning changes: day 1 13:00 start, 90/60 real seconds per normal game hour, wait 0.25 and sleep 0.05 seconds per game minute, day cap 60.
- Scott's QQ-08: backpack uses UI context but simulation and active action timers continue. Explicit pause menu stops both; safety/loading gates also stop advancement.
- Needs alone owns is_asleep; Clock owns rate mode, not sleep state. Clock never decides run-end presentation or forces a new deferred Results implementation.
- QQ-01 profiling targets remain PROPOSED; QQ-02–07/09–10 remain owner questions. No approved harshness, duration or scope is changed.

### Requirements
- Full provisional Time TR001–029 co-coverage with F1, including ordered boundaries, bad-data defaults, all published values/signals and acceptance/performance criteria.
- ≤120 owed ticks/frame with debt carried, never dropped/reordered; normal alarm wins mode conflicts.
- Typed payloads and idempotent run/sequence identity; one authoritative gameplay RNG stream, seed plus restorable state/draw position, no cosmetic consumption.

## Decision

Clock owns day, minute_of_day, derived hour/phase/sun data, rate_mode, fractional elapsed-real-second accumulator and owed work. It advances only through Coordinator's unpaused update, not physics frames, wall-clock dates or arbitrary Timers. Accumulate unpaused real delta, subtract the current T3 seconds-per-minute for each owed minute, then finish that minute's whole dispatch before another begins. Recompute rate/phase at each boundary rather than batch converting a hitch with one final rate. At 120 ticks stop processing and carry all remaining elapsed-time debt; a rate change applies at its next legal boundary, not retroactively to completed minutes.

Validate the entire Time table at startup: T1 daylight=max(d_min,d_start−d_shrink×(day−1)); T2 sunrise/sunset symmetric about solar_noon and twilight inside 0–24; T3 positive rates and GDD ranges; T4 is derived QA arithmetic, not another runtime clock; T5 clamped sun_progress. Bad tables are rejected/logged as a whole and replaced by approved defaults. Publish every GDD Clock value and keep exact signal names. On day cap, emit run_day_cap_reached once and hold day 60 23:59 without repeatedly consuming debt/emitting ticks; Coordinator receives the cap notification, Clock does not own Results.

At each minute boundary, apply queued rate requests (including a Needs sleep request before the first new-run interval), advance/derive the clock, then deliver boundary notifications/reset hooks at that minute before model integration. Normal beats wait/sleep with all reasons logged and one change notification; sleep can replace wait; wait during sleep is ignored with warning. A normal request raised inside a minute is honored before another owed minute, so a long catch-up cannot sleep past an alarm. Needs is_asleep is never written by Clock.

Coordinator alone invokes authoritative stages: capture pre-step movement/work and modifiers → Thermal inputs → Fire burn/source publication → Inventory drying → Body step → Needs step/wake → terminal arbitration → Morale ordered queue flush → complete snapshot/presentation publication. Each stage runs synchronously once; typed public signals notify observers but must never be a second simulation integration path. Day resets happen before the affected day's Morale integration; sunrise/nightfall reach consumers at their true boundaries even in sleep. The proposed Body/Needs pre-step read boundary is subject to C5's full formula audit; F3 establishes scheduling, not unreviewed physiology changes.

ActionRunner uses unpaused real seconds with start-rate/start-modifier duration snapshots from Interaction IA1; it never uses the survival accumulator as an action timer. Coordinator processes same-update forced cancellation/terminal candidates before eligible completion commits: death wins over collapse/immersion; hypothermia wins dehydration ties; immersion cancels even non-cancellable work with no interrupted use/roll/result. C4 must specify the exact completion checkpoint and owning resolver transactions; do not assume this coarse frame description is enough to implement them. Once terminal is chosen, gate further simulation/completions, discard pending uncommitted work, publish one final snapshot/event and prohibit further RNG draws. Presentation may finish using real-time adapters without mutating the frozen simulation.

RunCoordinator owns the authoritative gameplay RNG adapter; Map placement and Mishaps receive a narrow draw port, not their own generators. Stable map initialization consumes draws before interactive attempts; same-frame attempts use stable accepted arrival sequence. No-profile actions and cancelled/interrupted work consume no Mishaps roll. Guard state belongs to Mishaps, RNG state to Coordinator. Mishaps' GDD promise to keep/export seed and stream position is satisfied by its injected view of that same run stream, not a second mutable copy; its save-facing output must still include that view plus its own guards. Snapshot seed, opaque generator state and draw position at a quiescent boundary; restoring a seed alone is insufficient. Cosmetics use a separate non-authoritative source. Same pinned-engine version/inputs/draw order must replay; cross-version binary/state compatibility is not promised, and later Save/Load must version/validate it.

### Architecture Diagram
`Unpaused real delta → Clock accumulator → one minute → Coordinator staged owner calls → typed notifications + immutable snapshot`. Input real seconds and ActionRunner unpaused real seconds are separate lanes; `ordered accepted attempts → run RNG → owner resolver`. Pause gate stops Clock and ActionRunner, not recovery input/UI.

### Key Interfaces
- `request_rate_mode(mode: StringName, reason: StringName) -> void`, `snapshot() -> ClockSnapshot` preserve GDD/architecture names. Snapshot includes day/hour/minute_of_day/phase/is_night/sunrise_window/daylight_hours/sunrise_hour/sunset_hour/sun_progress/rate_mode.
- GDD notifications stay `minute_tick`, `hour_changed(hour)`, `day_changed(day)`, `phase_changed(phase)`, `nightfall`, `sunrise`, `rate_mode_changed(mode)`, `run_day_cap_reached`; do not rename them to fit envelope terminology or add required arguments to existing no-argument signals.
- Coordinator's internal `step_minute(context: MinuteContext) -> void` owner ports carry run_id, sequence, clock snapshot and immutable pre-step activity/modifiers. They are distinct from public minute_tick; consumers must never integrate via both.
- `enqueue_event(event: RunEvent) -> Result`: typed envelope with run_id, sequence, minute, kind and domain-specific payload. Keep GDD payload fields such as action_outcome{action_type, success, cause, severity, tag, base_fail_chance} and fell_in_water; reject stale/duplicate envelopes, warn/ignore unknown IDs according to their owning GDD.
- `draw_unit(request: RandomDrawRequest) -> RandomDrawResult`, `export_random_state() -> RandomState`, `restore_random_state(state: RandomState) -> Result`: proposed adapter ports, not asserted Godot method signatures. DrawResult explicitly represents rejection for stale/terminal requests. RandomState includes seed/state/draw_count/engine pin; restore validates before changing live state.

### Implementation Guidelines
- Clock must be the only survival clock; owners must integrate exactly once per ordered minute, even during skips. Input/feedback real-time timers must never advance survival state.
- Coordinator must call fixed stages directly; signal connection order, node order and deferred calls must never determine authoritative causal order.
- Same-minute Morale events must apply losses → failures → successes → comforts → deferred rival/medical, then rates/derived state once; preserve domain priority in addition to envelope sequence.
- Pause must add no paused wall-time debt, emit no ticks and freeze action timers; existing unprocessed debt remains gated until resume. Backpack must not activate that gate. Normal requests must be reconsidered before the next catch-up minute.
- Every event/transaction must validate run identity and once-only sequence. RNG must never be consumed by cosmetics, rejected requests or cancelled attempts. Restore must be atomic on invalid data.

## Alternatives Considered

### Alternative 1: Independent owner timers and signal-order dispatch
- **Description**: Every system integrates from its own Timer/process callback and subscribes directly to clock signals.
- **Pros**: Little central scheduling code; familiar node-local implementation.
- **Cons**: Drift, missed skip boundaries and connection-order-dependent survival outcomes.
- **Rejection Reason**: Cannot guarantee exactly-once staged integration or same-minute terminal priority.

### Alternative 2: Bulk skip plus independent seeded RNGs
- **Description**: Jump to final skip time, integrate aggregate deltas and seed a generator per consumer.
- **Pros**: Cheap fast-forward; locally isolated random use.
- **Cons**: Misses fire-out/wake/death boundaries and contradicts the single seeded gameplay stream contract; seed-only restoration loses position.
- **Rejection Reason**: Approved per-minute events and reproducible Mishaps sequence take precedence over shortcut performance.

## Consequences

### Positive
- Catch-up, wake and terminal behavior are testable with deterministic fake owners.
- Stable event identities and isolated random draws support QA reproduction and later restoration without new save scope.

### Negative
- Dispatch/DTO discipline increases integration work and requires coordinated C4/C5 acceptance.
- 120 ticks ×0.5 ms subscribers can produce ~60 ms catch-up bursts; bounded tick count alone does not meet a 16.6 ms frame target.

## Risks
- Inline godot-specialist review: single Node-backed clock, explicit owner calls and typed Callable signals are idiomatic per current-best-practices/deprecated APIs. Typed-return overrides must return; use Time.get_ticks_msec only for real diagnostics, never OS.get_ticks_msec or survival state. No deprecated API required. TD-ADR skipped — Lean mode.
- Engine library does not establish exact RNG state serialization or pause/process scheduling APIs. Adapter compile, state-round-trip and pause tests remain mandatory; no runtime/specialist-independent sign-off claimed.
- Coupled Body/Needs and action/death edge ordering can change outcomes: retain pre-step snapshots here, require C4/C5 exact boundary tests before implementation; never silently adjust formulas to fit order.
- GDD sync: checked Time, Interaction and Mishaps after merging origin/main; consistent with updated Time Rule 8 and resolved QQ-08 (backpack continues simulation/actions, explicit pause stops both), with no renamed signal/payload interfaces.
- Autonomous calls: assumptions A (ordered staged clock versus independent timers versus bulk skip, ADR-0001 upstream, full Time plus Interaction/Mishaps event linkage, Proposed); separate design tabs chose carried real-second accumulator, synchronous stages/typed envelopes, one run RNG with restorable state and terminal gate. Write chose ADR only/pending GDD sync; registry chose append Proposed stances. Closing chose stop after the three requested ADRs, not automatic authoring of C1 or new design.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [time-and-day-cycle.md](../../design/gdd/time-and-day-cycle.md) | Full provisional TR-time-and-day-cycle-001 … TR-time-and-day-cycle-029, co-covered with F1; all rules, T1–T5, edge cases, dependencies and AC/performance | Single Clock, complete snapshot/signals, correct phase/day/cap, validated tables, rate arbitration, pause exclusion, ordered 120-tick catch-up and restoration boundary. QQ-08 owner exception checked consistent with updated Time Rule 8. |
| [interaction-and-timed-actions.md](../../design/gdd/interaction-and-timed-actions.md) | IA1/start-rate lock; Edge Cases: backpack/pause, immersion/cancel, no saved in-flight action; AC9/14/21 exactly-one use/roll/result, start-rate lock, forced-cancel | Separate action real time from game minutes; run/sequence envelopes and terminal/cancel gate; C4 retains complete Interaction TR coverage and transaction ownership. |
| [mishaps-and-failure.md](../../design/gdd/mishaps-and-failure.md) | Rule 10 seeded stream; Edge Cases arrival order, no-tool loss, unknown profiles, restore stream/guards; AC1/2/6/7/13 deterministic rolls and consequences | Run RNG adapter, stable draw order, seed plus state/position, no-profile/cancel exclusion, typed unrenamed action_outcome/fell_in_water; no new random calls for rejected requests. C4 owns full Mishaps rule/formula validation. |

## Performance Implications
- **CPU**: Time ≤0.02 ms/tick and all subscribers ≤0.5 ms/tick at sleep ≤20 ticks/s; profile 120-tick bursts separately. No lost minutes or formula retuning as a performance fix.
- **Memory**: Bound dispatch storage by processing each minute before the next; track elapsed debt rather than allocating one object per future minute; size event queues from measured traffic and reject stale events.
- **Load Time**: Validate Time table, seed and draw ordering before initial snapshot; later restored DTOs must validate before replacing a live run.
- **Network**: None; deterministic local replay is not a multiplayer commitment.

## Migration Plan
No production dispatcher exists. After acceptance, implement Clock with fake staged owners and deterministic adapter tests, then integrate consumers only after their ADRs are Accepted. Do not migrate prototypes or implement a save file format; retain a versionable DTO boundary for deferred Alpha work.

## Validation Criteria
- Run all Time AC1–20: day1 13:00 Day/normal; 90 real seconds→60 ordered ticks; day3 23:59→day4 midnight one reset; day1 nightfall17:15/day2 dawn07:48/sunrise08:33; sunrise_window edges; 10 real minutes pause→zero advancement; normal beats skip; wait during sleep warns; 12 sleeping hours→720 ticks including day3 sunrise08:36; 200-minute debt drains 120+80; cap holds day60 once.
- T1 days1/11/31/40→8/7/5/5 h; T2 day1 sunrise08:30/sunset16:30 and day31 10:00/15:00; invalid solar_noon=1 uses defaults. T3 normal Day1.5/Night1.0/wait0.25/sleep0.05; zero/negative rate rejects whole table. First nightfall382.5±1 real seconds; T5 day1 08:00/12:30/16:30/20:00→0/0.5/1/1. Retain T4 derived check, not a runtime timer.
- Time AC17–18 integration: Needs sleep assertion/rate request and normal alarm produce one mode change; midnight resets Morale caps. AC19 owner daylight/pacing playtest and AC20 day1/day31 dusk screenshot pair remain required evidence, not completed checks.
- Empty event queues/heat-source lists must be safe; duplicate/stale/unknown events follow owner reject/ignore policy without extra integration. Invalid RandomState must leave current state unchanged. Same seed/inputs plus state restore must reproduce next Mishaps roll (Mishaps AC6); unknown profile success/error and no-profile zero-roll behavior must remain unchanged (AC1/7).
- Stage trace must be identical across normal and skipped minutes; inject alarm during a 200-tick debt, confirm next minute no longer sleeps. Simultaneous death/collapse/immersion/completion must publish one terminal state and no interrupted use/roll/result (Interaction AC21); future C4/C5 tests must ratify exact checkpoints.
- Backpack during work must keep action/minutes advancing; explicit pause must stop both with no paused-time debt. Restore fractional accumulator/sleep plus Needs ownership without duplicate events. Measure Time/subscriber budgets and worst hitch on nominated hardware; no min-spec compliance claimed.

## Related
- [ADR-0001](adr-0001-run-scene-composition-and-service-lifecycle.md) upstream Proposed; [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md) input/pause ports Proposed.
- [Master architecture](architecture.md), Ordered minute path, Action transaction, Save/Load boundary, ADR Audit and F3/C4/C5; no permanent TR allocation/RTM generated.
- Acceptance route: `/architecture-decision accept ADR-0003`; all three Foundation ADRs remain Proposed, not implementation authorization.
