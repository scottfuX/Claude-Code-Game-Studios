# ADR-0008: Body/Needs minute integration, sleep and terminal candidate ports

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — full Body/Needs contract/formula audit and inline engine-reference review; no simulation or playtest executed.

## Decision Makers
Scott (owner) and Devin (authoring agent, inline godot-specialist review). No acceptance or independent approval claimed.

## Summary
Body and Needs have coupled minute inputs and wake/death outcomes but must retain separate state ownership. Propose an immutable pre-step activity/sleep boundary, post-Body stage inputs to Needs, end-of-minute wake/mode arbitration and terminal candidates resolved once by C4's Coordinator gate.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core |
| **Layer** | Core |
| **Knowledge Risk** | LOW arithmetic domain per architecture; HIGH global post-May-2025 engine pin |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `current-best-practices.md`, `breaking-changes.md`, `deprecated-apis.md`; F3 scheduling and C3/C4 adapters |
| **Post-Cutoff APIs Used** | None required; explicit typed GDScript value models and direct calls, not Timer-rate integration |
| **Verification Required** | Exactly-once dispatch through sleep/catch-up, typed signals/adapters on pinned engine, detached snapshot isolation and pre/post-step numeric fixtures |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003, ADR-0005, ADR-0006, ADR-0007 (all Proposed; acceptance required before implementation) |
| **Enables** | ADR-0009, ADR-0012, ADR-0014, ADR-0016 (consumable plans and Morale/presentation) |
| **Blocks** | BodyThermoregulation/NeedsModel implementation until acceptance; no production story files exist |
| **Ordering Note** | Refines F3's explicit pre-step audit obligation and C4 terminal ports. Body/Needs exchange snapshots, not mutable peer references; C6 consumption adapter must satisfy this port, not create a reverse ADR dependency. |

## Context

### Problem Statement
Using mutable live state during a minute can make shiver costs, collapse, hunger, wake and simultaneous deaths depend on callback order. A skip must still expose each coldest minute and stop on a wake before the next minute.

### Constraints
- Body alone owns core/wetness/stage/shiver/allowed_actions; Needs alone owns stomach/weight/hydration/energy/stages/timers/is_asleep. Clock owns mode, not sleep state. Owner-only registry constraints still apply.
- No cold-intake penalty for snow, hunger heat penalty, food faucet, weight regain, stronger fire or new wake alarm without owner-approved design change. QQ-05/06/07 tuning/scope remain PROPOSED.
- Critical allowed_actions is Body's approved authority; unresolved contradictory Needs snow prose must not silently widen that whitelist.

### Requirements
- Backlog coverage / unblocks (verbatim): All Body and Needs TRs. Pin pre/post-step samples, activity maximum, wake ownership, grace/collapse timers, Critical whitelist and Clock mode arbitration against both GDDs; coordinate C4 terminal ordering.
- Preserve B1–B4, N1–N6, all stage hysteresis/one-step rules and every acceptance/performance criterion, including sleep/wait/death edges.

## Decision

At each minute take a detached `MinuteStart`: player position, movement activity, work intensity, sleep state, rest/fire context, Body core/wetness/stage, Needs stomach/weight/hydration/energy/stages/timers and fixed insulation. No substep reads state changed later in that same substep. Clock has advanced that minute and Thermal/Fire/Inventory have completed their F3/C3 stages before Body. Body queries one felt temperature at captured position, using this minute's published Fire sources; missing movement/work defaults to idle/none.

Activity is NOT one shared enum maximum: map movement/work to each system's own numeric table then take max. Body heat idle0/walk0.3/wade0.45/light0.3/heavy0.6; Needs calorie extra0/60/120/80/200, energy rate1/2/3.5/2.5/5. The wade-versus-light ordering differs between tables; never impose enum order. Hydration uses1.5 multiplier for wade OR heavy, not additive. Sleep's captured state suppresses all movement/work extras and treats Body activity as idle for the completed interval.

Body B1 uses captured core, wetness and shiver from the captured stage: gap=felt−5; negative exchange0.088×gap×(1+wetness)/insulation, positive0.3×gap; add highest activity and0.3 shiver only Chilled/Cold; clamp[−4,+3]°C/h, positive rate0 when core≥37. Integrate rate/60 and clamp core≤37; a death crossing clamps exactly30. B2 integrates wetness from the SAME pre-step wetness independently: moving wade gain0.03/h, dry0.6/h at felt≥10 or0.1/h at felt≥0, otherwise0; clamp[0,1]. Immersion sets wetness1 immediately before the next captured boundary, idempotent by event ID; never double-soak. Thus minute drying does not retroactively change B1's rate.

Derive post-step Body stage via B3/B4: ordinary changes at most one stage/minute, falling36.5/35.5/34/32 and rising threshold+0.2, one notification per transition; terminal core≤30 bypasses ordinary stage-step delay and submits hypothermia candidate immediately. Post-Body `is_shivering` and stage are the explicit inputs to Needs N1/N4 for THIS minute. A Warm→Chilled crossing uses no shiver heat in that completed B1 interval but starts its post-Body shiver charge in Needs; a Cold→Hypothermic crossing stops that charge. This is a proposed discrete integration convention to verify with cross-boundary fixtures, not a retuning of rates.

Needs N1–N4 compute from captured sleep/rest/activity and captured fullness/stages, with post-Body shiver/stage: burn=(awake110/asleep65)+max(activity extra)+shiver80; consume pre-step stomach first and lower weight by shortfall/7700, floor40 kg with warning, never gain. N3 drain awake1.4/asleep0.7 ×1.5 for wade/heavy, integrate/60 and clamp hydration[0,100]. N4 sleep8×q_warm[post-Body stage]×q_food[captured fullness], q_warm1/0.7/0.4/0.2/0 and q_food0.5+0.5×min(1,fullness/50); awake fire-rest in wait+1.5, otherwise negative(max activity energy+shiver1.5)×thirst1.2×starve1.2 when applicable. Compute N5 from post-burn weight, cap=max(60,100×(1−2×lost_fraction)); integrate energy then clamp[0,new cap]. N6 derives endpoint need stages, at most one ordinary step per machine/minute, rising hysteresis+2, preserving exact0 hydration and24 h empty rules. Immediate eating leaves Empty/Starving as the GDD requires.

Dehydration grace measures accumulated game minutes continuously at hydration0, including sleep/wait; on a minute crossing from positive to0 begin the grace at that endpoint, not count a full earlier zero minute. Already-zero intervals accumulate1 minute; exactly360 elapsed zero minutes submits one dehydration candidate. Any accepted drink/snow resets grace. Fullness-zero timer likewise begins at the empty endpoint and reaches Starving at1440 minutes; any food resets immediately. Keep integer minute counters plus event-boundary metadata where needed rather than real wall time. Rejected/cancelled consumption never resets timers. C4's checkpoint ordering means a fatal boundary wins over a simultaneously eligible but uncommitted drink.

After numeric integration, Needs alone reconciles sleep endpoints. Chosen sleep allowed energy<90 at night/<50 by day; set is_asleep and request sleep. Awake energy0 proposes collapse/asleep(exhaustion), cancels action per C4. Body worsening while asleep/waiting requests normal and emits wake_request(cold) once/stage step; sleeping at Cold-or-worse must not remain trapped after a collapse. Reconcile a new collapse in that cold context with one forced cold wake and energy floor5, not an infinite same-minute collapse/wake loop. Natural cap wake, explicit normal and all wake causes coalesce into one wake, log every cause. Forced wake from collapsed sleep floors energy≥5; no extra energy from duplicate wakes. Wake endpoint affects the NEXT interval's sleep/activity rates, not a second integration of the current minute.

Needs clears is_asleep on any wake/Clock normal; Clock never writes it. End-of-minute mode priority follows F3: normal beats sleep/wait; sleep beats wait; wait while asleep warns/ignored. Apply resulting mode before processing another owed minute, including the120-tick catch-up loop. Echoed normal notifications are idempotent and cannot trigger an endless request loop. Fire's actual GDD supplies no low-fire wake alarm; Needs' optional wake port is reserved, not enabled scope. User may choose sleep only through the accepted Interaction handoff, not direct UI state mutation.

Body and Needs submit candidate records to Coordinator; public `body_died`/`needs_died` are final winning-cause notifications, not two competing terminal transitions. At the barrier C4 chooses hypothermia>dehydration and death>collapse/immersion, emits exactly one final event/run and gates future ticks/commits/draws. Suppress losing collapse/wake presentation if terminal won. Nonfatal Critical entry cancels non-whitelisted work; whitelist is crawl/add_fuel/blow_embers/sit_warm/drop, with fire reach still required. Tap-out remains an unblocked reserved VS capability, not new MVP UI. Do not permit eat_snow in Critical merely because older Needs edge prose says “or worse”; flag that contradiction for owner/design reconciliation before acceptance, retaining the already-approved Body/Interaction boundary in this proposal.

Eating/drinking/snow use C4 prepared owner commits with Inventory: reject missing food/drink fields (no invented values), stomach overflow>1500 keeps item, accepted food adds kcal/reset timer and Inventory consumes once. Snow adds3 hydration/costs1 energy/takes3 game minutes, with no instant core cooling. Exhausted forbids heavy, not light. Needs publishes distinct `needs_move_speed_mult`, body move_speed_mult stays Body-owned. Restore core/wetness/stage exactly without stage_changed and restore Needs timers/asleep; queue sleep mode before first restored interval, with normal interruption still taking precedence. Deferred save implementation remains out of scope.

### Architecture Diagram
`MinuteStart → Body(B1/B2 → post-stage/shiver + candidates) → Needs(N1–N6 → sleep/wake + candidates) → C4 terminal gate → Clock mode + complete snapshots`; `Inventory/Interaction plans → Needs consumable commit`.

### Key Interfaces
- Preserve `step_minute(context)`, `apply_immersion(event_id)`, `snapshot() -> BodySnapshot`; `try_eat(stack_id)`, `try_eat_snow()`, `request_sleep()`, `wake(causes)` from architecture.
- `MinuteContext` includes typed pre-step values; `BodyStepResult` contains post-stage/shiver/rate, wake and terminal candidate; `NeedsStepResult` contains post-needs/timers/sleep endpoint/candidates. These are application DTOs, not engine-native APIs.
- Preserve GDD public `stage_changed`, `needs_stage_changed(need,stage)`, `wake_request(cold)`, `body_died(hypothermia)` and `needs_died(dehydration)` names/payloads; internal submit_terminal_candidate carries run/minute/sequence/cause and no public double death.

### Implementation Guidelines
- Each owner must integrate once/minute, never once per physics frame or via both public minute_tick and Coordinator call. Sleep must not bulk-skip physiology.
- Body must use pre-step wetness/shiver for B1; Needs must use post-Body stage/shiver but captured sleep/fullness/stages for its interval. Highest numeric activity must be selected independently per table.
- Needs alone must write is_asleep; all wake/mode requests must settle before the next minute; death gates collapse/completion and emits one terminal event.

## Alternatives Considered

### Alternative 1: Peer mutable reads in signal callbacks
- **Description**: Body/Needs each subscribe independently and read current peer fields.
- **Pros**: Fewer explicit context types.
- **Cons**: Connection-order shiver/sleep/rate differences and duplicate wake/death.
- **Rejection Reason**: No reproducible pre/post boundary or once-only integration.

### Alternative 2: Aggregate sleep integration or shared survival owner
- **Description**: Integrate a10-hour lump or merge Body/Needs state into Clock.
- **Pros**: Less loop overhead or one apparent state machine.
- **Cons**: Misses02:30 cold, grace/wake boundaries; violates state/layer ownership.
- **Rejection Reason**: GDD requires minute-by-minute queries, separate causes and sole Needs sleep authority.

## Consequences

### Positive
- Formula inputs and wake timing are explicit/replayable; Body and Needs retain independent owners.
- Collapse/grace/terminal races and differing activity orderings have testable boundaries.

### Negative
- Discrete crossing conventions require numeric fixtures; consumers cannot infer intermediate owner state.
- GDD snow/ Critical contradiction remains an acceptance concern; proposal is not owner approval to change either approved GDD.

## Risks
- Inline godot-specialist review: pure typed arithmetic plus Coordinator stages is idiomatic without deprecated/post-cutoff APIs. Use explicit returns for typed overrides if adapters subclass engine classes; no reliance on lambda reassignment of captured scalar variables. Runtime timing/snapshot isolation remain untested. TD-ADR skipped — Lean mode; no independent approval.
- GDD sync checked Body, Needs, Time, Interaction, Character, Inventory, Fire, Thermal and Morale (9). FOUND: Needs snow-eating “Hypothermic or worse” conflicts with Body/Interaction Critical whitelist; owner/design reconciliation before acceptance, no silent widening or GDD edit. Known Time Rule8/QQ-08 conflict persists. Fire's no-wake rule supersedes Needs' optional low-fire example. No new API rename; Needs already uses needs_move_speed_mult, correcting this author's earlier C2 mismatch note.
- NaN Thermal must reuse last valid felt value/error; if no valid prior exists, hold Body integration and block activation/report rather than invent fatal temperature. Bad insulation/threshold/start-weight/capacity tables log/reject/use approved defaults; malformed state never causes invented death.
- Autonomous calls: Proceed with Body/Needs problem, alternatives/full ranges and scanned dependencies; separate tabs selected pre/post boundary, per-table maxima, sole Needs sleep/wake and terminal candidates; write ADR only, append registry, continue C6. Snow cooling/hunger heat/harshness/scope remain owner-only, not decided.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [body-temperature.md](../../design/gdd/body-temperature.md) | Full provisional TR-body-temperature-001 … TR-body-temperature-029; B1–B4, every stage/activity/wetness/wake/terminal/invalid-data edge, dependency and AC1–20/performance | Explicit pre-step integration/post-stage outputs, Critical authority, bad-sample safety, one cold candidate and retained presentation/restore obligations. |
| [needs-and-weight.md](../../design/gdd/needs-and-weight.md) | Full provisional TR-needs-and-weight-001 … TR-needs-and-weight-033; N1–N6, every consumption/sleep/grace/collapse/weight/stage edge, dependency and AC1–20/performance | Separate max tables, bounded stores/timers, once-only consumption, sleep/mode arbitration, grace/collapse/terminal ports and reported snow-whitelist contradiction. |

## Performance Implications
- **CPU**: Each GDD≤0.02 ms/tick; Body includes one Thermal query, whose standalone C3 ceiling is0.05 ms. These are separate unmeasured target ceilings, not proof the combined Body path meets0.02; report inclusive/exclusive cost and escalate any budget inconsistency to QQ-01 before acceptance.
- **Memory**: Fixed model snapshots/counters plus event sequence guards; no per-frame history required.
- **Load Time**: Validate both tables before activation, restore owners and Clock mode coherently.
- **Network**: None.

## Migration Plan
After acceptance build pure B/N rate and boundary tests, one-minute Coordinator fixtures and collapse/wake/terminal matrix, then content/presentation adapters. Do not retune data to make fixtures pass. C6 adds atomic consumption plans; no GDD, config, prototype or runtime edit now. Save/Load remains deferred and must restore timers, not reset grace.

## Validation Criteria
- Body AC1–9:37/dry/Warm/insulation1 start, +15 felt keeps37, walk+chop heat0.6 not0.9; shiver36 true/33.5 false; asleep35.6→<35.5 one wake+normal; Critical chop refused/fuel allowed;30.01−1.49/60→30/death once; NaN reuses prior; stage order and33.9→34.1 held/34.2 Cold.
- Body AC10–18:−4.2 heavy/Warm−0.21, idle−0.81, Chilled heavy+0.09;−11.9 Chilled−1.19/Hypothermic−1.49; +6.87/core36→+0.86 and+10.32/core36.8→+1.60; soaked heavy−1.02 and extreme clamp−4; wet1 dries100±2 min at+10.3/no drying−4 for5 h; bad thresholds default; constant-night death5.1±0.1 h; strike base0.25+0.06+0.06→0.37; +10.3 fromcore34 reaches≥35.5/hour.
- Needs AC1–10:1200/72/100/90/awake;1400+400 refuses/keeps versus1000+400 consumes; sleep night95 refuses/day45 allows; cold wake and external normal clear sleep same minute; collapse0 with forced wake floor5; zero hydration360 min once/dehydration, drink359 min resets; Exhausted heavy refused; Exhausted+Parched fatigue0.15/action1.375; stages25/10 down/27/12 up once; zero fullness24 h Starving/food resets immediately.
- Needs AC11–18:burn390 heavy+shiver/65 asleep/110 idle/310 walk+heavy;3530 kcal deficit loses0.458±0.002 kg, idle stomach1090/fullness72.7, floor40; hydration−1.4/−2.1/−0.7; sleep10 h+80/+40/+28 and fire rest+1.5/h; loss10/20/30% cap80/60/60; snow+3/−1/3 min; Morale fullness40/loss6%→H52; full day schedule+one400 kcal ration+10 snow yields weight≥71.7/hydration≥70/energy≥50 after sleep.
- Boundary/error matrix: wade+light max separately; Warm→Chilled and Cold→Hypothermic shiver heat versus charge conventions; falling water sets1 once; empty activity ports idle; no last Thermal sample blocks unsafe activation; invalid tables default; restore emits no Body stage_changed; grace359/360 and starving1439/1440; collapse already Cold wakes once/floor5; multiple wake causes one transition; awake normal no-op; Fire out does not auto-wake; wait/sleep loses to normal before next catch-up tick; both deaths→one hypothermia and no lower-priority pose/commit. No Critical snow action pending reconciliation.
- Body AC19–20 and Needs AC19–20 remain unperformed visual/feel obligations: owner notices cold posture after3 real minutes without HUD;≥4/5 order stage clips; hunger/eat-or-keep byday3; collapse preceded by Tired/Exhausted posture. Profile inclusive/exclusive tick ceilings on nominated hardware, not just pure arithmetic. Backpack UI leaves physiology/actions running, explicit pause freezes them, ten-hour sleep still processes600 samples unless wake/terminal stops it.

## Related
- [Master architecture](architecture.md), C5; [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md); [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md); [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md).
- Owner-only: QQ-01 hardware/budget consistency, QQ-05 harshness/recovery, QQ-06 duration and QQ-07 new cold-intake/hunger heat/weight regain/deferred features. All remain PROPOSED; resolve snow/ Critical GDD conflict before `/architecture-decision accept ADR-0008`. No story unblocked.
