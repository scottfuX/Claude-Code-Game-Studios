# Story 002: Burn stomach calories before body weight

> **ID**: NEED-002
> **Epic**: [NeedsModel](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-needs-and-weight-001, TR-needs-and-weight-002, TR-needs-and-weight-003, TR-needs-and-weight-004, TR-needs-and-weight-010, TR-needs-and-weight-012, TR-needs-and-weight-013, TR-needs-and-weight-014, TR-needs-and-weight-017, TR-needs-and-weight-018, TR-needs-and-weight-027, TR-needs-and-weight-028 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) (Accepted)\
**ADR Decision Summary**: Body produces post-step state and cold wake; Needs alone owns sleep.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Start at 1,200 kcal and 72 kg. One awake idle hour yields 1,090 kcal, unchanged weight and fullness about 72.7. Use the highest activity term, not a sum.
- [ ] Burn 3,530 kcal with an empty stomach: lose about 0.458 kg, respecting the 40 kg floor. At 10% and 20% weight loss the cap is 80 and 60 respectively, with floor 60.
- [ ] Enter Starving at 1,440 elapsed empty minutes, not 1,439. Accepted food resets the timer and leaves Starving. Do not add independent starvation death.

## Implementation Notes

Apply N1/N2/N5/N6 to one minute at a time. Test the accepted-intake model boundary here; the item story adds the transaction.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/needs_model.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/needs/fullness_weight_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/unit/needs/fullness_weight_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: None
- Unlocks: [NEED-003](story-003-sleep-state.md), [ITEM-001](../item-catalog-inventory/story-001-nutrition-transaction.md)
