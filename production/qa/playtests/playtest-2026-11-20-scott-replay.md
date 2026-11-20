# Playtest Report: Scott's First-Night Replay

## Session Info

- **Date / tester:** 2026-11-20; Scott, returning player.
- **Build / speed:** main `fce1b66`, after PR #19; production `src/`, default speed.
- **Method:** relayed player feedback, followed by agent code inspection and staged GUI regression checks. Scott's platform, session duration and exact flicker timing were not supplied.

## Test Focus

Replay the feel-pass build; record snow contact, visual stability and animation context. No snow/animation implementation in this follow-up; scope was subsequently expanded to fix the S2 flicker.

## First Impressions (First 5 minutes)

Timing within the session was not recorded. The three supplied English translations are preserved below. **Original Chinese was not supplied; the Chinese column is a back-translation, not a verbatim quote from Scott.**

| 中文回译（非原话） | English supplied translation |
|---|---|
| 雪没有厚度，踩上去没有陷进去或凹凸不平的感觉。 | the snow has no depth, there's no sense of sinking in or unevenness when stepping |
| 屏幕有时候会闪烁。 | the screen flickers at times |
| 现在动画多了一些，但不符合当时的情境，看起来很奇怪。 | there are more animations now, but they don't fit the situation and feel strange |

## Gameplay Flow

- **What worked:** Scott noticed more animation; no further positive or loop-completion evidence supplied.
- **Pain points / confusion:** flat snow contact, intermittent flicker, and situation-inappropriate animation.
- **Moments of delight:** not recorded.

## Bugs Encountered

| ID | Defect / expected behavior | Severity / priority | Status / evidence |
|---|---|---|---|
| B1 | Intermittent whole-scene brightness flashes; lighting should remain stable between clock ticks and transition without a boundary pop. | **S2-High / P1, top priority** | **Fixed in this branch**, agent GUI/logic regression checked; Scott recheck pending. Reproduced in the production scene, OpenGL3 on DISPLAY=:0, with a lit fire and camera turn/zoom across 17:11–17:17. |

**Reproduced cause:** [RunCoordinator._update_lighting()](../../../src/run/run_coordinator.gd) runs each process frame and previously wrote the background colour into fog. It then called [WinterAtmosphere.set_daylight()](../../../src/presentation/winter_atmosphere.gd), which overwrote fog with the sky horizon colour only when daylight changed. Its cache returned on subsequent frames: each dusk minute produced one bright fog frame, then a dark reversion. At minute 1031, consecutive frames logged fog RGB `(0.3732, 0.4244, 0.5066)` → `(0.0799, 0.1061, 0.1708)`, with identical directional-light energy/rotation/shadow state. Freezing the fire visual and camera did not remove the flash, arguing against fire modulation or camera motion as its cause. This demonstrates a reachable matching defect, not proof of the exact frames Scott saw.

**Boundary contributor / fix:** the previous single-light override also jumped from energy 0.01889 to 0.28 at 17:15, abruptly changing colour, direction and shadow enablement. The coordinator now solely owns continuous sun/moon blending using the existing endpoints; atmosphere solely owns fog colour. Shadows fade in opacity, retaining the enabled shadow path: GUI comparison found toggling it still produced a separate OpenGL3 boundary pop after the other fixes. Fire modulation, particles, footprints and camera clipping were not changed; no engine-internal cause for that shadow-path difference is asserted.

**Visual evidence (local, not committed):** `/home/ubuntu/notes/replay-flicker-before-sequence.png` and `/home/ubuntu/notes/replay-flicker-after-stable-shadow-sequence.png`; 42 consecutive frames per run, with individual `-00.png` through `-41.png` siblings. Both contact sheets were viewed, plus full-size adjacent frames. The notes-only fixture manually steps the clock once per six frames for a repeatable comparison; this is a staged GUI check, not a default-speed human playthrough. Isolation frames/log: `/home/ubuntu/notes/replay-flicker-isolate-*`.

## Feature-Specific Feedback

- **Snow — polish backlog:** [WorldMap](../../../src/core/world_map.gd) builds a flat PlaneMesh and flat collision. [FootprintPool](../../../src/presentation/footprint_pool.gd) places pooled flat marks just above it; the [shader](../../../src/presentation/spatial_snow_footprint.gdshader) colours their surface without displacement. No terrain compaction, sinking or contact-driven height variation is present. Likely explanation for missing depth; defer to the later art/snow pass.
- **Animation — polish backlog:** [SurvivorVisual](../../../src/presentation/survivor_visual.gd) reuses rig-spike clips with broad action-to-chop/strike/idle selection; [SurvivorPose](../../../src/presentation/survivor_pose.gd) adds crouch, shiver, warming and fatigue layers. Generic clips plus simultaneous procedural layers can mismatch the situation. Scott did not identify particular actions, so the offending combination is unverified; defer contextual clips/blends to the later art/animation pass.

## Quantitative Data

No session length, deaths, frame rate or action-specific counts were supplied. Regression coverage adds fog persistence across repeated frames and sun/moon energy, colour, rotation and shadow continuity across twilight boundaries.

## Overall Assessment

Scott allows difficult fine-detail work to be recorded and deferred. Snow depth and animation fit remain backlog notes, unchanged in code. The reproduced flicker is fixed and agent-checked; no new full-loop or Scott validation is claimed.

## Top 3 Priorities from this session

1. **Bug S2 / P1:** flicker — fixed here; Scott should recheck on his GPU.
2. **Polish backlog:** snow depth/sinking/uneven foot contact — later art/snow pass.
3. **Polish backlog:** scene-fitting animations — later art/animation pass.

## Phase 3: Action Routing

- **Bug:** B1 fixed here, not deferred with the polish.
- **Polish:** snow and animation notes stay on the backlog for the next feel/art-animation round; no implementation requested.
- **Design / balance:** no changes requested.

CD-PLAYTEST skipped — Lean mode.
