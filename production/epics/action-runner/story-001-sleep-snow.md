# Story 001: Route contextual sleep and snow intake

> **ID**: ACT-001
> **Epic**: [ActionRunner](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.5 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [interaction-and-timed-actions](../../../design/gdd/interaction-and-timed-actions.md), [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-interaction-and-timed-actions-004, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006, TR-interaction-and-timed-actions-008, TR-interaction-and-timed-actions-009, TR-needs-and-weight-006, TR-needs-and-weight-009 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md), [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) (Accepted)\
**ADR Decision Summary**: One action commit; the terminal barrier gates stage/collapse and completion. Body produces post-step state and cold wake; Needs alone owns sleep.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Existing controls submit eligible sleep to Needs; refusal leaves an awake survivor awake, and wake restores eligible actions.
- [ ] One committed snow handful takes 3 game minutes, grants 3 hydration and costs 1 energy subject to clamps. On snow, Hypothermic is allowed and Critical refuses without effects or a new cooling cost.
- [ ] Cancel or reach terminal before completion: hydration, energy and grace timer do not change as a result of the action.

## Implementation Notes

Route through the current action and localized prompt systems, not raw keys. Consult the Body whitelist and apply snow only through Needs at commit.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/action_runner.gd`
- `src/run/run_coordinator.gd`
- `src/run/run_simulation.gd`
- `tests/integration/actions/sleep_and_snow_test.gd`

## QA Test Cases

N/A — Lean story-readiness review skipped. Use the acceptance criteria; add fixtures to the QA plan when scheduled.

## Test Evidence

- gdUnit4 `tests/integration/actions/sleep_and_snow_test.gd` must exist and pass; keep a smoke result.
- [ ] Not yet created.

## Dependencies

- Depends on: [BODY-001](../body-thermoregulation/story-001-cold-wake.md)
- Unlocks: [RUN-002](../run-coordinator/story-002-wire-three-day-chapter.md)
