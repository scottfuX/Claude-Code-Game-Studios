# Character Controller & Animation

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / art-director / technical-artist / gameplay-programmer lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 苦中有美 · 亲手做

## Summary

Character Controller & Animation is the survivor's body in motion: it turns the player's movement input into a heavy, sinking walk through snow, combines every system's slow-downs into one speed with a floor so the player is never stuck, tells the body systems what kind of effort is being made (walking, wading, hauling, hurrying), and plays the rigged animations that make work, cold, hunger and despair readable from the high, far camera. It is the direct fix for the playtest notes "人物没有动作" and "行走起来没有质感", and the reason the rig spike is the project's first technical risk.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input & Action Map, Terrain & Snow Surface`

## Overview

The controller is a capsule character on the terrain: each physics frame it reads `move_vector` from Input, queries `surface_at` from Terrain under its feet, derives the grade along its direction of travel (Formula C2 — Terrain's review assigned this derivation here), combines the speed multipliers of Terrain, Body Temperature, Needs & Weight and Inventory into one target speed with a floor (C1), and moves toward it with deliberately slow acceleration and turning (C3) — weight comes from acceleration, not input lag. It reports the movement *activity* that Body Temperature and Needs & Weight price (C4), emits footfalls that Terrain turns into compaction and footprints (C5), and lowers the figure into the snow by Terrain's sink depth (C6).

The animation side is a rigged, humanoid skeleton driven by three layers: **locomotion** (idle / walk / wade / haul / hurry / crawl, blended by speed and depth), an **action** layer played by Interaction for timed work (chop, pick up, kneel-work, strike, blow on embers, eat, eat snow, sit, sleep), and an **overlay** layer for state (shiver, stumble, posture sets from Body Temperature, Needs & Weight and Morale through Emotional Feedback). Everything is exaggerated for a figure only ~20–40 px tall on screen (art bible §5: "肢体动作要大，远镜头下才读得出"). The survivor mesh is unrigged today; the rig/animation spike is a prerequisite (Open Questions), with the owner's offer to help if rigging proves hard.

What it does not own: what an action does and how long it takes (Interaction), when the body is Critical or Exhausted (Body Temperature, Needs & Weight), which idle a mood selects (Emotional Feedback, from Morale), the camera (Camera), and the snow data (Terrain).

## Detailed Design

### Core Rules

1. **Body.** The survivor is a capsule (radius 0.3 m, height 1.75 m) on the terrain's collision, with a step height of 0.3 m (snow lips, stones). Gravity applies; there is no jumping in the MVP.
2. **Base speeds.** Walking `base_walk` 1.4 m/s; crawling `base_crawl` 0.35 m/s (used only in Body Temperature's Critical stage, replacing walking). Hurrying multiplies by `hurry_mult` 1.3.
3. **One speed.** Target speed = base × max(floor, product of every multiplier) (C1). The multipliers are:

   | Multiplier | Owner | Range |
   |---|---|---|
   | `terrain_speed_mult` | Terrain & Snow Surface | 0.225–1.0 |
   | `move_speed_mult` | Body Temperature | 0.40–1.00 (0.40 = Critical; in Critical the crawl base replaces walking and Body's 0.40 is **not** applied again) |
   | `needs_move_speed_mult` | Needs & Weight | 0.85–1.00 |
   | `carry_speed_mult` | Item Database & Inventory | 0.70–1.00 |
   | `hurry_mult` | this GDD | 1.0 or 1.3 |

   The floor (`speed_floor_mult`, default 0.15) answers Terrain's open question: the worst stack (≈ 5 % of base) is lifted to 15 %, so the player always moves visibly and always sees why they are slow.
4. **Grade along travel.** Character computes `grade_deg` from Terrain's surface normal and the direction of travel (C2) and passes it to Terrain's `terrain_speed_mult` query; moves with `grade_deg > slope_max_deg` (35°) are blocked and the character slides along the contour.
5. **Hurry** (`move_hurry` held). Allowed only when Body stage is Cold or better, Needs energy is not Exhausted, and the hauling flag is off. It multiplies speed by 1.3 and reports **heavy work** activity (Body +0.6 °C/h, Needs +200 kcal/h and −5 energy/h). In deep snow it is a lunge, not a run: speed still obeys the floor and depth rules.
6. **Weight through motion.** Acceleration and turning are slow and get slower in deeper snow and under load (C3). Starting a walk is never delayed beyond one frame of input (Input's Game Feel target); reaching full speed takes 0.35–0.9 s.
7. **Activity report** (C4). Every physics frame, Character reports one movement activity to Body Temperature and Needs & Weight: `idle`, `walk`, `wade`, or `heavy` (hurrying or hauling while moving). Interaction reports *work* activity separately; Body and Needs use the highest (their own rules).
8. **Footfalls.** Each foot contact (an animation event on the walk/wade cycles) emits `footfall{position, foot, sink_m}` to Terrain, which compacts the snow and records the footprint. Crawling emits drag marks instead.
9. **Sinking.** The figure is lowered by Terrain's `sink_m` under it, smoothed over 0.15 s (C6), with foot IK keeping the feet on the compacted surface; the snow surface line hides the lower legs.
10. **Animation layers** (priority, highest first):
    1. **Full-body overrides:** collapse (Needs exhaustion), sleep / wake, crawl (Body Critical), death / evacuation (end of run).
    2. **Action layer:** the current Interaction action (chop, pick up, kneel-work, strike, blow on embers, add fuel, eat, eat snow, sit at fire, warm hands). Movement input cancels unless Interaction says otherwise.
    3. **Locomotion:** idle / walk / wade / haul / hurry, blended by speed and effective depth.
    4. **Overlays (additive):** shiver (Body `is_shivering`), stumble (Body Hypothermic), breath (Body / Thermal), posture set (Body stage → Needs stage → Morale `dominant_strain`, in that order, chosen by Emotional Feedback), failure beats (Morale/Mishaps events, ≤ 1.2 s, cancelled by input).
11. **Action timing.** Interaction calls `play_action(action_id, duration_s)`. The clip's effort segment loops so the action fills `duration_s`; playback speed is clamped to 0.85–1.15 so cold, tired work looks *longer and heavier*, never slow-motion (C7).
12. **MVP animation set** (Tier A must ship in the MVP; Tier B may be placeholder):

    | Tier A | Tier B |
    |---|---|
    | idle (3 posture sets: steady, cold-hunched, exhausted), walk, wade, haul-walk, turn-in-place, chop (3-beat), pick up (crouch), kneel-work (clear snow, place stones, arrange tinder), strike ferro rod, blow on embers, add fuel, sit at fire + warm hands, lie down / sleep / wake, collapse, crawl, shiver overlay, stumble overlay | hurry, eat, eat snow, failure beats (kneel, head drop, kick snow), look at horizon, hand-to-stomach, sunrise look, sit-and-stare (grief) |
13. **Rig standard.** One humanoid skeleton (Godot's humanoid skeleton profile, so clips can be retargeted from libraries such as Mixamo if hand-authoring is too slow), ≤ 30 bones, one LOD (art bible §5), mesh within the survivor's triangle budget (art bible §8: 3,222 today; cap ≤ 4,500 pending the owner's decision).
14. **Readability bar.** Every Tier A animation must read as its verb in a gameplay-camera clip where the survivor is ≈ 30 px tall (C8 check). Limbs move big; no facial animation.

### States and Transitions

| State | Enter | Leave | Locomotion |
|---|---|---|---|
| Idle | no move input, no action | move input / action start | posture-set idle |
| Moving | move input with speed > 0.1 m/s | input released (decelerates) | walk / wade / haul / hurry blend |
| Acting | Interaction `play_action` | action end / cancel | action layer; locomotion frozen |
| Crawling | Body stage → Critical | Body stage → Hypothermic or better | crawl only; only Interaction's Critical whitelist |
| Collapsed / Sleeping | Needs `is_asleep` true (collapse or chosen sleep) | Needs `is_asleep` false | full-body override; no movement |
| In water (MVP: thin ice, Mishaps M4) | Mishaps `fell_in_water` | climbs out at the shore edge | swim-struggle override; Mishaps/Body handle consequences |
| Ended | death / evacuation / tap-out | — | final pose held |

Transitions out of Crawling and Collapsed play their get-up animations (≥ 0.8 s) before control returns.

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Input & Action Map | in | `move_vector` (0–1), `move_hurry` held | Input |
| Terrain & Snow Surface (approved) | in/out | in: `surface_at` (type, `effective_depth_m`, `sink_m`, `slope_deg`, `normal`, `is_wading`, `terrain_speed_mult` given `grade_deg`); out: `footfall{position, foot, sink_m}`, drag marks | Terrain / Character |
| Body Temperature (approved) | in/out | in: `move_speed_mult`, `stage`, `is_shivering`; out: movement activity | Body / Character |
| Needs & Weight (approved) | in/out | in: `needs_move_speed_mult`, energy stage, `is_asleep` (collapse/sleep); out: movement activity | Needs / Character |
| Item Database & Inventory (approved) | in | `carry_speed_mult`, hauling flag, `carry_load_frac` (backpack size) | Inventory |
| Interaction & Timed Actions | in/out | in: `play_action(id, duration_s)`, cancel; out: `is_idle`, action finished, move-cancels-action | Interaction / Character |
| Morale & Mental State / Emotional Feedback | in | posture set, failure beats, ritual poses | Emotional Feedback |
| Camera | out | position, velocity, facing | Character |
| Mishaps & Failure | in/out | in: fall-through (`fell_in_water`); stumbles come from Body Hypothermic overlay, slips are not rolled in the MVP; out: current surface and speed | Mishaps / Character |
| Ambient & Foley Audio | out | footfall events with surface type and sink | Character |
| Save/Load (Alpha) | out | position, facing, state | Character |

Implementation notes → become ADRs: CharacterBody3D vs. a custom kinematic controller on Jolt; AnimationTree layering with Godot 4.6+ `SkeletonModifier3D` foot IK (TwoBoneIK); retargeting via the humanoid skeleton profile.

## Formulas

**C1 — Target speed.** The `target_speed` formula is defined as:

`base = (body_stage == Critical) ? base_crawl : base_walk`
`mults = terrain_speed_mult × (body_stage == Critical ? 1 : move_speed_mult) × needs_move_speed_mult × carry_speed_mult × hurry_mult`
`target_speed = |move_vector| × base × max(speed_floor_mult, mults)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_walk | float | 1.0–2.0 | data file | default 1.4 m/s |
| base_crawl | float | 0.2–0.6 | data file | default 0.35 m/s |
| move_vector | Vector2 | length 0–1 | calculated (Input IN1) | |
| terrain_speed_mult | float | 0.225–1.0 | calculated (Terrain TS5) | |
| move_speed_mult | float | 0.40–1.00 | calculated (Body B4) | ignored in Critical |
| needs_move_speed_mult | float | 0.85–1.00 | calculated (Needs N6) | |
| carry_speed_mult | float | 0.70–1.00 | calculated (Inventory I2) | |
| hurry_mult | float | 1.0 / 1.3 | data file | 1.3 when hurrying is allowed and held |
| speed_floor_mult | float | 0.05–0.4 | data file | default 0.15 |

**Output Range:** 0–1.82 m/s at defaults (maximum product 1.0 × 1.3 → **1.82 m/s** hurrying on hard, snow-free ground); minimum moving speed 1.4 × 0.15 = **0.21 m/s** walking, 0.35 × 0.15 = **0.05 m/s** crawling. **Examples:** fresh snow, flat, healthy, light pack → 1.4 × 0.65 = **0.91 m/s**; own trail → 1.4 × 0.853 = **1.19 m/s**; drift uphill 15°, Hypothermic (0.8), Exhausted (0.85), full pack (0.70) → product 0.16 → **0.23 m/s**; the worst stack 0.054 → floored → **0.21 m/s**.

**C2 — Grade along travel.** The `grade_deg` formula is defined as:

`grade_deg = degrees(atan(−dot(n_xz, d) / n_y))` with `n` = Terrain surface normal (unit), `n_xz` its horizontal part, `d` = unit horizontal direction of travel

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| n | Vector3 | unit | calculated (Terrain) | surface normal under the character |
| d | Vector2 | unit | calculated | direction of `move_vector` (or of velocity when no input) |

Guard: if `n_y < 0.2` (near-vertical) treat as impassable.

**Output Range:** −90° to +90° (positive uphill). **Example:** a 20° slope, walking straight up → **+20°**; across it → **0°**; at 45° to the fall line → **+14.4°**.

**C3 — Acceleration and turning.** The `velocity` update is defined as:

`t_accel = a_base + a_depth × min(1, effective_depth_m / 0.5) + a_load × carry_load_frac`
`velocity' = move_toward(velocity, target_velocity, target_speed_max / t_accel × dt)`
`turn_rate = turn_base × (1 − t_depth × min(1, effective_depth_m / 0.5))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| a_base | float | 0.1–0.6 | data file | seconds to full speed on hard ground (default 0.35) |
| a_depth | float | 0–0.8 | data file | extra seconds in deep snow (default 0.35) |
| a_load | float | 0–0.5 | data file | extra seconds with a full pack (default 0.2) |
| turn_base | float | 180–720 | data file | °/s on hard ground (default 360) |
| t_depth | float | 0–0.8 | data file | turn slow-down in deep snow (default 0.4) |
| dt | float | — | engine | physics frame time |

Deceleration uses 0.7 × `t_accel`.

**Output Range:** `t_accel` 0.35–0.9 s; turn rate 216–360 °/s. **Example:** fresh snow (0.35), half-full pack (0.5): 0.35 + 0.245 + 0.1 = **0.70 s** to full speed; turning **259 °/s**.

**C4 — Movement activity.** The `movement_activity` rule is defined as:

`speed < 0.1 → idle · hurrying or (hauling and moving) → heavy · is_wading → wade · else → walk`

**Variables:** `speed` (m/s, calculated), `hauling` (Inventory, `carry_load_frac > 0.7`), `is_wading` (Terrain TS6), hurry state (Rule 5). Crawling reports `heavy` (it is exhausting). **Output:** one of idle · walk · wade · heavy. **Example:** wading with a full pack → **heavy** (higher than wade).

**C5 — Cadence.** The `cadence` formula is defined as:

`steps_per_second = clamp(speed / stride_m, 0.6, 2.4)`, `stride_m = stride_base × (1 − s_depth × min(1, effective_depth_m / 0.5))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| stride_base | float | 0.5–1.0 | data file | default 0.75 m |
| s_depth | float | 0–0.6 | data file | shorter strides in deep snow (default 0.35) |

**Output Range:** 0.6–2.4 steps/s; each step emits one footfall. **Example:** 1.4 m/s on hard ground → **1.87 steps/s**; 0.91 m/s in fresh snow (stride 0.57 m) → **1.61 steps/s** with high knees.

**C6 — Visible sink.** The `root_offset` update is defined as:

`root_offset' = lerp(root_offset, −sink_m, 1 − exp(−dt / sink_smooth_s))`

**Variables:** `sink_m` (Terrain TS2, 0–0.45 m), `sink_smooth_s` (data file, default 0.15 s). **Output Range:** 0 to −0.45 m. **Example:** stepping from a trail (0.13) into a drift (0.45) settles within ~0.45 s (3 time constants).

**C7 — Action playback.** The `action_playback` rule is defined as:

`loops = max(1, round((duration_s − intro_s − outro_s) / effort_s))`; `speed = clamp(effort_s × loops / (duration_s − intro_s − outro_s), 0.85, 1.15)`

**Variables:** `duration_s` (Interaction, real seconds after all multipliers), `intro_s`, `effort_s`, `outro_s` (per clip, data). **Output:** a whole number of effort loops at 0.85–1.15× speed. **Example:** chop clip intro 0.4 s, effort 1.2 s, outro 0.4 s; a 5.6 s chop → 4 loops at 1.0×; Fraying + Cold stretch it to 8.2 s → 6 loops at 0.97× — more swings, not slower swings.

**C8 — Readability check (QA rule, not runtime).** `figure_height_px = screen_h × 1.75 × cos(pitch) / (2 × cam_dist × tan(fov/2))` must be ≥ 20 px at the default Camera; `cos(pitch)` is the foreshortening term from Camera CA3. Every Tier A clip passes a 5-tester verb test at that size.

*systems-designer + gameplay-programmer lenses applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: the ≈5 % worst-case stack — floored at 15 % (C1); Body's 0.40 Critical multiplier would double-count with the crawl base — excluded in Critical; near-vertical normals (`n_y → 0`) in C2 — treated as impassable; zero stride → infinite cadence — clamped; action slow-motion at high duration multipliers (up to ×2 from Morale × Body × Needs) — looped instead (C7). No feedback loops of its own; hurrying → heavy activity → faster energy drain → Exhausted → hurry disabled is the intended self-limit.*

## Edge Cases

- **If move input arrives during an action**: cancel the action (Interaction decides whether it can be cancelled and what is lost); the outro plays at 2× speed.
- **If the character is on a slope steeper than 35°** (pushed by collision): slide down along the fall line to walkable ground, no damage.
- **If Body enters Critical while walking**: drop to the crawl override within 0.8 s; movement continues at crawl speed.
- **If Needs collapses the survivor mid-action**: cancel the action, play collapse.
- **If hurry is held while not allowed**: no effect and no activity change; the Exhausted / cold / hauling posture shows why.
- **If `move_vector` is tiny (< 0.1 m/s target)**: stay idle; no footfalls.
- **If the floor applies** (product < 0.15): the walk cycle still plays at the floored speed with a struggling overlay, so slow is visible, not frozen.
- **If two terrain cells under the feet differ** (edge of a trail): use the cell under the leading foot for speed and each foot's own cell for its footfall.
- **If an animation clip is missing** (Tier B placeholder): fall back to the nearest Tier A clip (eat → kneel-work) and log a warning.
- **If the survivor falls through ice (MVP: Mishaps M4)**: switch to In water; control limited to moving toward the nearest shore edge.
- **If time is in a sleep skip**: no physics movement; the sleeping pose holds; footfalls never fire.
- **If a save is loaded**: restore position, facing and state; sink offset is set directly (no 0.45 s settle).

## Dependencies

**Upstream — hard:** Input & Action Map (`move_vector`, `move_hurry`); Terrain & Snow Surface (approved — surface queries, speed, sink).

**Upstream — soft:** Body Temperature (approved), Needs & Weight (approved), Item Database & Inventory (approved), Interaction (actions), Emotional Feedback (posture sets), Mishaps (events).

**Downstream:** Camera (hard: position and velocity), Interaction (`is_idle`, action callbacks), Terrain (footfalls), Body Temperature and Needs & Weight (movement activity), Ambient & Foley Audio (footfalls), Emotional Feedback (the body it animates), Save/Load.

**Bidirectional check:** the systems index lists Character → Input, Terrain (matches) and lists Camera and Interaction as dependents (matches). Body Temperature lists Character for activity in / `move_speed_mult` out — matches. Needs & Weight lists Character for activity and `move_speed_mult` — Needs' review recommended renaming its output to `needs_move_speed_mult`; this GDD uses that name (Needs should apply the rename). Inventory lists Character for load, speed and hauling — matches (the index row does not list Item DB: soft input, add when convenient). Terrain lists Character for footfalls and speed and left `grade_deg` derivation open — resolved here (C2) and the movement floor — resolved (C1).

## Visual/Audio Requirements

*art-director + technical-artist lenses applied, against `design/art/art-bible.md` §1, §3, §5, §8.*
- **Exaggerated, slow, heavy** (§5 "慢、重、费力；肢体动作要大"): wade lifts the knees high and swings the arms for balance; haul leans the torso forward 15–20°; chop raises the hatchet fully overhead; strike is a two-handed scrape with a visible spark shower.
- **Silhouette first** (§5): the dark coat and orange collar must stay readable in every pose; no pose may hide the collar for more than a beat.
- **Postures are state** (§1 大块面): cold-hunched, exhausted and grief postures must differ at 30 px from silhouette alone.
- **Snow contact**: puffs at each footfall in fresh snow and drifts; legs disappear below the surface line; drag marks when crawling.
- **Rig/mesh budget** (§8): ≤ 30 bones, one material, one LOD, ≤ 4,500 tris pending the owner's decision.
- **Audio**: footfall events carry surface type and sink so Foley scales crunch depth; cloth rustle on fast turns; heavy breathing layered by Body/Needs state.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:character-controller-and-animation` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Heavy, then ritual** (owner: "Heavy effortful 为主，然后加上时不时的 Slow ritual-like"): every step in fresh snow costs something visible; sitting at the fire, warming hands and watching the sunrise are slow, quiet, unhurried.
- **Responsive but weighty**: the walk starts on the next frame; reaching full speed takes most of a second in deep snow; stopping drifts a step.
- **Never stuck, never mysterious**: at the slowest the survivor still moves (0.21 m/s) and the body shows why (sunk to the thigh, hunched, laden).
- **Work looks like work**: a cold, tired chop is more swings, not a slower one.
- **Playtest target**: the owner no longer says "人物没有动作" or "行走起来没有质感" after the MVP.

## UI Requirements

- **None in play.** The body is the interface.
- **Debug overlay (dev only):** target and actual speed, each multiplier, grade, effective depth, sink, activity, cadence, animation layers active, current clip and loop count.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 3–4, C1–C2 | Terrain & Snow Surface (`design/gdd/terrain-and-snow-surface.md`) | `terrain_speed_mult` (needs `grade_deg`), sink, wading; open questions on floor and grade resolved here | approved — matches |
| Rules 3, 10 | Body Temperature (`design/gdd/body-temperature.md`) | `move_speed_mult` (0.40 Critical = crawl), shiver, stumble, crawl whitelist | approved — matches |
| Rules 3, 10 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `needs_move_speed_mult` (review rename), collapse, sleep | approved — rename pending in Needs |
| Rule 3, C4 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | `carry_speed_mult`, hauling flag | approved — matches |
| Rule 2, C1 | Input & Action Map (`design/gdd/input-and-action-map.md`) | `move_vector`, `move_hurry` | in review — matches |
| Rules 10–11 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | `play_action(id, duration_s)`, cancel rules, `is_idle` | not yet written — provisional |
| Rule 10 | Emotional Feedback (`design/gdd/emotional-feedback.md`) | posture-set selection | not yet written — provisional |
| Rule 13, Visual | `design/art/art-bible.md` §5, §8 | animation style, tri budget | exists |
| Summary | `prototypes/firebeforedark-concept/REPORT.md` | "人物没有动作", "行走起来没有质感"; procedural motion refuted | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / screenshot evidence.

**Core rules**
1. [A] **GIVEN** full move input on flat fresh snow, healthy, kit-only pack, **WHEN** speed settles, **THEN** speed = 0.91 ± 0.01 m/s.
2. [A] **GIVEN** the worst stack (product 0.054), **THEN** speed = 0.21 ± 0.01 m/s, never below.
3. [A] **GIVEN** Body Critical on flat fresh snow, **THEN** state Crawling and speed = 0.35 × max(0.15, 0.65 × needs × carry) — Body's 0.40 is not applied.
4. [A] **GIVEN** hurry held while hauling (load 0.8), **THEN** no speed change and activity stays `heavy` (from hauling), not hurry.
5. [A] **GIVEN** hurry held on a trail, healthy, light pack, **THEN** speed ×1.3 and activity `heavy`.
6. [A] **GIVEN** a 40° slope uphill, **WHEN** moving up, **THEN** blocked; along the contour, allowed.
7. [A] **GIVEN** walking on hard ground at 1.4 m/s for 10 s, **THEN** 18–19 footfalls reach Terrain, alternating feet.
8. [A] **GIVEN** Needs collapses the survivor during a chop, **THEN** the chop is cancelled and collapse plays.

**States**
9. [A] **GIVEN** Crawling, **WHEN** Body rises to Hypothermic, **THEN** a ≥ 0.8 s get-up plays before walking control returns.

**Formulas**
10. [A] C2: 20° slope straight up → +20 ± 0.1; across → 0 ± 0.1; 45° to the fall line → +14.4 ± 0.2; normal with n_y 0.1 → impassable.
11. [A] C3: fresh snow, half pack → t_accel 0.70 ± 0.01 s, turn 259 ± 1 °/s; hard ground, empty → 0.35 s, 360 °/s.
12. [A] C4: speed 0.05 → idle; wading with load 0.8 → heavy; wading light → wade; walking → walk.
13. [A] C5: 1.4 m/s hard ground → 1.87 ± 0.01 steps/s; 0.91 m/s in 0.35 effective depth → 1.61 ± 0.02.
14. [A] C6: from offset −0.13 to target −0.45, after 0.45 s the offset is within 0.02 of −0.45.
15. [A] C7: duration 5.6 s → 4 loops at 1.0×; 8.2 s → 6 loops at 0.97 ± 0.01×; playback speed never leaves 0.85–1.15.

**Cross-system & feel**
16. [A] **GIVEN** walking 1 game hour through untouched fresh snow, **THEN** Body receives `wade` and Terrain receives footfalls that turn the path into a trail after 3 passes (integration with TS6–TS7).
17. [P] **GIVEN** gameplay-camera clips (survivor ≈ 30 px) of each Tier A animation, **WHEN** shown to 5 testers, **THEN** ≥ 4 name the verb correctly for each clip (C8).
18. [P] **GIVEN** the owner plays the MVP first afternoon, **THEN** they do not report "人物没有动作" or "行走起来没有质感" (PIVOT check).
19. [P] **GIVEN** cold-hunched, exhausted and steady idles side by side at 30 px, **THEN** testers tell them apart from silhouette.

**Performance:** controller ≤ 0.1 ms per physics frame; animation (one skeleton, 3 layers + foot IK) ≤ 0.5 ms per frame on min-spec.

*QA gaps found and resolved: Critical double-count (3), hurry permission (4–5), footfall cadence (7), collapse interrupt (8), get-up gate (9), slow-motion guard (15). Feel lines moved to playtest criteria 17–19.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| **Rig spike:** can the Hunyuan3D survivor be rigged by a scripted Blender armature (auto-weights) to the humanoid profile, and do idle/walk/chop/strike/shiver read at 30 px? Fallback: Mixamo auto-rig + library clips retargeted, or manual Blender with the owner's help ("如果骨骼不好绑…告知我大概怎么做"). | technical-artist + owner | first technical task after the MVP GDDs | spike; report to the owner with options if it fails |
| Survivor triangle cap: 3,000 ideal vs ≤ 4,500 (art bible §8, owner decision pending). | owner | before the rig spike | decide; rig on the final mesh |
| Should hurrying exist at all (it slightly undercuts the heavy feel)? | owner | MVP playtest | data toggle |
| Should timed actions require E held (Input/Interaction)? Affects whether movement or release cancels. | game-designer | Interaction GDD | — |
| Jumping / climbing over logs: none in the MVP. Needed for the VS map? | level-designer | Map GDD | — |
