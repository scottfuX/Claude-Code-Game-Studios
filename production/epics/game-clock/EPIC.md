# Epic: GameClock

> **Layer**: Foundation
> **GDD**: [Time & Day Cycle](../../../design/gdd/time-and-day-cycle.md)
> **Architecture Module**: M2 — GameClock ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 2 (2 Ready, 0 Blocked)

## Overview

Chapter clock coordinates, phase boundaries and interruptible rates. No run outcome policy. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Serial minute dispatch and bounded debt; rate changes resolve between minutes. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-time-and-day-cycle-001, TR-time-and-day-cycle-003, TR-time-and-day-cycle-004, TR-time-and-day-cycle-005, TR-time-and-day-cycle-006, TR-time-and-day-cycle-011, TR-time-and-day-cycle-013, TR-time-and-day-cycle-014 | One clock, day rollover and shrinking daylight | [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) Accepted |
| TR-time-and-day-cycle-002, TR-time-and-day-cycle-007, TR-time-and-day-cycle-008, TR-time-and-day-cycle-009, TR-time-and-day-cycle-015, TR-time-and-day-cycle-018, TR-time-and-day-cycle-019, TR-time-and-day-cycle-020, TR-time-and-day-cycle-021 | Process every owed minute; re-evaluate rate and pause at the boundary | [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| CLK-001 | [Advance day and phase through three nights](story-001-day-boundaries.md) | Logic | Ready | 1 |
| CLK-002 | [Arbitrate sleep and wait between minutes](story-002-interruptible-rates.md) | Logic | Ready | 1 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
