# Story 003: Route shelter construction through the provider

> **ID**: ACT-003
> **Epic**: [ActionRunner](EPIC.md)
> **Status**: Blocked — BLOCKED: An approved Shelter design and Feature provider are required before wiring build actions.
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.5 dev days (provisional)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [interaction-and-timed-actions](../../../design/gdd/interaction-and-timed-actions.md), [thermal-environment](../../../design/gdd/thermal-environment.md)\
**Requirement**: TR-interaction-and-timed-actions-001, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006, TR-thermal-environment-007 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) (Accepted)\
**ADR Decision Summary**: One action commit; the terminal barrier gates stage/collapse and completion. Versioned heat and insulation sources feed a read-only Thermal query. Validate item definitions and commit using versioned inventory commands.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] At an approved location the player can advance the specified build stages. Spend materials once at the approved commit boundary.
- [ ] An invalid or interrupted attempt does not grant uncommitted progress or warmth. The completed provider registers its volume and removes it at teardown.

## Implementation Notes

Core calls a resolver port, never imports a concrete Shelter controller. The supplier, recipe and construction visuals are outside this story.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/action_runner.gd`
- `src/run/run_simulation.gd`
- `tests/integration/actions/shelter_build_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/actions/shelter_build_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [WORLD-001](../world-map/story-001-place-content.md), [THERM-002](../thermal-field/story-002-insulation-provider.md)
- Unlocks: [RUN-002](../run-coordinator/story-002-wire-three-day-chapter.md)
