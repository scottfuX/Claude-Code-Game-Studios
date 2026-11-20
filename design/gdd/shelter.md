# Shelter

> **Status**: Designed — chapter content pending owner approval
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: Devin (design-system); scope from Scott
> **Last Updated**: 2026-11-20
> **Last Verified**: 2026-11-20
> **Implements Pillar**: 亲手做 · 冷是真的 · 越活越懂

## Summary

The three-day chapter adds one simple tarp lean-to. The player brings back wood, builds a frame and fits a tarp to make a spot that cuts wind while they rest. It helps without replacing the fire.

> **Quick reference** — Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `Interaction & Timed Actions, Item Database & Inventory, Gathering, Thermal Environment`

## Overview

The Chapter 2 player builds one simple, open-front tarp lean-to at a prepared camp spot in the existing snowy playfield. They have to bring wood back and work twice before they get any protection. A chopped log spent on the frame cannot go into the fire that night; choosing when to spend that fuel and daylight is the point of the system.

The finished roof gives a small, local advantage against the wind. It is neither a heat source nor a guarantee of safe sleep. The shelter is optional for victory; the run still ends at the third sunrise or on the existing terminal conditions. This is a design for the chapter profile only, not Sprint 001, the first-night profile, or a project stage change. No cabins, free placement, moving/dismantling, upgrades, decay, wetness protection, new gathering loop, Weather or Save/Load.

## Detailed Design

### Core Rules

1. **One authored site.** WORLD-001 supplies a fixed Chapter 2 marker and orientation on the lee side of a rock on the existing playfield; prefer the nook nearest the drop that meets the following constraints. Use a walkable route within 15 m of the drop on dry, non-ice, non-drift ground, with a footprint slope ≤ 8°, clear footprint and a traversable entrance and exit. There must be valid adjacent outdoor ground for a fire facing the opening and at least one reachable existing deadfall accessible with the starting hatchet. Mark the plot with stakes, not a map marker. No cursor placement, rotation or search for arbitrary buildable ground. Map/Jolt validate terrain and obstructions before enabling the site; Shelter does not infer validity from VFX or triggers. The plot's footprint is reserved for Shelter for the entire chapter (including before the frame); Map excludes fire placement intersecting it, but not the adjacent fire apron. This is a chapter placement constraint, not a new Fire-stage rule.
2. **Source the materials.** Give the chapter's starting loadout one existing `tarp` with ties bundled into it and the existing hatchet; no separate paracord cost or new catalogue item. Obtain a `log` via the existing deadfall chop and pickup/overflow loop. Use ordinary backpack units (not units on the ground). Existing Inventory masses, stacking and wetness stay unchanged; material wetness does not gate this recipe or affect its thermal result. The chapter loadout adapter must be validated against Inventory before a run starts, not handed out again on retrying construction.
3. **Two timed actions.** They use Interaction's existing targeting, work intensity, admission and IA1 duration. Each stage needs its own press of the contextual interact action. No action auto-queues the next stage. Both are cancellable, `progress_kept = false`, `counts_as_idle = false`, `critical_allowed = false`, with no tool use or Mishaps profile. The hatchet is for gathering, not for either construction action.

   | Available at | Action id | Base game minutes | Effort | Cost on successful commit | Next stage |
   |---|---|---:|---|---|---|
   | Empty | `build_shelter_frame` | 6 | Heavy | 1 `log` | Framed |
   | Framed | `cover_shelter` | 4 | Light | 1 `tarp` | Covered |

4. **Commit or cancel.** At start check the current site, stage, range, backpack cost and Body/Needs permission. At completion revalidate them inside the ordered ActionRunner gate, including run, token and target/owner revisions. Stage progress accrues only in ActionRunner while working. Prepare detached Inventory and Shelter plans; for the cover stage also prepare and validate the Thermal registration through its owner port. After validation all owners apply the one accepted consequence synchronously, without yielding or publishing intermediate state: spend just that stage's units as use (not loss), advance the site revision, register the volume if Covered, then publish the outcome. Invalid preparation or terminal/forced cancellation applies none of those effects; do not roll Mishaps, spend anything or keep fractional work. A successfully committed earlier stage stays paid and standing. Owner revisions and committed tokens rule out duplicate costs or registrations. No staging of materials in a second inventory.
5. **Insulation starts at Covered.** The Feature owns the pending or committed structure; ThermalField owns the live volume. Publish one versioned record per run/site with authored bounds, the values in Formulas, and stable owner/run/source IDs. Inside means the actual sample point is within the closed authored volume, including its faces. Outside samples receive no Shelter terms; a bare frame has no volume. Publish by the next ordered Thermal sample after commit, never retroactively to a minute already sampled. Remove on provider/site teardown before the next sample; a fresh run starts without a volume. Thermal decides containment from value data, not meshes, camera framing, or Area3D callbacks. If multiple volumes exist in a fixture or later feature, Thermal still applies its minimum exposure / maximum bonus rule, never additive stacking.
6. **Sleep and fire.** After covering, expose a contextual bedroll target inside the volume using the existing sleep action. It has no new item requirement or sleeping-bag bonus. The survivor must be inside at the actual Body sample position when entering shelter sleep; no snap, teleport or special sleep eligibility. The old sleep targets stay available under their own rules. Needs owns sleep/recovery; Body samples Thermal at the survivor each minute and owns cold wake. A fire stands outside the shelter, with its usual radius, wind and falloff. It can warm the interior through Thermal, not through any Fire–Shelter link. Fire Out removes fire heat only; it does not remove the volume, wake the survivor directly, or request normal time.

### States and Transitions

| Persistent site state | Offered verb | Transition and observable result |
|---|---|---|
| Empty | Build frame | Commit frame → Framed; show frame. Cancel/refuse → Empty. |
| Framed | Fit tarp | Commit cover → Covered; show roof and enable sleep target and insulation together. Cancel/refuse → Framed. |
| Covered | Sleep, when targeted and eligible | No further build action. Sleep/wake changes only Needs state. |
| Any | — | Teardown withdraws the site's targets, invalidates its work token through ActionRunner and removes its volume if any. New run → Empty. |

Midnight is not a transition. The run owns all stages; nothing persists across runs.

### Interactions with Other Systems

| Owner | Contract consumed or supplied by Shelter |
|---|---|
| Map / Terrain | Supplies the authored site ID, transform, walkability and clearance via the existing spatial boundary; Map owns the chapter fire-placement exclusion. |
| Gathering / Inventory | Gathering supplies ordinary deadfall logs through the existing loop. Inventory's read snapshots and prepared consumption plans own both inputs; Shelter cannot decrement stacks. |
| Interaction / Input | Shelter supplies a staged interactable and injected Feature resolver. ActionRunner owns targeting, progress, revalidation, cancellation and work intensity, using existing bindings. Core imports no concrete Shelter type. |
| RunCoordinator | Composes this provider only for the chapter, orders commit versus minute/terminal barriers, and disposes of the provider before tearing down its owner services. |
| ThermalField | Accepts a copied, revision-checked insulation record at cover commit, removes it on teardown, and samples exact geometry through its normal query. It never reads the Shelter node. |
| Body / Needs / Time | Consume existing work reports, Thermal samples and the sleep request through their current interfaces. No direct writes, new rate mode, or new wake reason. |
| Fire / Presentation | Fire stays a separate thermal source; visuals and localized contextual prompts read committed stage/action snapshots only. |

## Formulas

### SH1 — Work and cost

Reuse Interaction IA1: each stage's work duration is its base minutes multiplied by the current IA1 duration multiplier captured on start. Only on commit does the relevant Inventory count decrease by the stated quantity; it never goes below zero because the commit revalidates availability. A full healthy build is **10 game minutes** of work (not counting travel, gathering or time between stages); both stages at IA1's default cap take **20 game minutes**. At the normal daytime rate and healthy multiplier, each stage takes 9 s / 6 s, respectively.

| Input | Chapter value / range | Owner / reason |
|---|---|---|
| `base_game_min` | Frame 6, cover 4; IA1 accepts 0.25–30 game min | Shelter action data. Handling the wood takes longer than tying the tarp. |
| `dur_mult` | 1–2 at IA1 defaults | Interaction; no local multiplier. |
| `qty` | 1 unit for the applicable material per commit, otherwise 0 | Shelter recipe via Inventory; trades a piece of fuel for shelter without a new supply chain. |

### SH2 — Footprint and protection

In site-local metres with +Z facing out of the opening and Y up from the finished ground reference, author the chapter volume at x ∈ [−1.20, 1.20], y ∈ [0, 1.80], z ∈ [−1.50, 0]. The projected XZ rectangle is the reserved footprint. The visual proxy and navigable ground must agree with that value volume at the entrance and bedroll. For sleep, both the bedroll and the survivor's sample point must be strictly within the XZ footprint and within the closed Y interval (ground level counts). Exact transform and collision art are map implementation data subject to Core Rule 1.

| Input | Proposed chapter value | Valid range / meaning |
|---|---:|---|
| `wind_exposure_override` | 0.10 | 0–1; replaces zone exposure within the volume. Choose a site where ambient exposure across the interior is ≥ 0.10, so protection cannot amplify wind. |
| `bonus_c` | +2.0 °C | 0–10 °C per TH5; a small local insulation bonus, not imputed Fire heat. |
| `heat_reflect_mult` | 1.0 | 1.0–1.5 per TH4; neutral for this chapter. |

No new temperature formula: Thermal uses TH3–TH5. Example with no fire, the same lee-zone baseline exposure of 0.30, wind 3 m/s and default TH3 coefficient 1.2: outside chill is 1.08 °C; inside it is 0.36 °C. The net increase at otherwise equal air/zone conditions is 0.72 + 2.00 = **2.72 °C**. At zero wind the increase is only the 2.00 °C bonus. With a fire nearby, the ordinary distance-based heat term is separate and reflection stays neutral. These are felt-temperature differences, not core-temperature gains or changes to sleep thresholds.

## Edge Cases

| Case | Result |
|---|---|
| Missing log/tarp, covered site, or invalid ground/occupied footprint | No start, no cost. Unusable authored geometry must be rejected before enabling the chapter, not left as an impossible objective. If a previously valid site becomes obstructed at runtime, refuse the affected stage until it clears. |
| Player walks away, cancels, collapses, goes Critical, falls into water, or loses the target while working | ActionRunner cancels via its existing rules. No current-stage cost, work fraction or protection; earlier committed stages are untouched. |
| A material is dropped, moved by another valid transaction, or no longer available at completion | Revalidate backpack and owner revisions. If the cost/plan can no longer be accepted, leave all owners unchanged and report refusal; retry the same stage from zero after resolving it. |
| Cover completes on a minute/terminal boundary | The existing coordinator barrier decides first. If terminal or forced cancellation wins, leave the frame with no new spend or volume; if commit is accepted, it is visible to the next Thermal sample. Replays/stale tokens never commit a second time. |
| Player tries to sleep from the entrance or outside within interact reach | Offer no shelter sleep until the sleep-position check in SH2 passes; an invalid start never moves the player or wakes/changes time. Inside still uses the normal sleep checks. Exhaustion collapse still happens wherever the survivor stands. |
| Fire goes out while someone sleeps under the tarp | Thermal keeps the shelter terms and loses the fire term. If post-step Body meets the cold-wake rule, Needs wakes once and Time returns to normal before the next skipped minute; otherwise sleep continues. |
| Midnight, restart, or old callbacks | Midnight leaves stages and insulation unchanged. Exit/restart removes the site's volume and discards work; stale run/revision messages cannot add it back. |

## Dependencies

**Indexed upstream:** [Interaction & Timed Actions](interaction-and-timed-actions.md) for work admission and commit; [Inventory](item-database-and-inventory.md) for existing items and spend plans; [Gathering](gathering.md) for one ordinary log; [Thermal Environment](thermal-environment.md) for the insulation record and query. Each GDD already names Shelter or its provider boundary. Gathering's future poles/boughs are not needed for this chapter; there is no change to gathering yield.

**Chapter integration:** [Map](map-and-resource-distribution.md) owns the site and spatial eligibility. [Body](body-temperature.md), [Needs](needs-and-weight.md) and [Time](time-and-day-cycle.md) use the existing minute/sleep contracts; [Fire](fire.md) contributes heat separately. [HUD](hud.md), [Input](input-and-action-map.md) and [Ambient & Foley Audio](ambient-and-foley-audio.md) use established presentation paths; there are no new bindings, collections, or audio services.

**Handoff:** [WORLD-001](../../production/epics/world-map/story-001-place-content.md) takes the approved site constraints; Food still has its own approval and placement. [THERM-002](../../production/epics/thermal-field/story-002-insulation-provider.md) can land with fixtures before this provider. [ACT-003](../../production/epics/action-runner/story-003-shelter-build.md) wires the injected resolver after there is an approved design and Feature provider; [ACT-001](../../production/epics/action-runner/story-001-sleep-snow.md) supplies contextual sleep. [RUN-002](../../production/epics/run-coordinator/story-002-wire-three-day-chapter.md) composes the chapter once those dependencies are delivered. This document does not change any story readiness or add work to [Sprint 001](../../production/sprints/sprint-001.md).

## Visual/Audio Requirements

Empty shows low stakes; Framed shows unfinished, neutral timber; Covered shows the angled warm-orange tarp and open, readable entrance. Use flat low-poly proxies consistent with [Art Bible §§1–4](../art/art-bible.md); the tarp is non-emissive, and has no magical warmth glow. State is clear from the silhouette, not only color. Reuse existing work feedback; a stock wood knock on frame commit and cloth rustle on cover commit may use the existing foley route if available. No new animation, cloth simulation, audio pack, or particle system is required. On cancel, stop work feedback and display the last committed silhouette; never show finished cover early.

## Game Feel

Two deliberate presses, a short stretch of effort for each and a visible payoff when each stage completes. The frame should look like unfinished work, not a failed shelter. On returning to camp the entrance should be obvious at the gameplay camera zoom; stepping underneath should slow cooling in comparable conditions without a temperature number or a promise that it's safe to stop tending the fire.

## UI Requirements

Use the existing [localized HUD prompt pattern](../ux/hud.md) and contextual work progress. Example zh-CN verbs: “搭支架”, “铺篷布”, “睡觉”. Missing materials can use “缺木柴” and “缺篷布”; environmental/Body/Needs refusals use existing reason paths. Progress ends on cancel/refusal and must not imply retention. No construction menu, inventory panel changes, numeric thermal meter or new control. Keep localization IDs and presentation in existing owners.

## Cross-References

| Contract | Source | Check |
|---|---|---|
| Contextual work; IA1/IA2, forced cancellation and single commit | [Interaction](interaction-and-timed-actions.md), [Input](input-and-action-map.md), [ADR-0002](../../docs/architecture/adr-0002-input-routing-contexts-and-ui-pause-requests.md), [ADR-0007](../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) | Existing intent, progress and transaction path; no new roll or queue. |
| Run lifecycle and ordered commit/sampling | [Time](time-and-day-cycle.md), [ADR-0001](../../docs/architecture/adr-0001-run-scene-composition-and-service-lifecycle.md), [ADR-0003](../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Run-owned composition; no extra ticking, global provider, or direct state writes. |
| Authored site and ordinary kit/gather output | [Map](map-and-resource-distribution.md), [Inventory](item-database-and-inventory.md), [Gathering](gathering.md), [ADR-0004](../../docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md), [ADR-0009](../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md), [ADR-0010](../../docs/architecture/adr-0010-gathering-resolver-depletion-and-overflow-transactions.md) | Use authored spatial validation and inventory transactions; no parallel placement/inventory/gathering rules. |
| Insulation separated from heat and cold wake | [Thermal Rule 7](thermal-environment.md#core-rules) / [TH3–TH5](thermal-environment.md#formulas), [Fire](fire.md), [Body](body-temperature.md), [Needs](needs-and-weight.md), [ADR-0006](../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0008](../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0011](../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) | Separate terms and owners; the GDD does not supersede any equation, terminal precedence or wake threshold. |
| Read-only presentation | [HUD](hud.md), [Foley](ambient-and-foley-audio.md), [Control Manifest](../../docs/architecture/control-manifest.md#presentation-layer-rules) | Reuse existing action, camera, visual and audio adapters; no special locomotion, morale, camera or post-processing state. |

Relevant existing requirements are cited by the linked stories (including Thermal TRs 007, 009, 010 and 022). The chapter design adds no Accepted ADR or canonical TR entry; [Control Manifest](../../docs/architecture/control-manifest.md) remains the implementation boundary.

## Acceptance Criteria

**Automated targets (future implementation evidence, not tests claimed by this GDD):**

1. **Given** a fresh Chapter 2 run, **when** the map loads, **then** a player can walk from drop to the single authored site and an existing deadfall, the footprint is non-ice/non-drift and ≤ 8°, the adjoining fire apron is legal, and placing a fire across the plot boundary is refused. A bad site fixture fails validation before play. (WORLD-001)
2. **Given** the starting tarp and hatchet and no log in the backpack, **when** the survivor attempts to frame, **then** it is refused; **when** they gather and carry a log and finish the frame, **then** exactly one log is gone, the frame is visible and the tarp and Thermal records are unchanged. Cover needs a separate press; on successful cover exactly one tarp is gone, the sleep target is available and exactly one insulation record exists. Neither action uses a tool or draws randomness. (ACT-003)
3. **Given** each stage in progress, **when** the player cancels or is forced out, a material/target revision invalidates the commit, or terminal wins on the completion boundary, **then** partial work is not kept and no stage cost or registration occurs; earlier committed work remains. A duplicated or stale accepted completion has no further effects. If thermal preparation rejects the cover volume, the tarp remains in Inventory and the state is Framed. (ACT-003)
4. **Given** identical lee-zone inputs with no fire and 3 m/s wind, **when** Thermal samples just inside, on the boundary and just outside the finished volume, **then** inside and boundary get the override and +2 °C bonus; the outside uses zone exposure and no bonus. The inside/outside felt difference is 2.72 °C at the example inputs. Under matching fire contributions the heat term is unchanged by shelter reflection. Adding an overlapping fixture does not sum its bonus; removal restores baseline by the next sample. (THERM-002)
5. **Given** a Covered plot, **when** an eligible survivor starts existing `sleep` from inside, **then** Needs owns the sleep transition; the same shelter request outside or while ineligible changes neither position nor sleep. **When** fire goes Out with no valid wake trigger, sleep continues; qualifying Body cold wake still interrupts before the next skipped minute. (ACT-001, BODY-001, RUN-002)
6. **Given** a Framed or Covered site at midnight, **when** the day changes, **then** the state and any registered volume persist. **When** the run exits and a new run starts, **then** there is no old volume or stage; the first-night profile still has no chapter site or Shelter-specific grants. (RUN-002)

**Chapter playtest:** Build at the marked site without instructions or new controls; distinguish stakes, frame and roof at normal zoom; sleep under cover with a tended fire, and show a separate Body cold wake. Record placement, use and the third-sunrise run under the [milestone exit checks](../../production/milestones/three-day-survival.md#success-criteria). If the initial tuning makes shelter a replacement for fire or barely perceptible, bring the paired inside/outside samples back to the owner before changing the approved values.

## Open Questions

Scott decides these chapter content choices before Feature implementation. Recommendations below make the design reviewable; merging or passing design review alone does not approve the content.

| Owner decision | Recommended answer |
|---|---|
| SH-Q1 — Type and placement | One optional, open-front tarp lean-to at a marked lee-side site near the existing drop, with a separate outdoor fire apron. No free placement. |
| SH-Q2 — Materials, stages and cancellation | Use one gathered log to frame (6 game minutes), then the starting tarp to cover (4); charge at each completed stage and discard only unfinished-stage work on cancel. |
| SH-Q3 — Insulation | Activate only at cover: exposure 0.10, +2 °C, neutral reflection. Revisit after the chapter playtest rather than retuning fire or sleep. |

Resolve all three at the Shelter → Feature handoff, before WORLD-001's Shelter location is approved and ACT-003 is scheduled.
