# Story 001: Advance day and phase through three nights

> **ID**: CLK-001
> **Epic**: [GameClock](EPIC.md)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [time-and-day-cycle](../../../design/gdd/time-and-day-cycle.md)\
**Requirement**: TR-time-and-day-cycle-001, TR-time-and-day-cycle-003, TR-time-and-day-cycle-004, TR-time-and-day-cycle-005, TR-time-and-day-cycle-006, TR-time-and-day-cycle-011, TR-time-and-day-cycle-013, TR-time-and-day-cycle-014 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) (Accepted)\
**ADR Decision Summary**: Serial minute dispatch and bounded debt; rate changes resolve between minutes.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Foundation)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Start the chapter fixture at the Time GDD default of day 1, 13:00; do not change the first-night profile.
- [ ] 23:59 → 00:00 increments the day and emits one `day_changed`; sunrise emits once at the Dawn → Day boundary.
- [ ] Days 1–4 follow T1/T2 for daylight and phase; rollover does not reset run state.

## Implementation Notes

Use integer minute coordinates and emitted phase transitions. Rate modes and victory are separate stories.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/foundation/clock.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/clock/chapter_day_boundaries_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/unit/clock/chapter_day_boundaries_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: None
- Unlocks: [CLK-002](story-002-interruptible-rates.md), [THERM-001](../thermal-field/story-001-daily-cold-ramp.md)
