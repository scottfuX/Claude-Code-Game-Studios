# Epics Index

Last Updated: 2026-11-20\
Engine: Godot 4.7 (pinned 4.7.2) / GDScript / Jolt\
Milestone: [Three-day survival](../milestones/three-day-survival.md)\
Review: PR-EPIC and QL-STORY-READY skipped — Lean mode.

| Epic | Layer | System | GDD | Stories | Status |
|---|---|---|---|---:|---|
| [GameClock](game-clock/EPIC.md) | Foundation | M2 — GameClock | [Time & Day Cycle](../../design/gdd/time-and-day-cycle.md) | 2 | Ready |
| [RunCoordinator](run-coordinator/EPIC.md) | Foundation | RunCoordinator / scene composition | [Run composition](../../design/gdd/time-and-day-cycle.md) | 2 | Ready |
| [WorldMap](world-map/EPIC.md) | Core | M4 — WorldMap | [Map & Resource Distribution](../../design/gdd/map-and-resource-distribution.md) | 1 | Blocked |
| [ThermalField](thermal-field/EPIC.md) | Core | M7 — ThermalField | [Thermal Environment](../../design/gdd/thermal-environment.md) | 2 | Ready |
| [ActionRunner](action-runner/EPIC.md) | Core | M8 — ActionRunner | [Interaction & Timed Actions](../../design/gdd/interaction-and-timed-actions.md) | 3 | Ready |
| [BodyThermoregulation](body-thermoregulation/EPIC.md) | Core | M12 — BodyThermoregulation | [Body Temperature](../../design/gdd/body-temperature.md) | 1 | Ready |
| [NeedsModel](needs-model/EPIC.md) | Core | M13 — NeedsModel | [Needs & Weight](../../design/gdd/needs-and-weight.md) | 3 | Ready |
| [ItemCatalog / InventoryModel](item-catalog-inventory/EPIC.md) | Core | M15 — ItemCatalog / InventoryModel | [Item Database & Inventory](../../design/gdd/item-database-and-inventory.md) | 1 | Ready |

InputRouter, TerrainSurface and SurvivorController reuse the shipped first-night paths: no new bindings, snow depth or animation work. The [milestone](../milestones/three-day-survival.md) tracks Feature and Presentation handoffs separately. These epics do not complete full-system or phase-gate scope.
