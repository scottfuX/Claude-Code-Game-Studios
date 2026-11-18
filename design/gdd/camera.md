# Camera

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / ux-designer / gameplay-programmer / art-director lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 苦中有美 · 冷是真的

## Summary

Camera is the show's camera: a high, far, third-person view looking down at about 50° on a small figure in a large white world. It follows the survivor smoothly, lets the player turn it in 45° steps and zoom within limits, keeps trees from hiding the figure, and — when other systems ask — slowly pulls back into the wide, quiet framing of 《荒野独居》 for ritual moments, collapse, death and tapping out. It is half of the concept's hook: "高位远镜头就是节目组的机位".

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Character Controller & Animation, Terrain & Snow Surface`

## Overview

The camera is a pivot that follows the survivor's position with a short lag and a small look-ahead in the direction of travel (Formula CA2), with the camera placed on a fixed pitch and a user-chosen yaw and distance from it (CA1). Defaults come from the fire-before-dark prototype the owner played: pitch 50°, distance 22 m, vertical field of view 30°. The player turns it with `camera_turn_left/right` (45° steps) and zooms with `camera_zoom_in/out` between 14 m and 40 m (Input & Action Map). Trees and props that come between the camera and the survivor fade (CA5); the camera never collides, because it is always high above the ground.

Other systems shape the shot through one interface: **framing requests** (CA4). Emotional Feedback asks for the slow pull-back on a fire ritual or sunrise (Morale §6), a slightly wider hold when loneliness dominates, a small ease-in on relief; Needs & Weight's collapse and sleep, Body Temperature's death and Tap-out's extraction get their own wide holds. One request is active at a time, by priority, and any player input brings the camera back from the purely cinematic ones within about a second — the camera never takes control away (Morale §11). Camera does not own lighting or post-processing (Time, Emotional Feedback), the diary's self-filming camera (Diary, VS), or the figure's readability on screen beyond the framing numbers (Character Controller C8, art bible §5).

## Detailed Design

### Core Rules

1. **Rig.** A pivot follows the survivor; the camera sits at `distance` from the pivot along a fixed `pitch` (default 50° down) and the current `yaw`, looking at the pivot (CA1). Vertical field of view `fov` 30°. Orthographic projection is not used.
2. **Follow.** The pivot moves toward the survivor's ground position plus a look-ahead in the direction of travel, with exponential smoothing (CA2). Vertical follow is smoothed separately and more slowly, so stepping into a drift (Character's sink) does not bob the camera.
3. **Turning.** `camera_turn_left/right` rotates the yaw by 45°, eased over 0.4 s; holding repeats every 0.4 s. There is no free mouse-look (Input: mouse is not used in gameplay). Movement input stays relative to the camera's current yaw.
4. **Zoom.** `camera_zoom_in/out` changes the distance by 3 m per step between `d_min` 14 m and `d_max` 40 m, eased over 0.25 s. The chosen distance persists through the run and is saved with settings (Alpha).
5. **Framing requests.** Any system may call `request_framing(id, distance_mult, pitch_offset_deg, blend_in_s, blend_out_s, priority, cinematic)` and later `release_framing(id)`. The highest-priority active request applies; ties go to the newest. Requests marked `cinematic` are released automatically by any move or action input, with `blend_out_s` capped at 1.0 s.
6. **Standard framings** (data table; requester in brackets):

   | id | distance_mult | pitch_offset | blend in / out | priority | cinematic | Requester |
   |---|---|---|---|---|---|---|
   | ritual_wide (fire ritual, sunrise) | 1.4 | −10° (lower, more horizon) | 4.0 s / 1.0 s | 2 | yes | Emotional Feedback (Morale §6) |
   | lonely_hold (L dominant) | 1.15 | −5° | 6.0 s / 3.0 s | 1 | no | Emotional Feedback |
   | relief_ease (strain −5 or more) | 0.95 | 0 | 1.5 s / 2.0 s | 1 | no | Emotional Feedback |
   | sleep_wide (chosen sleep, collapse) | 1.3 | −5° | 3.0 s / 1.0 s | 3 | no | Needs & Weight |
   | end_rise (death, evacuation) | 2.5 | +15° (higher, looking down) | 8.0 s / — | 5 | no | Body Temperature / Tap-out & Run Results |
   | extraction_aerial (tap-out, VS) | 4.0 | +20° | 10.0 s / — | 5 | no | Tap-out & Run Results |

   Framings scale the player's chosen distance, so a zoomed-in player still gets a relative pull-back.
7. **Occlusion.** Scenery between the camera and the survivor (trees, rocks, the shelter) fades to `occluder_alpha` (30 %) using a dithered fade, never popping (CA5). The survivor itself is never faded. Terrain cannot occlude at these pitches; if a ridge would (steep slope below the camera), the pivot height is raised until the line of sight is clear.
8. **Ground clearance.** The camera stays at least `clearance_m` (3 m) above the terrain under it.
9. **Bounds.** The pivot is clamped to the map's playable area (Map & Resource Distribution) so the camera never looks past the world's edge.
10. **Readability.** At the default framing the survivor must be at least `min_figure_px` (20 px) tall at 1280 × 720 — the art bible §5 lower bound — and at `d_max` it must stay above that bound too (CA3).
11. **Never takes control.** Camera never moves the survivor, never locks input, and never cuts away during play; cuts happen only on screens (diary, results) owned by other systems.
12. **Pause.** While paused, the camera freezes; menus overlay the frozen frame.

### States and Transitions

| State | Enter | Leave | Behaviour |
|---|---|---|---|
| Follow | default | a framing request with priority > 0 | CA1–CA2 with the player's yaw and distance |
| Framed | an active framing request | the request is released (or a cinematic one is broken by input) | CA4 blend toward the framing; follow continues underneath |
| Turning / Zooming | a turn or zoom input (in Follow or a non-cinematic Framed state) | ease finished | eased yaw or distance change; framing multipliers still apply |
| End | `end_rise` or `extraction_aerial` | run ends (screen takes over) | input ignored by Camera; slow rise |

A turn or zoom input during a cinematic framing first releases it, then applies.

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Character Controller & Animation (approved) | in | survivor position, ground height, velocity, facing | Character |
| Terrain & Snow Surface (approved) | in | terrain height for clearance and ridge checks | Terrain |
| Input & Action Map | in | `camera_turn_left/right`, `camera_zoom_in/out`; any move/action input (breaks cinematic framings) | Input |
| Emotional Feedback | in | `request_framing` / `release_framing` (ritual, lonely, relief) | Emotional Feedback |
| Needs & Weight (approved) | in | sleep / collapse → `sleep_wide` | Needs (event) / Camera (framing) |
| Body Temperature (approved) | in | `body_died` → `end_rise` | Body |
| Tap-out & Run Results (VS) | in | extraction → `extraction_aerial` | Tap-out |
| Map & Resource Distribution | in | playable bounds | Map |
| Interaction, Character | out | camera yaw (movement is camera-relative) | Camera |
| HUD / world-space prompts | out | camera transform for screen projection | Camera |
| Self-Filmed Diary (VS) | — | Diary switches to its own camera; Camera resumes Follow afterwards | Diary |
| Save/Load & Settings (Alpha) | out | chosen distance and yaw | Camera |

## Formulas

**CA1 — Camera placement.** The `camera_position` formula is defined as:

`camera_position = pivot + R_y(yaw) × (0, sin(pitch_eff) × d_eff, cos(pitch_eff) × d_eff)`; the camera looks at `pivot`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pitch | float | 35–70° | data file | default 50° |
| pitch_eff | float | 25–80° | calculated (CA4) | pitch + framing offset |
| d_user | float | 14–40 m | player (zoom) | default 22 m |
| d_eff | float | 13–160 m | calculated (CA4) | distance after framing |
| yaw | float | 0–360° | player (turn) | 45° steps |
| fov | float | 20–50° | data file | vertical, default 30° |

**Output Range:** camera height above the pivot `sin(pitch_eff) × d_eff`. **Example:** defaults → height 16.9 m, horizontal offset 14.1 m.

**CA2 — Follow.** The `pivot` update is defined as:

`target = survivor_ground_pos + dir × min(ahead_max_m, speed × ahead_s)`
`pivot_xz' = lerp(pivot_xz, target_xz, 1 − exp(−dt / lag_s))`, `pivot_y' = lerp(pivot_y, target_y, 1 − exp(−dt / lag_y_s))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| lag_s | float | 0.05–1.0 | data file | horizontal lag (default 0.35 s) |
| lag_y_s | float | 0.1–2.0 | data file | vertical lag (default 0.8 s) |
| ahead_s | float | 0–1.5 | data file | seconds of look-ahead (default 0.8) |
| ahead_max_m | float | 0–4 | data file | default 2.0 m |
| speed, dir | float, Vector3 | — | calculated (Character) | survivor velocity |

**Output Range:** pivot lags the survivor by ≤ ~0.5 m while walking and leads by ≤ 2 m. **Example:** walking a trail at 1.19 m/s → look-ahead **0.95 m**; hurrying at 1.82 m/s → **1.46 m**.

**CA3 — Figure height on screen (readability check).** The `figure_px` formula is defined as:

`figure_px = screen_h × figure_h × cos(pitch_eff) / (2 × d_eff × tan(fov / 2))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| screen_h | int | 720–2160 | platform | vertical resolution |
| figure_h | float | — | constant | 1.75 m (Character capsule) |
| cos(pitch_eff) | float | — | calculated | foreshortening of an upright figure seen from above |

**Output Range:** at 1280 × 720 — **69 px** at the default (22 m), **108 px** at 14 m, **38 px** at 40 m, **32 px** in `ritual_wide` from 40 m (56 m, pitch 40°: 720 × 1.75 × 0.766 / 30.0). All ≥ 20 px. At 1080p multiply by 1.5. **Note:** the art bible §5 says the figure is "约 20–40 像素高"; the owner-tested prototype camera gives ≈ 69 px at 720p — the art bible line describes the far end of the zoom range. Character Controller's C8 now includes the `cos(pitch)` term (fixed 2026-11-17) and matches CA3.

**CA4 — Framing blend.** The `framing` formula is defined as:

`d_eff = d_user × lerp(1, distance_mult, w)`, `pitch_eff = pitch + w × pitch_offset_deg`, `w` eased 0 → 1 over `blend_in_s` (smoothstep) and 1 → 0 over `blend_out_s`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| distance_mult | float | 0.8–4.0 | data file (framing table) | |
| pitch_offset_deg | float | −15 – +25 | data file | |
| blend_in_s / blend_out_s | float | 0.2–12 | data file | cinematic `blend_out_s` capped at 1.0 |
| w | float | 0–1 | calculated | blend weight of the active framing |

When the active framing changes, the new one blends from the current `d_eff`/`pitch_eff`, never from the defaults (no snaps).

**Output Range:** `d_eff` 11.2–160 m; `pitch_eff` 35–70° plus offset. **Example:** fire ritual at 22 m → 30.8 m, pitch 40°, over 4 s; the player presses W → back to 22 m / 50° within 1 s.

**CA5 — Occluder fade.** The `occluder_alpha` rule is defined as:

an object intersecting the capsule from the camera to the survivor's chest (radius `occ_radius_m`, default 1.0 m) fades to `occluder_alpha` (default 0.3) over `occ_fade_s` (0.25 s) and back over 0.5 s after it leaves the capsule

**Output Range:** opacity 0.3–1.0 (dithered). **Example:** walking behind a pine cluster: the two pines in the line of sight fade within 0.25 s; the rest of the cluster stays solid.

*systems-designer + gameplay-programmer lenses applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: `lag_s = 0` → instant snap (allowed but jittery; min 0.05); `fov` → 0 or 180 divides by zero in CA3 — bounded 20–50°; framing switch snapping — blends from current values; combined pull-backs (ritual from max zoom) shrinking the figure below the readability floor — checked (32 px ≥ 20); pitch + offset beyond 80° making the figure vanish under foreshortening — `pitch_eff` clamped 25–80°. No feedback loops.*

## Edge Cases

- **If two framing requests have the same priority**: the newest wins; releasing it falls back to the older one, blending from current values.
- **If a cinematic framing is active and the player turns or zooms**: release the framing, then apply the turn/zoom.
- **If a non-cinematic framing (sleep_wide) is active and the player zooms**: zoom applies to `d_user`; the framing multiplier stays.
- **If the survivor stands right next to a tall tree between them and the camera**: the tree fades; if many objects fade at once (dense forest), the cap is 12 faded objects, nearest to the line first.
- **If terrain under the camera rises above `pivot + clearance`** (camera over a hill behind the player): raise the camera height along the pitch line until clearance holds; do not change pitch.
- **If the pivot would leave the map bounds**: clamp the pivot; the survivor may move off-centre near the edge.
- **If the survivor falls through ice (VS)**: Follow continues; the pivot's vertical lag prevents a sudden drop.
- **If the game is paused mid-blend**: blends freeze and resume on unpause.
- **If the window resolution changes**: nothing changes in world space; CA3 is re-checked only by QA.
- **If a framing request names an unknown id**: ignore it and log a warning.
- **If `end_rise` starts while a cinematic framing is active**: `end_rise` (priority 5) wins and blends from the current shot.

## Dependencies

**Upstream — hard:** Character Controller & Animation (approved: position, ground height, velocity); Terrain & Snow Surface (approved: heights for clearance).

**Upstream — soft:** Input & Action Map (turn/zoom; any input breaks cinematic framings), Emotional Feedback (framings), Needs & Weight, Body Temperature, Tap-out & Run Results (event framings), Map & Resource Distribution (bounds).

**Downstream:** Character and Interaction (camera-relative movement and targeting), HUD (world-space prompts), Emotional Feedback (its framings take effect here), Save/Load & Settings.

**Bidirectional check:** the systems index lists Camera → Character, Terrain (matches). Character lists Camera as a hard downstream (matches). Input lists Camera for turn/zoom and left "free turning and zoom" open — resolved here (45° steps, 14–40 m). Morale's Visual/Audio table ("camera slowly pulls back to a wide", "camera eases closer by a few percent", "camera holds wider") is implemented by `ritual_wide`, `relief_ease` and `lonely_hold` (matches). Needs' "camera holds wide (the show's framing)" on collapse → `sleep_wide` (matches). Gap: Camera's index row does not list Input — soft; add when convenient.

## Visual/Audio Requirements

*art-director lens applied (the camera is the show's framing), against `design/art/art-bible.md` §1, §2, §5 and the B 站 reference.*
- **Composition** (§1 大块面, reference BV1Pwbi6SE3i): the survivor sits slightly below centre with more world above (more snow, more horizon in wide framings); long blue shadows cross the frame diagonally at the day baseline (sun azimuth from Time).
- **Wide framings are quiet:** `ritual_wide` and `lonely_hold` show more empty snow (art bible §6 "空地留大片空白雪地（孤独感）").
- **End shots** follow the mood table (§2): death — the shot rises slowly as the image fades to snow white; tap-out — the aerial pull-away with dusk-warm light and a distant point of fire.
- **No camera shake** in normal play (a far, steady observer); the only motion is follow, turn, zoom and framing blends.
- **Audio:** none from the camera; distance-based mix (closer = more Foley) is Ambient & Foley's choice using `d_eff`.

## Game Feel

- **The steady observer.** The camera should feel like a patient operator on a far hill: smooth, unhurried, never jittery. No snaps outside screen cuts.
- **You always find yourself.** The survivor is never hidden for more than 0.25 s; never smaller than 20 px at 720p.
- **Turning helps, never fights.** A 45° step is quick (0.4 s) and predictable; movement stays camera-relative.
- **The pull-back is earned.** The wide, slow ritual shot only happens when the player chose to stop — and any input brings them back within a second.

## UI Requirements

- **None in play.** Zoom level and yaw are not displayed.
- **Settings (Alpha):** default zoom, turn-step size (45° / 90°), "reduce camera motion" (disables cinematic framings except end shots).
- **Debug overlay (dev only):** yaw, pitch_eff, d_eff, active framing and weight, faded occluders, figure_px estimate.

> **📌 UX Flag — Camera**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 1–2, CA2–CA3 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | position, velocity, 1.75 m figure; C8 readability formula missing `cos(pitch)` | approved — flag for its next revision |
| Rule 8 | Terrain & Snow Surface (`design/gdd/terrain-and-snow-surface.md`) | heights | approved — matches |
| Rules 3–5 | Input & Action Map (`design/gdd/input-and-action-map.md`) | turn/zoom actions; input breaks cinematic framings | in review — matches |
| Rule 6 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | ritual pull-back, lonely hold, relief ease (Visual/Audio table) | in review — matches |
| Rule 6 | Needs & Weight (`design/gdd/needs-and-weight.md`) | collapse/sleep wide hold | approved — matches |
| Rule 6 | Body Temperature (`design/gdd/body-temperature.md`) | `body_died` | approved — matches |
| Rule 6 | Emotional Feedback (`design/gdd/emotional-feedback.md`) | framing requests | not yet written — provisional |
| Rule 1 | `prototypes/firebeforedark-concept/main.gd` | pitch 50°, distance 22 m, fov 30° (owner-tested) | exists |
| Rule 10, CA3 | `design/art/art-bible.md` §5 | "约 20–40 像素高" — reconciled in CA3 note | exists |
| Summary | `design/gdd/game-concept.md` | "高位远镜头就是节目组的机位" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / screenshot evidence.

**Core rules**
1. [A] **GIVEN** defaults, **THEN** pitch 50°, distance 22 m, fov 30°, camera 16.85 ± 0.05 m above the pivot.
2. [A] **GIVEN** `camera_turn_right` pressed once, **THEN** yaw +45° reached in 0.4 ± 0.05 s; held for 1.0 s → steps fire at 0, 0.4 and 0.8 s → +135°.
3. [A] **GIVEN** zoom-out pressed 10 times from 22 m, **THEN** distance 40 m (clamped); zoom-in 10 times → 14 m.
4. [A] **GIVEN** a `ritual_wide` request and the player presses W after 2 s, **THEN** the framing is released and the camera is back to the user framing within 1.0 s.
5. [A] **GIVEN** `lonely_hold` (priority 1) then `ritual_wide` (priority 2), **THEN** ritual applies; releasing it blends back to lonely_hold from the current values (no snap: no frame-to-frame jump > 0.5 m).
6. [A] **GIVEN** a tree on the camera–survivor line, **THEN** it reaches 0.3 opacity within 0.25 s and the survivor is never faded.
7. [A] **GIVEN** terrain under the camera 2 m below it, **THEN** the camera rises until 3 m clearance; pitch unchanged.
8. [A] **GIVEN** the survivor at the map edge, **THEN** the pivot is clamped inside the bounds.

**States**
9. [A] **GIVEN** `body_died`, **THEN** `end_rise` applies over 8 s and turn/zoom input is ignored.

**Formulas**
10. [A] CA2: survivor at 1.19 m/s → look-ahead 0.95 ± 0.01 m; 3.0 m/s (test) → capped 2.0.
11. [A] CA3 at 1280 × 720: 22 m → 69 ± 1 px; 14 m → 108 ± 1; 40 m → 38 ± 1; ritual_wide from 40 m → 32 ± 1.
12. [A] CA4: ritual_wide at 22 m → d_eff 30.8 ± 0.1 m and pitch_eff 40 ± 0.1° after 4 s.
13. [A] Data with `fov` outside 20–50° or `pitch_eff` beyond 25–80° is clamped and logged.

**Cross-system & feel**
14. [A] **GIVEN** Morale's fire ritual fires (Emotional Feedback requests `ritual_wide`), **THEN** the camera pulls back over 4 s (integration).
15. [P] **GIVEN** a day screenshot at the default framing, **WHEN** shown to testers, **THEN** they identify the survivor within 2 seconds and describe the shot as "far, quiet, wide".
16. [P] **GIVEN** 10 minutes of play with turning, **THEN** testers never report losing the survivor behind trees or being disoriented by a turn.

**Performance:** camera update ≤ 0.05 ms per frame; occluder checks ≤ 0.1 ms per frame (capsule test against ≤ 12 candidates).

*QA gaps found and resolved: cinematic release by input (4), framing priority and no-snap fallback (5), survivor never faded (6), clearance without pitch change (7), end-shot input lock (9). Feel lines moved to playtest criteria 15–16.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Art bible says the figure is "约 20–40 像素"; the owner-tested camera gives ≈ 69 px at 720p (≈ 103 px at 1080p). Is the default distance right, or should it start further out? | owner + art-director | MVP playtest | try 22 m vs 32 m defaults |
| 45° steps or free (held) rotation? | owner | MVP playtest | data toggle |
| Should there be a "photo mode" / free camera for screenshots (the show's beauty)? | game-designer | Full Vision | — |
| Does the diary's self-filmed camera (VS) cut or blend? | narrative-director | Diary GDD | Camera supports both |
| Revise Character Controller C8 to include `cos(pitch)`. | game-designer | Character's next revision | — |
