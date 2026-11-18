# Ambient & Foley Audio

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / audio-director / sound-designer lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 苦中有美 · 冷是真的

## Summary

Ambient & Foley Audio is the sound of being alone in the snow: the wind that changes with where you stand, the crunch and plunge of every footstep, the fire's crackle, your own breathing and chattering teeth, the thock of the hatchet and the hiss of damp tinder. It is the loudest signal of solitude in a game with almost no music, and it carries information the player needs — how deep the snow is, how strong the wind is, whether the wood is dry, whether the fire is still alive — without any HUD.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Terrain & Snow Surface, Character Controller & Animation, Fire`

## Overview

The system plays three kinds of sound on four buses (Ambience, Foley, Music — owned by Emotional Feedback — and UI). **Ambience beds** follow the zone under the survivor (Map) and the time of day (Time), crossfading over dusk and dawn, with the wind layer driven by Thermal's `wind_eff` (Formula AF2) and Emotional Feedback's emphasis and ducking (its EF6). **Foley** is event-driven: a footstep per Character footfall chosen by Terrain's surface type and scaled by sink depth (AF1), work sounds per Interaction effort beat (chop, scrape, strike, tear), Mishaps cause sounds (hiss, gust, clatter), the fire's continuous crackle scaled by its size (AF3), and the body's breath layers from Body Temperature and Needs & Weight (AF4). The listener sits at the survivor, not the far camera, so the small figure still sounds close (AF5).

The goal is the show's sound: long stretches of wind and silence, a few precise, physical sounds, never a game "alert". This system owns no gameplay state; it reads Terrain, Character, Fire, Thermal, Time, Map, Body, Needs, Mishaps, Interaction and Emotional Feedback.

## Detailed Design

### Core Rules

1. **Buses.** Master → Ambience, Foley, Music (Emotional Feedback), UI. Ducking and wind emphasis from Emotional Feedback apply on Ambience.
2. **Listener at the survivor.** The 3D listener is placed at the survivor's head with the camera's orientation; Foley is mixed slightly louder when the camera is closer (AF5).
3. **Ambience beds** by zone (Map) and phase (Time), crossfaded over 5 s when the zone changes and over Dusk/Dawn when the phase changes:

   | Zone | Day bed | Night bed |
   |---|---|---|
   | open snow | open wind, distant birds (rare) | open wind, far ice creaks |
   | forest | soft wind in pines, branch creaks, occasional snow fall from boughs | creaks, owl (rare, VS) |
   | lake | flat wind, ice tension pings | louder ice booms (rare), wind |
   | lee | low wind, close quiet | near silence, wind beyond |
   | hill crest / scoured | strongest wind | strongest wind |
4. **Wind** is its own layer above the bed: gain from `wind_eff` at the survivor (AF2) plus Emotional Feedback's +2 dB per worsening state; gusts are random swells (±3 dB over 2–6 s) whose rate rises with wind.
5. **Footsteps** (one per Character footfall) by Terrain surface type: fresh snow (deep crunch), forest snow (soft crunch), drift (muffled plunge), trail (short packed squeak), lake ice (hollow squeak), rock (scrape); volume and low-frequency weight scale with sink depth (AF1); ±5 % pitch and 3 variants per type to avoid repetition. Crawling plays drag sounds.
6. **Work sounds** play on each effort beat of Interaction actions (Character's effort loop): hatchet thock, stick snap (dry: sharp crack; damp: dull crack — Gathering's wetness), bark tear, stone scrape, snow scrape (clear_snow), ferro-rod scrape with sparks, blowing breath, logs set down.
7. **Mishaps cause sounds** play before the outcome: damp → hiss; wind → gust swell and spark scatter; cold hands → rod clatter; fatigue → heavy exhale; poor tinder → fizzle; fumble → dull miss; ice → sharp crack then plunge (the sharpest sound in the game).
8. **Fire** is a continuous 3D source: crackle and roar scale with Fire's size factor `s` (AF3); damp burning adds pops and a steam hiss (Fire's `w_burn`); smother is a hiss burst; embers are a faint tick; out is silence.
9. **Body sounds** (AF4): breathing rate and weight from Needs' energy and the work intensity; teeth chatter and shaky breath in Body Chilled/Cold; the absence of chatter in Hypothermic (silence is the warning, Body Temperature); stomach growl about once per game hour while Hungry.
10. **No alert sounds.** No stingers for danger, no UI beeps in play; confirmations are soft paper/ink UI sounds only in menus.
11. **Voice budget.** ≤ 24 simultaneous voices; priority: Mishaps cause > footsteps > work > fire > body > ambience details.

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Ambience bed | zone × phase | zone change → 5 s crossfade; phase change → crossfade across Dusk/Dawn |
| Fire source | silent · embers · crackle(s) | follows Fire's stage |
| Body layer | calm · working · chattering · silent-cold | follows Body stage and Needs/work |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Terrain & Snow Surface (approved) | in | surface type, sink depth per footfall | Terrain |
| Character Controller & Animation (approved) | in | footfalls, effort beats, crawl | Character |
| Fire (approved) | in | stage, size factor `s`, `w_burn`, smother/out events | Fire |
| Thermal Environment (approved) | in | `wind_eff` at the survivor | Thermal |
| Time & Day Cycle (approved) | in | phase | Time |
| Map & Resource Distribution (approved) | in | zone under the survivor | Map |
| Body Temperature, Needs & Weight (approved) | in | stage, shivering, energy stage, hunger | Body / Needs |
| Mishaps & Failure (approved) | in | cause per outcome | Mishaps |
| Interaction & Timed Actions (approved) | in | action id per effort beat | Interaction |
| Gathering (approved) | in | produce wetness (dry vs damp snap) | Gathering |
| Emotional Feedback (approved) | in | wind emphasis, ambience ducking | Emotional Feedback |
| Camera (approved) | in | `d_eff` for the Foley mix | Camera |

## Formulas

**AF1 — Footstep loudness.** The `footstep_db` formula is defined as:

`footstep_db = step_base_db[type] + k_sink_db × (sink_m / 0.45)` (clamped to ≤ 0 dB)

**Variables:** `step_base_db` (data file: fresh −14, forest −16, drift −12, trail −18, ice −15, rock −13), `k_sink_db` (data file, default 6), `sink_m` (Terrain TS2, 0–0.45). **Output Range:** −18 to −6 dB. **Examples:** fresh snow at sink 0.315 → −14 + 4.2 = **−9.8 dB**; trail at 0.13 → **−16.3 dB**; drift at 0.45 → **−6 dB**.

**AF2 — Wind gain.** The `wind_db` formula is defined as:

`wind_db = clamp(wind_ref_db + 20 × log10(max(w_floor, wind_eff) / w_ref), wind_min_db, 0) + ef_step_db`

**Variables:** `wind_ref_db` −12, `w_ref` 3 m/s, `w_floor` 0.3, `wind_min_db` −36 (data file); `ef_step_db` from Emotional Feedback (0–6). **Output Range:** −36 to +6 dB. **Examples:** open snow (wind_eff 2.4) → **−13.9 dB**; forest (1.2) → **−20 dB**; lake (3.0) → **−12 dB**; lee (0.9) → **−22.5 dB**; storm 15 m/s (VS) → **0 dB**.

**AF3 — Fire loudness.** The `fire_db` formula is defined as:

`fire_db = Out ? −∞ : Embers ? −34 : fire_min_db + fire_span_db × s` (3D attenuation by distance on top)

**Variables:** `fire_min_db` −30, `fire_span_db` 24 (data file), `s` (Fire FI1). **Output Range:** −30 to −6 dB at the source. **Example:** F 120 (s 0.865) → **−9.2 dB**; kindling (s 0.35) → **−21.6 dB**.

**AF4 — Breath rate.** The `breaths_per_min` formula is defined as:

`breaths_per_min = 12 + 8 × work_level + 6 × (energy_stage ≥ Tired ? 1 : 0)`, `work_level` 0 idle · 0.5 light · 1 heavy; chatter on in Chilled/Cold, off in Hypothermic/Critical

**Output Range:** 12–26 breaths/min. **Example:** chopping while Tired → **26**; resting at the fire → **12**.

**AF5 — Foley distance mix.** The `foley_mix_db` formula is defined as:

`foley_mix_db = clamp(−0.15 × (d_eff − 22), −3, +3)`

**Output Range:** −3 to +3 dB. **Example:** zoomed to 14 m → **+1.2 dB**; at 40 m → **−2.7 dB**; ritual_wide (56 m) → **−3 dB** (capped — the wide shot sounds a little further away).

*audio-director + systems-designer lenses applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: `log10(0)` at zero wind — floored at 0.3 m/s; footstep clipping in drifts — clamped ≤ 0 dB; voice explosion when many footfalls and effort beats overlap — 24-voice cap with priorities; foley vanishing at wide framings — the listener stays at the survivor and AF5 caps at −3 dB. No feedback loops.*

## Edge Cases

- **If the survivor is asleep**: footsteps and work silent; body layer = slow sleep breathing; ambience continues (night bed); fire continues.
- **If time skips during sleep**: ambience does not accelerate; one-shot details are throttled to real time (no burst of 10 ice booms).
- **If two zones blend**: crossfade the beds by the same weights Thermal uses for the zone blend.
- **If the voice cap is reached**: drop the lowest-priority voice (an ambience detail), never a Mishaps cause sound.
- **If the game is paused**: all buses duck −12 dB; menu UI sounds play.
- **If a footfall happens on an unknown surface**: use fresh snow and log.
- **If death occurs**: Foley fades out over 3 s; the wind remains alone, then fades with the image (Emotional Feedback end shot).

## Dependencies

**Upstream — hard:** Terrain & Snow Surface, Character Controller & Animation, Fire (all approved).

**Upstream — soft:** Thermal, Time, Map, Body Temperature, Needs & Weight, Mishaps, Interaction, Gathering, Emotional Feedback, Camera (all approved).

**Downstream:** none (presentation leaf).

**Bidirectional check:** the systems index lists Ambient & Foley → Terrain, Character, Fire (matches). Terrain's footstep set (deep crunch, soft crunch, plunge, hollow squeak, scrape) is used (adds trail squeak); Fire's crackle/pop/hiss/silence (matches); Body's chatter and Hypothermic silence (matches); Mishaps' per-cause sounds (matches); Gathering's dry snap vs dull crack (matches); Emotional Feedback's wind +2 dB/state and −6 dB duck (matches); Map's zone ambience beds (matches).

## Visual/Audio Requirements

*audio-director + sound-designer lenses applied.*
- **Palette:** natural, close-miked, dry recordings; no synthetic stingers; long tails only on wind and ice.
- **Mix priority:** Mishaps causes and footsteps above everything; wind is the bed; music (Emotional Feedback) sits under ambience.
- **Loudness:** −16 LUFS integrated target for gameplay; nothing above −1 dBTP.
- **Asset list (MVP):** 6 footstep sets × 3 variants, 5 zone beds × day/night, wind loop + gusts, fire crackle/roar/pop/hiss/embers, 8 work sounds, 7 cause sounds, breath sets (calm, working, tired, chattering, sleeping), stomach growl, UI paper sounds.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:ambient-and-foley-audio` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **You hear where you are.** Eyes closed, a tester should tell lake from forest from open snow by the wind and the footsteps.
- **You hear the snow's depth.** Plunges in drifts, squeaks on your trail.
- **Silence means something.** When the chatter stops, or the fire goes quiet, it should land.
- **Close in a big world.** The tiny figure on screen still sounds right beside you.

## UI Requirements

- **None in play.** Volume sliders per bus (Master, Music, Ambience, Foley, UI) arrive with Settings (Alpha).
- **Debug overlay (dev only):** active bed, wind dB, voices used, last footstep type and dB.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 5, AF1 | Terrain & Snow Surface (`design/gdd/terrain-and-snow-surface.md`) | surface types, sink | approved — matches |
| Rules 5–6 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | footfalls, effort beats | approved — matches |
| Rule 8, AF3 | Fire (`design/gdd/fire.md`) | stage, `s`, `w_burn` | approved — matches |
| Rule 4, AF2 | Thermal Environment, Emotional Feedback | `wind_eff`; wind emphasis, ducking | approved — matches |
| Rule 3 | Map & Resource Distribution, Time & Day Cycle | zones, phases | approved — matches |
| Rule 9 | Body Temperature, Needs & Weight | chatter, Hypothermic silence, breath | approved — matches |
| Rule 7 | Mishaps & Failure | cause sounds | approved — matches |
| AF5 | Camera (`design/gdd/camera.md`) | `d_eff` | approved — matches |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

1. [A] **GIVEN** a footfall on fresh snow at sink 0.315, **THEN** a fresh-snow step plays at −9.8 ± 0.2 dB; on a trail at 0.13 → −16.3 ± 0.2; in a drift → −6.
2. [A] AF2: wind_eff 2.4 → −13.9 ± 0.1 dB; 1.2 → −20 ± 0.1; 0 → floored −32 ± 0.1 (log of 0.3/3); 15 → 0; with EF +4 → +4 added.
3. [A] AF3: F 120 → −9.2 ± 0.1 dB; Embers → −34; Out → silent.
4. [A] AF4: chopping while Tired → 26 breaths/min; Body Hypothermic → no chatter.
5. [A] AF5: d_eff 14 → +1.2; 40 → −2.7; 56 → −3.
6. [A] **GIVEN** a zone change from open snow to forest, **THEN** the beds crossfade over 5 ± 0.5 s.
7. [A] **GIVEN** 30 simultaneous sound requests, **THEN** ≤ 24 voices play and no Mishaps cause sound is dropped.
8. [A] **GIVEN** a Mishaps damp failure, **THEN** the hiss plays before the outcome beat (integration).
9. [A] **GIVEN** a sleep skip of 10 game hours, **THEN** one-shot ambience details play at real-time rates (no burst).
10. [P] **GIVEN** eyes-closed audio clips of lake, forest and open snow, **THEN** ≥ 4 of 5 testers identify each.
11. [P] **GIVEN** the owner's MVP session, **THEN** they report the snow "sounds deep" and walking has texture (playtest "行走起来没有质感").

**Performance:** audio thread ≤ 1 ms per frame on min-spec with 24 voices.

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Record field sounds vs licensed libraries for snow and ice? | audio-director + owner | before VS | budget decision |
| Rare wildlife sounds (owl, grouse) in the MVP or only with Wildlife (VS)? | sound-designer | VS | — |
| Reverb for the lake basin and forest (Godot 4.7 audio buses / reverb zones)? | sound-designer | ADR with the audio implementation | engine reference `modules/audio.md` |
