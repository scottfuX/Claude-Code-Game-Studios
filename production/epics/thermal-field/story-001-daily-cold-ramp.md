# Story 001: Verify the daily cold ramp across skips

> **ID**: THERM-001
> **Epic**: [ThermalField](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [thermal-environment](../../../design/gdd/thermal-environment.md)\
**Requirement**: TR-thermal-environment-002, TR-thermal-environment-003, TR-thermal-environment-009, TR-thermal-environment-027 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) (Accepted)\
**ADR Decision Summary**: Versioned heat and insulation sources feed a read-only Thermal query.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] At the same time and position, the daily mean decreases by the configured step toward its floor.
- [ ] For the same minute coordinates and sources, normal and skipped minutes agree; no previous-day sample leaks across midnight.

## Implementation Notes

Use the existing Thermal formulas and sealed minute samples. Do not introduce a second weather clock or a cold-snap system.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/thermal_field.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/thermal/daily_cold_ramp_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/unit/thermal/daily_cold_ramp_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: [CLK-001](../game-clock/story-001-day-boundaries.md)
- Unlocks: [THERM-002](story-002-insulation-provider.md)
