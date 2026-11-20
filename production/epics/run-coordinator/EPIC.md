# Epic: RunCoordinator

> **Layer**: Foundation
> **GDD**: [Run composition](../../../design/gdd/time-and-day-cycle.md)
> **Architecture Module**: RunCoordinator / scene composition ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 2 (1 Ready, 1 Blocked)

## Overview

Chapter profile wiring, ordered outcomes and teardown. No new mode picker or full Tap-out & Run Results. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0001](../../../docs/architecture/adr-0001-run-scene-composition-and-service-lifecycle.md) | Run-scoped composition, teardown and detached snapshots. | HIGH pin |
| [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Serial minute dispatch and bounded debt; rate changes resolve between minutes. | HIGH pin |
| [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) | Versioned heat and insulation sources feed a read-only Thermal query. | HIGH pin |
| [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) | One action commit; the terminal barrier gates stage/collapse and completion. | HIGH pin |
| [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body produces post-step state and cold wake; Needs alone owns sleep. | HIGH pin |
| [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) | Fire updates Thermal heat; Fire never requests wake or normal time. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-time-and-day-cycle-012 | Time does not own run termination | [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) Accepted |
| TR-needs-and-weight-011, TR-needs-and-weight-026 | One dehydration candidate; hypothermia wins ties | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |
| TR-time-and-day-cycle-004, TR-time-and-day-cycle-012 | Configured drop and coordinator-owned result | [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) Accepted |
| TR-needs-and-weight-002, TR-needs-and-weight-012 | Continuous physiology and published weight trend | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| RUN-001 | [Resolve third-sunrise outcomes and death precedence](story-001-chapter-outcomes.md) | Integration | Ready | 1.5 |
| RUN-002 | [Assemble the chapter in the main run scene](story-002-wire-three-day-chapter.md) | Integration | Blocked | 2 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
