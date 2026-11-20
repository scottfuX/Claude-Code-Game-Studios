# Systems Index: Lonefire（孤火）

> **Status**: Draft
> **Created**: 2026-11-16
> **Last Updated**: 2026-11-16
> **Source Concept**: design/gdd/game-concept.md (from design/game-brief.md + prototypes/firebeforedark-concept/REPORT.md — 2026-11-15 PIVOT)

---

## Overview

Lonefire is a single-player, no-combat winter survival sim in the spirit of
《荒野独居》: one person, one fire, a crude shelter and their own hands, each day
colder than the last, with the tap-out decision as the core gamble. The
fire-before-dark playtest refuted a thin chore loop: it was not tense, actions did
not read, the body and the snow had no weight, cold did not bite, and none of the
show's feelings were present. This index therefore treats three things as core,
not polish: **feeling** (Morale & Mental State, Mishaps & Failure, Emotional
Feedback), **body and ground** (Character Controller & Animation, Terrain & Snow
Surface), and **real pressure** (Thermal Environment, Body Temperature, Needs &
Weight). The broader MVP covers one harsh first day and night that must
be physically heavy, readable from the high camera, and emotionally legible.
The [first playable night](../../production/milestones/first-playable-night.md)
is a smaller dusk-to-dawn milestone within that scope.
Owner decision 2026-11-16: emotion design comes first, so Morale & Mental State
is designed out of dependency order, and its GDD carries the feeling → show
feature → mechanic map every later GDD answers to.

**Per-system notes**

- **Input & Action Map** *(inferred)* — every control is an InputMap action (WASD, E, Tab, Esc + controller); the base for later multi-platform support.
- **Time & Day Cycle** — game clock, day counter, shrinking winter daylight and real-time pacing by mode (day / night / wait / sleep); the pacing spine the playtest found too slow and empty. The day-over-day cold ramp belongs to Thermal Environment (decided in the Time GDD).
- **Terrain & Snow Surface** *(inferred, playtest)* — readable hills, lake edge and drifts; deep snow the body sinks into, persistent footprints/trails, snow depth and slope slowing movement.
- **Map & Resource Distribution** *(inferred)* — the single map's layout and where sticks, deadfall, water and animal ranges sit, and how nearby resources deplete so trips grow longer.
- **Character Controller & Animation** — rigged survivor with idle/walk/wade/chop/pick/strike/shiver/collapse; weight and effort must read from far away (playtest: "人物没有动作", "行走起来没有质感").
- **Camera** — the high ~50° far third-person camera from the brief; framing that keeps the figure small but its effort readable.
- **Thermal Environment** *(inferred)* — one heat field combining air temperature, wind chill, fire radiance and shelter insulation; sources register into it, so fire, shelter and weather never depend on each other.
- **Interaction & Timed Actions** — contextual E; every action has duration, animation, interruption and an outcome event (the playtest's actions "动动就干完了").
- **Mishaps & Failure** — the outcome model for actions: failed strikes, damp tinder, wind-killed fires, snapped tools, empty traps, the fish that gets away. The main engine of 无力 and 失望; failures must have readable causes.
- **Gathering** — picking sticks and tinder, chopping deadfall into logs; fatigue and cold cost per trip.
- **Fire** — multi-step lighting (clear snow, ring, tinder, kindling, strike), fuel burn, damp and wind; the only warm colour in the world.
- **Body Temperature** — core temperature driven by the thermal field, wetness and exertion; outdoor cold must actually bite (playtest: "出去体温也没有怎么降").
- **Needs & Weight** — hydration, energy, fullness and body weight; weight is the slow lifeline and the source of 饥饿感 over days.
- **Injury & Pain** *(inferred)* — cuts, burns, frostbite and pain that slow actions and raise mishap odds; delivers 痛苦.
- **Morale & Mental State** — the player's mental state as five strains (loneliness, frustration, grief, hunger distress, pain) folded into a hidden Resolve, fed by body, events and time; it bends action reliability and is what pushes toward tapping out. Its GDD owns the feeling → mechanic map.
- **Shelter** — tent or lean-to with at least two build stages; adds insulation to the thermal field.
- **Water** — melting snow, chopping an ice hole, boiling; dehydration is a fail state.
- **Wildlife Behavior** — fish, hare and grouse that only wander and flee; presence that eases or deepens loneliness.
- **Food** — snares, ice fishing and cooking; the chance of nothing is part of the design.
- **Weather & Cold Snaps** — wind, snowfall and cold snaps that raise fuel burn and outdoor danger.
- **Medical Check-ins** *(show feature)* — periodic weigh-ins and health checks; can force a medical evacuation, which counts as a loss.
- **Rival Simulation & Ranking** — simulated rivals who tap out over time; "how many are left" makes isolation and the tap-out gamble concrete.
- **Item Database & Inventory** — item definitions, backpack and carrying.
- **Kit Selection** *(show feature)* — choose 10 items before the drop; the first strategic commitment.
- **Self-Filmed Diary** *(show feature)* — a nightly camera diary built from the day's events; speaking to the camera is the only voice the player has and can ease loneliness.
- **Tap-out & Run Results** — voluntary 退赛, ranking at exit, rewards for a top placing or lasting the target days, penalties on death or evacuation.
- **Meta Rewards** *(inferred)* — what rewards buy between runs. Open question: undefined in the brief.
- **Save/Load & Settings** — one autosave per run, plus settings.
- **Emotional Feedback** *(inferred)* — how body and morale are shown without a "sad bar": posture, gait, breath vapour, shivering, colour grading, camera and music.
- **Ambient & Foley Audio** — snow crunch, wind, fire crackle, breathing; the loudest signal of solitude.
- **HUD** — the minimal in-play readout (temperature, needs, time) plus the single line of guidance.
- **Screens & Menus** — backpack, kit selection, diary, results, title and pause.
- **Localization, Accessibility & Onboarding** — Chinese/English, input remapping and text scaling, first-run guidance beyond the one-line hint.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input & Action Map (inferred) | Core | MVP | Approved | design/gdd/input-and-action-map.md | — |
| 2 | Time & Day Cycle | Core | MVP | Approved | design/gdd/time-and-day-cycle.md | — |
| 3 | Terrain & Snow Surface (inferred) | Core | MVP | Approved | design/gdd/terrain-and-snow-surface.md | — |
| 4 | Map & Resource Distribution (inferred) | Core | MVP | Approved | design/gdd/map-and-resource-distribution.md | Terrain & Snow Surface |
| 5 | Character Controller & Animation | Core | MVP | Approved | design/gdd/character-controller-and-animation.md | Input & Action Map, Terrain & Snow Surface, Map & Resource Distribution |
| 6 | Camera | Core | MVP | Approved | design/gdd/camera.md | Character Controller & Animation, Terrain & Snow Surface, Input & Action Map, Map & Resource Distribution |
| 7 | Thermal Environment (inferred) | Core | MVP | Approved | design/gdd/thermal-environment.md | Time & Day Cycle, Map & Resource Distribution |
| 8 | Interaction & Timed Actions | Gameplay | MVP | Approved | design/gdd/interaction-and-timed-actions.md | Input & Action Map, Character Controller & Animation |
| 9 | Mishaps & Failure | Gameplay | MVP | Approved | design/gdd/mishaps-and-failure.md | Interaction & Timed Actions, Terrain & Snow Surface, Thermal Environment |
| 10 | Gathering | Gameplay | MVP | Approved | design/gdd/gathering.md | Interaction & Timed Actions, Item Database & Inventory, Map & Resource Distribution |
| 11 | Fire | Gameplay | MVP | Approved | design/gdd/fire.md | Interaction & Timed Actions, Item Database & Inventory, Thermal Environment, Mishaps & Failure, Time & Day Cycle, Map & Resource Distribution |
| 12 | Body Temperature | Gameplay | MVP | Approved | design/gdd/body-temperature.md | Thermal Environment, Time & Day Cycle |
| 13 | Needs & Weight | Gameplay | MVP | Approved | design/gdd/needs-and-weight.md | Time & Day Cycle, Body Temperature, Item Database & Inventory |
| 14 | Injury & Pain (inferred) | Gameplay | Vertical Slice | Not Started | — | Mishaps & Failure, Body Temperature |
| 15 | Morale & Mental State | Gameplay | MVP | Approved | design/gdd/morale-and-mental-state.md | Time & Day Cycle, Body Temperature, Needs & Weight, Mishaps & Failure |
| 16 | Shelter | Gameplay | Vertical Slice | Approved | design/gdd/shelter.md | Interaction & Timed Actions, Item Database & Inventory, Gathering, Thermal Environment |
| 17 | Water | Gameplay | Vertical Slice | Not Started | — | Interaction & Timed Actions, Item Database & Inventory, Fire, Map & Resource Distribution, Needs & Weight |
| 18 | Wildlife Behavior | Gameplay | Vertical Slice | Not Started | — | Map & Resource Distribution, Terrain & Snow Surface |
| 19 | Food | Gameplay | Vertical Slice | Not Started | — | Wildlife Behavior, Interaction & Timed Actions, Item Database & Inventory, Fire, Mishaps & Failure, Needs & Weight |
| 20 | Weather & Cold Snaps | Gameplay | Vertical Slice | Not Started | — | Time & Day Cycle, Thermal Environment |
| 21 | Medical Check-ins | Gameplay | Vertical Slice | Not Started | — | Needs & Weight, Body Temperature, Injury & Pain, Time & Day Cycle |
| 22 | Rival Simulation & Ranking | Gameplay | Vertical Slice | Not Started | — | Time & Day Cycle |
| 23 | Item Database & Inventory | Economy | MVP | Approved | design/gdd/item-database-and-inventory.md | — |
| 24 | Kit Selection | Economy | Vertical Slice | Not Started | — | Item Database & Inventory |
| 25 | Self-Filmed Diary | Narrative | Vertical Slice | Not Started | — | Time & Day Cycle, Morale & Mental State, Mishaps & Failure, Needs & Weight |
| 26 | Tap-out & Run Results | Progression | Vertical Slice | Not Started | — | Time & Day Cycle, Rival Simulation & Ranking, Medical Check-ins, Body Temperature, Needs & Weight, Morale & Mental State |
| 27 | Meta Rewards (inferred) | Progression | Alpha | Not Started | — | Tap-out & Run Results, Save/Load & Settings |
| 28 | Save/Load & Settings | Persistence | Alpha | Not Started | — | Time & Day Cycle, Item Database & Inventory (+ every stateful system) |
| 29 | Emotional Feedback (inferred) | UI | MVP | Approved | design/gdd/emotional-feedback.md | Morale & Mental State, Body Temperature, Character Controller & Animation, Camera |
| 30 | Ambient & Foley Audio | Audio | MVP | Approved | design/gdd/ambient-and-foley-audio.md | Terrain & Snow Surface, Character Controller & Animation, Fire |
| 31 | HUD | UI | MVP | Approved | design/gdd/hud.md | Body Temperature, Needs & Weight, Time & Day Cycle, Item Database & Inventory |
| 32 | Screens & Menus | UI | Vertical Slice | Not Started | — | Item Database & Inventory, Kit Selection, Self-Filmed Diary, Tap-out & Run Results |
| 33 | Localization, Accessibility & Onboarding | Meta | Full Vision | Not Started | — | HUD, Screens & Menus |

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **Core** | Foundation systems everything depends on | Input, time, terrain, map, character, camera, thermal field |
| **Gameplay** | The systems that make the game tense and felt | Interaction, mishaps, fire, body, needs, morale, shelter, food, weather, rivals |
| **Progression** | How a run ends and what it earns | Tap-out & results, meta rewards |
| **Economy** | Resource definition and carrying | Item database & inventory, kit selection |
| **Persistence** | Save state and continuity | Save/load, settings |
| **UI** | Player-facing information displays | HUD, screens, emotional feedback |
| **Audio** | Sound and music systems | Ambient & foley (adaptive music is part of Emotional Feedback) |
| **Narrative** | Story and self-expression delivery | Self-filmed diary |
| **Meta** | Systems outside the core game loop | Localization, accessibility, onboarding |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | One harsh day and night, physical and emotionally legible | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Survive three days, full run with tap-out and results | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

> MVP scope approved by owner 2026-11-16 (18 systems), expanding the brief's build-order step 1 to include morale, mishaps, emotional feedback, full needs & weight, and terrain & snow, per the PIVOT report.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Input & Action Map — every control routes through InputMap actions; nothing reads raw keys.
2. Time & Day Cycle — the clock and day count that all drains, ramps and events key off.
3. Terrain & Snow Surface — the ground everything walks on and is placed on.
4. Item Database & Inventory — item definitions are pure data every gameplay system reads.

### Core Layer (depends on foundation)

1. Map & Resource Distribution — depends on: Terrain & Snow Surface
2. Character Controller & Animation — depends on: Input & Action Map, Terrain & Snow Surface, Map & Resource Distribution (soft)
3. Camera — depends on: Character Controller & Animation, Terrain & Snow Surface, Input & Action Map, Map & Resource Distribution (soft)
4. Thermal Environment — depends on: Time & Day Cycle, Map & Resource Distribution (soft). Fire, Shelter and Weather register as heat/insulation/chill sources through its interface.
5. Interaction & Timed Actions — depends on: Input & Action Map, Character Controller & Animation
6. Body Temperature — depends on: Thermal Environment, Time & Day Cycle

### Feature Layer (depends on core)

1. Mishaps & Failure — depends on: Interaction & Timed Actions, Terrain & Snow Surface, Thermal Environment (soft). Reads reliability modifiers (fatigue, cold hands, morale, injury, wind) through one contract.
2. Gathering — depends on: Interaction & Timed Actions, Item Database & Inventory, Map & Resource Distribution
3. Fire — depends on: Interaction & Timed Actions, Item Database & Inventory, Thermal Environment, Mishaps & Failure, Time & Day Cycle, Map & Resource Distribution (soft)
4. Needs & Weight — depends on: Time & Day Cycle, Body Temperature, Item Database & Inventory
5. Morale & Mental State — depends on: Time & Day Cycle, Body Temperature, Needs & Weight, Mishaps & Failure; consumes events from Injury, Diary, Rivals, Wildlife when present.
6. Injury & Pain — depends on: Mishaps & Failure, Body Temperature
7. Shelter — depends on: Interaction & Timed Actions, Item Database & Inventory, Gathering, Thermal Environment
8. Water — depends on: Interaction & Timed Actions, Item Database & Inventory, Fire, Map & Resource Distribution, Needs & Weight
9. Wildlife Behavior — depends on: Map & Resource Distribution, Terrain & Snow Surface
10. Food — depends on: Wildlife Behavior, Interaction & Timed Actions, Item Database & Inventory, Fire, Mishaps & Failure, Needs & Weight
11. Weather & Cold Snaps — depends on: Time & Day Cycle, Thermal Environment
12. Medical Check-ins — depends on: Needs & Weight, Body Temperature, Injury & Pain, Time & Day Cycle
13. Rival Simulation & Ranking — depends on: Time & Day Cycle
14. Kit Selection — depends on: Item Database & Inventory
15. Self-Filmed Diary — depends on: Time & Day Cycle, Morale & Mental State, Mishaps & Failure, Needs & Weight
16. Tap-out & Run Results — depends on: Time & Day Cycle, Rival Simulation & Ranking, Medical Check-ins, Body Temperature, Needs & Weight, Morale & Mental State
17. Meta Rewards — depends on: Tap-out & Run Results, Save/Load & Settings

### Presentation Layer (depends on features)

1. Emotional Feedback — depends on: Morale & Mental State, Body Temperature, Character Controller & Animation, Camera
2. Ambient & Foley Audio — depends on: Terrain & Snow Surface, Character Controller & Animation, Fire
3. HUD — depends on: Body Temperature, Needs & Weight, Time & Day Cycle, Item Database & Inventory
4. Screens & Menus — depends on: Item Database & Inventory, Kit Selection, Self-Filmed Diary, Tap-out & Run Results

### Polish Layer (depends on everything)

1. Save/Load & Settings — depends on: Time & Day Cycle, Item Database & Inventory, and every stateful system's serialized state
2. Localization, Accessibility & Onboarding — depends on: HUD, Screens & Menus

**Bottlenecks:** Thermal Environment, Interaction & Timed Actions, Mishaps & Failure, Morale & Mental State, Time & Day Cycle. **Leaf nodes (low risk, designable late):** Meta Rewards, Screens & Menus, Localization/Accessibility/Onboarding, Ambient & Foley Audio.

> TD-SYSTEM-BOUNDARY skipped — Lean mode.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Morale & Mental State (owner priority — out of dependency order; owns the feeling → mechanic map) | MVP | Feature | game-designer, creative-director | L |
| 2 | Time & Day Cycle | MVP | Foundation | game-designer, systems-designer | S |
| 3 | Thermal Environment | MVP | Core | systems-designer | M |
| 4 | Body Temperature | MVP | Core | systems-designer | M |
| 5 | Needs & Weight | MVP | Feature | systems-designer, economy-designer | M |
| 6 | Item Database & Inventory | MVP | Foundation | game-designer, economy-designer | S |
| 7 | Input & Action Map | MVP | Foundation | game-designer, ux-designer | S |
| 8 | Terrain & Snow Surface | MVP | Foundation | level-designer, technical-artist | M |
| 9 | Character Controller & Animation | MVP | Core | game-designer, technical-artist | M |
| 10 | Camera | MVP | Core | game-designer, art-director | S |
| 11 | Interaction & Timed Actions | MVP | Core | game-designer | M |
| 12 | Mishaps & Failure | MVP | Feature | systems-designer, game-designer | M |
| 13 | Map & Resource Distribution | MVP | Core | level-designer | M |
| 14 | Gathering | MVP | Feature | game-designer | S |
| 15 | Fire | MVP | Feature | game-designer, systems-designer | M |
| 16 | Emotional Feedback | MVP | Presentation | creative-director, art-director, audio-director | M |
| 17 | Ambient & Foley Audio | MVP | Presentation | audio-director, sound-designer | S |
| 18 | HUD | MVP | Presentation | ux-designer | S |
| 19 | Weather & Cold Snaps | Vertical Slice | Feature | systems-designer | M |
| 20 | Shelter | Vertical Slice | Feature | game-designer | M |
| 21 | Water | Vertical Slice | Feature | game-designer | S |
| 22 | Injury & Pain | Vertical Slice | Feature | systems-designer | S |
| 23 | Wildlife Behavior | Vertical Slice | Feature | ai-programmer, game-designer | M |
| 24 | Food | Vertical Slice | Feature | game-designer, economy-designer | M |
| 25 | Medical Check-ins | Vertical Slice | Feature | game-designer | S |
| 26 | Rival Simulation & Ranking | Vertical Slice | Feature | systems-designer | M |
| 27 | Kit Selection | Vertical Slice | Feature | economy-designer | S |
| 28 | Self-Filmed Diary | Vertical Slice | Feature | narrative-director, writer | M |
| 29 | Tap-out & Run Results | Vertical Slice | Feature | game-designer, economy-designer | M |
| 30 | Screens & Menus | Vertical Slice | Presentation | ux-designer | M |
| 31 | Save/Load & Settings | Alpha | Polish | game-designer | S |
| 32 | Meta Rewards | Alpha | Feature | economy-designer | M |
| 33 | Localization, Accessibility & Onboarding | Full Vision | Polish | localization-lead, accessibility-specialist, ux-designer | M |

Order 1 breaks dependency order on purpose: Morale's GDD defines the inputs it needs (body, needs, mishap events) as contracts that GDDs 2–15 must then satisfy.

> PR-SCOPE skipped — Lean mode.

---

## Circular Dependencies

- **Morale & Mental State <-> Mishaps & Failure:** low morale lowers action reliability, and failures lower morale. Resolution: Mishaps owns the outcome roll and reads one reliability-modifier input (morale is one contributor); Morale only consumes Mishaps' outcome events. Define the contract in the Morale GDD; Mishaps implements it.
- **Morale & Mental State <-> Self-Filmed Diary:** the diary reads morale and the day's events, and recording an entry eases loneliness. Resolution: the diary emits a `diary_recorded` event that Morale consumes; Morale never calls the diary.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Character Controller & Animation | Technical | The survivor mesh is unrigged; procedural motion was refuted in the playtest. | Rig spike (scripted Blender armature + idle/walk/chop/strike/shiver); fallback: Mixamo or manual Blender with owner help. |
| Terrain & Snow Surface | Technical | Deep-snow sinking and persistent trails can be costly, and mobile is a later target. | Terrain + snow spike early; measure against `project.yaml` performance budgets. |
| Morale & Mental State | Design | Feelings reduced to a visible meter read as gamey ("sad bar") and miss the show's emotions. | Deliver feelings through mechanics and Emotional Feedback, not numbers; owner playtest of the next build. |
| Mishaps & Failure | Design | Random failure feels unfair rather than helpless. | Every failure has a visible cause (damp, wind, fatigue, cold hands) and a player counter-measure. |
| Thermal Environment | Design | Bottleneck; wrong numbers make cold either toothless (playtest) or instantly lethal. | Tune with the first-day pressure curve; data-driven values. |
| Rival Simulation & Ranking | Design | Unseen rivals may not create loneliness or real stakes for tapping out. | Paper-test the tap-out gamble before building it. |
| Emotional Feedback | Scope | Animation, VFX, grading and adaptive music each grow large. | MVP limits it to posture/gait, breath, grading and a few music states. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 33 |
| Design docs started | 19 |
| Design docs reviewed | 19 |
| Design docs approved | 19 |
| MVP systems designed | 18/18 |
| Vertical Slice systems designed | 1/12 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`), starting with Morale & Mental State
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check technical-setup` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
