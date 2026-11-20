# Epic: ThermalField

> **Layer**: Core
> **GDD**: [Thermal Environment](../../../design/gdd/thermal-environment.md)
> **Architecture Module**: M7 — ThermalField ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 2 (2 Ready, 0 Blocked)

## Overview

Daily cold ramp and the insulation registration port. No shelter recipe or dynamic weather. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) | Versioned heat and insulation sources feed a read-only Thermal query. | HIGH pin |
| [ADR-0011](../../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md) | Fire updates Thermal heat; Fire never requests wake or normal time. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-thermal-environment-002, TR-thermal-environment-003, TR-thermal-environment-009, TR-thermal-environment-027 | Day-indexed mean, diurnal swing and per-minute samples | [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) Accepted |
| TR-thermal-environment-007, TR-thermal-environment-009, TR-thermal-environment-010, TR-thermal-environment-022 | Local insulation volume, read-only sampling and overlap rule | [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| THERM-001 | [Verify the daily cold ramp across skips](story-001-daily-cold-ramp.md) | Logic | Ready | 1 |
| THERM-002 | [Register and remove shelter insulation](story-002-insulation-provider.md) | Integration | Ready | 1.5 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
