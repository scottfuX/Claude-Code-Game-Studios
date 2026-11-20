# Epic: BodyThermoregulation

> **Layer**: Core
> **GDD**: [Body Temperature](../../../design/gdd/body-temperature.md)
> **Architecture Module**: M12 — BodyThermoregulation ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 1 (1 Ready, 0 Blocked)

## Overview

Body-owned cold wake while preserving minute temperature integration. No new cold penalties or injury. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) | Serial minute dispatch and bounded debt; rate changes resolve between minutes. | HIGH pin |
| [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body produces post-step state and cold wake; Needs alone owns sleep. | HIGH pin |
| [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) | Fire updates Thermal heat; Fire never requests wake or normal time. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-body-temperature-002, TR-body-temperature-009, TR-body-temperature-016, TR-body-temperature-017, TR-body-temperature-028 | Per-minute Thermal sample; Body-owned wake | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| BODY-001 | [Wake sleep from Body cold, not Fire Out](story-001-cold-wake.md) | Integration | Ready | 1.25 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
