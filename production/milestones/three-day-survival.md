# Milestone: Three-Day Survival (Chapter 2)

## Milestone Goal

Survive three days in the existing snowy playfield by tending fire, managing hunger, thirst and body weight, sleeping, making a simple shelter and eating food. Build on the [first playable night](first-playable-night.md) and [the core-loop plan](../../docs/PLAN.md#7-阶段与过关标准), not a new map or a full Production phase. Owner scope: “撑过三天，加饥饿、口渴、体重、睡觉、简易棚子和食物，一局延长到三天。”

For this chapter plan, count **three completed overnights after the drop**: a day 1 afternoon start and victory at day 4 sunrise. The accepted [Time GDD](../../design/gdd/time-and-day-cycle.md) supplies the clock and start; the run profile supplies the victory target. The first-night fixture still ends at day 2 sunrise. This is a reversible milestone configuration, not a change to the canonical run length.

## Feature List

| Must ship | Chapter floor |
|---|---|
| Multi-day run | Existing scene, fire and gathering loop; days 1–3 continue until the third sunrise. Cold ramps with day as defined in [Thermal](../../design/gdd/thermal-environment.md). |
| Hunger, thirst and weight | [Needs](../../design/gdd/needs-and-weight.md) integrates every game minute. Hunger depletes reserves and reduces recovery/cap via approved rules. Snow intake is the approved hydration stand-in; no melt, boil or ice-hole system. |
| Sleep | Voluntary sleep, exhaustion collapse and natural wake. Cold interruption comes from Body; Fire Out only updates Thermal per [ADR-0011](../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md). |
| Simple shelter | One simple buildable shelter type, on the existing playfield, with placeholder visuals and insulation via [ADR-0006](../../docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md). Recipe and placement remain design work. |
| Food | At least one obtainable and edible food source. Consumption is timed and atomic; source and availability remain design work. A synthetic ration in tests is not a design for the real food source. |
| Player feedback | Use existing localized prompts and [HUD patterns](../../design/ux/hud.md) to communicate fullness/hydration stages and sleep/wake without exposing raw needs values. Verify weight trend via the run snapshot; no new weigh-in screen or numeric HUD. |

The broad plan mentions starvation death. The existing Needs GDD models Starving as pressure, not its own fatal event; chapter tests use hypothermia and dehydration. A new hunger death rule would need a separate design decision. Full Water, hunting/fishing, Wildlife, medical check-ins, weather events, Save/Load, and full results are not chapter prerequisites. Snow depth and scene-fitting animations stay in the art pass; the separate flicker fix is not chapter scope.

## Delivery Order

1. [Sprint 001 — clock, needs and sleep fixtures](../sprints/sprint-001.md): ordered ticks → hunger/thirst/weight → sleep and Body cold wake → terminal and first-night regressions. No default gameplay change.
2. Add generic world/thermal/action and inventory extensions from the [Foundation and Core backlog](../epics/index.md). Land the approved player-facing sleep/snow actions, eat transaction and insulation fixture before using new chapter content.
3. Land the approved chapter content and HUD handoffs, then [assemble the default run](../epics/run-coordinator/story-002-wire-three-day-chapter.md) and run the milestone exit checks.

## Content and Presentation Handoffs

The [systems index](../../design/gdd/systems-index.md#systems-enumeration) and [architecture](../../docs/architecture/architecture.md#deferred-scope-only) list Shelter and Food as deferred without implementation contracts. The table tracks work needed to unblock this chapter, not accepted choices or Sprint 001 commitments.

| Handoff | Deliverable required before dependent work | Blocks |
|---|---|---|
| Shelter design → Feature provider | Owner approves the shelter type, placement limits, build stages/materials, cancellation and insulation values. Write the scoped design, then supply a resolver and lifecycle-owned volume through existing ports. | [WORLD-001](../epics/world-map/story-001-place-content.md), [ACT-003](../epics/action-runner/story-003-shelter-build.md), default run |
| Food design → Feature provider | Owner approves one obtainable source, availability across days, and item nutrition/effort. Write the scoped design, then supply authored content and an acquisition path through existing ports. No wildlife dependency is assumed without the design. | WORLD-001, default run |
| HUD → Presentation adapter | Extend the read-only adapter for hunger/thirst stages, sleep/wake and day progression; localize player copy and verify the existing Standard accessibility constraints and result display. Use fixture snapshots so this work need not wait for content. | Default run and chapter playtest |

## Success Criteria

- [ ] Launch the main project without debug flags and play through the third sunrise, with earlier sunrises and midnights retaining run state.
- [ ] On a survival run, show hydration falling/recovering, accepted food increasing fullness and the weight trend under hunger; build and use the shelter, and verify colder conditions outside.
- [ ] Show a safe sleep and a separate cold wake. Verify Fire Out alone does not wake a sleeper or jump past an owed cold minute.
- [ ] Verify cold and dehydration loss and same-minute precedence with deterministic fixtures. The winning result emits only once and a fresh run resets the prior run.
- [ ] Retain passing gdUnit4 results, a recorded normal-launch chapter playthrough, and localized HUD/result evidence. Retain the first-night regression fixtures; this is not a stage promotion.
