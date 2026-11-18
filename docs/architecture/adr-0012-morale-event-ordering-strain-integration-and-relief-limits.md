# ADR-0012: Morale event ordering, strain integration and relief limits

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/registry/reference audit; no runtime simulation or playtest.

## Decision Makers
Scott (owner), Devin (author/inline godot-specialist reviewer); no acceptance or independent approval.

## Summary
Morale must accumulate believable strain and bounded relief without event-order exploits or taking control from the player. Propose one minute-owned MoraleModel with ordered deduplicated events, timestamped action streaks, derived H/P/Resolve and capped rituals/second wind followed by one hysteretic state step.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core |
| **Layer** | Feature |
| **Knowledge Risk** | LOW rule arithmetic; HIGH engine pin post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `current-best-practices.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None required; typed direct calls/value snapshots |
| **Verification Required** | Stable event ordering, detached records, exactly-once skip boundaries/restore and bounded runtime bookkeeping on pin |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003, ADR-0007, ADR-0008, ADR-0009, ADR-0011 (all Proposed; acceptance required) |
| **Enables** | ADR-0013, ADR-0014, ADR-0015 (read-only mood presentation) |
| **Blocks** | MoraleModel implementation; no story files exist |
| **Ordering Note** | Final Body/Needs snapshots and committed losses/outcomes feed the F3 Morale stage, not per-signal integration. |

## Context
### Problem Statement
Failure bursts, relief and night boundaries must produce the same state regardless of subscription order; trivial success farming and unlimited rituals must not erase the intended pressure.
### Constraints
- Registry retains C4 physical causes/RNG, C5 physiology ownership, C6 losses and Fire no-wake. Morale never writes those owners or names itself as a failure cause.
- No Morale meter, kill, evacuation, forced tap-out, action prohibition or input takeover. Deferred Diary/Wildlife/Rivals/Injury/keepsakes provide no MVP inputs.
### Requirements
- Backlog coverage (verbatim): All Morale TRs; streak timing, meaningful success, one-state-step hysteresis, ritual/second-wind caps and delayed offers
- Preserve F1–F7, all feeling/presentation contracts and AC1–25/performance; QQ-05 tuning and QQ-07 relief additions remain owner-only.

## Decision
MoraleModel owns stored L/F/G (start0), mental_state (start Steady), action failure timestamp deques, ritual/second-wind/day/night caps and pending offers. H/P/Resolve are recomputed, not independently mutable or saved truth. Accept typed run/sequence envelopes via enqueue_event; reject duplicate/stale events and warn/ignore unknown action/kind/severity, never invent severity. A minute flush groups losses→failures→successes→comforts→rival/medical, stable source sequence within each category; apply each once, then rates, then derive H/P/R/state once. Events arriving during publication wait for the next flush, never reenter integration.

For F2 count prior failures of THAT action inside a sliding120 game-minute window since its most recent success; age timestamps individually, not a single “last failure” timer. Failure adds severity4/8/15×(1+0.25×min(prior_streak,4))×keepsake factor. A success is meaningful if profile.base_fail≥0.10 OR that action has a prior streak≥1; lift6 or streak-ending12 respectively. ANY success clears that action's deque, even trivial; other action outcomes never clear it. Morale streaks differ from Mishaps'4-fumble guard and must not share counters. Clamp each event's resulting strains[0,100], discard overflow rather than banking it. Emit strain_spike for individual |delta|≥5, not a fabricated aggregate.

F1 L/hour=0.6×(1+0.08×(day−1))×(sleep0.5/day1/night1.5)×keepsakeL; no passive L decay. F2 passive F−1/hour awake resting at burning fire,−2 asleep, else0. F3 G losses: unattended fire10 plus F8, tool10/other6, future shelter15, dawn milestone each7thday8; G decay−0.4/hour. Derive F4 H=0.6×(100−fullness)+0.4×100×min(1,max(0,weight_lost_frac)/0.15), clamp; invalid start_weight→weight_loss0/error. F5 P=max(clamp(100×(36.5−core)/(36.5−33),0,100),injury0 in MVP). F6 R=100−(0.6 weighted_mean+0.4 max_strain), weights L/F/G/H/P0.25/0.25/0.15/0.20/0.15 normalized. Dominant uses weighted contributions, ties L>F>G>H>P.

State falling strict<65/<40/<20, rising≥70/45/25, at most one step each minute in either direction. F7 penalties0/0.03/0.06/0.10 and duration1/1.05/1.12/1.20; C4 owns final failure clamp≤0.90 and action duration cap. Inherited pre-step action multipliers never change already-running duration. Snapshot hidden R only for Feedback/Diary/debug, never HUD.

Detect fire ritual only awake/non-skip continuous idle≥20 game minutes, core≥36, in Kindling/Burning warm_radius; reset continuity on invalid conditions. Apply L−4/G−3/F−3, at most once/game hour and3/day. Sunrise awake outdoors idle≥10 minutes within Time window gives F−5/G−2 once/day. Sleep AND wait skips integrate every minute with sleep multipliers but cannot accrue ritual eligibility. Second wind eligibility uses the mental_state at flush start (no intermediate state re-evaluation): first meaningful success/ritual while Breaking grants extra F−20/L−10 once/day, then latch until next day. Document this discrete convention in tests. Day resets precede new-day integration; dawn milestone is distinct from midnight reset and deduplicated.

At nightfall use the completed tick's state to emit one offer if Fraying/Breaking: quiet normally, plea on second consecutive Breaking night; ANY below-Breaking nightfall including Fraying resets that count. Sleeping nightfall defers delivery until wake if still qualifies, keyed by night ID to prevent repeats; no run-ending call or extra penalty for refusal. C4 terminal freezes values and suppresses late offers/relief. Restore deferred stored strains/state/caps/streak timing/night counters exactly; recompute H/P without spikes on first tick.

Deferred comforts retain typed ports but no MVP producers: first Diary/night L−15/G−5, WildlifeL−3, rival L+2/F−2, medical moderate disappointment. Keepsake gain multipliers multiply per stored strain with floor0.70, never survival bonuses. No enabling relief mechanics just because schema has a port.

### Architecture Diagram
`committed outcome/loss envelopes + final Body/Needs/Fire/Time snapshots → ordered Morale flush → rates/derived strains → one state step → read-only modifiers/Feedback/offer`.
### Key Interfaces
- Preserve `enqueue_event(event)`, `step_minute(context)`, `snapshot() -> MoraleSnapshot`, `state_changed`, `strain_spike(dimension,delta)`, `tap_out_offer(strength)`.
- Snapshot contains hidden strains/Resolve, dominant_strain and F7 outputs; application value ports, never writable fields or native Godot claims.
### Implementation Guidelines
- Morale must integrate once/minute and order categories before recomputing once. Timestamped per-action streaks must expire by game time.
- Relief must respect hour/day/night caps; no rituals during skip, no duplicate second wind/offer and no control/terminal authority.

## Alternatives Considered
### Alternative 1: Immediate per-event state changes
- **Pros**: Responsive simple callbacks. **Cons**: Event order causes repeated threshold hops and relief exploits.
- **Rejection Reason**: GDD mandates fixed order and one state step/tick.
### Alternative 2: Shared streak/RNG guard or unlimited comfort
- **Pros**: Less state, easier recovery. **Cons**: Confuses120-minute all-failure streak with fumble-only guard; changes pressure and scope.
- **Rejection Reason**: Contradicts F2 and bounded relief/owner decisions.

## Consequences
### Positive
- Deterministic, bounded pressure without hidden action bans; replayable night/relief bookkeeping.
### Negative
- Several independent caps/time windows need restore tests; discrete eligibility boundaries must be explicit.

## Risks
- Inline godot-specialist review: typed arithmetic/event queue fits references, no deprecated API required; runtime queue/restore still untested. TD-ADR skipped — Lean mode; no independent approval.
- GDD sync checked Morale/Time/Body/Needs/Mishaps/Inventory/Fire (7): names/cause/one-stream contracts align. Morale's generic “menus accrue nothing” must be read with updated Time Rule8's explicit backpack exception; checked consistent using that authoritative exception, no new pause. No GDD edited.
- Autonomous calls: Proceed assumptions/ranges/dependencies; separate tabs ordered flush, timestamp deques, single state step and bounded relief/offer records; ADR-only write, append registry, continue P1. No harshness/relief/content/paid-tool decision settled.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [morale-and-mental-state.md](../../design/gdd/morale-and-mental-state.md) | Full provisional TR-morale-and-mental-state-001 … TR-morale-and-mental-state-038; feeling map/rules/F1–F7/all edges/dependencies/AC1–25/performance | Ordered once-only events, exact formulas/streaks, bounded rituals/second wind/night offers, hidden outputs and forbidden control/terminal behavior. |

## Performance Implications
- **CPU**: GDD≤0.05 ms/minute, no authoritative per-frame work; benchmark burst queues and caps on nominated hardware.
- **Memory**: Age120-minute streak deques; retain only safe dedupe watermarks and necessary day/night records, not unbounded event history.
- **Load Time**: Validate positive weights/threshold ordering and t_comfort>t_max_pain; invalid table uses approved defaults.
- **Network**: None.

## Migration Plan
After acceptance implement pure formulas/ordered queue and boundary fixtures, then read-only Feedback/Audio consumers. No GDD/runtime/prototype edit; future comfort/save scope stays deferred. Accepting this ADR never accepts tuning on Scott's behalf.

## Validation Criteria
- AC1–11: start LFG0/Steady; pause10min unchanged; trivial0.05 no relief but clears streak; meaningful0.25 F20→14;20min ritual once/hour,3/day; Breaking success lift+20/F and−10L once/day; Fraying quiet offer;2Breaking nights plea/Fraying resets; no kill/action block under any event sequence; loss→failure→success and one R recomputation.
- AC12–21:64.9 Strained/69.9 holds/70 Steady;R15 crosses3 states/3 ticks; F1 day1+0.60/day10night+1.548/sleep+0.30;5minor failures sum30,next each8;firelossG10/F8,G10 decays0 after25h;H fullness40/loss6%52,bad start fullness-only/error;P37/35.1/33/30→0/40/100/100;R all0=100/all100=0/example31.2; Fraying base0.25→0.31/duration1.12,Breaking0.85 cap0.90;3keepsakes floor0.70.
- AC22 Body35.1/Needs40,6% yields P40/H52 within one tick. Empty queue still integrates rates; unknown/stale/duplicate events inert/warn;120-minute edge timestamps expire individually; success on another action leaves streak; missing deferred producers no fabricated comfort; wait/sleep no rituals; wake-delayed offer once/night and suppressed if no longer qualifies; terminal freezes, restore derives no spikes.
- AC23–25 remain unperformed:≥4/5 identify state direction without HUD, owner names≥3feelings, failure always shows physical cause. Profile≤0.05 ms; backpack continues inherited simulation, pause gates it; no runtime/visual/budget claim.

## Related
- [Architecture](architecture.md), S3; [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md), [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0008](adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md).
- QQ-01/05 budgets/emotional tuning and QQ-07/10 deferred relief/scope remain owner-only. `/architecture-decision accept ADR-0012` separate; no story unblocked.
