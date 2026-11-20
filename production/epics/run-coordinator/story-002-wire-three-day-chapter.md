# Story 002: Assemble the chapter in the main run scene

> **ID**: RUN-002
> **Epic**: [RunCoordinator](EPIC.md)
> **Status**: Blocked — BLOCKED: Approved chapter content suppliers and the milestone's read-only HUD handoff must be delivered.
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2 dev days (provisional)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [time-and-day-cycle](../../../design/gdd/time-and-day-cycle.md), [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-time-and-day-cycle-004, TR-time-and-day-cycle-012, TR-needs-and-weight-002, TR-needs-and-weight-012 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md), [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0001](../../../docs/architecture/adr-0001-run-scene-composition-and-service-lifecycle.md), [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) (Accepted)\
**ADR Decision Summary**: Serial minute dispatch and bounded debt; rate changes resolve between minutes. Body produces post-step state and cold wake; Needs alone owns sleep. Run-scoped composition, teardown and detached snapshots. Versioned heat and insulation sources feed a read-only Thermal query. One action commit; the terminal barrier gates stage/collapse and completion. Fire updates Thermal heat; Fire never requests wake or normal time.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Foundation)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Normal launch starts the chapter. A player can gather fuel, hydrate, eat, build/use the lean-to and sleep; changes survive midnight and reset on a fresh run.
- [ ] Display survival only at the configured third sunrise, or the winning cause on a prior loss. Feed detached stage and progress values to existing HUD/result adapters, with no raw physiology numbers on the HUD.
- [ ] Keep first-night regression fixtures and pass the chapter milestone exit checks.

## Implementation Notes

Bind only approved providers at composition, clean up sources at teardown, and reuse the terminal gate. HUD view implementation remains Presentation work.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/run/app_shell.gd`
- `src/run/run_coordinator.gd`
- `src/run/run_simulation.gd`
- `src/run/run.tscn`
- `tests/integration/run/three_day_chapter_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/run/three_day_chapter_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [RUN-001](story-001-chapter-outcomes.md), [WORLD-001](../world-map/story-001-place-content.md), [THERM-002](../thermal-field/story-002-insulation-provider.md), [ACT-001](../action-runner/story-001-sleep-snow.md), [ACT-002](../action-runner/story-002-eat-action.md), [ACT-003](../action-runner/story-003-shelter-build.md)
- Unlocks: None
