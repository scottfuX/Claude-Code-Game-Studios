# Story 002: Commit a timed eat action

> **ID**: ACT-002
> **Epic**: [ActionRunner](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 dev day (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [interaction-and-timed-actions](../../../design/gdd/interaction-and-timed-actions.md), [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-interaction-and-timed-actions-004, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006, TR-interaction-and-timed-actions-028, TR-needs-and-weight-005, TR-needs-and-weight-019 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) (Accepted)\
**ADR Decision Summary**: One action commit; the terminal barrier gates stage/collapse and completion. Body produces post-step state and cold wake; Needs alone owns sleep. Validate item definitions and commit using versioned inventory commands.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] A valid targeted food action consumes one unit on completion and grants that unit's nutrition.
- [ ] Cancel, terminal, stale stack and stomach-capacity rejection grant no nutrition and remove no item; report the refusal/cancellation.

## Implementation Notes

Revalidate the stack and attempt token at completion, then use the consumption port. Food acquisition is not part of this action.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/action_runner.gd`
- `src/run/run_simulation.gd`
- `tests/integration/actions/eat_action_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/actions/eat_action_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [ITEM-001](../item-catalog-inventory/story-001-nutrition-transaction.md)
- Unlocks: [RUN-002](../run-coordinator/story-002-wire-three-day-chapter.md)
