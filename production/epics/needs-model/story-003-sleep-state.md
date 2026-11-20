# Story 003: Own sleep, exhaustion collapse and natural wake

> **ID**: NEED-003
> **Epic**: [NeedsModel](EPIC.md)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.25 dev days (proposed)
> **Manifest Version**: 2026-11-19

## Context

**GDD**: [needs-and-weight](../../../design/gdd/needs-and-weight.md)\
**Requirement**: TR-needs-and-weight-008, TR-needs-and-weight-009, TR-needs-and-weight-016, TR-needs-and-weight-020, TR-needs-and-weight-021, TR-needs-and-weight-022, TR-needs-and-weight-023, TR-needs-and-weight-024 ([registry](../../../docs/architecture/tr-registry.yaml))\
**ADR Governing Implementation**: [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md), [ADR-0003](../../../docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md) (Accepted)\
**ADR Decision Summary**: Body produces post-step state and cold wake; Needs alone owns sleep. Serial minute dispatch and bounded debt; rate changes resolve between minutes.\
**ADR Version**: 2026-11-18\
**Engine**: Godot 4.7.2 / GDScript | **Risk**: HIGH (pin). Verify against the ADR Engine Compatibility sections.\
**Control Manifest Rules (Core)**: [Control Manifest](../../../docs/architecture/control-manifest.md). Use owner ports and ordered processing; no foreign state writes.

## Acceptance Criteria

- [ ] Voluntary sleep requires energy below 90 at night or 50 by day. Refusal leaves state/rate unchanged. Awake depletion to zero proposes one exhaustion collapse.
- [ ] Recover toward the weight-adjusted cap using post-Body warmth and fullness. Natural cap wake requests normal; a valid normal-rate interruption reconciles sleep once.
- [ ] Coalesce all wake causes into one transition. Forced wake after collapse raises energy to at least 5.

## Implementation Notes

Needs alone writes is_asleep. Use static Body/wake inputs in these unit tests, with changed rates applied to the next interval.

## Out of Scope

See [epic scope](EPIC.md#overview) and the [chapter milestone](../../milestones/three-day-survival.md).

## Files

- `src/core/needs_model.gd`
- `src/data/slice_tuning.gd`
- `tests/unit/needs/sleep_state_test.gd`

## QA Test Cases

See the [Sprint 001 QA plan](../../qa/qa-plan-sprint-001-2026-11-20.md) for fixtures and expected results.

## Test Evidence

- gdUnit4 `tests/unit/needs/sleep_state_test.gd` must exist and pass.
- [ ] Not yet created.

## Dependencies

- Depends on: [CLK-002](../game-clock/story-002-interruptible-rates.md), [NEED-001](story-001-hydration-energy.md), [NEED-002](story-002-fullness-weight.md)
- Unlocks: [BODY-001](../body-thermoregulation/story-001-cold-wake.md)
