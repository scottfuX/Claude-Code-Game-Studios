# Control Manifest

> **Engine**: Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt / Forward+ desktop
> **Last Updated**: 2026-11-20
> **Manifest Version**: 2026-11-20
> **ADRs Covered**: ADR-0001..ADR-0016 and ADR-0018 (17 Accepted records; ADR-0017 remains Proposed)
> **Status**: Built from **Accepted ADRs ADR-0001..0016** — accepted by Scott (owner), 2026-11-19, “Accept all 16” — plus **ADR-0018**, accepted under Scott's explicit delegation for PR #28 on 2026-11-20. Regenerate with `/create-control-manifest update` whenever ADR rules change. Acceptance does not claim runtime validation or settle the open QQ defaults below.
> **Review**: TD-MANIFEST skipped — Lean mode.

**Companion nomenclature check:** compared against PR #9's changes to `architecture.md` and `tr-registry.yaml` without merging that branch. Camera uses ADR-0013's full `request_framing(...)`, `release_framing(id)`, `yaw_snapshot()`, `project_world(p) -> ProjectionResult{visible,viewport_point}` and `orientation_snapshot()`; Thermal uses ADR-0006's `ThermalComponents`, `register_heat_source`, `update_heat_source` and `unregister_heat_source`. The older architecture aliases are not the manifest's contracts. Sources: ADR-0006 and ADR-0013 §Decision (Key Interfaces).

Programmer rules compiled from the four prescribed ADR sections, project configuration, technical preferences and the pinned engine reference. This is not ADR acceptance or proof of implementation, performance, visual or platform verification. Sources below identify the record and section; the index supplies every ADR's title. Main decision rules retain their technical detail so numeric/formula and failure-path constraints are not lost in paraphrase.

**Owner update:** conflicts 1–4 from architecture-review-2026-11-18 are **decided**, per owner decision **2026-11-19**, as explicitly attributed below. Their GDD/ADR edits are in flight in another session; this manifest neither edits those records nor treats the old reconciliation text as a remaining decision. The dated owner update is later than this generation date.

## Source Index
| ADR | Title | Primary layer | Recorded status at extraction |
|---|---|---|---|
| [ADR-0001](adr-0001-run-scene-composition-and-service-lifecycle.md) | Run scene composition and service lifecycle | Foundation | Accepted |
| [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md) | Input routing, contexts and UI pause requests | Foundation | Accepted |
| [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Ordered clock dispatch, typed events and run randomness | Foundation | Accepted |
| [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md) | Authored map, Jolt terrain/snow grid and persistent trail representation | Core | Accepted |
| [ADR-0005](adr-0005-survivor-locomotion-humanoid-retargeting-and-animation-ik-layers.md) | Survivor locomotion, humanoid retargeting and animation/IK layers | Core | Accepted |
| [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md) | Thermal spatial queries and source registration | Core | Accepted |
| [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) | Timed-action transactions, seeded mishaps and simultaneous-death precedence | Core | Accepted |
| [ADR-0008](adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body/Needs minute integration, sleep and terminal candidate ports | Core | Accepted |
| [ADR-0009](adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) | Item/action data validation, inventory transfers and tool-use transactions | Core | Accepted |
| [ADR-0010](adr-0010-gathering-resolver-depletion-and-overflow-transactions.md) | Gathering resolver/depletion and overflow transactions | Feature | Accepted |
| [ADR-0011](adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) | Fire stage machine, material consumption and heat/light publication | Feature | Accepted |
| [ADR-0012](adr-0012-morale-event-ordering-strain-integration-and-relief-limits.md) | Morale event ordering, strain integration and relief limits | Feature | Accepted |
| [ADR-0013](adr-0013-camera-framing-arbitration-collision-and-projection-ports.md) | Camera framing arbitration, collision and projection ports | Presentation | Accepted |
| [ADR-0014](adr-0014-read-only-emotional-feedback-layers-and-warm-hue-safe-grade.md) | Read-only emotional feedback layers and warm-hue-safe grade | Presentation | Accepted |
| [ADR-0015](adr-0015-audio-buses-survivor-listener-and-prioritized-voice-pool.md) | Audio buses, survivor listener and prioritized voice pool | Presentation | Accepted |
| [ADR-0016](adr-0016-non-numeric-hud-and-mvp-inventory-facade-contracts.md) | Non-numeric HUD and MVP inventory facade contracts | Presentation | Accepted |
| [ADR-0018](adr-0018-shell-navigation-end-shot-and-run-checkpoint.md) | Shell navigation, end shot and run checkpoint | Foundation / Presentation | Accepted |

## Unresolved / Provisional Defaults
These question references are tracking context, not new decisions. All 17 covered ADR-derived designs are Accepted; the four separately attributed owner decisions are settled. The unresolved QQ defaults below remain provisional.
- **QQ-01**: final hardware, shipping resolution, numeric budgets and measurement policy remain open. Keep the legacy 60 fps/16.6 ms fallback; no global draw/memory number is adopted. Profiling Body and tightening Thermal is now decided, but a replacement numeric allocation is not supplied — source: ADR-0001 §Performance Implications; ADR-0006 §Performance Implications; ADR-0008 §Performance Implications; .claude/docs/technical-preferences.md §Performance Budgets.
- **QQ-02/03**: retain legally usable evaluation clips/audio and sparse silence-first mix; authorize no addon, purchase, composer or replacement triangle cap — source: ADR-0004 §Alternatives Considered; ADR-0005 §Decision; ADR-0014 §Decision; ADR-0015 §Performance Implications.
- **QQ-04**: retain current camera table/framing and require owner visual/playtest verification, not silent reframing — source: ADR-0013 §Decision (CA1–CA5).
- **QQ-05/06/07**: preserve all approved formulas, rates, finite resources and MVP boundaries; do not retune pressure, grant passive food/relief, enable sleeping-bag/snow-cooling bonuses, auto-gather or force a ring — source: ADR-0003; ADR-0004; ADR-0007; ADR-0008; ADR-0009; ADR-0010; ADR-0011; ADR-0012 §Decision.
- **QQ-09/10**: retain 35% calm band, qualitative minimal list and 100% MVP scale; settings/accessibility hooks and future mechanics do not authorize expanded MVP scope — source: ADR-0014; ADR-0015; ADR-0016 §Decision.
- **Engine applicability exclusions**: omit 2D TileMap/YSort/VisibilityNotifier2D/Navigation2D, touch/VirtualJoystick, mobile/visionOS, unchosen navigation and SoftBody systems, optional FBX importer/editor-import flags and editor addon-install workflows from runtime forbidden APIs. These are not requirements of the current 3D survivor game; revisit if that scope is introduced — source: project.yaml `engine.*`; .claude/docs/technical-preferences.md §Input & Platform; docs/engine-reference/godot/deprecated-apis.md; docs/engine-reference/godot/current-best-practices.md.
- **Engine verification**: exact native adapter signatures, Jolt collision/IK, render callback lifecycle, UI focus/stretch, audio masks and nominated-device measurements remain unverified unless separate retained evidence proves them — source: ADR-0001..ADR-0016 §Engine Compatibility. Their presence here is not a test result.

## Foundation Layer Rules

### Required Patterns
- Shell owns BOOT → TITLE → RUN(playing/paused) → END_SHOT → RESULTS → TITLE/new RUN and an injected, non-autoload SaveStore. `start_run(config)` accepts profile, seed and optional validated restore DTO; `stop_run(reason)` is idempotent; `return_to_title()` saves only live runs and tears down only after success. Failed CLI or menu starts remain on a localized retryable title screen, never a partially active run. Serialize commands and invalidate stale callbacks on teardown. — source: ADR-0018 §Decision (Key Interfaces, Implementation Guidelines).

- Checkpoint v1 uses one slot `user://saves/run_checkpoint.json` with profile, seed, timestamp and detached owner DTOs. Export on the main ownership boundary only when nonterminal and quiescent: sunrise after terminal arbitration, deferred during active work; manual save cancels work without outcome, item use or RNG draw. Never serialize action/transaction tokens, nodes or Resources. — source: ADR-0018 §Decision.

- Validate every field, schema, profile and required owner in isolated staged state before mount activation; preserve full RNG stream state/draw position, not seed alone. Clock, Body, Needs, Inventory, Fire, Gathering and survivor adapters are required; rebuild registrations and publish a complete initial snapshot before input/time. Enabled Shelter/snare/physical Terrain owners require adapters before Continue; only footprint/trail visuals and transient feedback explicitly reset. — source: ADR-0018 §Decision (Implementation Guidelines).

- SaveStore flushes/closes a temporary sibling and atomically replaces by rename without deleting the old slot first; ignore orphan temps. Write/rename errors preserve the prior slot. Invalid, unreadable or unsupported data quarantines uniquely as `.corrupt` and hides Continue; quarantine failure preserves evidence and warns. Manual failure retains paused Retry/Cancel recovery; autosave failure warns without freezing play. Terminal cancels pending save admission, deletes the slot before results navigation and blocks retry/title/quit behind Retry on deletion failure. OS kill/crash during failed invalidation is not one-life-safe. Verify platform overwrite/flush behavior; do not claim crash-proof durability. — source: ADR-0018 §Decision; §Engine Compatibility.

- Continue owns a fresh one-second loading pause gate with input Locked and no explicit pause menu; afterward release only that token and recompute retained UI/pause context. No SceneTree pause, cross-owner state mutation, timed-action replay or mutable Resource reuse. — source: ADR-0018 §Decision (Implementation Guidelines).

- Use a persistent application shell only to mount/unmount a run. Each run has a fresh RunCoordinator and run-owned InputRouter, Clock, RNG adapter, Core/Feature models and Presentation adapters. Gameplay state must not live in autoload singletons. Immutable authoring definitions may be reused; mutable state must be constructed per run. Pure rules can use value/model objects; engine-facing scene nodes remain adapters. — source: ADR-0001 §Decision.

- The Coordinator validates definitions using each GDD's reject/default policy, allocates a new run identity and seed, starts Clock gated and Input Locked, constructs Map/Terrain and fixed-kit Inventory, then Character/Thermal/Body/Needs, then ActionRunner/Mishaps/Gathering/Fire/Morale. It injects explicit narrow query/command ports, registers interactables, attaches Camera/Feedback/Audio/HUD and subscriptions, publishes a complete initial snapshot, then enables Gameplay and time last. Empty heat-source/interactable lists are valid; invalid required definitions must never produce a partly playable run. — source: ADR-0001 §Decision.

- Shutdown first gates input/time and invalidates the run generation, cancels in-flight work without completion side effects, disconnects tracked subscriptions and clears queues/registrations, then releases the subtree. Deferred node deletion must not leave a window in which stale events can mutate the replacement run. Restart repeats construction with new state; ADR-0018 now enables bounded checkpoint restore from validated DTOs at a quiescent boundary. — source: ADR-0001 §Decision; ADR-0018 §Decision.

- **Pinned-engine constraints**: None required; explicitly returned typed overrides and explicit dirty tracking must respect 4.7 semantics **Verify before treating the adapter as proven**: Compile lifecycle/typed signal adapters on the pin; verify process-mode/pause behavior, teardown during deferred deletion, restart isolation and snapshot alias safety — source: ADR-0001 §Engine Compatibility.

- InputRouter is the sole application raw-event reader and named-action sampler. Its engine adapter classifies InputEventKey/Mouse/Joypad types, resolves authored InputMap actions and publishes typed snapshots/edges. UI adapters consume routed `ui_*` actions and pointer intents; any built-in Control input bridge must be contained within this input boundary and must prevent duplicate delivery. Gameplay consumers must not poll Input directly. Native UI focus behavior must be proven in an adapter spike, not assumed from a diagram. — source: ADR-0002 §Decision.

- Validate each binding in its effective context, retaining the old binding and rejecting/logging the newer conflicting one. Gameplay/UI overlap is allowed only because they are exclusive; within UI, built-in navigation and closing actions must still have one meaning per event. Preserve all defaults, including C/right mouse cancel, Q/R turns and optional zoom. Apply IN1 once with default deadzone 0.2 and normalized diagonals; choose the larger-magnitude keyboard/gamepad move vector, while the most recent meaningful event selects glyph device. Drift under deadzone must not switch device. — source: ADR-0002 §Decision.

- InputRouter owns IN2 real-second timing: tap below 0.25 s, hold from 0.35 s, intermediate release ignored, irreversible confirm at 1.5 s with early-release cancellation. IN3 stores one press per interact/secondary/cancel action for 0.15 real seconds; newer replaces older, ready delivery consumes it once, expiry drops it. Zero buffer disables buffering. Validate timing ranges, deadzone <1 and hold_min_s ≥ tap_max_s before activation. Input timing remains real-time under sleep and pause; it does not imply gameplay timers run while explicitly paused. — source: ADR-0002 §Decision.

- UI requests context through a Coordinator port, with Locked taking precedence over UI, then Gameplay. The router alone applies transitions. Closing the top UI layer recomputes context from remaining layers, never blindly returns to Gameplay. Locked admits only pause_menu, except ADR-0018’s gated terminal confirm/interact skip; UI admits ui_*, backpack-close, pause/back and deferred radio. Each transition clears holds/buffers; a physical key still down must be released before re-press, not reclassified as a fresh press on close. — source: ADR-0002 §Decision.

- Backpack open requests UI only. It must never acquire a pause token, cancel active work or freeze ActionRunner's unpaused-real-second duration. The explicit pause menu requests UI plus a pause token; all simulation and action timers stop until released. Loading and active-gamepad-disconnect safety gates also stop simulation. Reconnecting the active pad leaves the reconnect prompt/pause active until deliberate resume; keyboard remains usable to recover. Inactive-pad disconnect does nothing. These safety gates are not new menu design or exceptions allowing arbitrary UI to pause. — source: ADR-0002 §Decision.

- **Pinned-engine constraints**: 4.7 input device semantics: identify event types, never assume keyboard/mouse device 0; 4.6 separate mouse versus keyboard/gamepad focus and SDL3 gamepad behavior **Verify before treating the adapter as proven**: Compile router and pause adapters on pin; exercise SDL3 disconnect/recovery on macOS/Windows, dual-focus, input while paused, suppression of held input across UI closure, and no double UI delivery — source: ADR-0002 §Engine Compatibility.

- Clock owns day, minute_of_day, derived hour/phase/sun data, rate_mode, fractional elapsed-real-second accumulator and owed work. It advances only through Coordinator's unpaused update, not physics frames, wall-clock dates or arbitrary Timers. Accumulate unpaused real delta, subtract the current T3 seconds-per-minute for each owed minute, then finish that minute's whole dispatch before another begins. Recompute rate/phase at each boundary rather than batch converting a hitch with one final rate. At 120 ticks stop processing and carry all remaining elapsed-time debt; a rate change applies at its next legal boundary, not retroactively to completed minutes. — source: ADR-0003 §Decision.

- Validate the entire Time table at startup: T1 daylight=max(d_min,d_start−d_shrink×(day−1)); T2 sunrise/sunset symmetric about solar_noon and twilight inside 0–24; T3 positive rates and GDD ranges; T4 is derived QA arithmetic, not another runtime clock; T5 clamped sun_progress. Bad tables are rejected/logged as a whole and replaced by approved defaults. Publish every GDD Clock value and keep exact signal names. On day cap, emit run_day_cap_reached once and hold day 60 23:59 without repeatedly consuming debt/emitting ticks; Coordinator receives the cap notification, Clock does not own Results. — source: ADR-0003 §Decision.

- At each minute boundary, apply queued rate requests (including a Needs sleep request before the first new-run interval), advance/derive the clock, then deliver boundary notifications/reset hooks at that minute before model integration. Normal beats wait/sleep with all reasons logged and one change notification; sleep can replace wait; wait during sleep is ignored with warning. A normal request raised inside a minute is honored before another owed minute, so a long catch-up cannot sleep past an alarm. Needs is_asleep is never written by Clock. — source: ADR-0003 §Decision.

- Coordinator alone invokes authoritative stages: capture pre-step movement/work and modifiers → Thermal inputs → Fire burn/source publication → Inventory drying → Body step → Needs step/wake → terminal arbitration → Morale ordered queue flush → complete snapshot/presentation publication. Each stage runs synchronously once; typed public signals notify observers but must never be a second simulation integration path. Day resets happen before the affected day's Morale integration; sunrise/nightfall reach consumers at their true boundaries even in sleep. The Body/Needs pre-step read boundary is subject to C5's full formula audit; F3 establishes scheduling, not unreviewed physiology changes. — source: ADR-0003 §Decision.

- ActionRunner uses unpaused real seconds with start-rate/start-modifier duration snapshots from Interaction IA1; it never uses the survival accumulator as an action timer. Coordinator processes same-update forced cancellation/terminal candidates before eligible completion commits: death wins over collapse/immersion; hypothermia wins dehydration ties; immersion cancels even non-cancellable work with no interrupted use/roll/result. C4 must specify the exact completion checkpoint and owning resolver transactions; do not assume this coarse frame description is enough to implement them. Once terminal is chosen, gate further simulation/completions, discard pending uncommitted work, publish one final snapshot/event and prohibit further RNG draws. Presentation may finish using real-time adapters without mutating the frozen simulation. — source: ADR-0003 §Decision.

- RunCoordinator owns the authoritative gameplay RNG adapter; Map placement and Mishaps receive a narrow draw port, not their own generators. Stable map initialization consumes draws before interactive attempts; same-frame attempts use stable accepted arrival sequence. No-profile actions and cancelled/interrupted work consume no Mishaps roll. Guard state belongs to Mishaps, RNG state to Coordinator. Mishaps' GDD promise to keep/export seed and stream position is satisfied by its injected view of that same run stream, not a second mutable copy; its save-facing output must still include that view plus its own guards. Snapshot seed, opaque generator state and draw position at a quiescent boundary; restoring a seed alone is insufficient. Cosmetics use a separate non-authoritative source. Same pinned-engine version/inputs/draw order must replay; cross-version binary/state compatibility is not promised, and later Save/Load must version/validate it. — source: ADR-0003 §Decision.

- **Pinned-engine constraints**: None required; typed-return overrides must explicitly return; packed-array mutation must explicitly mark dirty state in 4.7 **Verify before treating the adapter as proven**: Compile typed dispatch/DTO adapters; confirm SceneTree pause gate and RandomNumberGenerator seed/state restoration on 4.7.2. Reference library does not verify exact RNG serialization APIs or cross-version sequence stability. — source: ADR-0003 §Engine Compatibility.



- `start_run(config: RunConfig) -> Result`, `stop_run(reason: StringName) -> void` on RunCoordinator; repeated stop is harmless. — source: ADR-0001 §Decision (Key Interfaces).

- `configure(ports: OwnerPorts) -> Result` before activation; actual owner ports are narrow typed contracts, not a service-locator dictionary. — source: ADR-0001 §Decision (Key Interfaces).

- `snapshot() -> OwnerSnapshot`: detached value/ID data; nested collections must not alias live owner state. Read-only is a contract, not an assertion that GDScript objects are intrinsically immutable. — source: ADR-0001 §Decision (Key Interfaces).

- Every command/event/attempt envelope carries `run_id` and monotonic `sequence`; owner commits reject duplicate/stale tokens. Domain payload names remain those in the GDDs. — source: ADR-0001 §Decision (Key Interfaces).

- Subscription records retain producer, typed signal and Callable for deterministic disconnect; registration tokens are invalid after stop. F2 defines input/pause ports; F3 defines clock/dispatch/RNG ports. — source: ADR-0001 §Decision (Key Interfaces).

- Systems must receive dependencies explicitly and must never search the tree or autoloads for gameplay owners. — source: ADR-0001 §Decision (Implementation Guidelines).

- Only the owner must mutate its state; shared Resources must contain definitions, never per-run mutable stacks/timers/counters. — source: ADR-0001 §Decision (Implementation Guidelines).

- Initialization must finish wiring before input/time advances. Failed setup must clean up and stay Locked, with a logged error rather than fabricated data. — source: ADR-0001 §Decision (Implementation Guidelines).

- Stop/restart must invalidate identity before deferred callbacks or node deletion. Snapshots must be copied at mutable-container boundaries; packed-array edits must explicitly mark dirty state in 4.7. — source: ADR-0001 §Decision (Implementation Guidelines).

- Input context must not be used as a proxy for pause. Subscription order must never determine simulation causality; F3 owns dispatch ordering. — source: ADR-0001 §Decision (Implementation Guidelines).

- `sample_actions(real_delta_s: float) -> InputSnapshot`, `set_context(context: InputContext) -> void` retain architecture names; snapshot contains move_vector, move_hurry, named press/release/classification/held_seconds, active_device and run/sequence identity. — source: ADR-0002 §Decision (Key Interfaces).

- `device_changed(active_device: StringName)` and `active_gamepad_disconnected()` are typed notifications; UI glyphs consume the former, Coordinator handles recovery on the latter. — source: ADR-0002 §Decision (Key Interfaces).

- `request_ui_context(source: StringName, open: bool) -> void` is an idempotent Coordinator command; tracked sources must be cleared on teardown. — source: ADR-0002 §Decision (Key Interfaces).

- `request_pause(source: StringName) -> PauseToken`, `release_pause(token: PauseToken) -> void` are Coordinator ports; source/run-tagged tokens prevent one overlay releasing another's pause. Backpack is forbidden as a pause source. — source: ADR-0002 §Decision (Key Interfaces).

- Binding validation returns a Result/reason, preserves the accepted table on conflict and logs the rejected binding. All existing GDD action and field names are preserved; these Coordinator ports are new internal interfaces, not renames. — source: ADR-0002 §Decision (Key Interfaces).

- Input must use named authored actions; gameplay/UI scripts must never read raw keycodes/buttons/axes or bypass InputRouter. — source: ADR-0002 §Decision (Implementation Guidelines).

- Router must process real timing while paused; simulation/ActionRunner must use a separate pause gate. Process-mode wiring must not let an always-running input parent accidentally unpause gameplay children. — source: ADR-0002 §Decision (Implementation Guidelines).

- Context transitions must clear state and suppress held-until-release actions; buffer delivery must be once-only and run-scoped. — source: ADR-0002 §Decision (Implementation Guidelines).

- UI must never call SceneTree pause directly; only Coordinator may apply pause policy. Backpack must leave clock and in-progress work running, even while gameplay input is blocked. — source: ADR-0002 §Decision (Implementation Guidelines).

- Active device must be selected by meaningful event type/time, never device==0; UI focus and glyphs must support mouse and keyboard/gamepad independently. — source: ADR-0002 §Decision (Implementation Guidelines).

- `request_rate_mode(mode: StringName, reason: StringName) -> void`, `snapshot() -> ClockSnapshot` preserve GDD/architecture names. Snapshot includes day/hour/minute_of_day/phase/is_night/sunrise_window/daylight_hours/sunrise_hour/sunset_hour/sun_progress/rate_mode. — source: ADR-0003 §Decision (Key Interfaces).

- GDD notifications stay `minute_tick`, `hour_changed(hour)`, `day_changed(day)`, `phase_changed(phase)`, `nightfall`, `sunrise`, `rate_mode_changed(mode)`, `run_day_cap_reached`; do not rename them to fit envelope terminology or add required arguments to existing no-argument signals. — source: ADR-0003 §Decision (Key Interfaces).

- Coordinator's internal `step_minute(context: MinuteContext) -> void` owner ports carry run_id, sequence, clock snapshot and immutable pre-step activity/modifiers. They are distinct from public minute_tick; consumers must never integrate via both. — source: ADR-0003 §Decision (Key Interfaces).

- `enqueue_event(event: RunEvent) -> Result`: typed envelope with run_id, sequence, minute, kind and domain-specific payload. Keep GDD payload fields such as action_outcome{action_type, success, cause, severity, tag, base_fail_chance} and fell_in_water; reject stale/duplicate envelopes, warn/ignore unknown IDs according to their owning GDD. — source: ADR-0003 §Decision (Key Interfaces).

- `draw_unit(request: RandomDrawRequest) -> RandomDrawResult`, `export_random_state() -> RandomState`, `restore_random_state(state: RandomState) -> Result`: application adapter ports, not asserted Godot method signatures. DrawResult explicitly represents rejection for stale/terminal requests. RandomState includes seed/state/draw_count/engine pin; restore validates before changing live state. — source: ADR-0003 §Decision (Key Interfaces).

- Clock must be the only survival clock; owners must integrate exactly once per ordered minute, even during skips. Input/feedback real-time timers must never advance survival state. — source: ADR-0003 §Decision (Implementation Guidelines).

- Coordinator must call fixed stages directly; signal connection order, node order and deferred calls must never determine authoritative causal order. — source: ADR-0003 §Decision (Implementation Guidelines).

- Same-minute Morale events must apply losses → failures → successes → comforts → deferred rival/medical, then rates/derived state once; preserve domain priority in addition to envelope sequence. — source: ADR-0003 §Decision (Implementation Guidelines).

- Pause must add no paused wall-time debt, emit no ticks and freeze action timers; existing unprocessed debt remains gated until resume. Backpack must not activate that gate. Normal requests must be reconsidered before the next catch-up minute. — source: ADR-0003 §Decision (Implementation Guidelines).

- Every event/transaction must validate run identity and once-only sequence. RNG must never be consumed by cosmetics, rejected requests or cancelled attempts. Restore must be atomic on invalid data. — source: ADR-0003 §Decision (Implementation Guidelines).

### Forbidden Approaches
- Never use **Gameplay autoload service singletons** as the implementation baseline — Run lifetime and owner boundaries cannot be guaranteed by scene replacement alone. — source: ADR-0001 §Alternatives Considered.

- Never use **Self-wiring nodes using tree discovery** as the implementation baseline — A complete initial snapshot and reproducible restart require explicit ordered construction. — source: ADR-0001 §Alternatives Considered.

- Never use **Per-screen unhandled-input handlers** as the implementation baseline — Sole raw ownership and release/buffer invariants need one auditable boundary. — source: ADR-0002 §Alternatives Considered.

- Never use **Automatically pause whenever context is UI** as the implementation baseline — Contradicts Scott's QQ-08 decision and Interaction's backpack edge case. — source: ADR-0002 §Alternatives Considered.

- Never use **Independent owner timers and signal-order dispatch** as the implementation baseline — Cannot guarantee exactly-once staged integration or same-minute terminal priority. — source: ADR-0003 §Alternatives Considered.

- Never use **Bulk skip plus independent seeded RNGs** as the implementation baseline — Approved per-minute events and reproducible Mishaps sequence take precedence over shortcut performance. — source: ADR-0003 §Alternatives Considered.

### Performance Guardrails
- **CPU**: No per-frame service discovery; measure composition and snapshot cost. Time's ≤0.02 ms/tick, combined subscribers ≤0.5 ms/tick and Input ≤0.05 ms/frame remain GDD obligations, not measured results. — source: ADR-0001 §Performance Implications.

- **Memory**: Fresh models and snapshots add bounded live-state copies; verify no growth across restarts. Final device/memory budgets await QQ-01. — source: ADR-0001 §Performance Implications.

- **Load Time**: Validation and wiring occur before first publication; measure startup on owner-nominated devices, no invented loading-time budget. — source: ADR-0001 §Performance Implications.

- **CPU**: Input ≤0.05 ms/frame and next-rendered-frame movement ≤16.6 ms are GDD obligations; measure, not claimed achieved. No repeated binding-table validation in hot path. — source: ADR-0002 §Performance Implications.

- **Memory**: One hold/buffer record per named action and tracked UI/pause sources, cleared per run; no unbounded raw-event history. — source: ADR-0002 §Performance Implications.

- **Load Time**: Validate bindings before Gameplay activation; invalid new bindings cannot corrupt the accepted table. — source: ADR-0002 §Performance Implications.

- **CPU**: Time ≤0.02 ms/tick and all subscribers ≤0.5 ms/tick at sleep ≤20 ticks/s; profile 120-tick bursts separately. No lost minutes or formula retuning as a performance fix. — source: ADR-0003 §Performance Implications.

- **Memory**: Bound dispatch storage by processing each minute before the next; track elapsed debt rather than allocating one object per future minute; size event queues from measured traffic and reject stale events. — source: ADR-0003 §Performance Implications.

- **Load Time**: Validate Time table, seed and draw ordering before initial snapshot; later restored DTOs must validate before replacing a live run. — source: ADR-0003 §Performance Implications.

---

## Core Layer Rules

### Required Patterns
- WorldMap owns immutable authored height/zone/bounds data and mutable node identities/remaining yields. TerrainSurface owns the runtime surface grid, compaction/cooldown state, broken ice and footprint records. Construct a built-in heightmap mesh with flat per-face normals and a HeightMapShape3D Jolt collision adapter; static ground height is unchanged at runtime. Snow sink is a visual/body offset, not runtime digging or moving the collision surface. Exact engine adapter compatibility remains subject to the spike. — source: ADR-0004 §Decision.

- Use packed structure-of-arrays storage for the 480 × 480 surface cells: type, depth, compaction, ice thickness/broken state and per-cell pass time. Derive effective depth, sink, type/depth/slope multipliers and wading rather than duplicating cached truth. A preliminary layout of one byte type, four float32 fields and one byte broken flag would be 18 bytes/cell (4,147,200 payload bytes); this is an estimate only, excludes runtime overhead/height/marks/renderer buffers, and is not a measured ≤8 MB result. Spike must report each category separately and the complete surface allocation. Float precision and time storage must preserve cooldown semantics over the intended run. — source: ADR-0004 §Decision.

- Preserve `surface_at(p)` with a default grade argument for directional TS4 queries; grade along travel, not merely slope magnitude, blocks >35° uphill while contour travel remains possible. Sample normal/height from the same authored triangles as collision. TS1 depth×(1−compaction), TS2 min(depth,sink cap)×type sink, TS3/4 floors and TS5 product stay unchanged. Character alone applies final movement modifiers/floor and sends activity; moving at effective depth ≥0.25 m is wading, standing still is not. — source: ADR-0004 §Decision.

- For an accepted foot contact, sample pre-stamp surface/sink once, collect every covered cell within the foot radius (~0.15 m), update eligible compaction with TS7 at most once/cell per 5 real seconds, and append a unique mark storing original position/foot/sink/time. Publish the contact sample to Audio/Mishaps and mark modified render regions explicitly. Duplicate run/sequence contacts and stationary shuffling must not restamp. Subsequent queries see new compaction; repeated read-only queries never mutate it. Crawling uses drag marks through the same boundary. Terrain reports thin ice; only a validated Mishaps command breaks a cell, after which it reports open water. Nearest shore escape comes from Map/Character, not Terrain movement code. — source: ADR-0004 §Decision.

- Keep authoritative marks for the whole run; render them through chunked dirty-region world-space trail textures/mesh updates with near-camera snow displacement as the selected adapter. Distant chunks may change rendering LOD/cull draw work but must never evict gameplay grid/mark history; re-entering restores the same marks. No decal-per-mark node population is authoritative. Precision, geometry, upload strategy and camera readability must be established by the spike before this adapter is treated as production-proven. — source: ADR-0004 §Decision.

- WorldMap resolves overlapping zones using lake > drift field > lee > forest > open snow > scoured ridge; cells use their centre's zone. Seeded scatter uses the injected run RNG in fixed ring/kind/node/retry order, MR1 count variation and MR2 at most 30 placement retries. Force the drop-facing 20–30 m deadfall and second near-ring deadfall first; guarantee three authored safe lee camp sites. Stable node IDs distinguish saved remaining yields from rerolled placement. Empty nodes remain visible but non-actionable; no MVP regrowth. Gathering commits an idempotent successful depletion request to WorldMap; failures never deplete. No nodes/sites on ice, >0.6 m drift or >20° slope. Authoring validation must report impossible guaranteed placement rather than silently start a run missing required safety content. — source: ADR-0004 §Decision.

- **Pinned-engine constraints**: Jolt default since 4.6 does not change an existing project's selection; 4.7 packed-array element edits require explicit dirty tracking. No new 4.7 rendering feature required. **Verify before treating the adapter as proven**: HeightMapShape3D/mesh alignment and scaling on Jolt; collision masks/ray samples; snow displacement/trail upload adapters and exact signatures; memory/query/render/collision spike on nominated hardware — source: ADR-0004 §Engine Compatibility.

- Use CharacterBody3D in `_physics_process` with explicit velocity, gravity and move_and_slide; propose a downward-floor probe and bounded preflight step-up adapter for the 0.3 m step requirement (not a claimed native automatic stair property). Capsule is radius0.3 m/height1.75 m. No jumping. Collision root remains on static ground; visual rig alone applies smoothed −sink_m (C6, 0.15 s). — source: ADR-0005 §Decision.

- Compute travel grade C2 from horizontal intended direction and Terrain normal; near-vertical normals are impassable. Query leading-foot cell for speed and block uphill >35° while projecting motion along contour; collision displacement onto an unwalkable slope slides down safely without damage. Target is base_walk1.4 × max(0.15, terrain×Body×Needs×carry×hurry). In Critical use base_crawl0.35 and omit Body0.40, not both penalties. Apply C3 acceleration/turning; starting movement is never delayed beyond one input frame. Hurry1.3 only Cold-or-better, not Exhausted, not hauling; disallowed hurry changes neither speed nor activity. — source: ADR-0005 §Decision.

- Each physics frame supplies one movement activity per C4: idle below0.1 m/s; heavy when moving/hurrying or hauling; otherwise wade when effective depth≥0.25 m, else walk. ActionRunner supplies work separately; Body/Needs select their own maximum at the Clock barrier. Sample load/Body/Needs once for the frame. No physics movement/footfalls during sleep skip, explicit pause or run end. Backpack UI removes gameplay input but simulation/action timers continue per Scott's QQ-08; it is not a pause request. — source: ADR-0005 §Decision.

- Retarget legally approved clips to SkeletonProfileHumanoid on one ≤30-bone skeleton and one LOD. Use priority full-body overrides (terminal beats collapse/sleep/crawl), action layer, locomotion, additive overlays; posture precedence Body→Needs→Morale. AnimationTree/AnimationMixer and explicit bone masks implement layers; BoneAttachment3D attaches held tools. SkeletonModifier3D/TwoBoneIK foot placement runs after base pose with contacts against the compacted snow surface, avoiding double sink. Exact modifier/API/mask setup is a spike gate, not assumed from model memory. Input cancels failure beats ≤1.2 s; Critical enters crawl within0.8 s; leaving crawl/collapse gates control behind ≥0.8 s get-up. — source: ADR-0005 §Decision.

- Foot contacts originate in animation method tracks at C5 cadence, alternating left/right, but pass a single authoritative adapter per run/sequence/contact. Capture the actual foot's surface and pre-stamp sink; Terrain stamps once, and Audio/Mishaps consume that same sample (ADR-0004). No separate physics timer duplicates a method-track step. Crawling sends drag marks; tiny motion/idle/sleep cannot emit stamps. Cosmetic pose callbacks are never commands to grant a result or consume a tool. Missing Tier B clips fall back to nearest Tier A with warning; missing required Tier A is a content validation failure, not a hidden scope cut. — source: ADR-0005 §Decision.

- `play_action(action_id, duration_s)` maps ActionRunner's real-time duration to C7 whole effort loops, with playback clamped0.85–1.15. Intro/outro and actual effort remainder must fit the authoritative deadline: C7's rounded/clamped loop estimate is a pose schedule, not permission to extend the action. Safely trim/blend effort at the deadline when exact fit is impossible; reject malformed zero/negative segments and use a logged fallback pose. Result animation waits for C4 arbitration; move-cancel uses the GDD2× outro. Full-body/terminal override invalidates pending cosmetic callbacks. — source: ADR-0005 §Decision.

- **Pinned-engine constraints**: 4.6+ SkeletonModifier3D/TwoBoneIK architecture; AnimationTree via AnimationMixer.active; skeleton_updated rather than deprecated bone_pose_updated. Exact IK class/properties require pinned-engine verification. **Verify before treating the adapter as proven**: Jolt step/floor/slide behavior; TwoBoneIK modifier ordering, targets and masks; import/retarget profiles and loop method-track cadence; no engine run performed here — source: ADR-0005 §Engine Compatibility.

- ThermalField owns the thermal table, minute air/wind inputs and source registries, not source heat/radius design. Compile authored Map zone polygons into a coarse uniform XZ index (selected 10 m cells) covering polygon bounds expanded by the5 m blend. At query, obtain candidates then evaluate exact containment and boundary distances; index cells never quantize felt temperature. Stable zone IDs break exact geometry ties, and Map's zone precedence remains authoritative for discrete terrain surfaces. — source: ADR-0006 §Decision.

- Represent the zone transition as a shared5 m linear boundary band: a point2.5 m through the specified forest/open blend gets equal weights. For a two-zone band use weights1−t,t; at multi-zone junctions use nonnegative distance-band weights for every participating zone then normalize once in stable ID order. Validate band endpoints/midpoint, corners and continuity against the GDD before production wiring; do not substitute nearest-zone selection or an inverse-distance curve. Export the same weights for audio beds. No-zone fallback is open snow offset0/exposure0.8; preserve all six zone values including drift0/0.6 and ridge0/1.0. Band geometry at junctions is an explicit authoring/adapter verification item, not a claim that the GDD specifies a unique triangulation. — source: ADR-0006 §Decision.

- Sources are copied value records keyed by stable owner/run/source ID: position, heat_c, radius_m, enabled plus revision. Selected coarse source bins cover the source radius AABB; exact Euclidean distance and strict d<radius decide TH4. Process candidate sources in stable ID order for reproducible float accumulation. Reject nonfinite position/heat/radius, radius≤0 and negative heat with error; an invalid update disables that ID until a valid update so bad source data contributes no heat. heat0 disables but retains the record; relight re-enables; unregister removes. Stale-run/revision commands cannot resurrect removed sources; teardown clears all registrations. — source: ADR-0006 §Decision.

- Preserve formulas exactly: TH1 max(t_floor,t_start−t_ramp×(day−1)); TH2 daily mean+t_swing×cos(2π×(hour−(solar_noon+peak_lag))/24)+weather_offset, noon=(sunrise+sunset)/2; TH3 min(chill_cap,k_wind×wind_speed×exposure_eff); TH4 source_heat×(1−(d/radius)²)×reflect strictly inside radius; cap sum at heat_cap30; TH5 air+zone−wind_chill+heat+shelter_bonus. components must agree with that same query's total. Registry/model queries are pure, with no RNG, cache warming side effects or per-point history. — source: ADR-0006 §Decision.

- At each Coordinator minute: establish Clock-derived TH1/TH2/weather/wind → Fire samples this minute's wind and burns → Fire publishes every changed heat/radius/enabled record synchronously → seal Thermal source revision → Inventory/Body query that minute's updated view. Fire.warm_radius is exactly its registered radius_m; Morale reads Fire's port, not Thermal. A source extinguished this minute contributes0 to this minute's Body step, never yesterday's heat. Normal real-time action changes publish atomically before subsequent readers/completion checkpoints. Sleep executes every minute, not final-time bulk evaluation; restore owners re-register before the first minute. — source: ADR-0006 §Decision.

- Reserve typed Weather/Shelter registration ports without implementing deferred features. Inside multiple shelters take minimum exposure override and maximum bonus, never additive stacking; the responsible shelter's reflection applies to eligible inside/opening sources with stable ties, not multiplying all volumes. Weather owns offsets; absent weather uses wind_base3. Unregistering weather transitions wind to base over10 game minutes. Reject an invalid thermal table (including floor>start, negative swing or chill_cap≤0), log and install whole approved defaults before activation. Future volume/reflection adapters must pass the GDD overlap rules before enabling that scope. — source: ADR-0006 §Decision.

- **Pinned-engine constraints**: None required by model; typed records/arrays and geometry adapters, not 4.7 physics callbacks **Verify before treating the adapter as proven**: Pinned-engine polygon/distance adapters, deterministic boundary ties, packed-array explicit dirty handling if used, same-minute source barrier and query cost — source: ADR-0006 §Engine Compatibility.

- ActionRunner owns action state and one live token `(run_id, action_sequence, attempt_sequence, target_id, target_revision)`. Lifecycle is Free→Working/Attempting/Continuous or Refused→eligible/prepared→committed OR cancelled; completed/cancelled tokens can never reopen. Target owners retain kept progress, not an unsaved action coroutine. Repeats get a fresh attempt sequence each time, obey IA4 and the sole Input buffer;3 real seconds without taps returns Free. Instant actions use the same admission/commit gate without elapsed work. — source: ADR-0007 §Decision.

- Use registered interactable action lists and IA2 within1.5 m/±50°: d/reach+0.5×|angle|/cone−kind bonus (fire0.3), current-target hysteresis0.15; ties keep current else nearer then stable ID. snow_ground is fallback only with no candidate on snow. Empty/no available actions clears prompts. At start validate target availability/revision, current range, required backpack tool, Body allowed_actions and Needs heavy permission. Refuse diegetically for1.5 s; reject invalid action IDs/table fields before activation according to owning GDD defaults. No action queue beyond Input's one buffered press. — source: ADR-0007 §Decision.

- Snapshot IA1 start Time rate and Morale×Body×Needs duration product capped2.0. Advance unpaused real seconds; progress uses dt_real/start_seconds_per_game_minute divided by snapshotted game_minutes (IA3). Changing night/rate/stage never retroactively stretches an in-flight duration. Resume uses target fraction with a new current duration. Work activity is reported while working; `is_idle` requires≥2 real seconds without movement and no action or counts_as_idle; rest requires burning Fire warm_radius, requests wait and returns normal on stop/fire out. Needs/Clock arbitrate sleep/normal, never Interaction writing is_asleep. — source: ADR-0007 §Decision.

- Coordinator's explicit update checkpoint is: sample input/contacts → ingest external owner changes and force-cancel notifications → finish each admitted ordered minute through Body/Needs candidate collection → arbitrate terminal/forced state → revalidate eligible completions → commit → publish. At most120 minutes are admitted in a frame by F3; if survival debt still precedes the checkpoint, hold an eligible completion until that debt is resolved, rather than commit against unprocessed fatal state. Checkpoint ordering must be reproducible at the same input/update sequence; it is not a promise of frame-rate-independent continuous physics replay. Never implement completion from Timer timeout, clip-finished or public minute_tick callbacks. — source: ADR-0007 §Decision.

- Force-cancel on collapse, forbidden Critical entry, immersion, missing target, external tool break/loss or run end, even when non-cancellable; player move/cancel obeys cancellable. Immersion cancels critical_allowed work too, stores target progress if progress_kept, gives Character In-water control and sends NO interrupted result, Inventory use or action Mishaps roll. Target disappearance discards progress. Cancellation wins a same-checkpoint completion tie. Death beats collapse and immersion animation/control; hypothermia beats dehydration when both death candidates exist in that checkpoint. Coordinator chooses exactly one terminal event/run, freezes future survival/completion/RNG and ignores later terminal/collapse callbacks. Ice's own world roll is not an interrupted action roll. — source: ADR-0007 §Decision.

- After revalidation, prepare detached revision-checked plans from Inventory and the resolver, including both profile success/failure consequences, output fit/overflow and all required resources. No owner mutates during prepare. Commit in one synchronous non-yielding section with owner events queued until the whole transaction ends: one tool use → one profile roll if applicable → once-only owner result/consequence commits → notifications. Plans must guarantee post-validation commits cannot refuse; no arbitrary callbacks run inside. A tool broken by THIS authorized use/failure does not cancel its own accepted outcome: current result stands, next start fails. External loss before checkpoint cancels. Distinct consequence IDs prevent duplicate durability/loss/soak/depletion under event redelivery. A failed preflight consumes neither use nor RNG. Unexpected commit invariant failure gates the run with a diagnostic instead of retrying/rerolling; implementation must prove this cannot occur under admitted valid input. — source: ADR-0007 §Decision.

- MishapResolver owns profiles and per-action fumble guards, not another RNG or inventory. M1 sums base+damp+wind+tinder+Morale+Body+Needs, clamp[0,0.90]. M2 picks only physical terms≥0.05; ties damp>wind>cold_hands>fatigue>tinder, else fumble, never Morale. M3 after4 fumble failures halves the next fumble-dominated chance; success clears, physical non-fumble failures never arm it. Preserve all seven profiles and their exact on_fail owner requests, including partial-yield profiles rather than treating every failure as zero yield. Sample completion-time conditions once for the accepted attempt. Profile absent means success/no roll/no action_outcome; unknown ID logs error/cannot-fail/no invented chance; a valid base0 profile still has one attempt roll and reports its trivial success. Missing nonwettable material damp0; missing Thermal wind0+warning. — source: ADR-0007 §Decision.

- Draw order: Map initialization first (F3); then stable accepted contact/attempt arrival sequence. For one eligible action exactly one M1 uniform, even at cap/base0; no-profile/cancelled/stale work draws none. Ice uses M4 only on unbroken ice footfalls thinner than15 cm; safe ice/open water/no contact draws none. On a break, request Terrain break, Body wetness1, Inventory soak, Character nearest-shore escape and major helplessness Morale event; if carried tools exist draw loss-test0.10, and only on loss draw one weighted existing-tool choice hatchet:knife:rod2:1:1. No tools means no loss-test/selection draws. Same-frame arrivals have explicit sequence; never Dictionary iteration order. M4 and invalid t_safe rejection remain unchanged. — source: ADR-0007 §Decision.

- Enqueue a cause cue before the outcome/result cue for a failed profiled attempt; consumers must present/read the cause before the result lands, using staged presentation if needed without delaying or blocking committed simulation. Morale receives exactly one `action_outcome{action_type,success,cause,severity,tag,base_fail_chance=profile.base_fail}` through F3's ordered flush. The run RNG snapshot includes seed+opaque state+draw position/engine pin plus separate guard state; restore all at one validated quiescent boundary, not seed-only. Save/Load remains deferred and action-in-flight is not saved; load Free with kept target progress only. — source: ADR-0007 §Decision.

- **Pinned-engine constraints**: None required by transaction model; uses F3 run-RNG adapter, not version-portable RNG internals **Verify before treating the adapter as proven**: Same-frame input/physics/minute checkpoint ordering, reentrant signal rejection, RNG state restore on pinned engine, callback invalidation and cause-before-result visual ordering — source: ADR-0007 §Engine Compatibility.

- At each minute take a detached `MinuteStart`: player position, movement activity, work intensity, sleep state, rest/fire context, Body core/wetness/stage, Needs stomach/weight/hydration/energy/stages/timers and fixed insulation. No substep reads state changed later in that same substep. Clock has advanced that minute and Thermal/Fire/Inventory have completed their F3/C3 stages before Body. Body queries one felt temperature at captured position, using this minute's published Fire sources; missing movement/work defaults to idle/none. — source: ADR-0008 §Decision.

- Activity is NOT one shared enum maximum: map movement/work to each system's own numeric table then take max. Body heat idle0/walk0.3/wade0.45/light0.3/heavy0.6; Needs calorie extra0/60/120/80/200, energy rate1/2/3.5/2.5/5. The wade-versus-light ordering differs between tables; never impose enum order. Hydration uses1.5 multiplier for wade OR heavy, not additive. Sleep's captured state suppresses all movement/work extras and treats Body activity as idle for the completed interval. — source: ADR-0008 §Decision.

- Body B1 uses captured core, wetness and shiver from the captured stage: gap=felt−5; negative exchange0.088×gap×(1+wetness)/insulation, positive0.3×gap; add highest activity and0.3 shiver only Chilled/Cold; clamp[−4,+3]°C/h, positive rate0 when core≥37. Integrate rate/60 and clamp core≤37; a death crossing clamps exactly30. B2 integrates wetness from the SAME pre-step wetness independently: moving wade gain0.03/h, dry0.6/h at felt≥10 or0.1/h at felt≥0, otherwise0; clamp[0,1]. Immersion sets wetness1 immediately before the next captured boundary, idempotent by event ID; never double-soak. Thus minute drying does not retroactively change B1's rate. — source: ADR-0008 §Decision.

- Derive post-step Body stage via B3/B4: ordinary changes at most one stage/minute, falling36.5/35.5/34/32 and rising threshold+0.2, one notification per transition; terminal core≤30 bypasses ordinary stage-step delay and submits hypothermia candidate immediately. Post-Body `is_shivering` and stage are the explicit inputs to Needs N1/N4 for THIS minute. A Warm→Chilled crossing uses no shiver heat in that completed B1 interval but starts its post-Body shiver charge in Needs; a Cold→Hypothermic crossing stops that charge. This is an Accepted discrete integration convention to verify with cross-boundary fixtures, not a retuning of rates. — source: ADR-0008 §Decision.

- Needs N1–N4 compute from captured sleep/rest/activity and captured fullness/stages, with post-Body shiver/stage: burn=(awake110/asleep65)+max(activity extra)+shiver80; consume pre-step stomach first and lower weight by shortfall/7700, floor40 kg with warning, never gain. N3 drain awake1.4/asleep0.7 ×1.5 for wade/heavy, integrate/60 and clamp hydration[0,100]. N4 sleep8×q_warm[post-Body stage]×q_food[captured fullness], q_warm1/0.7/0.4/0.2/0 and q_food0.5+0.5×min(1,fullness/50); awake fire-rest in wait+1.5, otherwise negative(max activity energy+shiver1.5)×thirst1.2×starve1.2 when applicable. Compute N5 from post-burn weight, cap=max(60,100×(1−2×lost_fraction)); integrate energy then clamp[0,new cap]. N6 derives endpoint need stages, at most one ordinary step per machine/minute, rising hysteresis+2, preserving exact0 hydration and24 h empty rules. Immediate eating leaves Empty/Starving as the GDD requires. — source: ADR-0008 §Decision.

- Dehydration grace measures accumulated game minutes continuously at hydration0, including sleep/wait; on a minute crossing from positive to0 begin the grace at that endpoint, not count a full earlier zero minute. Already-zero intervals accumulate1 minute; exactly360 elapsed zero minutes submits one dehydration candidate. Any accepted drink/snow resets grace. Fullness-zero timer likewise begins at the empty endpoint and reaches Starving at1440 minutes; any food resets immediately. Keep integer minute counters plus event-boundary metadata where needed rather than real wall time. Rejected/cancelled consumption never resets timers. C4's checkpoint ordering means a fatal boundary wins over a simultaneously eligible but uncommitted drink. — source: ADR-0008 §Decision.

- After numeric integration, Needs alone reconciles sleep endpoints. Chosen sleep allowed energy<90 at night/<50 by day; set is_asleep and request sleep. Awake energy0 proposes collapse/asleep(exhaustion), cancels action per C4. Body worsening while asleep/waiting requests normal and emits wake_request(cold) once/stage step; sleeping at Cold-or-worse must not remain trapped after a collapse. Reconcile a new collapse in that cold context with one forced cold wake and energy floor5, not an infinite same-minute collapse/wake loop. Natural cap wake, explicit normal and all wake causes coalesce into one wake, log every cause. Forced wake from collapsed sleep floors energy≥5; no extra energy from duplicate wakes. Wake endpoint affects the NEXT interval's sleep/activity rates, not a second integration of the current minute. — source: ADR-0008 §Decision.

- Needs clears is_asleep on any wake/Clock normal; Clock never writes it. End-of-minute mode priority follows F3: normal beats sleep/wait; sleep beats wait; wait while asleep warns/ignored. Apply resulting mode before processing another owed minute, including the120-tick catch-up loop. Echoed normal notifications are idempotent and cannot trigger an endless request loop. Fire's actual GDD supplies no low-fire wake alarm; Needs' optional wake port is reserved, not enabled scope. User may choose sleep only through the accepted Interaction handoff, not direct UI state mutation. — source: ADR-0008 §Decision.

- Body and Needs submit candidate records to Coordinator; public `body_died`/`needs_died` are final winning-cause notifications, not two competing terminal transitions. At the barrier C4 chooses hypothermia>dehydration and death>collapse/immersion, emits exactly one final event/run and gates future ticks/commits/draws. Suppress losing collapse/wake presentation if terminal won. Nonfatal Critical entry cancels non-whitelisted work; whitelist is crawl/add_fuel/blow_embers/sit_warm/drop, with fire reach still required. Tap-out remains an unblocked reserved VS capability, not new MVP UI. Critical excludes eat_snow: retain the Body/Interaction whitelist; snow remains available in Hypothermic, not Critical. — source: ADR-0008 §Decision; owner decision 2026-11-19, architecture-review-2026-11-18 conflict 1 (decided).

- Eating/drinking/snow use C4 prepared owner commits with Inventory: reject missing food/drink fields (no invented values), stomach overflow>1500 keeps item, accepted food adds kcal/reset timer and Inventory consumes once. Snow adds3 hydration/costs1 energy/takes3 game minutes, with no instant core cooling. Exhausted forbids heavy, not light. Needs publishes distinct `needs_move_speed_mult`, body move_speed_mult stays Body-owned. Restore core/wetness/stage exactly without stage_changed and restore Needs timers/asleep; queue sleep mode before first restored interval, with normal interruption still taking precedence. Deferred save implementation remains out of scope. — source: ADR-0008 §Decision.

- **Pinned-engine constraints**: None required; explicit typed GDScript value models and direct calls, not Timer-rate integration **Verify before treating the adapter as proven**: Exactly-once dispatch through sleep/catch-up, typed signals/adapters on pinned engine, detached snapshot isolation and pre/post-step numeric fixtures — source: ADR-0008 §Engine Compatibility.

- ItemCatalog owns validated definitions keyed by stable StringName item/action/profile IDs. Author via typed Resources/data rows, compile before activation into catalog-owned immutable records; return copied/read-only value views, never cached writable Resource references. Runtime count/wetness/durability/container never lives on ItemDefinition. Validate unique IDs, required localized keys/category/positive finite backpack mass, integer stack_max≥1, tool stack_max1/durability_max>0, optional food/drink/fuel fields with documented ranges, quality/wetness[0,1], and every referenced tool/resolver/profile/clip/item ID. Missing optional food means non-edible, not zero-calorie food; unknown ID/missing required field refuses operation+error. Worn clothing's authored mass dash is an explicit non-carried case, not an invented backpack mass. Invalid capacity≤0, l_free≥1 or negative mass tables reject/log/use approved defaults as the GDD specifies. Missing required kit/action content blocks activation rather than fabricate values. Future optional rows are not new enabled scope. — source: ADR-0009 §Decision.

- InventoryModel alone owns Stack{stack_id,item_id,count,container_id,wetness?,durability?,revision}, Container IDs for backpack/worn/piles and monotonically assigned run-local identities. Every live stack has exactly one container; split allocates a new ID and copies source state; moved whole stacks retain identity. Merge into stable existing target IDs, remove depleted source IDs and invalidate their revisions. Tools never merge, and callers refer to stack_id rather than choose “any hatchet” at commit. Piles own position and persist whole run; pick nearest within1.5 m on drop, exact ties by stable pile ID, else create a pile. Worn/radio/camera drop refuses; valid carried-item drop has no capacity restriction and is a transfer, never loss. — source: ADR-0009 §Decision.

- Prepare transfers from snapshots then validate all source/destination revisions at C4's checkpoint. Compute integer units fitting weight using catalog unit mass, clamp to requested/source counts, merge up to stack_max and open overflow stacks without inventing a slot limit. Whole unit heavier than free mass means taken0/refusal; partial fit leaves the exact remainder at source and reports 背不动了. Use deterministic unit-mass arithmetic/tolerance only for roundoff, never to admit an extra unit. Generated produce uses `add_or_pile`: fit units enter backpack, excess becomes a feet pile; if placement cannot validate, refuse the whole preflight, never delete produce. Failed Gathering/depleted nodes must not generate a batch. Before/after conservation holds per item across all owners plus explicit authorized creation/consumption/loss deltas. — source: ADR-0009 §Decision.

- When merging wettable stacks use `(m1*w1+m2*w2)/(m1+m2)`, with masses=count×unit mass; split preserves wetness and merge preserves total wet mass. Nonwettable items have no wetness, not a synthesized damp value. On immersion set backpack fuel/tinder1 only, not food/tools or Body clothing. Accepted recipe-specific feather_stick creation retains its defined source-stick wetness×0.5, not generic drying. Each minute after Fire's source publication apply I4 once/stack at pile position or player position for backpack: felt≥10 dry0.5/h, felt≥0 dry0.05/h, below0 dry0, divide60 and clamp[0,1]. Camp status is derived from a burning Fire warm_radius; no stale camp flag or second special drying multiplier. Thermal invalid sample logs/skips drying for that stack instead of inventing warmth. Body B2 and Inventory I4 remain different rates/owners. — source: ADR-0009 §Decision.

- Publish I1 load=backpack mass/25, I2 speed=1−0.3×max(0,(load−0.5)/(1−0.5)) and hauling iff load>0.7; no worn/show-kit mass. Character alone combines speed penalties; moving hauling activity is heavy, standing is not. I3 MVP insulation remains1.0 awake/asleep; reserved future sleeping-bag0.5 bonus does not activate here. — source: ADR-0009 §Decision.

- Use C4 prepared plans for tool use, damage, loss, consumption and produced stacks. Normal accepted completion/attempt charges I5 exactly one use (−1); profile damage is an additional once-only consequence ID, clamp durability≥0. If the accepted use/damage reaches0 remove tool and emit one `loss{kind:item_lost,item_class:tool,item_id}` after the transaction, but keep that completion's accepted result. Next start refuses. External loss before completion cancels the action without a use/roll. A duplicate loss/damage/use never charges twice. Consuming food/drink/fuel removes units without loss; tool break is explicitly a loss despite normal-use provenance. Transfer/drop emits no loss. Mishaps decides stochastic external loss, Inventory validates/removes; grief belongs only to Morale. — source: ADR-0009 §Decision.

- Cross-owner transactions prepare all effects first: Needs accepts stomach/hydration before consuming the food; Fire accepts fuel/tinder before removing it; Gathering/Map commit authorized yield plus output plan; action gate admits tool use and profile outcome. No plan mutates or emits during prepare. Validate revision/resource availability and both success/failure branches before use/RNG; execute a non-yielding commit whose owner operations cannot then refuse, with notifications queued until all writes finish. On invalid/stale/duplicate token reject without any owner/RNG mutation. Unexpected commit invariant failure gates the run/diagnostic, never retries a partial transaction. Inventory never writes Needs/Fire/Map fields and never passes writable stack arrays to them. Restore later validates all counts/IDs/references atomically and exactly restores wetness/durability/container ownership; camp status recomputes after Fire registration, not serialized truth. — source: ADR-0009 §Decision.

- **Pinned-engine constraints**: None required; Resource import adapter and typed value records. If packed arrays are used, 4.7 element writes need explicit dirty notifications. **Verify before treating the adapter as proven**: Resource-cache isolation, detached nested snapshots, content cross-reference validator, exactly-once transfers/tool notifications and pinned-engine import signatures — source: ADR-0009 §Engine Compatibility.



- `surface_at(p: Vector3, grade_deg: float = 0.0) -> SurfaceSample`: retains GDD fields type/snow_depth_m/compaction/effective_depth_m/sink_m/slope_deg/normal/terrain_speed_mult/is_wading/ice_thickness_cm/footstep_sound; moving/activity context is supplied by the Character adapter, never guessed from read-only query side effects. — source: ADR-0004 §Decision (Key Interfaces).

- `stamp_footfall(event: FootfallEvent) -> void`, `break_ice(cell_id) -> void`: validated run-tagged commands; snapshots remain detached values. `zone_at(p)`, `node_snapshot(id)`, `deplete_node(id, attempted_units)` preserve architecture names. — source: ADR-0004 §Decision (Key Interfaces).

- Map query ports expose playable bounds, drop/facing, safe sites and nearest safe shore edge; Terrain exposes height/normal for engine adapters. These are application contracts, not claims of native Godot methods. — source: ADR-0004 §Decision (Key Interfaces).

- Terrain must never move Character, mutate static height, or roll an ice break. WorldMap alone must mutate remaining yield; each accepted depletion token must commit once. — source: ADR-0004 §Decision (Implementation Guidelines).

- Packed-array mutation must explicitly dirty changed cells/chunks. Marks must never be silently expired to meet a memory target. — source: ADR-0004 §Decision (Implementation Guidelines).

- Scatter must use stable ordering and finite retries, never its own gameplay RNG. Invalid authoring must fail closed or follow the GDD's named fallback, not fabricate guaranteed success. — source: ADR-0004 §Decision (Implementation Guidelines).

- Outside-grid query must return rock/speed1 with warning and heightmap-derived slope; zero-depth snow must have no sink/mark and use rock sound. Approved terrain bad-data defaults remain mandatory. — source: ADR-0004 §Decision (Implementation Guidelines).

- Preserve `surface_at(p, grade_deg)`, `footfall{position, foot, sink_m}`, movement activity, `play_action(id, duration_s)` and `is_idle`/action callbacks from GDD; typed run/sequence metadata is internal. — source: ADR-0005 §Decision (Key Interfaces).

- `CharacterSnapshot` exposes position, velocity, facing and animation state, never writable physics state. Action callbacks carry the action token and are presentation acknowledgments only. — source: ADR-0005 §Decision (Key Interfaces).

- `cancel_action_pose(token)` stops only that pose; the ActionRunner transaction must already be cancelled before a success callback can be considered. — source: ADR-0005 §Decision (Key Interfaces).

- Character must apply the speed floor once after multiplying, and exclude Body's Critical penalty on crawl. Grade must be directional, never absolute slope alone. — source: ADR-0005 §Decision (Implementation Guidelines).

- Exactly one accepted contact must stamp one event; layer blends must not double method callbacks. Activity must reflect actual motion, not animation names. — source: ADR-0005 §Decision (Implementation Guidelines).

- No root-motion gameplay authority, clip-triggered inventory effects, AnimationTree.playback_active or deprecated bone_pose_updated. Gameplay duration must not be inferred from clip end. — source: ADR-0005 §Decision (Implementation Guidelines).

- Preserve GDD `effective_temp_c(p) -> float`, `components(p) -> ThermalComponents{air,zone,wind_chill,heat,shelter_bonus}`, `wind_eff(p)`, `is_sheltered(p)` and air_temp_c/wind_speed snapshots. — source: ADR-0006 §Decision (Key Interfaces).

- `register_heat_source(source) -> Result`, `update_heat_source(source) -> Result`, `unregister_heat_source(id) -> Result` validate ownership/run/revision; supplied DTO includes all GDD fields. These are application ports, not asserted Godot methods. — source: ADR-0006 §Decision (Key Interfaces).

- `begin_minute(context)` and `seal_sources(minute_sequence)` are Coordinator-only barriers, not a second public minute_tick subscription; optional `zone_weights(p)` exports detached weights. — source: ADR-0006 §Decision (Key Interfaces).

- Query must be pure and exact after coarse candidate lookup; index membership must never decide final distance/zone weight. — source: ADR-0006 §Decision (Implementation Guidelines).

- Body must sample after Fire's same-minute publication; no deferred signal callback or Area3D overlap list may be authoritative. — source: ADR-0006 §Decision (Implementation Guidelines).

- Source values must remain Fire-owned, table/registry Thermal-owned. Invalid registration must contribute nothing; no NaN may enter Body integration. — source: ADR-0006 §Decision (Implementation Guidelines).

- Preserve architecture `try_start(action_id,target_id) -> StartResult`, `cancel(reason)`, `progress()`, `resolve_attempt(attempt) -> Outcome`, `check_ice(footfall)`, `action_outcome` and `fell_in_water` with their GDD payloads; internal token metadata adds no required args to public GDD signals. — source: ADR-0007 §Decision (Key Interfaces).

- `prepare_completion(token, snapshots) -> PreparedCompletion`, owner `validate_plan(plan) -> Result` / `commit_plan(plan, consequence_id)`, and `submit_terminal_candidate(candidate)` are injected typed ports, not native Godot APIs. — source: ADR-0007 §Decision (Key Interfaces).

- Cancellation and world-contact ports carry run/sequence; old callbacks and repeated commits are rejected without mutation. Prepared snapshots must not expose mutable owner state. — source: ADR-0007 §Decision (Key Interfaces).

- Forced cancellation/terminal arbitration must precede completion and RNG admission. No interrupted action may send result/use/roll, including immersion and non-cancellable work. — source: ADR-0007 §Decision (Implementation Guidelines).

- Owner commits must be atomic/non-yielding/idempotent; tool-loss notifications from the accepted use must not reenter cancellation of that same completion. — source: ADR-0007 §Decision (Implementation Guidelines).

- Exactly one terminal event; hypothermia>dehydration, death>collapse/immersion. Cause presentation must precede result and Morale must never be named as cause. — source: ADR-0007 §Decision (Implementation Guidelines).

- Preserve `step_minute(context)`, `apply_immersion(event_id)`, `snapshot() -> BodySnapshot`; `try_eat(stack_id)`, `try_eat_snow()`, `request_sleep()`, `wake(causes)` from architecture. — source: ADR-0008 §Decision (Key Interfaces).

- `MinuteContext` includes typed pre-step values; `BodyStepResult` contains post-stage/shiver/rate, wake and terminal candidate; `NeedsStepResult` contains post-needs/timers/sleep endpoint/candidates. These are application DTOs, not engine-native APIs. — source: ADR-0008 §Decision (Key Interfaces).

- Preserve GDD public `stage_changed`, `needs_stage_changed(need,stage)`, `wake_request(cold)`, `body_died(hypothermia)` and `needs_died(dehydration)` names/payloads; internal submit_terminal_candidate carries run/minute/sequence/cause and no public double death. — source: ADR-0008 §Decision (Key Interfaces).

- Each owner must integrate once/minute, never once per physics frame or via both public minute_tick and Coordinator call. Sleep must not bulk-skip physiology. — source: ADR-0008 §Decision (Implementation Guidelines).

- Body must use pre-step wetness/shiver for B1; Needs must use post-Body stage/shiver but captured sleep/fullness/stages for its interval. Highest numeric activity must be selected independently per table. — source: ADR-0008 §Decision (Implementation Guidelines).

- Needs alone must write is_asleep; all wake/mode requests must settle before the next minute; death gates collapse/completion and emits one terminal event. — source: ADR-0008 §Decision (Implementation Guidelines).

- Preserve architecture `definition(item_id) -> ItemDefinition`, `add_or_pile(stacks,position) -> TransferResult`, `consume(request) -> Result`, `use_tool(id) -> Result`; adapters carry stable stack/token/revision rather than mutable references. — source: ADR-0009 §Decision (Key Interfaces).

- `prepare_transfer(request) -> InventoryPlan`, `validate_plan(plan) -> Result`, `commit_plan(plan,consequence_id)` are application ports, not asserted Godot methods. TransferResult distinguishes accepted/remainder/refusal and new pile/stack IDs. — source: ADR-0009 §Decision (Key Interfaces).

- GDD loss payload stays `kind:item_lost,item_class:tool|other` plus item ID; all internal envelopes include run/sequence and no duplicate public grief event. — source: ADR-0009 §Decision (Key Interfaces).

- Catalog definitions must be immutable to consumers; mutable stack ownership must be singular, counts integer/nonnegative and transfers conserved. — source: ADR-0009 §Decision (Implementation Guidelines).

- Partial pick-up must retain remainder; generated overflow must become a pile, never disappear. Wetness merge must be mass-weighted and tools must retain individual durability. — source: ADR-0009 §Decision (Implementation Guidelines).

- Accepted tool-breaking completion must retain its result; consumption/drop must never emit item_lost. No cancelled action may use/consume/roll via Inventory callbacks. — source: ADR-0009 §Decision (Implementation Guidelines).

### Forbidden Approaches
- Never use **Terrain GDExtension/addon** as the implementation baseline — Not authorized; no addon is chosen or purchased. Revisit only with owner approval and spike evidence. — source: ADR-0004 §Alternatives Considered.

- Never use **Decal-only transient footprints** as the implementation baseline — Violates whole-run trail persistence and deterministic surface queries. — source: ADR-0004 §Alternatives Considered.

- Never use **Custom Jolt kinematic body from scratch** as the implementation baseline — CharacterBody3D is the Accepted baseline; failed step/grade spike would require a revised ADR, not silently switching implementation. — source: ADR-0005 §Alternatives Considered.

- Never use **Root-motion and globally stretched action clips** as the implementation baseline — C1–C7 require model-driven movement/activity and repeated effort, not slow motion. — source: ADR-0005 §Alternatives Considered.

- Never use **Area3D overlap-derived temperature** as the implementation baseline — Cannot guarantee deterministic same-minute samples; areas may visualize but never own Thermal truth. — source: ADR-0006 §Alternatives Considered.

- Never use **Quantized temperature grid or full rescans** as the implementation baseline — Coarse index plus exact evaluation retains formulas without assuming full scans meet the unmeasured query budget. — source: ADR-0006 §Alternatives Considered.

- Never use **Clip/Timer callbacks directly apply results** as the implementation baseline — Cannot meet no-interrupted-effect or atomic consequence guarantees. — source: ADR-0007 §Alternatives Considered.

- Never use **Separate RNG per resolver or roll at action start** as the implementation baseline — Violates one accepted completion roll and F3 state ownership. — source: ADR-0007 §Alternatives Considered.

- Never use **Peer mutable reads in signal callbacks** as the implementation baseline — No reproducible pre/post boundary or once-only integration. — source: ADR-0008 §Alternatives Considered.

- Never use **Aggregate sleep integration or shared survival owner** as the implementation baseline — GDD requires minute-by-minute queries, separate causes and sole Needs sleep authority. — source: ADR-0008 §Alternatives Considered.

- Never use **Mutable shared Resource per item** as the implementation baseline — Violates immutability and sole stack/container ownership. — source: ADR-0009 §Alternatives Considered.

- Never use **Resolver directly removes input then adds output** as the implementation baseline — Cannot guarantee atomic owner effects or conserved overflow. — source: ADR-0009 §Alternatives Considered.

### Performance Guardrails
- **CPU**: GDD obligations: surface_at ≤0.02 ms/query; node queries ≤0.05 ms; scatter ≤200 ms. Spike query, stamp/upload, collision and mesh costs, not merely averages. — source: ADR-0004 §Performance Implications.

- **Memory**: Grid ≤8 MB is an unverified GDD target; whole-run mark growth and renderer/collision allocations must be reported separately. No unmeasured min-spec claim. — source: ADR-0004 §Performance Implications.

- **Load Time**: Validate authoring, build collision and bounded scatter before activation; report full-run trail restore cost in later save work. — source: ADR-0004 §Performance Implications.

- **CPU**: GDD controller≤0.1 ms/physics frame; one skeleton/three layers/foot IK≤0.5 ms/frame on owner-nominated min-spec. Existing prototype is not this measurement. — source: ADR-0005 §Performance Implications.

- **Memory**: One rig/LOD, shared immutable clips and bounded cosmetic tokens; no per-step accumulating scene nodes. — source: ADR-0005 §Performance Implications.

- **Load Time**: Validate skeleton mappings, clip segments/events/masks and fallbacks before run activation. — source: ADR-0005 §Performance Implications.

- **CPU**: GDD≤0.05 ms/effective_temp_c query with8 sources/4 nearby zones; profile index lookup+exact weights/distances, not just arithmetic. Selected 10 m bin size is not measured optimal. — source: ADR-0006 §Performance Implications.

- **Memory**: World registries/indices only; no per-point temperature state or saved Thermal caches. — source: ADR-0006 §Performance Implications.

- **Load Time**: Validate table/build polygon index; restore sources from owners before activation. — source: ADR-0006 §Performance Implications.

- **CPU**: GDD targeting≤0.1 ms/frame with30 nearby interactables; Mishaps≤0.02 ms/attempt; ice checks only qualifying foot contacts. Profile prepare/commit and catch-up separately. — source: ADR-0007 §Performance Implications.

- **Memory**: One action, one Input buffer; bounded current plans and per-action guards; prune committed-ID ledgers only at safe run/sequence watermarks, never while redelivery possible. — source: ADR-0007 §Performance Implications.

- **Load Time**: Validate actions/profiles/IDs before activation; invalid reach/cone/t_safe rejected per GDD; no unapproved tuning. — source: ADR-0007 §Performance Implications.

- **CPU**: Each GDD target remains ≤0.02 ms/tick. Profile the inclusive Body path (including its Thermal query) and exclusive costs; tighten the Thermal per-query allocation first rather than silently raising either ceiling. The standalone Thermal ceiling of 0.05 ms is not proof of inclusive Body compliance; the tightened numeric allocation awaits profiling. — source: ADR-0008 §Performance Implications; owner decision 2026-11-19, architecture-review-2026-11-18 conflict 4 (decided).

- **Memory**: Fixed model snapshots/counters plus event sequence guards; no per-frame history required. — source: ADR-0008 §Performance Implications.

- **Load Time**: Validate both tables before activation, restore owners and Clock mode coherently. — source: ADR-0008 §Performance Implications.

- **CPU**: GDD≤0.1 ms/pick-up/drop, drying≤0.05 ms/tick for50 stacks. Include preflight/commit and Thermal query cost; benchmark, do not claim measured compliance. — source: ADR-0009 §Performance Implications.

- **Memory**: Persistent pile/stack records; immutable definitions shared read-only, detached bounded snapshots. Ledgers prune only after safe sequence watermark/run teardown. — source: ADR-0009 §Performance Implications.

- **Load Time**: Validate full cross-reference tables and fixed kit once before activation; no runtime defaults invented for unknown IDs. — source: ADR-0009 §Performance Implications.

---

## Feature Layer Rules

### Required Patterns
- GatheringResolver is a run-owned Feature service with validated action/node recipes, no independent yield counter or timer. C4 passes an eligible token and one accepted Outcome. Revalidate node identity/revision/kind/remaining/tool and recipe before the use/roll checkpoint; unknown kind refuses+logs. Prepare both success/failure branches and Inventory overflow plans without mutation. — source: ADR-0010 §Decision.

- G1: attempted=min(recipe take,remaining); success keeps attempted and requests Map remaining−attempted once; failure keeps floor(attempted/2), except chop0, and leaves remaining unchanged. Preserve the approved unusual partial-failure faucet; do not “fix” it by depleting failures. A duplicate completion never repeats produce even when failed yields did not change node revision. Final-unit success empties the node; retain depleted mesh and remove verbs. Map owns sticks/logs/bark/grass/stone sub-yields and bush bonus; never infer remaining from visuals. A bush success grants at most one available bonus grass and depletes that bonus once; failure must not consume bonus reserve. Apply floor-to-half separately to each produce line on failure: one bonus grass yields zero; do not consume the bonus reserve. — source: ADR-0010 §Decision; owner decision 2026-11-19, architecture-review-2026-11-18 conflict 2 (decided).

- Preserve recipes: bush sticks3 + optional grass1, deadfall sticks2, chop log1, birch bark2, grass2, stone1; durations3/3/4/4/2/1 game minutes and light/light/heavy/light/light/heavy. C4 alone charges one hatchet/knife use per accepted completion plus Mishaps failure damage; no-profile stones has no roll/outcome. Last-use break keeps current result, next start refuses; cancellation produces no result/use/roll. Missing hatchet still permits deadfall branches, no knife refuses bark. — source: ADR-0010 §Decision.

- G2 creates wetness by source: standing sticks0, deadfall sticks/logs0.3 or forest0.2, bark0, sheltered grass0.1/open0.4/bush bonus0.1; future snowfall offset0 in MVP, clamp[0,1]. Inventory handles mass-weighted merge; Gathering never dries items. One conserved output batch goes through add_or_pile, fit into backpack and remainder at feet. Validate pile allocation before Map depletion; no output may vanish on capacity failure. Commit Map+Inventory plans synchronously under C4; events queue until all writes complete, keyed by token/consequence IDs. No callbacks or yielding between owner validation and commit. — source: ADR-0010 §Decision.

- G3/G4 are derived QA estimates, not auto-production loops or additional timers. G3 rate tests require a sufficiently provisioned isolated fixture because a real finite deadfall cannot provide13.5 logs for a whole hour; report that fixture assumption rather than silently replenish a run node. G4 guards zero/nonpositive free capacity as “cannot haul without freeing load,” not division by zero or infinity trips. Valid8 logs/kit still needs2 trips. Night gathering adds no darkness penalty. Save/Load remains deferred: Map restores yields, Inventory produce; no second Gathering save truth. — source: ADR-0010 §Decision.

- **Pinned-engine constraints**: None required; typed value plans and direct owner ports **Verify before treating the adapter as proven**: Atomic Map/Inventory commits, detached DTOs, once-only notifications; no native adapter assumed proven — source: ADR-0010 §Engine Compatibility.

- FireController owns stable site/fire IDs, stage, ringed flag, F, burning wetness, material escrow and absolute game-minute ember/window deadlines. Validate site inside Map, slope≤8°, no ice, drift≤0.6 m; bare rock skips clearing, otherwise clear5 heavy, optional stones6/3min light, tinder arrange2min with bark2 OR grass3 OR feather1 plus sticks4. At most2 simultaneous fires; preflight admission reserves capacity to reject a third before consuming/building. Retain cold cleared/ringed site history separately from active-source admission. — source: ADR-0011 §Decision.

- Inventory remains sole stack owner: arranging transfers designated inputs into a Fire-owned container/escrow plan retaining exact IDs/count/wetness, not premature anonymous deletion. strike repeat0.5min with rod and one C4 outcome moves Laid→Smoldering; blow1min within3 game minutes succeeds→Kindling. On successful ignition consume tinder+kindling into FI5 fuel (dry bark recipe F26). Failed/expired blow consumes tinder, keeps kindling available at site and returns Cleared/Ringed; next arrange preflight accounts for retained kindling, never charges four sticks twice. Carving stick/knife through C4 yields feather_stick wetness=source×0.5; failure follows profile waste/damage. No resolver draws its own luck. — source: ADR-0011 §Decision.

- After lighting derive stages from F: Burning≥30, Kindling5≤F<30, Embers<5; ember expiry90 game minutes from entry, Out after expiry. Adding fuel in Embers requires a successful blow to relight; failed blow leaves Embers with finite original expiry, no new tinder cost. Deadlines advance only via Clock minutes, including sleep/wait, never wall Timer. C4 cancellation does not reset Fire's independent smoldering deadline; expiry consumes tinder even if the player moved away. On exact expiry/completion boundary process Fire deadline stage before C4 revalidates a blow. — source: ADR-0011 §Decision.

- Preserve FI1 s=1−exp(−F/60); FI2 heat=28s(1−0.4w), Embers4, Out0; FI3 radius0.8+2.6s, Embers1; FI4 burn=(0.25+F/240)×(1+0.08×wind_eff×(ringed?0.6:1)); FI5 added=fuel_value×(1−0.3wetness), w'=(wF+wetness×added)/(F+added); reject over300 with item kept, never truncate paid units to fit; zero-fuel addition refuses safely rather than divide by0. Burning wetness dries0.05/min; FI6 light1.5+5s, Embers1.5. Wet log>0.6 into pre-add Kindling F<30 smothers to Embers, retains that log's effective fuel and shows hiss/white smoke. Do not test smother against post-add F or discard the log. — source: ADR-0011 §Decision.

- Minute convention: use pre-step F/w to compute FI4 burn; apply/clamp F, dry burning w, derive post-step stage/deadline/heat/radius/light and publish before Inventory/Body queries in F3. Out disables source immediately. Same radius is Thermal.radius_m and Fire.warm_radius; Morale reads Fire, never infers from6m light. For authoritative queries publish any changed source exactly each affected minute/action commit; rendering may coalesce <0.1 changes. The >0.1 source-change threshold applies to visuals only; exact changed heat/radius is published to Thermal/Body each minute. — source: ADR-0011 §Decision; owner decision 2026-11-19, architecture-review-2026-11-18 conflict 3 (decided).

- On transition Out emit one unattended loss iff captured Needs asleep OR distance>15m; awake near emits none. Token/run-stage sequence deduplicates losses. Never request wake/normal from Fire; only Body feels cooling and requests wake. Rest target availability may stop Interaction rest/return normal without inventing a sleeping alarm. Critical permits add_fuel/blow only through Body whitelist, not strike/lay. Restore deferred stage/F/w/deadlines exactly and re-register Thermal before first tick; no replayed loss event. Out-site snowfall reset is reserved VS scope. — source: ADR-0011 §Decision.

- **Pinned-engine constraints**: None required; selected OmniLight3D/GPUParticles3D adapters, not new AreaLight3D **Verify before treating the adapter as proven**: Light/particle signatures and radius/readability on pin, exact Thermal publication, ember deadlines and resource conservation — source: ADR-0011 §Engine Compatibility.

- MoraleModel owns stored L/F/G (start0), mental_state (start Steady), action failure timestamp deques, ritual/second-wind/day/night caps and pending offers. H/P/Resolve are recomputed, not independently mutable or saved truth. Accept typed run/sequence envelopes via enqueue_event; reject duplicate/stale events and warn/ignore unknown action/kind/severity, never invent severity. A minute flush groups losses→failures→successes→comforts→rival/medical, stable source sequence within each category; apply each once, then rates, then derive H/P/R/state once. Events arriving during publication wait for the next flush, never reenter integration. — source: ADR-0012 §Decision.

- For F2 count prior failures of THAT action inside a sliding120 game-minute window since its most recent success; age timestamps individually, not a single “last failure” timer. Failure adds severity4/8/15×(1+0.25×min(prior_streak,4))×keepsake factor. A success is meaningful if profile.base_fail≥0.10 OR that action has a prior streak≥1; lift6 or streak-ending12 respectively. ANY success clears that action's deque, even trivial; other action outcomes never clear it. Morale streaks differ from Mishaps'4-fumble guard and must not share counters. Clamp each event's resulting strains[0,100], discard overflow rather than banking it. Emit strain_spike for individual |delta|≥5, not a fabricated aggregate. — source: ADR-0012 §Decision.

- F1 L/hour=0.6×(1+0.08×(day−1))×(sleep0.5/day1/night1.5)×keepsakeL; no passive L decay. F2 passive F−1/hour awake resting at burning fire,−2 asleep, else0. F3 G losses: unattended fire10 plus F8, tool10/other6, future shelter15, dawn milestone each7thday8; G decay−0.4/hour. Derive F4 H=0.6×(100−fullness)+0.4×100×min(1,max(0,weight_lost_frac)/0.15), clamp; invalid start_weight→weight_loss0/error. F5 P=max(clamp(100×(36.5−core)/(36.5−33),0,100),injury0 in MVP). F6 R=100−(0.6 weighted_mean+0.4 max_strain), weights L/F/G/H/P0.25/0.25/0.15/0.20/0.15 normalized. Dominant uses weighted contributions, ties L>F>G>H>P. — source: ADR-0012 §Decision.

- State falling strict<65/<40/<20, rising≥70/45/25, at most one step each minute in either direction. F7 penalties0/0.03/0.06/0.10 and duration1/1.05/1.12/1.20; C4 owns final failure clamp≤0.90 and action duration cap. Inherited pre-step action multipliers never change already-running duration. Snapshot hidden R only for Feedback/Diary/debug, never HUD. — source: ADR-0012 §Decision.

- Detect fire ritual only awake/non-skip continuous idle≥20 game minutes, core≥36, in Kindling/Burning warm_radius; reset continuity on invalid conditions. Apply L−4/G−3/F−3, at most once/game hour and3/day. Sunrise awake outdoors idle≥10 minutes within Time window gives F−5/G−2 once/day. Sleep AND wait skips integrate every minute with sleep multipliers but cannot accrue ritual eligibility. Second wind eligibility uses the mental_state at flush start (no intermediate state re-evaluation): first meaningful success/ritual while Breaking grants extra F−20/L−10 once/day, then latch until next day. Document this discrete convention in tests. Day resets precede new-day integration; dawn milestone is distinct from midnight reset and deduplicated. — source: ADR-0012 §Decision.

- At nightfall use the completed tick's state to emit one offer if Fraying/Breaking: quiet normally, plea on second consecutive Breaking night; ANY below-Breaking nightfall including Fraying resets that count. Sleeping nightfall defers delivery until wake if still qualifies, keyed by night ID to prevent repeats; no run-ending call or extra penalty for refusal. C4 terminal freezes values and suppresses late offers/relief. Restore deferred stored strains/state/caps/streak timing/night counters exactly; recompute H/P without spikes on first tick. — source: ADR-0012 §Decision.

- Deferred comforts retain typed ports but no MVP producers: first Diary/night L−15/G−5, WildlifeL−3, rival L+2/F−2, medical moderate disappointment. Keepsake gain multipliers multiply per stored strain with floor0.70, never survival bonuses. No enabling relief mechanics just because schema has a port. — source: ADR-0012 §Decision.

- **Pinned-engine constraints**: None required; typed direct calls/value snapshots **Verify before treating the adapter as proven**: Stable event ordering, detached records, exactly-once skip boundaries/restore and bounded runtime bookkeeping on pin — source: ADR-0012 §Engine Compatibility.



- `prepare_gather(token,node_snapshot,outcome) -> GatherPlan`, `validate_plan`, `commit_plan(plan,consequence_id)` are application ports using C4/C6 protocols. — source: ADR-0010 §Decision (Key Interfaces).

- Preserve Map `node_snapshot`/`deplete_node` and Inventory `add_or_pile`; result DTO includes per-produce attempted/kept/overflow and emptied state, not mutable stacks. — source: ADR-0010 §Decision (Key Interfaces).

- Map alone must deplete; only success decrements attempted units. Produce creation must commit once independently of whether yield changed. — source: ADR-0010 §Decision (Implementation Guidelines).

- Full backpack must yield a visible feet pile; no second tool-use or Mishaps call in Gathering. — source: ADR-0010 §Decision (Implementation Guidelines).

- Preserve Fire source `{id,position,heat_c,radius_m,enabled}`, warm_radius/fire_burning, stage snapshots and `loss{kind:fire_died_unattended}`. — source: ADR-0011 §Decision (Key Interfaces).

- `prepare_fire_action(token,inputs,outcome)`, `step_minute(context)`, `snapshot()` and C4 validate/commit ports; application contracts, not native Godot methods. — source: ADR-0011 §Decision (Key Interfaces).

- Material transfer/consume and fire state must commit atomically; refusals must keep inputs. Cause cue must precede failure result. — source: ADR-0011 §Decision (Implementation Guidelines).

- Fire must publish same-minute source/radius and never directly warm Body or wake Needs. Out/loss/deadline transitions must be once-only. — source: ADR-0011 §Decision (Implementation Guidelines).

- Preserve `enqueue_event(event)`, `step_minute(context)`, `snapshot() -> MoraleSnapshot`, `state_changed`, `strain_spike(dimension,delta)`, `tap_out_offer(strength)`. — source: ADR-0012 §Decision (Key Interfaces).

- Snapshot contains hidden strains/Resolve, dominant_strain and F7 outputs; application value ports, never writable fields or native Godot claims. — source: ADR-0012 §Decision (Key Interfaces).

- Morale must integrate once/minute and order categories before recomputing once. Timestamped per-action streaks must expire by game time. — source: ADR-0012 §Decision (Implementation Guidelines).

- Relief must respect hour/day/night caps; no rituals during skip, no duplicate second wind/offer and no control/terminal authority. — source: ADR-0012 §Decision (Implementation Guidelines).

### Forbidden Approaches
- Never use **Gathering-owned yield cache** as the implementation baseline — Two authorities violate finite-node ownership. — source: ADR-0010 §Alternatives Considered.

- Never use **Deplete then independently try inventory insertion** as the implementation baseline — C4/C6 require preflight and conserved atomic output. — source: ADR-0010 §Alternatives Considered.

- Never use **Scene Timers and light-radius-derived heat** as the implementation baseline — Violates authoritative Clock/Thermal barriers. — source: ADR-0011 §Alternatives Considered.

- Never use **Consume all material at arrange and wake on low fuel** as the implementation baseline — GDD requires exact consumption and explicitly no Fire wake. — source: ADR-0011 §Alternatives Considered.

- Never use **Immediate per-event state changes** as the implementation baseline — GDD mandates fixed order and one state step/tick. — source: ADR-0012 §Alternatives Considered.

- Never use **Shared streak/RNG guard or unlimited comfort** as the implementation baseline — Contradicts F2 and bounded relief/owner decisions. — source: ADR-0012 §Alternatives Considered.

### Performance Guardrails
- **CPU**: GDD resolution≤0.02 ms/completion, including plan creation; measure complete Map/Inventory path separately on nominated hardware. — source: ADR-0010 §Performance Implications.

- **Memory**: Immutable recipes/short-lived plans; Map/Inventory retain persistent state. — source: ADR-0010 §Performance Implications.

- **Load Time**: Reject invalid bush grass>sticks/3 and unknown recipe references before activation. — source: ADR-0010 §Performance Implications.

- **CPU**: ≤0.02 ms/fire/tick GDD target; profile inclusive source/plan path and coalesced render work separately; no measurement claimed. — source: ADR-0011 §Performance Implications.

- **Memory**: Two active fire records, persistent cold sites and bounded escrow; renderer effects separately budgeted under QQ-01. — source: ADR-0011 §Performance Implications.

- **Load Time**: Reject b_div<60/h_max≥30 and malformed references using approved defaults; restore sources before activation. — source: ADR-0011 §Performance Implications.

- **CPU**: GDD≤0.05 ms/minute, no authoritative per-frame work; benchmark burst queues and caps on nominated hardware. — source: ADR-0012 §Performance Implications.

- **Memory**: Age120-minute streak deques; retain only safe dedupe watermarks and necessary day/night records, not unbounded event history. — source: ADR-0012 §Performance Implications.

- **Load Time**: Validate positive weights/threshold ordering and t_comfort>t_max_pain; invalid table uses approved defaults. — source: ADR-0012 §Performance Implications.

---

## Presentation Layer Rules

### Required Patterns
- Title shows Continue only for a validated checkpoint, plus New Run, Three-Night Chapter and confirmed Quit; CLI three-day/demo bypass title but share failure recovery. Confirm checkpoint discard for fresh/profile starts and retain the old slot until fresh initialization succeeds. Pause exposes Resume, Save & Return to Title, profile switch and confirmed Quit. Use routed authored keyboard/gamepad/mouse intents, visible focus, localized CSV strings and text at least 20px. — source: ADR-0018 §Decision; §GDD Requirements Addressed.

- Terminal hides gameplay HUD, holds the camera, retains authored death fade/silence and uses one coordinator-owned eight-real-second end-shot timer, advancing only with finite delta and no router pause gates. Esc opens terminal pause using the run's owned token; Resume Shot releases only that token, never revives simulation. After one unpaused second permit a fresh confirm/interact skip through InputRouter; this is the sole bounded exception to Locked-only-pause and the prior no-skip shot contract. No terminal save or profile switch. Results show localized cold/dehydration/dawn outcome and qualitative nights lasted, Try Again with the same profile and Return to Title; no scores/rewards. Presentation never emits a second outcome. — source: ADR-0018 §Decision (Key Interfaces, Implementation Guidelines); §Risks.

- SurvivalCamera owns pivot, chosen d_user/yaw, eased turn/zoom, request token registry, occluder fade state and projection snapshot. CA1 perspective Camera3D at pivot+R_y(yaw)×(0,sin(pitch_eff)d_eff,cos(pitch_eff)d_eff), looking at pivot; no orthographic substitution or free mouse-look. Named routed turns45°/0.4s repeat0.4s; zoom3m/step clamp14–40 eased0.25s. Handle turn/zoom input in an early phase, publish a yaw value fixed for each Character physics step; follow final Character ground position afterward. Character never reads a transform being edited halfway through its step. Visual sink does not feed ground pivot. — source: ADR-0013 §Decision.

- CA2 lookahead=dir×min(2,speed×0.8), exponential XZ lag0.35s/Y0.8s. Clamp pivot to Map playable bounds, permit survivor off-centre near edge. CA4 token priority highest wins/newest stable sequence tie; losing requests stay registered, release falls back to previous. Blend from CURRENT effective distance/pitch, not defaults. Scale chosen distance, not a global base; pitch clamp25–80°. Unknown IDs warn/ignore; stale/duplicate run token release no-op. Input move/action breaks cinematic tokens, blend-out≤1s; turn/zoom breaks first then applies; noncinematic sleep retains multiplier while user zooms. — source: ADR-0013 §Decision.

- Keep standard framing values: ritual1.4/−10°/4in1out/p2/cinematic; lonely1.15/−5°/6in3out/p1; relief0.95/0°/1.5in2out/p1; sleep1.3/−5°/3in1out/p3; end2.5/+15°/8s/p5; extraction4/+20°/10s/p5 reserved VS. Camera ignores its own turn/zoom in End but never locks InputRouter globally or moves Character. C4 final terminal starts end_rise once; it runs on unpaused presentation real seconds after survival freezes, explicit pause still freezes rig/blends. Other menus freeze only when they actually hold a pause token; backpack alone does not. — source: ADR-0013 §Decision.

- CA5 query a radius1m capsule camera→survivor chest, exclude survivor/gameplay triggers, at most12 scenery candidates nearest line first with stable-ID ties. Dither each occluder's visual opacity to0.3 over0.25s, restore over0.5s after leaving; no collision removal, no shared material mutation, never fade survivor. Track/restoration ownership through request changes/teardown so a freed run cannot leave trees faded. Terrain ridges use a bounded height/line-of-sight clearance solver, not transparent terrain: raise pivot where needed for visibility and lift camera along fixed pitch line until≥3m above terrain; do not rotate pitch or move survivor. Validate authored map admits a solution; bounded failure logs and uses last valid shot rather than endless ray loops. — source: ADR-0013 §Decision.

- CA3 is QA screen_h×1.75×cos(pitch_eff)/(2d_eff tan(fov/2)), not a runtime autozoom override. Default/user max and ritual at max must≥20px at720p; owner framing acceptance remains QQ-04. Projection API uses the FINAL camera transform/viewport snapshot after clearance, with explicit visible/behind-camera flag and viewport-local coordinates. HUD converts through CanvasLayer stretch/safe area; Audio takes orientation, not elevated camera position for hearing. No gameplay targeting or world movement is decided by projection. Settings/save deferred: chosen distance/yaw restorable; token state is run-owned and teardown invalidates it. — source: ADR-0013 §Decision.

- **Pinned-engine constraints**: None required; Camera3D projection, PhysicsDirectSpaceState3D shape/ray adapters; verify signatures and collision masks on pin **Verify before treating the adapter as proven**: Capsule queries/masks, per-instance dither material overrides, viewport projection/stretch, terrain clearance and CA3 screenshots — source: ADR-0013 §Engine Compatibility.

- EmotionPresenter reads complete snapshots/events only. Each unpaused real second choose EF4 Body→Needs→Morale-if-Strained+→steady posture; blend0.8s. Body Critical/crawl and sleep/death remain Character full-body overrides; Body shiver remains additive whenever is_shivering, never inferred from mood. Needs exhausted/tired/hunger precede Morale L/F/G/H/P postures; grief idle requires10real seconds. State improvement posture lifts over≥3s independently of beat cooldown. — source: ADR-0014 §Decision.

- EF3 one beat at a time,≤1.2s, same-ID20unpaused-real-second cooldown: death>loss>failure>second_wind>relief>fire_lit>tap_out_offer. Higher interrupts, lower drops (no backlog). Input cancels in the same frame. Unknown beat logs/ignores, stale sequence inert. During active work hold at most one highest eligible overlay tagged to that action's end; replace/drop by priority, discard on cancel/stale token/input, never interrupt effort or mutate action duration. C4's physical cause cue MUST precede frustration beat; outcome receipt alone is not permission to display it before the cause. Sleep suppresses beats, holds grade and fades music to silence. — source: ADR-0014 §Decision.

- Maintain owned Camera tokens: ritual_wide for eligible ritual/sunrise, lonely_hold only L-dominant Strained+ idle outdoors, relief_ease on qualifying relief; release promptly when conditions end. Needs sleep/terminal are authoritative state sources: route sleep_wide/end_rise through one shared per-source token adapter, not duplicate requests from both direct source and Feedback. Death stops beats, music silent and snow-white fade8s with Camera end-rise; explicit pause freezes presentation, terminal survival freeze alone does not block this end animation. Reduced camera motion suppresses ritual/lonely/relief only; end shots remain. — source: ADR-0014 §Decision.

- Attach an owned `Compositor` Resource containing one `CompositorEffect` to the run's WorldEnvironment or Camera3D (one attachment, never both). Presenter publishes detached double-buffered parameter values; render callback reads the latest complete buffer, never SceneTree/gameplay objects or mutable main-thread records. Allocate/recreate resolution-dependent buffers and free render RIDs on the appropriate rendering adapter lifecycle; exact API/callback stages require a pinned-engine spike. No manual viewport shader chain, no Compositor child node, no global Resource mutation across runs. — source: ADR-0014 §Decision.

- EF1 saturation offset=−(0.05×state_index+(Grief and index≥1?0.05:0))×fx_scale, max magnitude0.20. Classify hue in an explicitly tested colour-space conversion; warm band15°–55° must retain saturation/fire/tarp/collar/skin warmth, including boundaries. Grade only cold hue saturation, never apply a whole-screen saturation slider. EF2 edge vignette toward trunk_navy: Body Warm/Chilled/Cold0,Hypothermic0.25,Critical0.5, eased1.5s; mental Breaking never adds vignette. Keep vignette desaturation warm-masked too, cap edge strength and do not hide centre/survivor. Grade blends≥3s; reduced screen effects fx_scale0.5 scales BOTH grade/vignette; posture still carries meaning. End-white is a separate terminal overlay, not a new strain grade. Restore starts weights at targets, no neutral fade-in. — source: ADR-0014 §Decision.

- EF5 targets warm/pad/thin: Steady-fire0.6/0/0,Steady-else0.25/0/0,Strained0.15/0.3/0,Fraying0/0.4/0.2,Breaking0/0.3/0.35, ease4s. These are gains when sparse score cues are active, not permission for continuous music; approved cue assets/schedule must leave mostly silence and remain sourcing/tuning obligations. Ritual sets all targets0 and foregrounds crackle, never starts music. EF6 sends additive wind+2dB/state (max+6) and other-ambience duck−6dB only L-dominant Strained+; Audio owns physical base wind and final buses. No gameplay danger stinger, no grade-driven gameplay/RNG, deferred Diary receives localization word pools only. — source: ADR-0014 §Decision.

- **Pinned-engine constraints**: Compositor and CompositorEffect are Resources assigned to WorldEnvironment/Camera3D, never scene nodes; 4.6 glow-before-tonemap/AgX changes affect verification **Verify before treating the adapter as proven**: Exact render callback/buffer/RID lifecycle on pin, shader colour-space/warm mask, FX scaling, pose/mix adapters and actual screenshots/listening — source: ADR-0014 §Engine Compatibility.

- SurvivalAudio owns buses/players/scheduling only. Route Ambience/Foley/Music/UI into Master; bus sends point TO Master, despite shorthand tree notation. Use wind and other-ambience sub-buses so Feedback's loneliness−6dB ducks birds/creaks without ducking wind; keep physical base wind, emotional additive emphasis, pause and user volume as separate parameters (never accumulate dB each frame). UI menu paper/ink remains audible when world branches duck−12dB on explicit pause; do not duck Master/UI and then compensate double. Backpack alone is not pause and causes no pause duck. — source: ADR-0015 §Decision.

- One AudioListener3D sits at survivor head position with final Camera orientation; disable competing current listeners. Foley gain AF5 depends on Camera effective distance, not listener displacement. Spatial fire players stay at Fire positions. Explicitly set area_mask=0 if no intended area overrides, or the documented audio-area layer mask where used (including layer1 when that is the authored convention); never rely on the changed4.7 default. Audio area effects cannot decide gameplay shelter/thermal state. — source: ADR-0015 §Decision.

- Preallocate pooled 2D/3D players and count EVERY simultaneous active playback, including bed crossfades, wind, fire loops, body,3 score layers and menu UI, against≤24. No hidden polyphony on a stream/player bypasses the count. Priority cause>footsteps>work>fire>body>ambience details; score/bed continuous voices reserve within the same ceiling, not an extra pool. On pressure stop/drop lowest-priority non-cause with short cosmetic fade; do not steal a playing cause. Cause requests carry ordered event IDs, admitted before ordinary effects and held for sequenced playback if all playing slots are protected, not silently dropped. Real production throughput bound must be demonstrated from C4's admitted actions/contacts; excess arbitrary all-cause test traffic must retain pending sequence without exceeding active cap, never block simulation. Missing licensed clip logs/silence and fails audible acceptance rather than crash or invent an alert. — source: ADR-0015 §Decision.

- One accepted footfall plays exactly one sample using the C1/C2 pre-stamp surface/sink, with fresh/forest/drift/trail/ice/rock variants (3/type, cosmetic ±5% pitch); crawling drag instead. Effort-loop beats trigger work sounds, not success effects. Cause hiss/gust/clatter/exhale/fizzle/miss/ice crack→plunge starts before the corresponding outcome/frustration presentation; send a presentation-only cue-start ack to P2 when needed, never stall gameplay commit. Deduplicate source event IDs, discard stale callbacks on restart. — source: ADR-0015 §Decision.

- Preserve AF1 step_base fresh−14/forest−16/drift−12/trail−18/ice−15/rock−13 +6×sink/0.45, clamp≤0dB. AF2 physical wind=clamp(−12+20log10(max(0.3,wind_eff)/3),−36,0)+EF emphasis0…6; lake3→−12, not open2.4→−13.9. Cosmetic gusts±3dB over2–6real seconds use isolated non-authoritative randomness, no gameplay draws. AF3 Fire Out silent/Embers−34/otherwise−30+24s, spatial attenuation on top; wet pops/hiss from w_burn, smother burst separate. AF4 breath12+8×work_level(0/0.5/1)+6 if Tired+, chatter only Chilled/Cold, never Hypothermic/Critical. Hungry growl about once/game hour is still real-time throttled during skips. AF5 clamp(−0.15×(d_eff−22),−3,+3). — source: ADR-0015 §Decision.

- Blend zone beds using Thermal's SAME weights and current phase, zone transition5s, phase across Dawn/Dusk; drift uses the authored appropriate snow bed fallback rather than new content approval, scoured strongest wind. Absent VS owl/wildlife stays absent. Sleep: no step/work, slow breathing, ambience/fire continue at real playback rate. Catch-up advances latest world/mix state but never replays a minute per audio detail; coalesce cosmetic environmental updates and schedule details on real time. Explicit pause ducks world−12dB, UI plays; release restores underlying mix targets without drift. Death fades Foley3s, wind alone then with8s end image; active cause/end ordering cannot send owner commands. Teardown stops all players/listener and clears pending cues/pooled callbacks. — source: ADR-0015 §Decision.

- **Pinned-engine constraints**: 4.7 AudioStreamPlayer3D.area_mask defaults0: explicitly set intended masks; no removed AudioEffectSpectrumAnalyzer.tap_back_pos **Verify before treating the adapter as proven**: AudioListener3D transform/current selection, bus routing/masks, active voice accounting, spatial attenuation and actual cause pre-roll on pin — source: ADR-0015 §Engine Compatibility.

- SurvivalHud owns presentation state only: body band/trend, at most3 need icons, sun/moon arc, localized prompts/refusal/hint, calm fade and minimal backpack list facade. Use one run-owned CanvasLayer/Control tree with a validated Theme and localized keys, no gameplay queries from draw callbacks. Render a complete detached end-of-update snapshot; cache only derived visuals, never duplicate food/load/stage authority. Missing target/verbs clears old prompts immediately. InputRouter active_device/glyph bindings choose labels, never hard-coded E/F when rebound/gamepad active. — source: ADR-0016 §Decision.

- H1 fill=clamp((core−30)/7,0,1), no printed values, snowflake/flame icons plus fill direction/ticks preserve colourblind readability. H2 thresholds±0.1 single/±1double, arrow candidate must persist2unpaused real seconds before replacement; steady hides it. H3 calm=Warm/no trend/no need warning/no prompt, after8real seconds targetalpha0.35 eased down1.5s; any warning/trend/stage/prompt raises1 within0.5s. H4 energy/water/food first-warning icon normal ink, urgent bold+pulse1Hz/10% scale; one per need, max3. H5 angle180×sun_progress by Dawn/Day/Dusk, otherwise normalized minutes since nightfall/night length; no hour/day numerals. Invalid snapshot logs/holds last valid band/arc rather than displaying NaN; absent optional warning is hidden. — source: ADR-0016 §Decision.

- Visibility precedence: end hides all; sleep/ritual hides all except body band0.35; ordinary Critical forces band1 and keeps applicable needs/prompts (only owner-approved verbs), else calm rules. This makes contextual hide explicit rather than competing fades; verify conflict cases before acceptance. Ritual ends restore0.5s. First-minute localized hint disappears on first Kindling flame OR after10game minutes, latches gone until new run; settings restore remains deferred; bounded run checkpoint restore is enabled by ADR-0018. Refusals newest replaces previous for1.5real seconds; no queue. Reconnect overlay uses InputRouter recovery path, not a new gameplay pause authority. — source: ADR-0016 §Decision.

- Use final Camera.project_world output, reject behind-camera/invisible points, map viewport coordinates through CanvasLayer/stretch once. Keep prompts40px clear of actual projected survivor silhouette; clamp to safe rectangle without overlapping survivor or inventing offscreen markers. At720p text≥18px, anchors5% safe area; ultrawide uses centred16:9 safe rectangle before5% inset. Long localization text wraps/reflows; missing key dev shows key/release empty+log. Paper/off-white/ink strokes remain UI, not low-poly world meshes. MVP scale100%; reserve80–140% Alpha hook without adding settings controls.4.7 line rendering lost antialias feather, so thin band/arc strokes require actual screenshot verification, not assuming old widths. — source: ADR-0016 §Decision.

- Backpack open requests InputRouter UI context ONLY. It does not request pause, stop Clock, cancel active action or freeze physiology/Fire/Morale. Existing in-flight action continues, even if it completes/death occurs behind the list; continuously refresh inventory from owner snapshots so stale rows cannot become commands. Buttons send action/transfer requests with stable stack ID/revision to C4/C6; running hands/action/critical/tool constraints still apply. Unknown/deleted row fails/reloads harmlessly, never directly mutates stack/count/Needs. Minimal list shows localized item identity and qualitative wetness/load bands, no numbers; no drag-grid, nested crafting, full settings or scope addition. Use/drop/eat routes through existing owner resolver, never calls engine Input gameplay handlers directly. — source: ADR-0016 §Decision.

- Explicit pause menu acquires an F2 pause token; world Clock/action timers freeze until all pause tokens released. If backpack stays open behind pause, closing pause returns to UI context, not Gameplay. Closing backpack releases only its UI request; rearm gameplay bindings after release per F2 so Tab/confirm doesn't leak a use/step. Noninteractive HUD nodes ignore input/focus; keyboard/gamepad focus for active list restored explicitly while mouse hover remains independent. Disconnect safety retains InputRouter gate/reconnect instructions; next keyboard action updates glyphs. Terminal closes/disables command facade and uses C4's single end snapshot, never accepts new stale commands. — source: ADR-0016 §Decision.

- **Pinned-engine constraints**: 4.6 mouse/touch focus separate from keyboard/gamepad; 4.7 stretch defaults are not retroactive and accessibility_live is typed. Use updated RichTextLabel image units if glyph adapter needs images. **Verify before treating the adapter as proven**: Dual-focus/input leak, glyph lookup, actual project stretch/projection mapping, locale text sizing, keyboard/gamepad reconnect and UI rendering on pin — source: ADR-0016 §Engine Compatibility.



- Preserve `request_framing(id,distance_mult,pitch_offset_deg,blend_in_s,blend_out_s,priority,cinematic)` / `release_framing(id)` via owner/run-tagged token adapter. — source: ADR-0013 §Decision (Key Interfaces).

- `yaw_snapshot()`, `project_world(p) -> ProjectionResult{visible,viewport_point}`, `orientation_snapshot()` are read-only application ports; exact Camera3D calls belong to pinned-engine adapter tests. — source: ADR-0013 §Decision (Key Interfaces).

- Camera must never move survivor/lock gameplay/cut away; cinematic requests must release on input and transition from current shot. — source: ADR-0013 §Decision (Implementation Guidelines).

- Occluders must fade visually only and restore on teardown; projection must correspond to final clearance-adjusted camera, not desired pre-collision position. — source: ADR-0013 §Decision (Implementation Guidelines).

- Preserve posture/beat, `request_framing/release_framing`, `strain_spike`, state/ritual/second-wind/offer consumers; `set_mix(request)` is an abstract Audio port. — source: ADR-0014 §Decision (Key Interfaces).

- `render_parameters() -> GradeSnapshot`, `set_accessibility(flags)` and `on_cause_presented(sequence)` are value/ack adapters, not asserted native methods. A presentation ack never blocks/commits simulation. — source: ADR-0014 §Decision (Key Interfaces).

- Presenter must remain read-only to gameplay; never mutate source snapshots or award relief itself. — source: ADR-0014 §Decision (Implementation Guidelines).

- Compositor/Effect must be Resources; warm hues must retain saturation; beat priority/cooldown/input cancel and cause-first ordering must hold independently of frame rate. — source: ADR-0014 §Decision (Implementation Guidelines).

- Preserve `on_footfall(event,surface)`, `on_cause(event)`, `set_mix(request)` from architecture; typed requests carry run/event sequence and validated asset IDs. — source: ADR-0015 §Decision (Key Interfaces).

- `request_voice(cue)`, `cause_started(sequence)` and final bus/listener snapshots are application adapters, not asserted Godot methods; no audio result controls gameplay. — source: ADR-0015 §Decision (Key Interfaces).

- All active streams must count toward24; cause must precede outcome and never be silently stolen/dropped. No per-event node creation or gameplay RNG draws. — source: ADR-0015 §Decision (Implementation Guidelines).

- Listener must stay at survivor head; wind formula/base versus emotional modifiers must remain separate; explicit area masks and no Hypothermic chatter. — source: ADR-0015 §Decision (Implementation Guidelines).

- Preserve `render_snapshot(snapshot)` and `set_visibility_context(context)` from architecture; facade issues typed owner commands, not mutable Inventory views. — source: ADR-0016 §Decision (Key Interfaces).

- Use F2 `request_ui_context(source,open)` / `request_pause(source)` / `release_pause(token)`, C13 `project_world` and C4/C6 token/stack IDs. These are application ports, not native Godot APIs. — source: ADR-0016 §Decision (Key Interfaces).

- Hold progress/radio ring remains VS hook, not a new MVP extraction mechanic. UI paper/ink Audio requests have no simulation effects. — source: ADR-0016 §Decision (Key Interfaces).

- UI must be read-only to models and non-numeric; prompt/glyph/target must reflect current owner snapshot, no stale actionable affordance. — source: ADR-0016 §Decision (Implementation Guidelines).

- Backpack must not pause/cancel time/actions; pause menu must pause through token ownership, not SceneTree mutations. Closing overlays must not leak Gameplay input. — source: ADR-0016 §Decision (Implementation Guidelines).

- Text≥18px at720p,5% safe area,40px survivor clearance and at most3icons must survive aspect/locale changes. — source: ADR-0016 §Decision (Implementation Guidelines).

### Forbidden Approaches
- Never use **Per-caller camera Tweens** as the implementation baseline — One token arbiter is required for priority/breakability. — source: ADR-0013 §Alternatives Considered.

- Never use **Pull camera close or move survivor around blockers** as the implementation baseline — GDD requires scenery fade, fixed-pitch clearance and no survivor control. — source: ADR-0013 §Alternatives Considered.

- Never use **Global saturation and per-event Tweens** as the implementation baseline — Violates warm band and priority/cooldown design. — source: ADR-0014 §Alternatives Considered.

- Never use **Manual viewport chain or Compositor node** as the implementation baseline — Engine reference explicitly specifies Resource pipeline. — source: ADR-0014 §Alternatives Considered.

- Never use **Camera listener and ad-hoc players** as the implementation baseline — Violates survivor listener and total voice budget. — source: ADR-0015 §Alternatives Considered.

- Never use **Catch-up replay or danger stingers** as the implementation baseline — GDD requires real-time sparse details and no danger alerts. — source: ADR-0015 §Alternatives Considered.

- Never use **Full-screen UI automatically pauses SceneTree** as the implementation baseline — Context and pause are independent authoritative F2 requests. — source: ADR-0016 §Alternatives Considered.

- Never use **Bind numeric Inventory/model fields directly to widgets** as the implementation baseline — GDD requires non-numeric read-only facade and owner commands. — source: ADR-0016 §Alternatives Considered.

### Performance Guardrails
- **CPU**: GDD update≤0.05ms/frame; occlusion≤0.1ms/frame/≤12 candidates; profile clearance too, not just hit count. — source: ADR-0013 §Performance Implications.

- **Memory**: Bounded fade candidates plus live requester tokens; release all on run teardown. — source: ADR-0013 §Performance Implications.

- **Load Time**: Validate framing table/FOV/pitch and isolated shader/material adapters. — source: ADR-0013 §Performance Implications.

- **CPU/GPU**: GDD logic≤0.05ms/frame; combined grade/vignette pass≤0.5ms/frame on nominated min-spec, unmeasured. — source: ADR-0014 §Performance Implications.

- **Memory**: One effect instance/buffer set per run and one beat candidate; no accumulating Tweens/events. — source: ADR-0014 §Performance Implications.

- **Load Time**: Validate grade tables/beat IDs/shader backend; compilation/resource failure logs and disables cosmetic pass without simulation failure, but release visual acceptance remains unmet. — source: ADR-0014 §Performance Implications.

- **CPU**: GDD audio thread≤1ms/frame with24voices; measure actual mixing/stream formats and main-thread scheduling separately. — source: ADR-0015 §Performance Implications.

- **Memory**: Preloaded approved short cues, streamed beds/score where validated; pool allocations bounded. No unapproved asset tooling or measured-memory claim. — source: ADR-0015 §Performance Implications.

- **Load Time**: Validate buses/clip routing, masks/listener and license manifest before activation; missing cosmetics log/silence, never block survival. — source: ADR-0015 §Performance Implications.

- **CPU/GPU**: GDD HUD draw≤0.3ms/frame; benchmark layout/projection/localization updates separately, not claimed measured. — source: ADR-0016 §Performance Implications.

- **Memory**: Reused3icons/fixed controls and current list snapshot; remove stale rows on owner revision, no event/refusal backlog. — source: ADR-0016 §Performance Implications.

- **Load Time**: Validate theme/glyph/localization refs and actual stretch settings; missing keys follow dev/release behavior, never invent gameplay text values. — source: ADR-0016 §Performance Implications.

---


## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example | Source |
|---|---|---|---|
| Classes | PascalCase | PlayerController | project.yaml `naming.classes` |
| Variables | snake_case | move_speed | project.yaml `naming.variables` |
| Signals/Events | Past tense; snake_case | health_changed | project.yaml `naming.signals`; .claude/docs/technical-preferences.md §Naming Conventions |
| Files | snake_case | player_controller.gd | project.yaml `naming.files` |
| Constants | SCREAMING_SNAKE | MAX_HEALTH | project.yaml `naming.constants` |
| Scenes | snake_case | player_controller.tscn | project.yaml `naming.scenes` |
| Functions | snake_case | start_run | .claude/docs/technical-preferences.md §Naming Conventions |

### Performance Budgets
`project.yaml` has no `performance.*` values; use the technical-preferences fallback, not the architecture's unapproved QQ-01 proposals.

| Target | Value | Source |
|---|---|---|
| Framerate | 60 fps | .claude/docs/technical-preferences.md §Performance Budgets (fallback for `performance.target_framerate`) |
| Frame budget | 16.6 ms | .claude/docs/technical-preferences.md §Performance Budgets (fallback for `performance.frame_budget_ms`) |
| Draw calls | Not configured; no numeric ceiling adopted here | .claude/docs/technical-preferences.md §Performance Budgets (fallback for `performance.draw_call_limit`) |
| Memory ceiling | Not configured; no numeric ceiling adopted here | .claude/docs/technical-preferences.md §Performance Budgets (fallback for `performance.memory_ceiling_mb`) |

Layer budgets are unmeasured targets, not benchmark results. QQ-01 still reserves nominated hardware, resolution, final allocations and measurement policy. Conflict 4's profiling/tightening direction is decided; it supplies no measured or approved replacement numeric query limit.

### Approved Libraries / Addons
None configured: `[None configured yet — add as dependencies are approved]` — source: .claude/docs/technical-preferences.md §Allowed Libraries / Addons.
This is not an approval of a terrain addon or any other third-party dependency. The configured test framework is gdUnit4, not an entry in this empty approval list — source: .claude/docs/technical-preferences.md §Testing.

### Forbidden APIs (Godot 4.7.2)
Every row below is sourced to `docs/engine-reference/godot/deprecated-apis.md`; these are scoped to this project's GDScript, 3D/Jolt, animation, rendering, audio and UI usage. Renames/removals and project-verified nonexistent APIs are distinguished from formal deprecations.

| Never use | Use instead / scope | Reference status |
|---|---|---|
| `VisibilityNotifier3D` | `VisibleOnScreenNotifier3D` when visibility notification is used | Renamed 4.0 |
| `yield()` | `await signal` | GDScript 4.0 |
| `connect("signal", obj, "method")` / string-based connect | Typed signal connections with Callable | Changed 4.0 |
| `instance()` / `PackedScene.instance()` | `instantiate()` / `PackedScene.instantiate()` | Renamed 4.0 |
| `get_world()` | `get_world_3d()` for 3D world access | Changed 4.0 |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | Changed 4.0 |
| `duplicate()` when a nested resource deep copy is needed | `duplicate_deep()`; ordinary shallow duplication is not banned | Explicit deep-copy control 4.5 |
| `Skeleton3D.bone_pose_updated` signal | `skeleton_updated` | Renamed 4.3 |
| `AnimationPlayer.method_call_mode` | `AnimationMixer.callback_mode_method` | Moved 4.3 |
| `AnimationPlayer.playback_active` | `AnimationMixer.active` | Moved 4.3 |
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `ImageUpdateMask.UPDATE_WIDTH_UNIT` if image glyphs are used | Renamed 4.7 |
| `add_image()/update_image()` boolean `width_in_percent/height_in_percent` | `width_unit/height_unit` with `RichTextLabel.ImageUnit` if image glyphs are used | Renamed/retyped 4.7 |
| `DisplayServer.AccessibilityLiveMode` for `Control.accessibility_live` | `AccessibilityServer.AccessibilityLiveMode` when setting live accessibility | Moved 4.7 |
| `$NodePath` lookups in `_process()` | Cached `@onready` references | Forbidden pattern |
| Untyped `Array/Dictionary` for typed application data | Typed arrays/variables | Forbidden pattern |
| Narrow `Texture2D` assumption for `Shader.set_default_texture_parameter()/get_default_texture_parameter()` | `Texture` base type; shader-language `sampler2D/texture()` is unchanged | Changed 4.4 |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` Resources | Pattern changed 4.3+ |
| GodotPhysics3D as new-project physics baseline | Jolt Physics 3D | Default since 4.6; project.yaml `engine.physics` |
| `event.device == 0` as keyboard/mouse detection | Event type or `InputEvent.DEVICE_ID_MOUSE/DEVICE_ID_KEYBOARD` | Changed 4.7 |
| `ConeMesh` | `CylinderMesh` with `top_radius = 0` if a cone is required | Project-verified nonexistent primitive on 4.7 |

### Required Engine Practices
- When using these GDScript constructs, use correct variadic syntax (`...name`, last, typed Array or untyped), explicit abstract-method declarations with no body, and shared captured state for lambda callbacks rather than expecting a captured scalar assignment to mutate an outer local — source: docs/engine-reference/godot/current-best-practices.md §GDScript (4.5+).
- Typed-method overrides need an explicit return. Packed-array element writes do not invoke a property setter: explicitly dirty affected terrain/buffers or assign the whole array when the setter must run — source: docs/engine-reference/godot/current-best-practices.md §GDScript (4.7).
- If a WorldBoundaryShape3D from 4.6 is reused with Jolt, negate the old plane.d; when using audio-area overrides, explicitly set the intended AudioStreamPlayer3D area mask (the new default is zero) — source: docs/engine-reference/godot/current-best-practices.md §Physics (4.7).
- Verify thin HUD lines on 4.7 (the antialias feather is gone), glow-before-tonemap/AgX appearance and warm-hue preservation; do not assume the old look survives migration — source: docs/engine-reference/godot/current-best-practices.md §Rendering (4.7), §Rendering (4.6); ADR-0014; ADR-0016.
- Use SkeletonModifier3D-based IK; explicitly verify LookAtModifier3D.relative if used (default false). Keep mouse hover separate from keyboard/gamepad focus, and inspect actual stretch settings rather than assuming an older project gained 4.7 defaults — source: docs/engine-reference/godot/current-best-practices.md §Animation (4.6), §Animation (4.7), §UI (4.6), §UI and Input (4.7).
- Verify post-cutoff API signatures on the pinned engine before relying on them; application ports in the ADRs are not native Godot APIs. For screenshot capture, wait for RenderingServer.frame_post_draw. Treat headless import exit zero alone as insufficient: inspect ERROR/SCRIPT ERROR output — source: docs/engine-reference/godot/VERSION.md §Knowledge Gap Warning, §Installed-Version Gap Warning; docs/engine-reference/godot/current-best-practices.md §Verified on this project (2026-11-16).

### Forbidden Patterns from Technical Preferences
Copied as configured: `[None configured yet — add as architectural decisions are made]` — source: .claude/docs/technical-preferences.md §Forbidden Patterns.
This empty legacy list does not remove the ADR-specific prohibitions above.

### Cross-Cutting Constraints
- **Backpack does not pause or cancel**: opening inventory requests UI context only; Clock, in-flight actions, physiology, Fire and Morale continue. Only the explicit pause menu requests player-initiated pause, through owned tokens; loading/controller-disconnect safety gates remain separate. Closing pause over backpack returns to UI, and release/re-press prevents input leakage — source: ADR-0002; ADR-0003; ADR-0016 (QQ-08 resolved).
- **Minimal, non-numeric HUD and inventory facade**: no gameplay numbers, hidden Resolve, numeric item counters or added settings/grid/crafting scope. Preserve the 35% calm body band, at most three need icons and qualitative inventory labels — source: ADR-0012; ADR-0016 (QQ-09 default, not newly decided).
- **Ownership and once-only effects** apply across every layer: detached snapshots, explicit injected ports, source/run/revision validation, no mutable resource aliasing, deterministic teardown and no presentation authority over simulation — source: ADR-0001; ADR-0003; ADR-0007; ADR-0009; ADR-0014; ADR-0016.
- **Deferred means dormant**: ADR-0018 explicitly enables only bounded menu/checkpoint persistence and its terminal skip/visual-reset amendments. Wider Save/Load/settings, weather/shelter/Diary/Wildlife/keepsake producers, new survival bonuses, cold-intake cooling, paid sourcing and new radio mechanics remain deferred; merely having a reserved port does not enable them — source: ADR-0001; ADR-0006; ADR-0007; ADR-0008; ADR-0009; ADR-0012; ADR-0016; ADR-0018 §Decision, §Risks. QQ-02/03/06/07/09/10 defaults remain provisional.
