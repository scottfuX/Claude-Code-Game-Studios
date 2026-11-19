# ADR-0009: Item/action data validation, inventory transfers and tool-use transactions

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/reference/registry review; no runtime transfer, data-import or performance test.

## Decision Makers
Scott (owner) and Devin (authoring agent, inline godot-specialist review); Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Inventory must preserve item identity/counts across partial transfers, overflow, wetness and action effects without exposing mutable definitions. Propose validated immutable catalog data, uniquely owned stack/container records and revision-checked atomic owner commits under C4's action gate.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core |
| **Layer** | Core |
| **Knowledge Risk** | LOW data/arithmetic domain; HIGH post-cutoff engine pin |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `current-best-practices.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None required; Resource import adapter and typed value records. If packed arrays are used, 4.7 element writes need explicit dirty notifications. |
| **Verification Required** | Resource-cache isolation, detached nested snapshots, content cross-reference validator, exactly-once transfers/tool notifications and pinned-engine import signatures |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003, ADR-0006, ADR-0007, ADR-0008 (all Accepted; must be Accepted before implementation) |
| **Enables** | ADR-0010, ADR-0011, ADR-0012, ADR-0016; deferred save/kit adapters |
| **Blocks** | ItemCatalog/InventoryModel implementation pending acceptance; no story files exist |
| **Ordering Note** | Pure catalog can validate independently; runtime commits refine C4/C5 ports without making those ADRs depend back on this adapter. |

## Context

### Problem Statement
Shared Resource mutation or transfer callbacks can duplicate items, lose overflow, reset wetness/durability or consume a ration after refusal. Tool break must not cancel the valid result that used its last durability.

### Constraints
- Registry: sole-owner writes, detached values, prepared synchronous C4 commits, C5 Needs ownership and C3 Fire-before-drying barrier. Inventory does not roll RNG, choose losses or set Body wetness.
- Preserve fixed10-item kit/8 pemmican, no food faucet or kit UI scope; winter clothing/radio/camera remain protected. Sleep-bag insulation bonus remains inactive in MVP. Owner tuning/cost/scope calls stay PROPOSED.

### Requirements
- Backlog coverage / unblocks (verbatim): All Item Database/Inventory TRs. Immutable definitions, IDs/stack identity, conservation, partial fit/overflow, wetness merge/drying, durability/loss versus consumption and atomic owner commits.

## Decision

ItemCatalog owns validated definitions keyed by stable StringName item/action/profile IDs. Author via typed Resources/data rows, compile before activation into catalog-owned immutable records; return copied/read-only value views, never cached writable Resource references. Runtime count/wetness/durability/container never lives on ItemDefinition. Validate unique IDs, required localized keys/category/positive finite backpack mass, integer stack_max≥1, tool stack_max1/durability_max>0, optional food/drink/fuel fields with documented ranges, quality/wetness[0,1], and every referenced tool/resolver/profile/clip/item ID. Missing optional food means non-edible, not zero-calorie food; unknown ID/missing required field refuses operation+error. Worn clothing's authored mass dash is an explicit non-carried case, not an invented backpack mass. Invalid capacity≤0, l_free≥1 or negative mass tables reject/log/use approved defaults as the GDD specifies. Missing required kit/action content blocks activation rather than fabricate values. Future optional rows are not new enabled scope.

InventoryModel alone owns Stack{stack_id,item_id,count,container_id,wetness?,durability?,revision}, Container IDs for backpack/worn/piles and monotonically assigned run-local identities. Every live stack has exactly one container; split allocates a new ID and copies source state; moved whole stacks retain identity. Merge into stable existing target IDs, remove depleted source IDs and invalidate their revisions. Tools never merge, and callers refer to stack_id rather than choose “any hatchet” at commit. Piles own position and persist whole run; pick nearest within1.5 m on drop, exact ties by stable pile ID, else create a pile. Worn/radio/camera drop refuses; valid carried-item drop has no capacity restriction and is a transfer, never loss.

Prepare transfers from snapshots then validate all source/destination revisions at C4's checkpoint. Compute integer units fitting weight using catalog unit mass, clamp to requested/source counts, merge up to stack_max and open overflow stacks without inventing a slot limit. Whole unit heavier than free mass means taken0/refusal; partial fit leaves the exact remainder at source and reports 背不动了. Use deterministic unit-mass arithmetic/tolerance only for roundoff, never to admit an extra unit. Generated produce uses `add_or_pile`: fit units enter backpack, excess becomes a feet pile; if placement cannot validate, refuse the whole preflight, never delete produce. Failed Gathering/depleted nodes must not generate a batch. Before/after conservation holds per item across all owners plus explicit authorized creation/consumption/loss deltas.

When merging wettable stacks use `(m1*w1+m2*w2)/(m1+m2)`, with masses=count×unit mass; split preserves wetness and merge preserves total wet mass. Nonwettable items have no wetness, not a synthesized damp value. On immersion set backpack fuel/tinder1 only, not food/tools or Body clothing. Accepted recipe-specific feather_stick creation retains its defined source-stick wetness×0.5, not generic drying. Each minute after Fire's source publication apply I4 once/stack at pile position or player position for backpack: felt≥10 dry0.5/h, felt≥0 dry0.05/h, below0 dry0, divide60 and clamp[0,1]. Camp status is derived from a burning Fire warm_radius; no stale camp flag or second special drying multiplier. Thermal invalid sample logs/skips drying for that stack instead of inventing warmth. Body B2 and Inventory I4 remain different rates/owners.

Publish I1 load=backpack mass/25, I2 speed=1−0.3×max(0,(load−0.5)/(1−0.5)) and hauling iff load>0.7; no worn/show-kit mass. Character alone combines speed penalties; moving hauling activity is heavy, standing is not. I3 MVP insulation remains1.0 awake/asleep; reserved future sleeping-bag0.5 bonus does not activate here.

Use C4 prepared plans for tool use, damage, loss, consumption and produced stacks. Normal accepted completion/attempt charges I5 exactly one use (−1); profile damage is an additional once-only consequence ID, clamp durability≥0. If the accepted use/damage reaches0 remove tool and emit one `loss{kind:item_lost,item_class:tool,item_id}` after the transaction, but keep that completion's accepted result. Next start refuses. External loss before completion cancels the action without a use/roll. A duplicate loss/damage/use never charges twice. Consuming food/drink/fuel removes units without loss; tool break is explicitly a loss despite normal-use provenance. Transfer/drop emits no loss. Mishaps decides stochastic external loss, Inventory validates/removes; grief belongs only to Morale.

Cross-owner transactions prepare all effects first: Needs accepts stomach/hydration before consuming the food; Fire accepts fuel/tinder before removing it; Gathering/Map commit authorized yield plus output plan; action gate admits tool use and profile outcome. No plan mutates or emits during prepare. Validate revision/resource availability and both success/failure branches before use/RNG; execute a non-yielding commit whose owner operations cannot then refuse, with notifications queued until all writes finish. On invalid/stale/duplicate token reject without any owner/RNG mutation. Unexpected commit invariant failure gates the run/diagnostic, never retries a partial transaction. Inventory never writes Needs/Fire/Map fields and never passes writable stack arrays to them. Restore later validates all counts/IDs/references atomically and exactly restores wetness/durability/container ownership; camp status recomputes after Fire registration, not serialized truth.

### Architecture Diagram
`validated Item/Action/Profile rows → immutable ItemCatalog`; `ActionRunner/Needs/Fire/Gathering plans → InventoryModel prepare/validate/commit → stacks/piles + detached load/UI/loss snapshots`; `Thermal + Fire → once/minute drying`.

### Key Interfaces
- Preserve architecture `definition(item_id) -> ItemDefinition`, `add_or_pile(stacks,position) -> TransferResult`, `consume(request) -> Result`, `use_tool(id) -> Result`; adapters carry stable stack/token/revision rather than mutable references.
- `prepare_transfer(request) -> InventoryPlan`, `validate_plan(plan) -> Result`, `commit_plan(plan,consequence_id)` are proposed application ports, not asserted Godot methods. TransferResult distinguishes accepted/remainder/refusal and new pile/stack IDs.
- GDD loss payload stays `kind:item_lost,item_class:tool|other` plus item ID; all internal envelopes include run/sequence and no duplicate public grief event.

### Implementation Guidelines
- Catalog definitions must be immutable to consumers; mutable stack ownership must be singular, counts integer/nonnegative and transfers conserved.
- Partial pick-up must retain remainder; generated overflow must become a pile, never disappear. Wetness merge must be mass-weighted and tools must retain individual durability.
- Accepted tool-breaking completion must retain its result; consumption/drop must never emit item_lost. No cancelled action may use/consume/roll via Inventory callbacks.

## Alternatives Considered

### Alternative 1: Mutable shared Resource per item
- **Description**: Store count/wetness/durability on loaded ItemDefinition.
- **Pros**: Fewer runtime record types.
- **Cons**: Resource cache aliases stacks/runs, UI can mutate gameplay, tool identities collapse.
- **Rejection Reason**: Violates immutability and sole stack/container ownership.

### Alternative 2: Resolver directly removes input then adds output
- **Description**: Each consumer edits Inventory in callbacks and handles overflow later.
- **Pros**: Short imperative implementation.
- **Cons**: Rejected food loses items, stale callbacks duplicate output, partial commits lose resources.
- **Rejection Reason**: Cannot guarantee atomic owner effects or conserved overflow.

## Consequences

### Positive
- Stable identity and prepared commits make transfers, wetness and losses reproducible/testable.
- Definitions/data can change through validation without scattered hard-coded values.

### Negative
- Validators/typed plans and idempotency ledgers require implementation effort; UI must refresh snapshots instead of mutate rows.
- Atomic recipes require coordinated owner preflight, not an arbitrary callback extension point.

## Risks
- Inline godot-specialist review: Resource authoring with copied run-owned records and direct typed owner ports fits engine reference; no deprecated APIs. Godot Resources are not inherently frozen; cache isolation/nested snapshots must be tested. Explicit dirty notifications required for4.7 packed writes if adopted. TD-ADR skipped — Lean mode; no runtime or independent approval.
- GDD sync checked Inventory, Interaction, Mishaps, Needs, Body, Fire, Gathering and Time (8). No renamed item/API/payload; feather_stick/grass/stones and kit rules already exist. Checked updated Time Rule 8 after merging origin/main: consistent with resolved QQ-08. Worn-drop exception refines general “drop always allowed.” No GDD edit.
- GDD I5 narrative says~40 swings/log but Interaction charges one use/completion; preserve normative one-use contract and flag narrative tuning for owner review, not multiply uses. I4 strict<0.2 at1.6 h meets the stated±0.05 tolerance only just after96 min; test tolerance without retuning0.5/h.
- Autonomous calls: Proceed on conservation/immutable-data problem, alternatives/full range/scanned dependencies; separate tabs chose typed validated catalog, unique stack IDs, conserved plans, wetness/durability/loss boundaries; ADR-only write, registry append, then requested dependency-graph repair. No kit/food/durability tuning or paid data tool approved.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [item-database-and-inventory.md](../../design/gdd/item-database-and-inventory.md) | Full provisional TR-item-database-and-inventory-001 … TR-item-database-and-inventory-030; rules1–12, I1–I5, all edges/dependency/presentation ports and AC1–19/performance | Immutable validated IDs/fields, exact kit, unique conserved containers/stacks, partial fit/pile overflow, wetness/soak/dry, MVP insulation, tool-use/damage/loss versus consumption and atomic owner commits. |

## Performance Implications
- **CPU**: GDD≤0.1 ms/pick-up/drop, drying≤0.05 ms/tick for50 stacks. Include preflight/commit and Thermal query cost; benchmark, do not claim measured compliance.
- **Memory**: Persistent pile/stack records; immutable definitions shared read-only, detached bounded snapshots. Ledgers prune only after safe sequence watermark/run teardown.
- **Load Time**: Validate full cross-reference tables and fixed kit once before activation; no runtime defaults invented for unknown IDs.
- **Network**: None.

## Migration Plan
After acceptance implement validators/pure transfer simulations/property tests, owner plan fakes, then C4/C5 adapters and the fixed kit. No data/config/GDD/prototype implementation now. Save schema and VS kit/shelter/bag features stay deferred; reserve versioned IDs without enabling them.

## Validation Criteria
- AC1–9: exact10-item kit/pemmican8/worn clothing/load6.9±0.05;24 kg+log refused,20 kg+4logs takes2/leaves2;10dry+10wet bark→20wet0.5; immersion only backpack fuel/tinder1; durability1 use removes/emits one tool loss, eaten pemmican no loss; ice tool loss once; drop1 m joins/2 m new pile; unknown item refuses/error; camp status disappears when burning fire ends.
- AC10–17: kit+6logs+10sticks load0.956±0.002; speed0.727±0.005 hauling; kit0.276 speed1/no haul,load0.7 speed0.88/no haul,0.71 haul; MVP insulation1 awake/asleep, future bag1.5 reserved; I4 wet1→<0.2 after1.6±0.05 h at+12,unchanged−4 after5 h; hatchet600/599uses→1,damage50 at30→0; bad capacity/l_free defaults; scripted pemmican-at-fullness≤60 hunger first sustained3 h onday3; hauling hour+200 kcal/+0.6 heat rather than walking.
- Property/error matrix: empty pile/zero requested units no mutation, negative counts/nonfinite fields/stale IDs refuse; whole-unit partial fit/stack_max boundaries conserved; split/merge cycles preserve item counts and wet mass; tool identities/durability never merge; nearest-pile ties stable; zero-use/damage no phantom break; duplicate commit/loss/soak no second change. Mid-transaction owner preflight refusal leaves all stacks/Needs/Fire/Map/RNG unchanged. THIS use breaks tool but grants current accepted result; external pre-completion loss cancels with zero interrupted effects.
- Protected worn/radio/camera drops refuse; full produce overflow remains accessible pile; invalid fields never invent food/fuel; low/no heat no drying; same-minute Fire Out affects this minute's drying; restored stack state exact/camp recomputed; bag bonus stays off; no new food faucet or hidden UI item values.
- AC18–19 unperformed visual/feel obligations: owner chooses one heavy versus two light trips; wet/dry tinder distinguishable in greyscale. Benchmark stated operations/50-stack drying on nominated hardware; backpack UI continues timers/simulation, explicit pause freezes. No runtime/visual/performance result claimed.

## Related
- [Master architecture](architecture.md), C6; [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md); [ADR-0008](adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md).
- Owner-only: QQ-01 budgets/hardware, QQ-05 durability/food pacing, QQ-06 MVP scope, QQ-07/10 VS kit/bag/recipe additions and tool costs remain PROPOSED. Acceptance `/architecture-decision accept ADR-0009` is separate; no story unblocked.
