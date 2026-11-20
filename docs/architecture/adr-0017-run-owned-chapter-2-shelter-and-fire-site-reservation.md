# ADR-0017: Run-owned Chapter 2 shelter and fire-site reservation

## Status
Proposed

## Date
2026-11-20

## Last Verified
2026-11-20 — reconciled with the pinned engine references, Shelter GDD and Accepted ADRs; implementation behavior is not yet runtime-verified.

## Decision Makers
Devin (proposal); Scott (acceptance pending).

## Summary
Add a run-owned Shelter Feature provider for Chapter 2. It commits stage, material spend and insulation through the existing action gate; Map supplies the plot reservation that FireController checks at placement.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot `4.7.2.stable.official.ed1daf0bf`; GDScript; Jolt |
| **Domain** | Core / Physics |
| **Layer** | Feature |
| **Knowledge Risk** | HIGH — see [pin and release timeline](../engine-reference/godot/VERSION.md). |
| **References Consulted** | [Physics](../engine-reference/godot/modules/physics.md), [breaking changes](../engine-reference/godot/breaking-changes.md), [deprecated APIs](../engine-reference/godot/deprecated-apis.md) |
| **Post-Cutoff APIs Used** | None required. Port names below are application contracts, not Godot methods. |
| **Verification Required** | Compile typed ports on the pin; prove prepared commits do not yield and snapshots cannot alias owner state; validate approach/clearance in Jolt and exact footprint and volume boundaries separately. |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (run lifecycle), ADR-0003 (ordered dispatch), ADR-0004 (Map/Jolt validation), ADR-0006 (Thermal registries), ADR-0007 (action gate), ADR-0008 (sleep/cold wake), ADR-0009 (Inventory plans), ADR-0011 (Fire site and source ownership) |
| **Enables** | None (no downstream ADR identified). |
| **Blocks** | [WORLD-001](../../production/epics/world-map/story-001-place-content.md) (Shelter placement only), [ACT-003](../../production/epics/action-runner/story-003-shelter-build.md) and [RUN-002](../../production/epics/run-coordinator/story-002-wire-three-day-chapter.md) (Shelter integration). |
| **Ordering Note** | [THERM-002](../../production/epics/thermal-field/story-002-insulation-provider.md) can implement the generic registry with fixtures independently. Acceptance resolves only this ADR prerequisite, not content or story readiness. |

## Context

### Problem Statement
The [Shelter GDD](../../design/gdd/shelter.md) calls for one optional authored lean-to. ADR-0006 reserves the insulation boundary but deliberately leaves the producer deferred. A fire site can be established before a shelter is built and retain cleared/ringed history, so blocking construction only at completion would allow the run to lose its one build plot.

### Constraints
- Chapter 2 only; first-night placement, sleep, and default composition stay unchanged. No Sprint 001 changes, save format, free placement or new engine dependencies.
- Keep the existing Thermal equations and Fire stage machine; use owner-only writes, detached records and the Coordinator's ordered completion barrier.
- Start with one optional open-front lean-to at a marked lee-side site near the drop, with a separate outdoor fire apron. Use the [GDD tuning](../../design/gdd/shelter.md#tuning-knobs) as the source of values: one gathered log (6 game minutes, heavy), then one starting-kit tarp (4 game minutes, light); at Covered, exposure `0.10`, bonus `+2.0 °C` and reflection `1.0`. Revisit the tuning after playtests.

### Requirements
- Commit each stage once or leave materials, stage and protection untouched. Framing alone does not insulate.
- Keep the plot available from run start while preserving a legal separate fire apron and existing sleep and wake rules.
- On reset or exit, no registration, stage, target or callback from the old run may affect the next one.

## Decision

RunCoordinator composes one Shelter provider for Chapter 2 only, after Map and its dependencies' owner ports are ready. Shelter owns the run-local stage (`Empty` → `Framed` → `Covered`), stage revision and insulation values; ActionRunner owns the attempt and temporary progress. Map owns the authored site geometry and static reservation independently of Shelter stage. Inventory owns the spend; Thermal owns the registered volume. Core must not reference a concrete Shelter type.

Map validates the authored transform, path, terrain and clearance before gameplay. Extend ADR-0004's spatial output with a read-only Chapter 2 reservation: the projected XZ rectangle of the authored insulation volume. FireController applies the ADR-0011 placement policy with this new spatial input before a site record is created. Route the current [RunCoordinator placement entry point](../../src/run/run_coordinator.gd) and all new-site routes, including bare rock, through that same Chapter 2 check at admission and before commit. Reject overlap, edge contact and invalid geometry regardless of Shelter stage. The apron still obeys ADR-0011. The first-night profile keeps its existing checks.

Require ADR-0007's post-minute terminal/forced-cancel and prepared-commit gate before wiring Shelter completions; the current runner does not expose that full gate. Revalidate run/token identity, stage, target/range, material availability, Body/Needs permission and owner revisions. Prepare detached, non-mutating plans for Inventory and Shelter and, on cover, for Thermal registration. Reject an invalid or duplicate volume before any spend. Once all plans are accepted, apply them synchronously without exposing intermediate state, yielding, emitting signals or invoking callbacks, then publish the result. A cancelled or stale attempt has no spend, effect or retained work; a previously paid stage stands. No construction action uses a tool or draws a Mishaps roll.

On cover, Thermal receives a copied, versioned run/site record with the site transform and closed local bounds. Convert the actual sample position into site-local space and apply ADR-0006's insulation queries and overlap rules unchanged; presentation geometry and physics overlaps cannot decide membership. Reflection stays neutral in this chapter; non-neutral opening/reflection geometry is out of scope. The commit becomes visible to the next ordered sample, not to a completed minute. Covered exposes a bedroll target for the existing `sleep` action: both target and Body sample point must be strictly inside the XZ footprint and within the closed Y interval. No snap, and Needs retains sleep admission; Body retains cold wake. Fire Out removes Fire's heat, not insulation, and never wakes directly.

On provider/site teardown, gate further work, invalidate affected attempts, and remove the registration through the Thermal owner before any further sample. Dispose of the run's stage/targets before owner service disposal; a fresh run starts Empty.

### Architecture Diagram

```text
RunCoordinator ── composes Chapter 2 only ── Shelter provider
Map ── site + reservation ── Shelter / FireController (validates fire placement)
ActionRunner ── ordered prepare / commit ── Inventory + Shelter [+ Thermal on cover]
Thermal ── existing felt-temperature query ── Body ── cold wake request ── Needs
```

### Key Interfaces

| Boundary | Contract |
|---|---|
| Map → Shelter and FireController | Add a typed read for the validated plot and a pure candidate-disc intersection test. Return detached geometry or a validation result; Map does not set Fire state. |
| ActionRunner → Shelter | Inject an action resolver for `build_shelter_frame` and `cover_shelter`; the resolver validates a stable site/revision and prepares the owner plan through the existing attempt token. No new scheduler. |
| Shelter → Thermal | Prepare/apply/remove one copied record using ADR-0006 identity and revision semantics; `bounds`, `wind_exposure_override`, `bonus_c` and `heat_reflect_mult` retain their GDD meanings. Thermal alone updates its registry. |
| Shelter → presentation | Publish a detached committed stage snapshot; no visual or audio callback can advance it. |

### Implementation Guidelines

- Owner plans must be prevalidated and infallible once commit starts; unexpected invariant failures gate the run per ADR-0007, never retry a partial commit.
- Fire owns a fixed, finite, positive Chapter 2 placement radius in metres that covers its largest authored ground footprint (clearing and ring); it is neither warm/light radius nor Fire spacing. Validate that the apron fits this disc. In site-local XZ, Map clamps the candidate centre to the reservation rectangle and refuses when the distance to the clamped point is ≤ radius + ε.
- Validate finite geometry and one upright authored transform with an orthonormal basis and no scale, shear or reflection. Use ε = 0.0001 m for round-off at boundaries: expand closed Thermal bounds by ε; require more than ε of clearance from each XZ edge for sleep. If Map needs a Jolt space query to verify clearance, run it on a physics tick before lifting the run gate.
- Do not use `Area3D` notifications, global lookup, timers or animation completion to update authoritative stage or insulation. Typed GDScript overrides must return explicitly. Do not alias nested mutable data or Resources, and do not retain a provider node or callback in Map or Thermal records.

## Alternatives Considered

### Alternative 1: Put Shelter in ThermalField
- **Description:** Store the structure and apply the building commands in the thermal service.
- **Pros:** One owner for the structure and its protection.
- **Cons:** Thermal would need recipe, inventory and build-stage knowledge.
- **Rejection Reason:** The registry is a consumer of insulation values, not a feature owner.

### Alternative 2: Use a scene trigger and check Fire at build completion
- **Description:** Let a shelter scene infer protection from Area overlaps and refuse building if there is already a fire.
- **Pros:** Quick to prototype in the editor.
- **Cons:** Sample and trigger ordering can differ, and retained fire-site history can block the only plot.
- **Rejection Reason:** Neither a trigger nor late rejection satisfies ordered sampling or guarantees the reserved plot.

## Consequences

### Positive
- The chapter adds one small provider and uses existing action/thermal/sleep paths; the first-night profile need not instantiate it.
- Owner boundaries and validation order remain testable without presentation nodes.

### Negative
- Cover spans three owners, which all need prepare/commit contract tests. Map and Fire need a chapter-only validation input and a boundary fixture.

## Risks
- Godot specialist validation: a headless probe on the pin found that default geometry predicates may drop touching edges and transform round-off can put an exact corner just outside. Verify the explicit tolerance, rotated edges and corners, and unambiguous points on either side once the port is wired.
- A stale callback could reinstall an old volume: reject stale identity/revisions across restart and test no partial commit on invalid Thermal preparation.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| [shelter.md](../../design/gdd/shelter.md) | Core Rules 1–6, SH1–SH2 and AC1–7 | Run-local stage ownership, the spatial reservation, transactional spend, volume lifetime and existing sleep behavior. |
| [map-and-resource-distribution.md](../../design/gdd/map-and-resource-distribution.md) / [fire.md](../../design/gdd/fire.md) | Map/Fire Chapter 2 forward links; TR-fire-001 baseline | Map supplies the exclusion for Chapter 2; Fire owns placement and keeps existing terrain checks in every profile. |
| [interaction-and-timed-actions.md](../../design/gdd/interaction-and-timed-actions.md) / [item-database-and-inventory.md](../../design/gdd/item-database-and-inventory.md) | IA1/IA2; Inventory kit and owner transactions | Separate stages use existing work/targeting; committed plans spend only the existing kit/gathered items specified by the GDD. |
| [thermal-environment.md](../../design/gdd/thermal-environment.md) | TR-thermal-environment-007/009/010/022; TH3–TH5 | Reuses the owner registry, read boundaries, overlap and formulas without a new heat source. |
| [body-temperature.md](../../design/gdd/body-temperature.md) / [needs-and-weight.md](../../design/gdd/needs-and-weight.md) | Ordered temperature sampling, sleep admission and cold wake | Body reads one existing Thermal sample; Needs remains the only owner of sleep. |

## Performance Implications
- **CPU:** New-site footprint check on admission/commit only; one extra volume record at most in the chapter. No new per-frame scene search or integration loop.
- **Memory:** One small provider and copied volume/plot records per chapter run; none for first night.
- **Load Time:** Validate the one authored plot with existing Map setup; no new asset loader.
- **Network:** Not applicable.

## Migration Plan
Keep this proposal inactive until Scott accepts it. After acceptance, use `/propagate-design-change` to record the Chapter 2 extensions against ADR-0004 and ADR-0011 and align Fire Rule 1 with the GDD forward link. Update the architecture's deferred-system inventory for this chapter scope and regenerate the Control Manifest from the Accepted set before scheduling Shelter work. Registry candidates for that handoff: run-scoped stage ownership, the Map footprint query and the cover-to-Thermal prepared publication. Do not amend those records in this proposal. Wire the provider only after the map and Thermal fixtures are in place; recheck each story's remaining approvals and dependencies.

## Validation Criteria
1. An invalid plot fails chapter setup before input/time advance. Validate GDD path, ground and ambient-wind constraints; in every stage, reject rock/snow fire footprints touching an edge or corner or overlapping the plot, but allow eligible apron placement. Reject invalid Chapter 2 radius/transform data; first-night fixtures stay unchanged.
2. A valid frame spends one log and registers no volume. A valid cover spends the one tarp and registers exactly once before the next sample. Cancel, terminal, duplicate, changed revision or a refused Thermal plan produces no new cost or state.
3. Under matched no-fire GDD inputs, inside/on-boundary/outside samples respect the closed volume and existing formulas. Repeat with a rotated plot, normal Fire heat and Fire Out; protection is independent of Fire and sleep changes only via the existing owner rules.
4. Verify no insulation in a sampled minute preceding cover commit, no state or volume after restart, and rejection of stale callbacks. Run the existing first-night and Chapter 2 regression suites on the pinned engine.

## Related
- [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md) and [ADR-0011](adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md): scoped Chapter 2 extensions; no global replacement.
- [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md) and [ADR-0007](adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md): preserve registry and commit boundaries.
- [Control Manifest](control-manifest.md) and [Chapter 2 milestone](../../production/milestones/three-day-survival.md): current accepted contract and scope.
