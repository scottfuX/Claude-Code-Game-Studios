# ADR-0010: Gathering resolver/depletion and overflow transactions

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/registry/engine-reference audit only; no runtime or visual check.

## Decision Makers
Scott (owner), Devin (author and inline godot-specialist reviewer); no acceptance or independent approval claimed.

## Summary
Gathering must grant approved produce without double-depleting finite Map nodes or losing backpack overflow. Propose a stateless GatheringResolver that prepares G1/G2 yield batches and commits once through Map/Inventory owner plans, leaving action timing, wear and rolls to C4.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core |
| **Layer** | Feature |
| **Knowledge Risk** | LOW arithmetic; HIGH engine pin post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `current-best-practices.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None required; typed value plans and direct owner ports |
| **Verification Required** | Atomic Map/Inventory commits, detached DTOs, once-only notifications; no native adapter assumed proven |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004, ADR-0007, ADR-0009 (all Proposed; acceptance required before implementation) |
| **Enables** | ADR-0011, ADR-0014, ADR-0015 (fuel and gathering presentation) |
| **Blocks** | GatheringResolver implementation; no story files exist |
| **Ordering Note** | Feature resolver consumes Core ports, never owns Map yields or Inventory stacks. |

## Context
### Problem Statement
One gathering completion spans finite-node state and produce creation, with partial failure yields and overflow that must remain visible.
### Constraints
- Registry retains sole Map depletion/Inventory ownership, C4 tokens and one injected roll, no foreign writes; source ADRs remain Proposed.
- No auto-gather/repeat convenience, darkness penalty, new wood source, free food or yield/duration retuning. QQ-05/06/07 remain owner-only.
### Requirements
- Backlog coverage (verbatim): All Gathering TRs; single-success Map depletion, tool wear and wetness recipes, finite-node visuals
- Preserve G1–G4, all action rows, node visuals and AC1–14/performance.

## Decision
GatheringResolver is a run-owned Feature service with validated action/node recipes, no independent yield counter or timer. C4 passes an eligible token and one accepted Outcome. Revalidate node identity/revision/kind/remaining/tool and recipe before the use/roll checkpoint; unknown kind refuses+logs. Prepare both success/failure branches and Inventory overflow plans without mutation.

G1: attempted=min(recipe take,remaining); success keeps attempted and requests Map remaining−attempted once; failure keeps floor(attempted/2), except chop0, and leaves remaining unchanged. Preserve the approved unusual partial-failure faucet; do not “fix” it by depleting failures. A duplicate completion never repeats produce even when failed yields did not change node revision. Final-unit success empties the node; retain depleted mesh and remove verbs. Map owns sticks/logs/bark/grass/stone sub-yields and bush bonus; never infer remaining from visuals. A bush success grants at most one available bonus grass and depletes that bonus once; failure must not consume bonus reserve. Exact bonus-on-failure output is not explicit in G1: propose applying the same floor-to-half per produce line (one grass→0) and flag for design confirmation before acceptance, not an unrecorded new reward rule.

Preserve recipes: bush sticks3 + optional grass1, deadfall sticks2, chop log1, birch bark2, grass2, stone1; durations3/3/4/4/2/1 game minutes and light/light/heavy/light/light/heavy. C4 alone charges one hatchet/knife use per accepted completion plus Mishaps failure damage; no-profile stones has no roll/outcome. Last-use break keeps current result, next start refuses; cancellation produces no result/use/roll. Missing hatchet still permits deadfall branches, no knife refuses bark.

G2 creates wetness by source: standing sticks0, deadfall sticks/logs0.3 or forest0.2, bark0, sheltered grass0.1/open0.4/bush bonus0.1; future snowfall offset0 in MVP, clamp[0,1]. Inventory handles mass-weighted merge; Gathering never dries items. One conserved output batch goes through add_or_pile, fit into backpack and remainder at feet. Validate pile allocation before Map depletion; no output may vanish on capacity failure. Commit Map+Inventory plans synchronously under C4; events queue until all writes complete, keyed by token/consequence IDs. No callbacks or yielding between owner validation and commit.

G3/G4 are derived QA estimates, not auto-production loops or additional timers. G3 rate tests require a sufficiently provisioned isolated fixture because a real finite deadfall cannot provide13.5 logs for a whole hour; report that fixture assumption rather than silently replenish a run node. G4 guards zero/nonpositive free capacity as “cannot haul without freeing load,” not division by zero or infinity trips. Valid8 logs/kit still needs2 trips. Night gathering adds no darkness penalty. Save/Load remains deferred: Map restores yields, Inventory produce; no second Gathering save truth.

### Architecture Diagram
`C4 eligible outcome → Gathering recipe/G1/G2 plans → Map depletion + Inventory add_or_pile → finite-node snapshot/visuals`; `C4 → tool use + activity`.
### Key Interfaces
- `prepare_gather(token,node_snapshot,outcome) -> GatherPlan`, `validate_plan`, `commit_plan(plan,consequence_id)` are application ports using C4/C6 protocols.
- Preserve Map `node_snapshot`/`deplete_node` and Inventory `add_or_pile`; result DTO includes per-produce attempted/kept/overflow and emptied state, not mutable stacks.
### Implementation Guidelines
- Map alone must deplete; only success decrements attempted units. Produce creation must commit once independently of whether yield changed.
- Full backpack must yield a visible feet pile; no second tool-use or Mishaps call in Gathering.

## Alternatives Considered
### Alternative 1: Gathering-owned yield cache
- **Pros**: Local simple counters. **Cons**: Diverges from Map restore/visible depletion.
- **Rejection Reason**: Two authorities violate finite-node ownership.
### Alternative 2: Deplete then independently try inventory insertion
- **Pros**: Short callback flow. **Cons**: Capacity/refusal/crash can lose produce or duplicate on retry.
- **Rejection Reason**: C4/C6 require preflight and conserved atomic output.

## Consequences
### Positive
- One finite source and once-only outputs; wetness lessons survive stacking/overflow.
### Negative
- Recipe/owner plans and partial-failure idempotency require tests; bonus-on-failure ambiguity remains an acceptance concern.

## Risks
- Inline godot-specialist review: typed GDScript records and explicit run-owned ports fit references with no deprecated API; snapshot isolation/queued signals remain untested. TD-ADR skipped — Lean mode, author self-review only.
- GDD sync checked Gathering/Map/Interaction/Inventory/Mishaps (5): current tables already adopt grass/stones; historical “adopt next revision” prose is stale, not a rename to perform. G1 failure partial-yield and bonus ambiguity are explicitly retained/flagged; no GDD edited. Updated Time Rule8 is consistent with inherited QQ-08 behavior.
- Autonomous calls: Proceed assumptions/alternatives/dependencies/full range; separate design choices Map-only depletion, prepared output batch, source wetness and no extra use/roll; write ADR only, append registry, continue S2. Proposed bonus interpretation is not owner acceptance; no tuning/scope choice settled.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [gathering.md](../../design/gdd/gathering.md) | Full provisional TR-gathering-001 … TR-gathering-023; every rule/G1–G4/edge/dependency and AC1–14/performance | Validated recipes, sole-success Map depletion, conserved produce/overflow, tool/activity separation, wetness, finite-node visuals and explicit ambiguity/testing obligations. |

## Performance Implications
- **CPU**: GDD resolution≤0.02 ms/completion, including plan creation; measure complete Map/Inventory path separately on nominated hardware.
- **Memory**: Immutable recipes/short-lived plans; Map/Inventory retain persistent state.
- **Load Time**: Reject invalid bush grass>sticks/3 and unknown recipe references before activation.
- **Network**: None.

## Migration Plan
After acceptance add pure recipe/G1/G2 tests and owner-plan fixtures, then wire C4 and depleted visuals; no implementation/prototype/GDD changes now. No automatic repeat or additional save system scope.

## Validation Criteria
- AC1–8: bush7sticks/2grass success→3dry sticks+1grass0.1,remaining4/1; chop6 success→log0.3/forest0.2,left5, failure0/left6/damage10; knife refusal; full pack feet pile; last unit clears verbs; chop/stones heavy/sticks light; bonus exhausted means sticks only; G1 failed3→1/unchanged7 and last1 success1.
- AC9–12:6logs0.3+2dry→0.225±0.001; seeded isolated G3 rate13.5±1.5 logs/h (sufficient finite fixture explicitly identified);8logs/kit2trips; deadfall kindling wet0.3 yields Mishaps damp0.15.
- Empty/unknown/depleted node refuses safely; malformed bonus count rejects; zero free capacity never divides; partial remaining clamps; token redelivery produces/depletes once; preflight inventory/pile failure leaves Map/tool/RNG unchanged; last-use break keeps log; external loss/immersion cancels with no interrupted output/use/roll. Partial failure keeps the approved node reserve; bonus-on-failure test awaits design confirmation.
- AC13–14 require owner work/light pressure and second-run dry-bush/birch preference; finite meshes must visibly thin/cut/strip/hollow, dry versus damp audio/values readable. Visual/playtest not performed. Profile≤0.02 ms and inherited load/activity/timer behavior; no measured compliance claimed.

## Related
- [Architecture](architecture.md), S1; [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md), [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0009](adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md).
- Owner-only repeat convenience/durations/darkness/new sources and QQ-01 budgets remain undecided. `/architecture-decision accept ADR-0010` is separate; fresh-session architecture-review required, no story unblocked.
