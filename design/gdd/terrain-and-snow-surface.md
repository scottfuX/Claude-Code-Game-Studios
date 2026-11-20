# Terrain & Snow Surface

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (systems-designer / level-designer / technical-artist lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 苦中有美 · 亲手做

## Summary

Terrain & Snow Surface is the ground: the shape of the land (hills, slopes, the lake basin) and the snow lying on it — how deep it is, how packed, what kind of surface it is (fresh snow, a trodden trail, a drift, lake ice, bare rock). It answers "what is under the survivor's feet?" for every other system, makes deep snow and uphill slopes slow and tiring, makes the body sink into it, and keeps every footprint as a trail that gets easier to walk the more it is used. It is the answer to three playtest notes at once: "地形看不出来", "脚印太假，雪地里应该有陷入的感觉", "行走起来没有质感".

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

The system has two layers. The **terrain** is a heightmap-defined landform (shape, slope, collision) rendered in the art bible's flat, per-face low-poly look so that slopes read through faceted light and long shadows from the high camera. The **snow surface** is a grid laid over it (`cell_size_m`, default 0.5 m) storing, per cell, a surface type, `snow_depth_m` and `compaction` (0–1). From these the system derives the *effective* depth a foot sinks into (Formula TS1), how far the body visibly sinks (TS2), how fast one can move (TS3–TS5), and whether moving counts as wading (TS6, the "wade" activity Body Temperature and Needs & Weight already price). Every footfall compacts the cells it lands on (TS7) and leaves a footprint that stays: repeated trips carve a visible, faster path — the survivor's own map drawn into the snow.

For the player this is the physical feel of the world: knee-deep drifts that turn a short walk into a slog, a packed trail home that is a relief to step onto, a hill that has to be climbed, lake ice that is flat and fast but thin in places. It does not own the map layout and where resources sit (Map & Resource Distribution paints types and depths into this grid), the character's base walk speed and animation (Character Controller & Animation), falling through ice (Mishaps decides the roll from `ice_thickness_cm`), or snowfall (Weather & Cold Snaps, VS, writes into the grid).

## Detailed Design

### Core Rules

1. **Terrain shape.** The map's landform is defined by a heightmap (resolution set by Map & Resource Distribution; target ≤ 1 m per sample). It provides height, surface normal and `slope_deg` at any point, plus collision. Slopes the player can walk are ≤ `slope_max_deg` (default 35°); steeper ground is impassable (cliffs, rock faces).
2. **Readable landform.** Terrain is rendered with flat per-face shading (art bible §1 大块面, §3 "雪地是缓坡大平面"): every slope of 5° or more must show a visible value step between faces facing the sun and faces away from it at the gameplay camera, so the land reads without texture. The lake basin is a flat plane; drifts are long, soft mounds on the lee side of trees and rocks.
3. **Surface grid.** A grid of `cell_size_m` cells covers the playable map. Each cell stores `type`, `snow_depth_m` (0–1.5) and `compaction` (0–`c_max`). Map & Resource Distribution authors the initial values; Weather (VS) adds snowfall.
4. **Surface types** (data-file table):

   | type | default snow_depth_m | sink_factor | type_speed_mult | compaction applies | footstep sound | notes |
   |---|---|---|---|---|---|---|
   | fresh snow 新雪 | 0.35 | 0.9 | 1.0 | yes | deep crunch | the default open ground |
   | forest snow 林下雪 | 0.20 | 0.8 | 1.0 | yes | soft crunch | shallower under canopy |
   | drift 雪堆 | 0.8–1.2 | 1.0 | 1.0 | yes | muffled plunge | lee of trees, rocks, shore |
   | lake ice 湖冰 | 0.05 | 0.3 | 0.9 | no | hollow squeak | flat and fast; `ice_thickness_cm` per cell |
   | rock / scoured 裸岩 | 0.0 | 0 | 1.0 | no | scrape | wind-blown ridges, boulders |
5. **Ice.** Every lake-ice cell has `ice_thickness_cm` (authored by Map; default 25 cm, thin spots 5–10 cm near inflows and the shore). Terrain only reports it; Mishaps & Failure decides when ice breaks and emits `fell_in_water`.
6. **Effective depth and sinking.** The foot sinks into the *loose* part of the snow: effective depth = depth × (1 − compaction) (TS1). The visible sink of the body (TS2) is capped at knee-to-thigh height (`sink_max_m`, 0.45 m); Character Controller lowers the figure and hides the legs in the snow by that amount.
7. **Movement.** The terrain speed multiplier (TS5) combines depth (TS3), uphill grade (TS4) and type. Character Controller multiplies it with its base speed and with Body Temperature's, Needs & Weight's and Inventory's movement multipliers.
8. **Wading.** When effective depth ≥ `wade_depth_m` (default 0.25 m), moving reports the **wade** activity (TS6) — the value Body Temperature (+0.45 °C/h heat) and Needs & Weight (+120 kcal/h, −3.5 energy/h) already use.
9. **Footprints and trails.** Each footfall stamps the cells under the foot: their `compaction` rises (TS7) and a footprint mark is recorded with depth = the sink at that moment. Footprints persist for the whole run (until snowfall fills them, VS). Cells walked often become a **trail**: visibly trodden, shallower effective depth, faster to walk. Trails are never authored — they are the player's history.
10. **Snowfall (VS contract).** Weather adds `snow_depth_m` to cells (fresh snow on top: compaction is reduced in proportion — new loose snow over an old trail) and fills footprint marks by the same depth.
11. **Queries.** `surface_at(p)` returns `{type, snow_depth_m, compaction, effective_depth_m, sink_m, slope_deg, normal, terrain_speed_mult, is_wading, ice_thickness_cm, footstep_sound}`. Results are deterministic for the same grid state.
12. **What Terrain never does.** It never moves the character, never decides that ice breaks, never changes the heightmap at runtime (no digging in the MVP), and never shows numbers to the player.

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Snow cell | untouched · trodden (compaction > 0) · trail (compaction ≥ 0.5) | footfall raises compaction (TS7); snowfall (VS) lowers it toward untouched |
| Footprint mark | fresh · filled (VS) | created by a footfall; filled when snowfall depth since creation ≥ its depth |
| Ice cell | solid · broken (VS: refreezes over days) | Mishaps reports a break → broken (open water) until `refreeze_h` passes |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Map & Resource Distribution | in | heightmap, initial cell types, depths, ice thickness | Map (content) / Terrain (format) |
| Character Controller & Animation | in/out | in: footfall positions and the foot's contact; out: `terrain_speed_mult`, `sink_m`, `slope_deg`, `normal`, `is_wading`, footstep sound | Terrain |
| Body Temperature (approved) | out | `wade` activity (via Character) | Character reports, Terrain decides |
| Needs & Weight (approved) | out | `wade` activity (via Character) | Character reports, Terrain decides |
| Thermal Environment (approved) | — | no direct link: zones come from Map; lake zone and lake-ice cells are authored together | Map |
| Mishaps & Failure | out | `ice_thickness_cm`, surface type under the player (slips on ice, stumbles in drifts) | Terrain |
| Camera | out | heights and slopes for framing and collision | Terrain |
| Wildlife Behavior (VS) | out | surface queries; animals also leave tracks | Terrain |
| Weather & Cold Snaps (VS) | in | snowfall depth per cell | Weather |
| Ambient & Foley Audio | out | `footstep_sound`, sink depth for the crunch intensity | Terrain |
| Emotional Feedback / rendering | out | trail and footprint data for the snow shader | Terrain |
| Save/Load (Alpha) | out | cell depths, compaction, footprint marks, broken ice | Terrain |

Implementation notes → become ADRs: (a) terrain representation — Godot 4.7 has no built-in terrain node in the engine reference: heightmap mesh + `HeightMapShape3D` collision (Jolt) vs. a terrain GDExtension; (b) footprint rendering — a world-space trail texture sampled by the snow shader (vertex displacement near the camera) vs. decals; (c) grid storage and save size.

## Formulas

**TS1 — Effective depth.** The `effective_depth_m` formula is defined as:

`effective_depth_m = snow_depth_m × (1 − compaction)` (types where compaction does not apply — lake ice, rock — keep compaction 0, so their effective depth is their depth)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| snow_depth_m | float | 0–1.5 | calculated (grid) | snow on the cell |
| compaction | float | 0–0.85 | calculated (TS7) | how packed |

**Output Range:** 0–1.5 m. **Examples:** fresh snow 0.35, untouched → **0.35**; after 3 passes (0.58) → **0.147**; drift 1.0 → **1.0**.

**TS2 — Visible sink.** The `sink_m` formula is defined as:

`sink_m = min(effective_depth_m, sink_max_m) × sink_factor[type]`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| sink_max_m | float | 0.2–0.7 | data file | knee-to-thigh cap (default 0.45) |
| sink_factor | float | 0–1 | data file (type table) | how much of the loose snow the foot goes through |

**Output Range:** 0–0.45 m. **Examples:** fresh untouched → 0.35 × 0.9 = **0.32 m** (mid-shin); trail (0.147) → **0.13 m**; drift → **0.45 m** (thigh, capped); lake ice → 0.05 × 0.3 = **0.015 m**.

**TS3 — Depth slow-down.** The `depth_speed_mult` formula is defined as:

`depth_speed_mult = max(depth_floor, 1 − k_depth × effective_depth_m)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| k_depth | float | 0.5–2.0 | data file | slow-down per metre of loose snow (default 1.0) |
| depth_floor | float | 0.2–0.7 | data file | slowest wading (default 0.45) |

**Output Range:** 0.45–1.0. **Examples:** fresh 0.35 → **0.65**; trail 0.147 → **0.85**; drift 1.0 → **0.45** (floor).

**TS4 — Uphill slow-down.** The `slope_speed_mult` formula is defined as:

`slope_speed_mult = grade_deg ≤ 0 ? 1 : max(slope_floor, 1 − k_up × grade_deg / 30)`, where `grade_deg` is the slope angle along the direction of travel (positive uphill); `grade_deg > slope_max_deg` is impassable

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| k_up | float | 0.2–1.0 | data file | slow-down at 30° uphill (default 0.5) |
| slope_floor | float | 0.3–0.8 | data file | default 0.5 |
| slope_max_deg | float | 20–45 | data file | default 35 |

Downhill gives no speed bonus in snow (deep snow brakes the descent); on lake ice the slope is 0.

**Output Range:** 0.5–1.0. **Examples:** flat → **1.0**; 15° uphill → **0.75**; 30° → **0.5**; 40° → impassable.

**TS5 — Terrain speed.** The `terrain_speed_mult` formula is defined as:

`terrain_speed_mult = depth_speed_mult × slope_speed_mult × type_speed_mult[type]`

**Output Range:** 0.225–1.0. **Examples:** fresh snow, flat → **0.65**; fresh snow, 15° uphill → **0.49**; trail, flat → **0.85**; drift, 15° uphill → 0.45 × 0.75 = **0.34**; lake ice → 0.95 × 1 × 0.9 = **0.855**. With a base walk of 1.4 m/s (Character GDD to confirm), fresh snow is ≈ 0.9 m/s and a trail ≈ 1.2 m/s.

**TS6 — Wading.** The `is_wading` rule is defined as:

`is_wading = moving and effective_depth_m ≥ wade_depth_m`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| wade_depth_m | float | 0.1–0.5 | data file | default 0.25 |

**Output Range:** true / false. **Examples:** fresh untouched (0.35) → **wading**; after 2 passes (0.4375 compaction → 0.197) → **walking**; forest (0.20) → **walking**. A trodden trail turns a wade into a walk — trails save heat, energy and calories, not just time.

**TS7 — Compaction per footfall.** The `compaction` update is defined as (per footfall on a cell, at most once per cell per `pass_cooldown_s`):

`compaction' = min(c_max, compaction + c_step × (1 − compaction))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| c_step | float | 0.05–0.5 | data file | default 0.25 |
| c_max | float | 0.5–0.95 | data file | default 0.85 — even a trail keeps some loose snow |
| pass_cooldown_s | float | 1–30 | data file | real seconds before the same cell can compact again (default 5) — standing still does not pack snow |

**Output Range:** 0–0.85. **Examples:** passes 1 → **0.25**; 2 → **0.4375**; 3 → **0.578**; 6 → **0.822**; then capped at 0.85.

*systems-designer + technical-artist lenses applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: `c_max = 1` would make trails bottomless-fast (effective depth 0) — capped below 1; stomping in place to build a trail — blocked by `pass_cooldown_s`; very deep drifts (1.5 m) making the player stuck — bounded by `depth_floor` (always ≥ 0.45 × base speed); multiplying TS5 with Body (0.40), Needs (0.85) and Inventory (0.70) gives a worst case of 0.225 × 0.40 × 0.85 × 0.70 ≈ 0.054 × base — Character must define a movement floor (flagged). Positive loop: walk a path → it gets faster → walk it more; intended (trails are the player's map), bounded by `c_max` and reset by snowfall (VS).*

## Edge Cases

- **If a foot lands on a cell boundary**: stamp every cell under the foot's footprint radius (≈ 0.15 m); each counts once per cooldown.
- **If the player stands still or shuffles in place**: no extra compaction (`pass_cooldown_s`); footprints are not re-stamped.
- **If the slope along travel exceeds `slope_max_deg`**: the move is blocked in that direction (Character slides along the contour); across the slope remains walkable.
- **If the player walks out onto a thin-ice cell**: Terrain reports thickness only; Mishaps decides; after a break the cell becomes open water (impassable except wading out at the shore edge — Character handles the climb-out).
- **If a cell has `snow_depth_m` 0 on a snow type** (scoured by wind): effective depth 0, no sink, no footprint, rock sound.
- **If snowfall (VS) lands on a trail**: new depth adds to the cell and compaction falls to `compaction × old_depth / new_depth` — the trail softens but does not vanish at once.
- **If a query is outside the grid**: return rock, slope from the heightmap, speed 1.0, and log a warning (map bounds should prevent it).
- **If the grid would exceed its memory budget** (very large map): Map must reduce the playable area or Terrain coarsens cells away from paths (ADR).
- **If two systems query the same point in a tick**: identical results (deterministic).
- **If a save is loaded**: cell state and footprint marks restore exactly; footprints render from saved marks, not from replay.
- **If the player is crawling (Body Critical)**: footfalls are replaced by drag marks; compaction still applies.

## Dependencies

**Upstream — hard:** none (Foundation; content comes from Map).

**Upstream — soft:** Map & Resource Distribution (authored heightmap, types, depths, ice — without it, a flat fresh-snow test field), Weather & Cold Snaps (VS, snowfall), Mishaps (ice breaks), Character Controller (footfall reports).

**Downstream:** Map & Resource Distribution (authors into this format), Character Controller & Animation (hard: speed, sink, slope, wading), Camera (heights), Mishaps (ice thickness, surface type), Wildlife Behavior (VS), Ambient & Foley Audio (footsteps), Emotional Feedback / rendering (trail shader), Body Temperature and Needs & Weight (wade activity, via Character), Save/Load.

[Food (three-day chapter)](food.md) relies on Map's validation of ice, drift depth and slope along the authored approach; Terrain does not resolve catches.

**Bidirectional check:** the systems index lists Terrain with no dependencies (matches) and Map, Character, Camera, Wildlife, Ambient & Foley as dependents (matches). Body Temperature and Needs & Weight define the `wade` activity values (+0.45 °C/h; +120 kcal/h, −3.5 energy/h) and Needs adds hydration ×1.5 — this GDD supplies the rule for when wading applies (TS6). Mishaps' index row does not list Terrain (ice thickness, surface) — soft; fix when Mishaps is designed.

## Visual/Audio Requirements

*art-director + technical-artist lenses applied (visual feedback is central: the playtest's three terrain complaints are visual), against `design/art/art-bible.md` §1–4.*
- **Landform reads at the far camera** (§1 大块面, §3): flat-shaded faces; ≥ one visible value step between sun-facing and shaded faces on any slope ≥ 5°; long blue shadows (snow_shadow `#B9D0EA`) from trees and ridges carry the shape. No textures.
- **Footprints and trails** (§1, §6 无文字叙事 "脚印…说明时间过去了多少"): footprints are real depressions, darker (snow_shadow) inside; a trail reads as a continuous grey-blue groove from the gameplay camera; the survivor's paths between camp, woodland and lake become the map's most readable human mark.
- **Sinking:** the figure visibly drops into deep snow (shin, knee, thigh); snow puffs at each step in fresh snow and drifts; legs disappear below the surface line.
- **Ice:** a flatter, slightly bluer, glossier plane; thin ice shows darker patches the attentive player can learn to read (cause visible before Mishaps rolls).
- **Audio:** footstep sets per type (deep crunch, soft crunch, plunge, hollow squeak, scrape), louder and slower when wading; occasional ice creak on the lake at night.
- **Budget:** the snow surface (displacement + trail texture) must fit the 16.6 ms frame (60 fps, `project.yaml`) on the min-spec target with the rest of the scene; a decal fallback must exist for a future mobile build.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:terrain-and-snow-surface` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Snow has weight.** Walking into fresh snow should feel like effort — slower, lower, louder — from the first step; stepping onto your own trail should feel like relief.
- **The land has shape.** A player should be able to point at "the hill", "the lake", "the hollow where the drifts are" in a screenshot without labels.
- **Your history is in the snow.** After a few days, the trodden paths should look like the player's own map of the place.
- **Never stuck.** Deep snow slows to under half speed but never to zero; the player always sees why they are slow (they are sunk to the thigh).

## UI Requirements

- **None in play.** The surface is read from the world (depth, trails, ice colour, sound).
- **Debug overlay (dev only):** cell type, depth, compaction, effective depth, sink, slope, speed multiplier, wading flag, ice thickness; optional compaction heatmap.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 8, TS6 | Body Temperature (`design/gdd/body-temperature.md`) | `wade` activity heat +0.45 | approved — matches |
| Rule 8, TS6 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `wade` +120 kcal/h, −3.5 energy/h, hydration ×1.5 | approved — matches |
| Rule 7, TS5 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | `carry_speed_mult` multiplied in Character | approved — matches |
| Rules 3–5 | Map & Resource Distribution (`design/gdd/map-and-resource-distribution.md`) | authors heightmap, types, depths, ice | not yet written — provisional |
| Rules 6–9 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | base speed (1.4 m/s assumed), sink display, footfalls, movement floor | not yet written — provisional |
| Rule 5 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | ice break roll from thickness | not yet written — provisional |
| Rule 10 | Weather & Cold Snaps | snowfall | VS |
| Visual/Audio | `design/art/art-bible.md` §1, §3, §4, §6 | flat faces, snow planes, palette, footprints as story | exists |
| Summary | `prototypes/firebeforedark-concept/REPORT.md` | "地形看不出来", "脚印太假", "行走起来没有质感" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / screenshot evidence.

**Core rules**
1. [A] **GIVEN** a cell of fresh snow, **WHEN** queried, **THEN** it returns type fresh, depth 0.35, compaction 0, effective 0.35, sink 0.315 ± 0.005, wading true when moving.
2. [A] **GIVEN** ground with a 40° grade along travel, **WHEN** the character tries to move uphill, **THEN** the move is blocked; across the slope it is allowed.
3. [A] **GIVEN** a lake-ice cell with 8 cm thickness, **WHEN** queried, **THEN** `ice_thickness_cm` = 8 and no break happens from Terrain alone.
4. [A] **GIVEN** the player stands on one cell for 60 real seconds, **THEN** its compaction rises at most once per 5 s of new footfalls and not at all while standing still.
5. [A] **GIVEN** a footprint stamped at sink 0.32 m, **WHEN** the run continues for 10 game days without snowfall, **THEN** the mark still exists with depth 0.32.
6. [A] **GIVEN** a point outside the grid, **WHEN** queried, **THEN** rock, speed 1.0 and a warning are returned.
7. [A] **GIVEN** the same grid state, **WHEN** queried twice, **THEN** results are identical.

**States**
8. [A] **GIVEN** an untouched cell, **WHEN** 2 passes land, **THEN** trodden (0.4375); at 3 passes → trail (≥ 0.5).

**Formulas**
9. [A] TS1/TS2: drift 1.0 → effective 1.0, sink 0.45 (cap); lake ice → sink 0.015 ± 0.001; rock → 0.
10. [A] TS3: effective 0.35 → 0.65; 0.147 → 0.853 ± 0.002; 1.0 → 0.45; 1.5 → 0.45.
11. [A] TS4: 0° → 1.0; 15° → 0.75; 30° → 0.5; 34° → 0.5 (floor); downhill 20° → 1.0.
12. [A] TS5: fresh, 15° uphill → 0.4875 ± 0.001; drift, 15° → 0.3375 ± 0.001; lake ice flat → 0.8555 ± 0.001.
13. [A] TS6: effective 0.25 → wading; 0.249 → not; standing still on 0.35 → not wading.
14. [A] TS7: compaction after 1, 2, 3, 6, 20 passes → 0.25, 0.4375, 0.578, 0.822, 0.85.
15. [A] Data with `c_max ≥ 1` or `depth_floor ≤ 0` is rejected and defaults are used.

**Cross-system & feel**
16. [A] **GIVEN** the player walks 1 game hour through untouched fresh snow, **THEN** Body Temperature receives activity `wade` (+0.45 heat) and Needs & Weight burns +120 kcal; **GIVEN** the same hour on a trail with compaction ≥ 0.44, **THEN** activity is `walk`.
17. [P] **GIVEN** a gameplay-camera screenshot of the MVP map at day and at dusk, **WHEN** shown to 5 testers, **THEN** ≥ 4 can point out the hill, the lake and a drift area without labels (playtest "地形看不出来").
18. [P] **GIVEN** the owner walks into deep snow, **THEN** they report that the survivor sinks and moving feels heavy (playtest "脚印太假", "行走起来没有质感").
19. [P] **GIVEN** a screenshot after 3 game days of play, **THEN** the player's trails between camp, woods and lake are visible from the gameplay camera.

**Performance:** `surface_at` ≤ 0.02 ms per query; snow surface rendering within the 16.6 ms frame on min-spec (measured in the terrain/snow spike); grid memory ≤ 8 MB for the MVP map.

*QA gaps found and resolved: standing-still compaction (4), footprint persistence (5), out-of-grid queries (6), trodden/trail thresholds (8), wade boundary (13), cross-system wade pricing (16). Feel lines moved to playtest criteria 17–19.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Terrain technology in Godot 4.7: heightmap mesh + `HeightMapShape3D` (Jolt) or a terrain GDExtension? The engine reference has no terrain module — knowledge gap. | technical-director | terrain/snow spike → ADR | spike both on the MVP map size; measure frame time |
| Footprint rendering: trail texture + vertex displacement vs decals; how dense must the mesh near the camera be? | technical-artist | terrain/snow spike → ADR | spike against the 16.6 ms budget |
| The full movement-multiplier stack can drop to ≈ 5 % of base speed (Body Critical × Needs Exhausted × full pack × drift uphill). What floor does Character apply? | game-designer | Character Controller GDD | suggest a floor of 0.15 × base outside Critical crawl |
| Can the player stamp a trail deliberately (snowshoes, a "break trail" action) as a VS feature? | game-designer | VS | — |
| MVP map size and grid resolution (memory budget) | level-designer | Map & Resource Distribution GDD | — |
