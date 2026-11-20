# Epic: ActionRunner

> **Layer**: Core
> **GDD**: [Interaction & Timed Actions](../../../design/gdd/interaction-and-timed-actions.md)
> **Architecture Module**: M8 — ActionRunner ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 3 (2 Ready, 1 Blocked)

## Overview

Contextual sleep, snow and eat actions, plus the shelter provider boundary. No new bindings or animations. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) | Versioned heat and insulation sources feed a read-only Thermal query. | HIGH pin |
| [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) | One action commit; the terminal barrier gates stage/collapse and completion. | HIGH pin |
| [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body produces post-step state and cold wake; Needs alone owns sleep. | HIGH pin |
| [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) | Validate item definitions and commit using versioned inventory commands. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-interaction-and-timed-actions-004, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006, TR-interaction-and-timed-actions-008, TR-interaction-and-timed-actions-009 | Contextual start, work and completion | [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) Accepted |
| TR-needs-and-weight-006, TR-needs-and-weight-009 | Snow intake and chosen sleep | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |
| TR-interaction-and-timed-actions-004, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006, TR-interaction-and-timed-actions-028 | Timed eat; cancelled attempts have no effect | [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) Accepted |
| TR-needs-and-weight-005, TR-needs-and-weight-019 | Refuse an over-capacity eat before consuming | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |
| TR-interaction-and-timed-actions-001, TR-interaction-and-timed-actions-005, TR-interaction-and-timed-actions-006 | Registered interaction, eligibility and cancellation | [ADR-0007](../../../docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md) Accepted |
| TR-thermal-environment-007 | Register shelter insulation at the approved boundary | [ADR-0006](../../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| ACT-001 | [Route contextual sleep and snow intake](story-001-sleep-snow.md) | Integration | Ready | 1.5 |
| ACT-002 | [Commit a timed eat action](story-002-eat-action.md) | Integration | Ready | 1 |
| ACT-003 | [Route shelter construction through the provider](story-003-shelter-build.md) | Integration | Blocked | 1.5 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
