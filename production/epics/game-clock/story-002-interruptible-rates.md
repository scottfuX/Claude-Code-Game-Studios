# Story 002: Arbitrate sleep and wait between minutes

> **ID**: CLK-002
> **Epic**: [GameClock](EPIC.md)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [time-and-day-cycle](../../../design/gdd/time-and-day-cycle.md)\
**Requirement**: TR-time-and-day-cycle-002, TR-time-and-day-cycle-007, TR-time-and-day-cycle-008, TR-time-and-day-cycle-009, TR-time-and-day-cycle-015, TR-time-and-day-cycle-018, TR-time-and-day-cycle-019, TR-time-and-day-cycle-020, TR-time-and-day-cycle-021 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) (Accepted)\
**ADR Decision Summary**: Serial minute dispatch and bounded debt; rate changes resolve between minutes.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Foundation)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Use profile rates for normal/wait/sleep. `normal` beats any same-minute skip request and applies before the next owed minute.
- [ ] Sleep across midnight and sunrise without skipping or duplicating ticks. At the default 120-tick frame cap, carry remaining debt.
- [ ] Explicit pause accrues no new debt and emits no ticks; opening inventory alone does not pause.

## Implementation Notes

Re-check the active rate after each integrated minute, not after a whole catch-up batch. Needs owns sleep eligibility.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/foundation/clock.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/clock/interruptible_rates_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/unit/clock/interruptible_rates_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: [CLK-001](story-001-day-boundaries.md)
- Unlocks: [NEED-003](../needs-model/story-003-sleep-state.md)
