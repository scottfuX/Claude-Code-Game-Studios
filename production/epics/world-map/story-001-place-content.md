# Story 001: Expose approved shelter and food locations

> **ID**: WORLD-001
> **Epic**: [WorldMap](EPIC.md)
> **Status**: Blocked — BLOCKED: Approved Shelter and Food location/availability specs are missing.
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 dev day (provisional)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [map-and-resource-distribution](../../../design/gdd/map-and-resource-distribution.md)\
**Requirement**: TR-map-and-resource-distribution-001, TR-map-and-resource-distribution-008, TR-map-and-resource-distribution-009, TR-map-and-resource-distribution-010, TR-map-and-resource-distribution-011 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0004](../../../docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md) (Accepted)\
**ADR Decision Summary**: Authored map and typed queries; validate world data before activation.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript / Jolt | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Approved build sites and food sources are reachable from the existing drop without a new map.
- [ ] The map exposes valid placement or rejection according to the approved designs. Location queries do not spawn food or generate warmth.

## Implementation Notes

Keep spatial validation in the map/physics adapter and content rules in their respective Feature providers.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/world_map.gd`
- `src/run/run.tscn`
- `tests/integration/world/chapter_placements_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/world/chapter_placements_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: None
- Unlocks: [RUN-002](../run-coordinator/story-002-wire-three-day-chapter.md), [ACT-003](../action-runner/story-003-shelter-build.md)
