# Story 001: Resolve third-sunrise outcomes and death precedence

> **ID**: RUN-001
> **Epic**: [RunCoordinator](EPIC.md)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.5 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [time-and-day-cycle](../../../design/gdd/time-and-day-cycle.md), [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-time-and-day-cycle-012, TR-needs-and-weight-011, TR-needs-and-weight-026 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md), [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0001](../../../docs/architecture/adr-0001-run-scene-composition-and-service-lifecycle.md), [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) (Accepted)\
**ADR Decision Summary**: Serial minute dispatch and bounded debt; rate changes resolve between minutes. Body produces post-step state and cold wake; Needs alone owns sleep. Run-scoped composition, teardown and detached snapshots. One action commit; the terminal barrier gates stage/collapse and completion.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Foundation)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] The chapter fixture runs through the first two sunrises and emits survival once at the third sunrise after the drop (day 4). The first-night fixture still wins at day 2 sunrise.
- [ ] At the same-minute barrier choose hypothermia over dehydration and either death over survival, collapse or an uncommitted action. After a terminal result no more minutes, commits or RNG draws occur.
- [ ] Repeat the seeded fixture using different frame partitions: final state and event order match. A fresh run resets the old outcome and state.

## Implementation Notes

Drive the existing RunSimulation. Keep minute order Thermal/Fire → Body → Needs → terminal barrier → surviving mode/action results and snapshots. Configure chapter victory outside GameClock; do not change its global day cap.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/run/run_simulation.gd`
- `src/data/slice_tuning.gd`
- `tests/integration/run/chapter_outcomes_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/integration/run/chapter_outcomes_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [BODY-001](../body-thermoregulation/story-001-cold-wake.md)
- Unlocks: [RUN-002](story-002-wire-three-day-chapter.md)
