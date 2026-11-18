# ADR-0007: Timed-action transactions, seeded mishaps and simultaneous-death precedence

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/reference/registry audit; no transaction, replay or presentation runtime test executed.

## Decision Makers
Scott (owner) and Devin (authoring agent, inline godot-specialist review). No acceptance or independent approval claimed.

## Summary
ActionRunner needs one completion authority that cannot grant results after cancellation or race simultaneous deaths. Propose run-tagged tokens, prepared owner commits, one injected seeded stream and a Coordinator checkpoint that forces cancellation/arbitrates terminal candidates before committing eligible work and publishing cause-before-result events.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core / Input / Animation |
| **Layer** | Core |
| **Knowledge Risk** | HIGH engine pin; model transactions avoid post-cutoff callback assumptions |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/input.md`, `modules/animation.md`, `modules/physics.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None required by transaction model; uses F3 run-RNG adapter, not version-portable RNG internals |
| **Verification Required** | Same-frame input/physics/minute checkpoint ordering, reentrant signal rejection, RNG state restore on pinned engine, callback invalidation and cause-before-result visual ordering |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001–0006 (Proposed); acceptance required before implementation |
| **Enables** | ADR-0008 terminal candidate ports, ADR-0009 inventory commit details, backlog S1/S2/S3 and P2/P3 |
| **Blocks** | ActionRunner/MishapResolver transaction implementation until acceptance; no story files exist |
| **Ordering Note** | Layer Core comes from ActionRunner/Interaction in the layer map; Feature MishapResolver is an injected collaborator, not a new layer value. C5/C6 refine owner ports, not a reverse dependency cycle. |

## Context

### Problem Statement
Timer/animation callbacks, owner signals and a long skip can otherwise race completion, tool loss, collapse, immersion and two death causes. Every accepted attempt needs once-only effects with no hidden reroll or interrupted result.

### Constraints
- Registry: one run-owned RNG, direct ordered dispatch, detached values, sole-owner writes; InputRouter alone owns the one0.15 s buffer. No new queue in Interaction.
- Interaction Rule7 immersion cancellation is approved/resolved, including non-cancellable actions; it is not a new owner question. QQ-08 backpack does not pause or cancel work, explicit pause menu does.
- Keep approved profiles/formulas/penalties, Critical whitelist and overflow rules; no owner tuning/scope/cost decision here.

### Requirements
- Backlog coverage / unblocks (verbatim): All Interaction and Mishaps TRs. Define token lifecycle, revalidation, RNG state/draw order, cause-before-result presentation, idempotent consequences and forced-cancel dispatch. Explicitly codify hypothermia > dehydration; death > collapse/immersion; exactly one terminal event; no interrupted result/use/roll. Rule 7 immersion is already resolved, not a new owner design choice.

## Decision

ActionRunner owns action state and one live token `(run_id, action_sequence, attempt_sequence, target_id, target_revision)`. Lifecycle is Free→Working/Attempting/Continuous or Refused→eligible/prepared→committed OR cancelled; completed/cancelled tokens can never reopen. Target owners retain kept progress, not an unsaved action coroutine. Repeats get a fresh attempt sequence each time, obey IA4 and the sole Input buffer;3 real seconds without taps returns Free. Instant actions use the same admission/commit gate without elapsed work.

Use registered interactable action lists and IA2 within1.5 m/±50°: d/reach+0.5×|angle|/cone−kind bonus (fire0.3), current-target hysteresis0.15; ties keep current else nearer then stable ID. snow_ground is fallback only with no candidate on snow. Empty/no available actions clears prompts. At start validate target availability/revision, current range, required backpack tool, Body allowed_actions and Needs heavy permission. Refuse diegetically for1.5 s; reject invalid action IDs/table fields before activation according to owning GDD defaults. No action queue beyond Input's one buffered press.

Snapshot IA1 start Time rate and Morale×Body×Needs duration product capped2.0. Advance unpaused real seconds; progress uses dt_real/start_seconds_per_game_minute divided by snapshotted game_minutes (IA3). Changing night/rate/stage never retroactively stretches an in-flight duration. Resume uses target fraction with a new current duration. Work activity is reported while working; `is_idle` requires≥2 real seconds without movement and no action or counts_as_idle; rest requires burning Fire warm_radius, requests wait and returns normal on stop/fire out. Needs/Clock arbitrate sleep/normal, never Interaction writing is_asleep.

Coordinator's explicit update checkpoint is: sample input/contacts → ingest external owner changes and force-cancel notifications → finish each admitted ordered minute through Body/Needs candidate collection → arbitrate terminal/forced state → revalidate eligible completions → commit → publish. At most120 minutes are admitted in a frame by F3; if survival debt still precedes the checkpoint, hold an eligible completion until that debt is resolved, rather than commit against unprocessed fatal state. Checkpoint ordering must be reproducible at the same input/update sequence; it is not a promise of frame-rate-independent continuous physics replay. Never implement completion from Timer timeout, clip-finished or public minute_tick callbacks.

Force-cancel on collapse, forbidden Critical entry, immersion, missing target, external tool break/loss or run end, even when non-cancellable; player move/cancel obeys cancellable. Immersion cancels critical_allowed work too, stores target progress if progress_kept, gives Character In-water control and sends NO interrupted result, Inventory use or action Mishaps roll. Target disappearance discards progress. Cancellation wins a same-checkpoint completion tie. Death beats collapse and immersion animation/control; hypothermia beats dehydration when both death candidates exist in that checkpoint. Coordinator chooses exactly one terminal event/run, freezes future survival/completion/RNG and ignores later terminal/collapse callbacks. Ice's own world roll is not an interrupted action roll.

After revalidation, prepare detached revision-checked plans from Inventory and the resolver, including both profile success/failure consequences, output fit/overflow and all required resources. No owner mutates during prepare. Commit in one synchronous non-yielding section with owner events queued until the whole transaction ends: one tool use → one profile roll if applicable → once-only owner result/consequence commits → notifications. Plans must guarantee post-validation commits cannot refuse; no arbitrary callbacks run inside. A tool broken by THIS authorized use/failure does not cancel its own accepted outcome: current result stands, next start fails. External loss before checkpoint cancels. Distinct consequence IDs prevent duplicate durability/loss/soak/depletion under event redelivery. A failed preflight consumes neither use nor RNG. Unexpected commit invariant failure gates the run with a diagnostic instead of retrying/rerolling; implementation must prove this cannot occur under admitted valid input.

MishapResolver owns profiles and per-action fumble guards, not another RNG or inventory. M1 sums base+damp+wind+tinder+Morale+Body+Needs, clamp[0,0.90]. M2 picks only physical terms≥0.05; ties damp>wind>cold_hands>fatigue>tinder, else fumble, never Morale. M3 after4 fumble failures halves the next fumble-dominated chance; success clears, physical non-fumble failures never arm it. Preserve all seven profiles and their exact on_fail owner requests, including partial-yield profiles rather than treating every failure as zero yield. Sample completion-time conditions once for the accepted attempt. Profile absent means success/no roll/no action_outcome; unknown ID logs error/cannot-fail/no invented chance; a valid base0 profile still has one attempt roll and reports its trivial success. Missing nonwettable material damp0; missing Thermal wind0+warning.

Draw order: Map initialization first (F3); then stable accepted contact/attempt arrival sequence. For one eligible action exactly one M1 uniform, even at cap/base0; no-profile/cancelled/stale work draws none. Ice uses M4 only on unbroken ice footfalls thinner than15 cm; safe ice/open water/no contact draws none. On a break, request Terrain break, Body wetness1, Inventory soak, Character nearest-shore escape and major helplessness Morale event; if carried tools exist draw loss-test0.10, and only on loss draw one weighted existing-tool choice hatchet:knife:rod2:1:1. No tools means no loss-test/selection draws. Same-frame arrivals have explicit sequence; never Dictionary iteration order. M4 and invalid t_safe rejection remain unchanged.

Enqueue a cause cue before the outcome/result cue for a failed profiled attempt; consumers must present/read the cause before the result lands, using staged presentation if needed without delaying or blocking committed simulation. Morale receives exactly one `action_outcome{action_type,success,cause,severity,tag,base_fail_chance=profile.base_fail}` through F3's ordered flush. The run RNG snapshot includes seed+opaque state+draw position/engine pin plus separate guard state; restore all at one validated quiescent boundary, not seed-only. Save/Load remains deferred and action-in-flight is not saved; load Free with kept target progress only.

### Architecture Diagram
`Input/Clock/owner forced events → Coordinator gate → ActionRunner token/revalidate → prepared Inventory + resolver plans → Mishaps/RNG → owner commits → cause cue → outcome cue/Morale`; `Body + Needs candidates → terminal arbiter → one terminal`.

### Key Interfaces
- Preserve architecture `try_start(action_id,target_id) -> StartResult`, `cancel(reason)`, `progress()`, `resolve_attempt(attempt) -> Outcome`, `check_ice(footfall)`, `action_outcome` and `fell_in_water` with their GDD payloads; internal token metadata adds no required args to public GDD signals.
- Proposed `prepare_completion(token, snapshots) -> PreparedCompletion`, owner `validate_plan(plan) -> Result` / `commit_plan(plan, consequence_id)`, and `submit_terminal_candidate(candidate)` are injected typed ports, not native Godot APIs.
- Cancellation and world-contact ports carry run/sequence; old callbacks and repeated commits are rejected without mutation. Prepared snapshots must not expose mutable owner state.

### Implementation Guidelines
- Forced cancellation/terminal arbitration must precede completion and RNG admission. No interrupted action may send result/use/roll, including immersion and non-cancellable work.
- Owner commits must be atomic/non-yielding/idempotent; tool-loss notifications from the accepted use must not reenter cancellation of that same completion.
- Exactly one terminal event; hypothermia>dehydration, death>collapse/immersion. Cause presentation must precede result and Morale must never be named as cause.

## Alternatives Considered

### Alternative 1: Clip/Timer callbacks directly apply results
- **Description**: Each owner listens to action-finished and mutates immediately.
- **Pros**: Short prototype wiring.
- **Cons**: Connection order races terminal/cancel, double uses/results and partial cross-owner changes.
- **Rejection Reason**: Cannot meet no-interrupted-effect or atomic consequence guarantees.

### Alternative 2: Separate RNG per resolver or roll at action start
- **Description**: Pre-roll hidden success or seed generators per system.
- **Pros**: Simple local replay bookkeeping.
- **Cons**: Cancelled work advances luck; not the single run stream; completion conditions stale.
- **Rejection Reason**: Violates one accepted completion roll and F3 state ownership.

## Consequences

### Positive
- Forced events and death ties are deterministic; results/uses/rolls cannot leak from cancelled tokens.
- Plans preserve owner boundaries and let duplicate messages be harmless.

### Negative
- Every resolver needs prepare/validate/commit ports; synchronous sections prohibit yields or reentrant public signals.
- Presentation needs a separate cause/result queue; replay includes contact order, guard state and full RNG state, not just seed.

## Risks
- Inline godot-specialist review: typed direct calls/resources, explicit checkpoints and queued notifications avoid signal/animation callback ordering hazards. No deprecated API required. Reference alone does not prove pinned-engine RNG export/replay, callback timing or cause visual ordering; tests remain mandatory. TD-ADR skipped — Lean mode; no independent specialist approval.
- GDD sync checked Interaction, Mishaps, Body, Needs, Inventory, Character, Time and Morale (8). Rule7 immersion already matches the required forced-cancel contract. Time Rule8 still conflicts with QQ-08; action/backpack wording agrees with Scott. No API rename proposed, no GDD edited.
- Autonomous calls: Proceed with action/terminal problem, alternatives, full ranges and dependencies; separate tabs chose tokens/plans, seeded draw ledger and terminal/cancel checkpoint; picked Core from ActionRunner's layer-map value, not the backlog's mixed label; write ADR only; append registry; continue C5. No owner-only choice settled.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [interaction-and-timed-actions.md](../../design/gdd/interaction-and-timed-actions.md) | Full provisional TR-interaction-and-timed-actions-001 … TR-interaction-and-timed-actions-030; rules1–11, IA1–IA4, all edges/dependencies and AC1–21/performance | Target/admission/modes/timing/idle ports, kept progress, revalidation, once-only tool/roll/result, every forced cancel and resolved Rule7 immersion. |
| [mishaps-and-failure.md](../../design/gdd/mishaps-and-failure.md) | Full provisional TR-mishaps-and-failure-001 … TR-mishaps-and-failure-026; rules1–10, M1–M4, all edges/dependencies and AC1–16/performance | Seed/state/order/guards, all profiles/consequences, physical cause precedence, ice/soak/loss owner requests, presentation and error behavior. |

## Performance Implications
- **CPU**: GDD targeting≤0.1 ms/frame with30 nearby interactables; Mishaps≤0.02 ms/attempt; ice checks only qualifying foot contacts. Profile prepare/commit and catch-up separately.
- **Memory**: One action, one Input buffer; bounded current plans and per-action guards; prune committed-ID ledgers only at safe run/sequence watermarks, never while redelivery possible.
- **Load Time**: Validate actions/profiles/IDs before activation; invalid reach/cone/t_safe rejected per GDD; no unapproved tuning.
- **Network**: None; idempotency is an in-process reliability contract.

## Migration Plan
After acceptance implement token/gate tests, pure IA/M functions, owner plan fakes and simultaneous-event tests, then Inventory/Gathering/Fire adapters under their ADRs. C5/C6 refine owner contracts before integration; no production change now. Deferred save schema must validate RNG/guards atomically and omit active actions.

## Validation Criteria
- Interaction AC1–8,13–17:1.2 m forward chop; initial fire1.03 beats deadfall1.1; no candidates→snow fallback; no hatchet refusal; Exhausted heavy refused/light allowed; Critical only add_fuel/blow_embers/sit_warm/drop;60% chop resumes40%; half meal no use/kcal; refused1.5 s; durations6/7.39±0.02/cap12 s and day-start rate held; hysteresis0.15; repeat0.75/1.03 s; invalid reach/cone reject.
- Interaction AC9–12,18,21: one completion use/roll/success result;5 taps→5 of each; repeat timeout3 s; rest wait and fire-out normal; idle2 s/sit versus chop; heavy work+0.6 Body/+200 kcalh Needs; immersion at60% or strike-in-flight cancels same tick even non-cancellable/critical_allowed with no interrupted use/roll/result and correct progress.
- Mishaps AC1–8: no-profile add_fuel no roll/outcome; strike one roll/outcome+Morale minor/helplessness/base0.35; failed chop hatchet−10/no log; failed blow consumes laid tinder/embers die; never morale cause; seed/state restore identical; unknown profile success/error;4 fumbles arm/next half, success clears,4 damp never arm.
- Mishaps AC9–14: strike0.406/0.39/0.486/0.526/soaked cap0.90; M2 examples fumble/tinder/cold_hands/damp and ties; guarded0.203; ice25 cm0,8 cm/load0.276→0.0159±0.0005,5 cm/full hurry0.06; t_safe0 reject;1000 breaks tool loss10±2%/hatchet twice; sum Cold/Tired/Strained strike0.536.
- Adversarial checkpoint matrix: both death candidates→one hypothermia event; death+collapse+immersion→death state once; late terminal duplicates ignored; completion simultaneous with cancel/target loss/tool loss/forbidden Critical/immersion sends zero effects/draws; THIS completion breaks tool yet outcome stands. Duplicate/stale plans/callbacks produce nothing; injected preflight rejection leaves every owner/RNG unchanged. Full backpack spawns conserved output pile; invalid/nonwettable/missing Thermal inputs follow GDD fallbacks; no-tools ice/no-profile work consumes no forbidden draws.
- Interaction AC19–20 and Mishaps AC15–16: owner describes effort, ≥4/5 find fire next step, first fire1–4 strikes with explainable failures, ≥4/5 identify damp/wind/cold and cue precedes result. Unperformed visual/feel obligations, not claimed results. Benchmark targeting/attempt budgets, backpack continues/pause freezes, and replay full state/guards across ordered mixed map/action/ice draws.

## Related
- [Master architecture](architecture.md), C4 and layer map; [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md); [ADR-0005](adr-0005-survivor-locomotion-humanoid-retargeting-and-animation-ik-layers.md); [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md).
- QQ-01/05 budgets/tuning and other open QQ defaults remain PROPOSED; no new owner question for resolved Rule7. `/architecture-decision accept ADR-0007` remains separate and no stories are unblocked.
