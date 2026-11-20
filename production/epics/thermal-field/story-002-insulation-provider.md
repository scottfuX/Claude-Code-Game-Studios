# Story 002: Register and remove shelter insulation

> **ID**: THERM-002
> **Epic**: [ThermalField](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.5 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [thermal-environment](../../../design/gdd/thermal-environment.md)\
**Requirement**: TR-thermal-environment-007, TR-thermal-environment-009, TR-thermal-environment-010, TR-thermal-environment-022 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) (Accepted)\
**ADR Decision Summary**: Versioned heat and insulation sources feed a read-only Thermal query. Fire updates Thermal heat; Fire never requests wake or normal time.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] A test volume changes the sample inside its bounds; outside is unchanged. Removal restores unsheltered values before the next sample.
- [ ] Overlap uses the GDD exposure/bonus rule, not summed shelter bonuses. Expose separate fire and shelter terms; no volume leaks into a fresh run.

## Implementation Notes

Implement the Thermal-owned registry with fixture volumes until a Shelter producer exists. Fire Out only changes heat.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/thermal_field.gd`
- `src/run/run_simulation.gd`
- `tests/integration/thermal/shelter_registration_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/thermal/shelter_registration_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [THERM-001](story-001-daily-cold-ramp.md)
- Unlocks: [RUN-002](../run-coordinator/story-002-wire-three-day-chapter.md), [ACT-003](../action-runner/story-003-shelter-build.md)
