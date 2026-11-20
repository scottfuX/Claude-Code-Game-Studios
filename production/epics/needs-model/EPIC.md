# Epic: NeedsModel

> **Layer**: Core
> **GDD**: [Needs & Weight](../../../design/gdd/needs-and-weight.md)
> **Architecture Module**: M13 — NeedsModel ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 3 (3 Ready, 0 Blocked)

## Overview

Hydration, hunger, weight, energy and sleep on the existing minute pipeline. No medical evacuation or independent hunger death. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Serial minute dispatch and bounded debt; rate changes resolve between minutes. | HIGH pin |
| [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body produces post-step state and cold wake; Needs alone owns sleep. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-needs-and-weight-001, TR-needs-and-weight-002, TR-needs-and-weight-007, TR-needs-and-weight-008, TR-needs-and-weight-010, TR-needs-and-weight-011, TR-needs-and-weight-015, TR-needs-and-weight-016, TR-needs-and-weight-018, TR-needs-and-weight-025, TR-needs-and-weight-026 | Hydration, stage penalties and zero-hydration grace | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |
| TR-needs-and-weight-001, TR-needs-and-weight-002, TR-needs-and-weight-003, TR-needs-and-weight-004, TR-needs-and-weight-010, TR-needs-and-weight-012, TR-needs-and-weight-013, TR-needs-and-weight-014, TR-needs-and-weight-017, TR-needs-and-weight-018, TR-needs-and-weight-027, TR-needs-and-weight-028 | Stomach-first burn, weight, energy cap and fullness stages | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |
| TR-needs-and-weight-008, TR-needs-and-weight-009, TR-needs-and-weight-016, TR-needs-and-weight-020, TR-needs-and-weight-021, TR-needs-and-weight-022, TR-needs-and-weight-023, TR-needs-and-weight-024 | Sleep eligibility, recovery, collapse and wake reconciliation | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| NEED-001 | [Integrate hydration and submit dehydration once](story-001-hydration-energy.md) | Logic | Ready | 1 |
| NEED-002 | [Burn stomach calories before body weight](story-002-fullness-weight.md) | Logic | Ready | 1 |
| NEED-003 | [Own sleep, exhaustion collapse and natural wake](story-003-sleep-state.md) | Logic | Ready | 1.25 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
