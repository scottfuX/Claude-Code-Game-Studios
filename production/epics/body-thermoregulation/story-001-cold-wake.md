# Story 001: Wake sleep from Body cold, not Fire Out

> **ID**: BODY-001
> **Epic**: [BodyThermoregulation](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.25 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [body-temperature](../../../design/gdd/body-temperature.md)\
**Requirement**: TR-body-temperature-002, TR-body-temperature-009, TR-body-temperature-016, TR-body-temperature-017, TR-body-temperature-028 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md), [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) (Accepted)\
**ADR Decision Summary**: Body produces post-step state and cold wake; Needs alone owns sleep. Serial minute dispatch and bounded debt; rate changes resolve between minutes. Fire updates Thermal heat; Fire never requests wake or normal time.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Body samples each minute in sleep/wait. Worsening cold while skipping or reaching Cold while asleep produces the qualifying wake once.
- [ ] Fire Out with no cold wake leaves a stable below-cap sleeper asleep. When later cooling qualifies, Needs clears sleep and Clock returns to normal before the next owed minute.
- [ ] Collapse while already Cold or worse reconciles once to awake with energy ≥ 5; no repeated integration or collapse loop.

## Implementation Notes

Take immutable pre-step sleep/activity values, pass post-Body stage and shiver to Needs, and let Needs reconcile wake. Fire never requests wake; Body never writes is_asleep.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/body_thermoregulation.gd`
- `src/run/run_simulation.gd`
- `tests/integration/run/body_cold_wake_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/integration/run/body_cold_wake_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [NEED-003](../needs-model/story-003-sleep-state.md)
- Unlocks: [RUN-001](../run-coordinator/story-001-chapter-outcomes.md), [ACT-001](../action-runner/story-001-sleep-snow.md)
