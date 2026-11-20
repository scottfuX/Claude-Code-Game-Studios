# Story 001: Validate and consume nutrition by stack ID

> **ID**: ITEM-001
> **Epic**: [ItemCatalog / InventoryModel](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.5 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [item-database-and-inventory](../../../design/gdd/item-database-and-inventory.md), [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-item-database-and-inventory-001, TR-item-database-and-inventory-002, TR-item-database-and-inventory-007, TR-item-database-and-inventory-008, TR-needs-and-weight-005, TR-needs-and-weight-019, TR-needs-and-weight-029 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md), [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) (Accepted)\
**ADR Decision Summary**: Validate item definitions and commit using versioned inventory commands. Body produces post-step state and cold wake; Needs alone owns sleep.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] With a 400 kcal test ration: from 1,400 kcal refuse and keep the item; from 1,000 kcal reach 1,400 and remove exactly one.
- [ ] Reject undefined/invalid nutrition and stale/duplicate commits with no partial effects. A valid commit reports consumption, not item loss.

## Implementation Notes

Use immutable catalog values and an inventory-owned versioned commit. Ration is a fixture, not approval to ship food as starting inventory.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/inventory_model.gd`
- `src/core/needs_model.gd`
- `tests/integration/inventory/nutrition_transaction_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/inventory/nutrition_transaction_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [NEED-002](../needs-model/story-002-fullness-weight.md)
- Unlocks: [ACT-002](../action-runner/story-002-eat-action.md)
