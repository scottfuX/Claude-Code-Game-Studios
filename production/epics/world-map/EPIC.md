# Epic: WorldMap

> **Layer**: Core
> **GDD**: [Map & Resource Distribution](../../../design/gdd/map-and-resource-distribution.md)
> **Architecture Module**: M4 — WorldMap ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Blocked
> **Stories**: 1 (0 Ready, 1 Blocked)

## Overview

Placement queries and approved chapter locations on the existing map. No terrain rebuild or resources outside chapter scope. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0004](../../../docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md) | Authored map and typed queries; validate world data before activation. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-map-and-resource-distribution-001, TR-map-and-resource-distribution-008, TR-map-and-resource-distribution-009, TR-map-and-resource-distribution-010, TR-map-and-resource-distribution-011 | Reuse authored map, safe drop and spatial data | [ADR-0004](../../../docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| WORLD-001 | [Expose approved shelter and food locations](story-001-place-content.md) | Integration | Blocked | 1 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
