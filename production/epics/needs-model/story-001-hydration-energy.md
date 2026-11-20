# Story 001: Integrate hydration and submit dehydration once

> **ID**: NEED-001
> **Epic**: [NeedsModel](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-needs-and-weight-001, TR-needs-and-weight-002, TR-needs-and-weight-007, TR-needs-and-weight-008, TR-needs-and-weight-010, TR-needs-and-weight-011, TR-needs-and-weight-015, TR-needs-and-weight-016, TR-needs-and-weight-018, TR-needs-and-weight-025, TR-needs-and-weight-026 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) (Accepted)\
**ADR Decision Summary**: Body produces post-step state and cold wake; Needs alone owns sleep.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Start at 100 hydration and 90 energy. Awake idle loses 1.4 hydration/hour; asleep loses 0.7; awake heavy work loses 2.1. Respect clamps and stage hysteresis.
- [ ] Start grace at the crossing-to-zero endpoint. No death candidate at 359 elapsed zero minutes, one at 360; an accepted intake at 359 resets grace, a refusal does not.
- [ ] Parched and Exhausted yield fatigue +0.15 and action duration ×1.375; use the prescribed thirst penalty on energy drain.

## Implementation Notes

Keep counters and changes in Needs. Use pre-step awake/asleep fixtures here; the later action commits intake through Needs. The run arbitrates death separately.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/needs_model.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/needs/hydration_energy_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/unit/needs/hydration_energy_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: None
- Unlocks: [NEED-003](story-003-sleep-state.md)
