# Epic: ItemCatalog / InventoryModel

> **Layer**: Core
> **GDD**: [Item Database & Inventory](../../../design/gdd/item-database-and-inventory.md)
> **Architecture Module**: M15 — ItemCatalog / InventoryModel ([architecture](../../../docs/architecture/architecture.md#module-ownership))
> **Engine Risk**: HIGH — Godot 4.7.2 pin
> **Status**: Ready
> **Stories**: 1 (1 Ready, 0 Blocked)

## Overview

Validate nutrition data and transact one consumption. No inventory redesign or decision on what food ships. This is the scoped [three-day chapter](../../milestones/three-day-survival.md), not whole-system completion.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) | Body produces post-step state and cold wake; Needs alone owns sleep. | HIGH pin |
| [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) | Validate item definitions and commit using versioned inventory commands. | HIGH pin |

## GDD Requirements

| TR-ID(s) | Requirement | ADR Coverage |
|---|---|---|
| TR-item-database-and-inventory-001, TR-item-database-and-inventory-002, TR-item-database-and-inventory-007, TR-item-database-and-inventory-008 | Data-defined nutrition and consumption, not loss | [ADR-0009](../../../docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md) Accepted |
| TR-needs-and-weight-005, TR-needs-and-weight-019, TR-needs-and-weight-029 | Refuse invalid food or stomach overflow without spending | [ADR-0008](../../../docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md) Accepted |

Untraced requirements: none among these scoped registry IDs. Chapter victory and Feature content planning are milestone scope, not new ADR or TR decisions.

## Stories

| ID | Story | Type | Status | Est. dev days |
|---|---|---|---|---:|
| ITEM-001 | [Validate and consume nutrition by stack ID](story-001-nutrition-transaction.md) | Integration | Ready | 1.5 |

## Definition of Done

- Close each story with `/story-done` after required dependencies and acceptance checks pass.
- Retain passing gdUnit4 evidence for scoped criteria and first-night regressions.
- Verify relevant chapter exit checks without claiming unscoped GDD requirements are complete.
