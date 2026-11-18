# ADR-0011: Fire stage machine, material consumption and heat/light publication

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/reference review; no engine, timing or visual test.

## Decision Makers
Scott (owner), Devin (author/inline godot-specialist reviewer); no acceptance or independent approval.

## Summary
Fire needs coherent build materials, game-minute ember deadlines and same-minute heat/light without directly waking the survivor. Propose FireController-owned stage records, escrowed materials and C4/C6 atomic consumption, with exact authoritative Thermal publication separated from cosmetic render updates.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core / Rendering |
| **Layer** | Feature |
| **Knowledge Risk** | HIGH rendering post-cutoff; LOW formulas |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/rendering.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None required; proposed OmniLight3D/GPUParticles3D adapters, not new AreaLight3D |
| **Verification Required** | Light/particle signatures and radius/readability on pin, exact Thermal publication, ember deadlines and resource conservation |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003, ADR-0004, ADR-0006, ADR-0007, ADR-0009, ADR-0010 (all Proposed; acceptance required) |
| **Enables** | ADR-0012, ADR-0014, ADR-0015, ADR-0016 |
| **Blocks** | FireController implementation; no story files exist |
| **Ordering Note** | Feature publishes Core Thermal source values; no Core concrete Fire import or direct Body heat mutation. |

## Context
### Problem Statement
Materials must not vanish on refused lighting/fuel, ember timers must survive skip boundaries, and Body must feel a dying fire this minute.
### Constraints
- Registry retains owner plans, one C4 roll/use, C3 source barrier and no wake alarm. Body/Needs alone govern waking.
- No fire-budget, larger warmth, easier ember window, new ignition or paid asset decision; QQ-01/03/05/07 remain owner-only.
### Requirements
- Backlog coverage (verbatim): All Fire TRs; build/ember/smother transitions, timer/source coherence and unattended losses; no direct wake
- Preserve FI1–FI6, every build/material/critical/restore edge and AC1–20.

## Decision
FireController owns stable site/fire IDs, stage, ringed flag, F, burning wetness, material escrow and absolute game-minute ember/window deadlines. Validate site inside Map, slope≤8°, no ice, drift≤0.6 m; bare rock skips clearing, otherwise clear5 heavy, optional stones6/3min light, tinder arrange2min with bark2 OR grass3 OR feather1 plus sticks4. At most2 simultaneous fires; preflight admission reserves capacity to reject a third before consuming/building. Retain cold cleared/ringed site history separately from active-source admission.

Inventory remains sole stack owner: arranging transfers designated inputs into a Fire-owned container/escrow plan retaining exact IDs/count/wetness, not premature anonymous deletion. strike repeat0.5min with rod and one C4 outcome moves Laid→Smoldering; blow1min within3 game minutes succeeds→Kindling. On successful ignition consume tinder+kindling into FI5 fuel (dry bark recipe F26). Failed/expired blow consumes tinder, keeps kindling available at site and returns Cleared/Ringed; next arrange preflight accounts for retained kindling, never charges four sticks twice. Carving stick/knife through C4 yields feather_stick wetness=source×0.5; failure follows profile waste/damage. No resolver draws its own luck.

After lighting derive stages from F: Burning≥30, Kindling5≤F<30, Embers<5; ember expiry90 game minutes from entry, Out after expiry. Adding fuel in Embers requires a successful blow to relight; failed blow leaves Embers with finite original expiry, no new tinder cost. Deadlines advance only via Clock minutes, including sleep/wait, never wall Timer. C4 cancellation does not reset Fire's independent smoldering deadline; expiry consumes tinder even if the player moved away. On exact expiry/completion boundary process Fire deadline stage before C4 revalidates a blow.

Preserve FI1 s=1−exp(−F/60); FI2 heat=28s(1−0.4w), Embers4, Out0; FI3 radius0.8+2.6s, Embers1; FI4 burn=(0.25+F/240)×(1+0.08×wind_eff×(ringed?0.6:1)); FI5 added=fuel_value×(1−0.3wetness), w'=(wF+wetness×added)/(F+added); reject over300 with item kept, never truncate paid units to fit; zero-fuel addition refuses safely rather than divide by0. Burning wetness dries0.05/min; FI6 light1.5+5s, Embers1.5. Wet log>0.6 into pre-add Kindling F<30 smothers to Embers, retains that log's effective fuel and shows hiss/white smoke. Do not test smother against post-add F or discard the log.

Minute convention: use pre-step F/w to compute FI4 burn; apply/clamp F, dry burning w, derive post-step stage/deadline/heat/radius/light and publish before Inventory/Body queries in F3. Out disables source immediately. Same radius is Thermal.radius_m and Fire.warm_radius; Morale reads Fire, never infers from6m light. O3 resolved by Scott (2026-11-19): publish exact authoritative heat/radius to Thermal every minute before Body queries, and at action commits; the >0.1 threshold applies to visual updates only. Changes≤0.1 must still reach Body in the same minute.

On transition Out emit one unattended loss iff captured Needs asleep OR distance>15m; awake near emits none. Token/run-stage sequence deduplicates losses. Never request wake/normal from Fire; only Body feels cooling and requests wake. Rest target availability may stop Interaction rest/return normal without inventing a sleeping alarm. Critical permits add_fuel/blow only through Body whitelist, not strike/lay. Restore deferred stage/F/w/deadlines exactly and re-register Thermal before first tick; no replayed loss event. Out-site snowfall reset is reserved VS scope.

### Architecture Diagram
`C4 token + C6 material plans → Fire stage/escrow → FI minute update → exact Thermal source + render snapshot + once-only unattended loss`; `Thermal wind → FI4`; `Body cold → Needs wake`.
### Key Interfaces
- Preserve Fire source `{id,position,heat_c,radius_m,enabled}`, warm_radius/fire_burning, stage snapshots and `loss{kind:fire_died_unattended}`.
- Proposed `prepare_fire_action(token,inputs,outcome)`, `step_minute(context)`, `snapshot()` and C4 validate/commit ports; application contracts, not native Godot methods.
### Implementation Guidelines
- Material transfer/consume and fire state must commit atomically; refusals must keep inputs. Cause cue must precede failure result.
- Fire must publish same-minute source/radius and never directly warm Body or wake Needs. Out/loss/deadline transitions must be once-only.

## Alternatives Considered
### Alternative 1: Scene Timers and light-radius-derived heat
- **Pros**: Easy visual prototype. **Cons**: Skip loses deadlines, brightness is not warmth, callback lag heats after Out.
- **Rejection Reason**: Violates authoritative Clock/Thermal barriers.
### Alternative 2: Consume all material at arrange and wake on low fuel
- **Pros**: Fewer escrow records, kinder nights. **Cons**: Loses kept kindling and changes approved unattended-cold design.
- **Rejection Reason**: GDD requires exact consumption and explicitly no Fire wake.

## Consequences
### Positive
- Material conservation and exact source publication survive skips/interrupts; cold nights retain their story.
### Negative
- Escrow/deadlines need validation; source threshold tension must be reconciled, not masked by visuals.

## Risks
- Inline godot-specialist review: Node/value model plus light/particle adapters fits references, no deprecated API required. Glow/tonemapping changed4.6; nighttime flame/embers need pinned-engine screenshots. TD-ADR skipped — Lean mode; no runtime/independent approval.
- GDD sync checked Fire/Thermal/Inventory/Interaction/Body/Needs/Morale (7): no rename, no-wake matches current Fire; source-threshold tension noted. Updated Time Rule8 checked consistent with inherited QQ-08. No GDD edit.
- Autonomous calls: Proceed assumptions/ranges/dependencies; separate design tabs stage+deadline owner, escrow plans, exact authoritative source versus cosmetic threshold; ADR-only write, append registry, continue S3. No owner tuning/cost/scope choice settled.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [fire.md](../../design/gdd/fire.md) | Full provisional TR-fire-001 … TR-fire-031; all rules/FI1–FI6/edges/dependencies and AC1–20/performance | Stages, site/build escrow, timers, critical relight, smother, owner materials, source/light coherence, unattended loss/no wake and explicit threshold verification. |

## Performance Implications
- **CPU**: ≤0.02 ms/fire/tick GDD target; profile inclusive source/plan path and coalesced render work separately; no measurement claimed.
- **Memory**: Two active fire records, persistent cold sites and bounded escrow; renderer effects separately budgeted under QQ-01.
- **Load Time**: Reject b_div<60/h_max≥30 and malformed references using approved defaults; restore sources before activation.
- **Network**: None.

## Migration Plan
After acceptance test pure stages/FI/deadlines and atomic escrow fakes, then C3 publication and rendering. Do not alter GDD/config/prototypes or enable VS weather/new ignition now.

## Validation Criteria
- AC1–10: flat snow clears/ice refuses; bark2+sticks4→Laid,sticks3 refuses; strike→Smoldering/3min expiry consumes tinder-keeps sticks; successful blow F26±0.5; wetlog0.8 smothers;F280+log refuses/keeps; Thermal exact radius matches Morale; asleep2m Out one loss/awake2m none; Critical Embers fuel+blow allowed;90min Embers expiry or successful relight.
- AC11–17: F120 dry24.2±0.1/3.05±0.01, F26 9.8/1.71,Emb ers4/1; wet0.3 heat21.3; ringed open burn0.836±0.005;F240 Kindling4.3/Embers5.5/Out7.0±0.1h,unringed Embers5.1;wetlog+54.6→174.6/w0.094±0.002/dry2min; light5.8±0.05/Embers1.5; invalid b_div/h_max reject; night02:30 near1.5m felt~+6.5 warms Body.
- Empty escrow/missing material/unknown IDs/third fire refuse atomically; duplicate actions/Out notification do not consume/lose twice; zero fuel never NaN; exact deadline wins revalidation; cancellation doesn't extend window; failed ember blow retains fuel/timer; same-minute Out reaches Body/Inventory; unattended distance15m boundary and sleep handled; restore no duplicate loss and source before tick.
- AC18–20 unperformed owner relief-before-dark, cold wake/relight night and screenshots distinguishing strong/embers/smoke; O3 threshold interpretation is owner-resolved (2026-11-19); test same-minute Body sampling for changes≤0.1, including extinguish to zero. Budget still requires profiling. Visual/runtime/performance unverified.

## Related
- [Architecture](architecture.md), S2; [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0009](adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md).
- QQ-01/03/05/07 budgets, audio sourcing and easier/larger warmth remain owner-only; `/architecture-decision accept ADR-0011` separate, no story unblocked.
