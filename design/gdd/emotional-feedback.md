# Emotional Feedback

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / art-director / technical-artist / audio-director lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 苦中有美 · 冷是真的

## Summary

Emotional Feedback is how the survivor's inner state becomes visible and audible without a single number: it picks the body language (how they stand, sit, breathe and react to a failure), asks the camera for the show's quiet wide shots, shifts the picture's cold colours toward grey as morale sinks and darkens its edges as the body freezes, and shapes a sparse score and the wind in the mix. It is the presentation layer for Morale & Mental State, Body Temperature and Needs & Weight, and the reason the player can say "he's falling apart" from the far camera alone.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Morale & Mental State, Body Temperature, Character Controller & Animation, Camera`

## Overview

Emotional Feedback reads states and events from Morale (mental state, dominant strain, strain spikes, ritual moments, second wind, tap-out offers), Body Temperature (stage, shivering), Needs & Weight (energy/hunger stages, collapse, sleep), Mishaps (failure causes) and Fire, and drives five output channels: **posture sets and beats** on Character's overlay layer (EF4, EF3), **framing requests** to the Camera (its standard table), **screen grade** — cold-colour desaturation and a freezing vignette through a Compositor post-effect (EF1–EF2), **adaptive music** — three sparse layers (EF5), and **ambience emphasis** — wind and silence (EF6). It implements, line by line, Morale's Visual/Audio table and the posture and vignette rules in Body Temperature and Needs & Weight.

The design principle is restraint: the world stays mostly quiet and beautiful (art bible: "整个世界是冷的，只有活下去的东西是暖的"); mood changes blend slowly (≥ 3 s), event beats are short (≤ 1.2 s) and never take control; warm colours are never desaturated, so the fire stays the warmest thing on screen whatever the survivor feels. Emotional Feedback owns no state of its own beyond blend weights and cooldowns — it never changes morale, temperature or needs.

## Detailed Design

### Core Rules

1. **Read-only.** Emotional Feedback only reads other systems and drives presentation. It never writes gameplay state.
2. **Posture set** (EF4) — chosen every second, highest-priority source wins:
   1. Body Temperature: Critical → crawl (Character override); Hypothermic → stumble-walk + no-shiver idle; Cold → hunched idle (hands in armpits), strong shiver; Chilled → arms-in idle, light shiver.
   2. Needs & Weight: Exhausted → swaying idle, dragging walk; Tired → hand-on-knee stops; Hungry/Empty → hand-to-stomach idle.
   3. Morale `dominant_strain` (only when state ≥ Strained): L → looks to the horizon; F → rubs hands / kicks snow; G → sits and stares when idle ≥ 10 s; H → hand-to-stomach; P → hugs self.
   4. Otherwise: steady idle.
   Shiver is additive and always applied when Body reports `is_shivering`.
3. **Beats** (EF3) — short reactions on events, layered over control, cancelled by the next input:

   | Event (source) | Beat (Character) | Audio |
   |---|---|---|
   | failure with F +5 or more (Morale `strain_spike`, Mishaps cause) | 0.6–1.2 s: kneel / head drop / frustrated gesture, chosen by action type; the Mishaps cause is shown first | quiet exhale |
   | loss with G +5 or more | stops and looks at what was lost | muted music sting |
   | relief (any strain −5 or more) | small upright beat | soft warm tone |
   | state improves | posture lifts over ≥ 3 s | the warm music layer returns |
   | state worsens | shoulders drop, slower turns | the warm layer thins out; wind slightly louder |
   | second wind | visible breath in, straightening | one held chord |
   | tap-out offer | the radio on the pack catches the light | faint radio static |
   | fire lit (Fire → Kindling flame) | hands out to the flame | first crackle foregrounded |

4. **Framings** — requests to the Camera's standard table: `ritual_wide` on Morale's fire ritual and sunrise; `lonely_hold` while dominant strain is L and state ≥ Strained and the survivor is idle outdoors; `relief_ease` on relief; `sleep_wide` when Needs `is_asleep`; `end_rise` on death; `extraction_aerial` on tap-out (VS).
5. **Screen grade** (EF1): cold colours (hues outside the warm band 15°–55°) lose saturation by Morale state; Grief dominant adds a little more. Warm colours — fire, tarp, collar, skin — are never desaturated. Blends over ≥ 3 s.
6. **Freezing vignette** (EF2): from Body Hypothermic, the screen edge darkens toward trunk_navy and desaturates (art bible §2 失温危险); Critical narrows it further. Morale's Breaking never adds a vignette (cold and despair stay distinguishable).
7. **Music** (EF5): the score is sparse and mostly silent (the show is ambience). Three layers: **warm** (a single acoustic instrument), **pad** (low, cold), **thin** (a high sustained line). Layer gains follow mental state and whether the survivor is at a burning fire; ritual moments do *not* start music — crackle and silence are foregrounded (Morale's table).
8. **Ambience emphasis** (EF6): wind gain rises one step per worsening state; when loneliness dominates, other ambience (birds, distant creaks) is ducked so the wind is alone.
9. **Cooldowns.** The same beat cannot repeat within 20 real seconds; at most one beat plays at a time (priority: death > loss > failure > second wind > relief > fire lit > tap-out offer); state-change posture blends are never cooldown-limited.
10. **Accessibility.** "Reduce camera motion" suppresses `ritual_wide`, `lonely_hold` and `relief_ease` (end shots remain); "Reduce screen effects" scales grade and vignette by 0.5; nothing is shown by colour alone (posture always carries the meaning). Settings arrive with Save/Load & Settings (Alpha); MVP uses defaults.
11. **Diary text (VS).** The nightly diary's mood words come from Morale's `dominant_strain`; Emotional Feedback supplies the word pools (localisation keys), Diary owns the page.

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Posture set | one of the Rule 2 sets | re-evaluated each second; changes blend over 0.8 s |
| Grade / vignette | weights 0–1 | eased toward targets over ≥ 3 s (vignette 1.5 s, it is urgent) |
| Music layers | gains 0–1 | eased over 4 s; stings and chords are one-shots |
| Beat | idle · playing | event → playing (≤ 1.2 s) → idle; input cancels |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Morale & Mental State | in | `mental_state`, `dominant_strain`, `strain_spike`, `state_changed`, ritual moments, second wind, `tap_out_offer` | Morale |
| Body Temperature (approved) | in | `stage`, `is_shivering`, `stage_changed`, `body_died` | Body |
| Needs & Weight (approved) | in | energy / fullness stages, collapse, `is_asleep` | Needs |
| Mishaps & Failure (approved) | in | outcome cause (shown before the beat) | Mishaps |
| Fire (approved) | in | stage changes (lit, smothered, out) | Fire |
| Character Controller & Animation (approved) | out | posture set, beats (overlay layer) | Character |
| Camera (approved) | out | `request_framing` / `release_framing` | Camera |
| Rendering (Compositor) | out | grade and vignette parameters | Emotional Feedback |
| Ambient & Foley Audio | out | wind emphasis, ducking | Ambient & Foley |
| Self-Filmed Diary (VS) | out | mood word pools | Emotional Feedback |
| Save/Load & Settings (Alpha) | in | accessibility toggles | Settings |

Implementation note → becomes an ADR: grade and vignette as a Godot 4.7 `Compositor` + `CompositorEffect` (engine reference: Compositor is a Resource assigned to the WorldEnvironment/Camera, not a node).

## Formulas

**EF1 — Cold-colour saturation.** The `grade_cold_saturation` formula is defined as:

`sat_offset = −(sat_step × state_index + (dominant == G and state_index ≥ 1 ? grief_extra : 0)) × fx_scale`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| state_index | int | 0–3 | calculated (Morale) | Steady 0 · Strained 1 · Fraying 2 · Breaking 3 |
| sat_step | float | 0–0.1 | data file | default 0.05 |
| grief_extra | float | 0–0.1 | data file | default 0.05 |
| fx_scale | float | 0.5 / 1.0 | settings | 0.5 with "reduce screen effects" |

**Output Range:** 0 to −0.20 saturation on cold hues only. **Examples:** Fraying → **−10 %**; Breaking with Grief dominant → **−20 %**; Breaking with reduced effects → **−7.5 %**.

**EF2 — Freezing vignette.** The `vignette_strength` formula is defined as:

`vignette = vig[body_stage] × fx_scale`, `vig` = Warm/Chilled/Cold 0 · Hypothermic 0.25 · Critical 0.5

**Output Range:** 0–0.5. **Example:** Hypothermic → **0.25**; Critical with reduced effects → **0.25**.

**EF3 — Beat gating.** The `beat_allowed` rule is defined as:

`allowed = no higher-priority beat playing and (now − last_time[beat]) ≥ beat_cooldown_s`; a lower-priority event during a playing beat is dropped, not queued

**Variables:** `beat_cooldown_s` (data file, default 20 real s), priority order (Rule 9). **Output:** play / drop. **Example:** five failed strikes in 6 s → one kneel beat, then the next allowed 20 s later; a loss during it is played after (higher priority interrupts: loss replaces failure).

**EF4 — Posture set.** The `posture_set` lookup is defined as: the first matching row of Rule 2 (Body → Needs → Morale-if-Strained+ → steady). **Output:** one set id. **Example:** Cold + Tired + Fraying/L → **hunched (Body wins)**; Warm + Rested + Fraying/L → **horizon-gazing**; Warm + Rested + Steady/L → **steady** (morale postures need Strained or worse).

**EF5 — Music layer gains.** The `music_gains` table is defined as (targets, eased over 4 s):

| State | warm | pad | thin |
|---|---|---|---|
| Steady, at a burning fire | 0.6 | 0 | 0 |
| Steady, elsewhere | 0.25 | 0 | 0 |
| Strained | 0.15 | 0.3 | 0 |
| Fraying | 0 | 0.4 | 0.2 |
| Breaking | 0 | 0.3 | 0.35 |

During ritual moments all music targets drop to 0 (silence and crackle). **Output Range:** 0–0.6 per layer. **Example:** dropping from Strained to Fraying fades the warm instrument out over 4 s while a thin high line enters.

**EF6 — Wind emphasis.** The `wind_gain_db` formula is defined as:

`wind_gain_db = wind_base_db + wind_step_db × state_index`, and when `dominant == L` and state ≥ Strained, other ambience is ducked by `duck_db`

**Variables:** `wind_step_db` (default +2 dB), `duck_db` (default −6 dB). **Output Range:** +0 to +6 dB over the base wind (which Ambient & Foley sets from Thermal's `wind_eff`). **Example:** Fraying → **+4 dB**; Fraying with Loneliness dominant → +4 dB wind, birds and creaks −6 dB.

*systems-designer + technical-artist lenses applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: grade stacking to a grey screen — capped at −20 % and warm hues excluded; vignette hiding the survivor — capped at 0.5 at the edge only; beat spam from repeated failures — cooldown 20 s; music changing on every state flicker — Morale's hysteresis plus 4 s easing. No feedback loops (read-only).*

## Edge Cases

- **If Body is Cold and Morale is Breaking at once**: posture shows Body (hunched); grade shows Morale (desaturation); vignette absent (not Hypothermic) — both readable, neither hides the other.
- **If a beat event arrives during an Interaction action**: the beat plays as an overlay at the action's end (failure beats follow the Mishaps outcome), never mid-swing.
- **If the player presses a move key during a beat**: the beat is cancelled at once.
- **If the survivor is asleep**: no beats; posture is the sleep override; music fades to silence; grade holds.
- **If death occurs**: all beats stop; `end_rise` framing; music to silence; grade fades to snow white over 8 s (art bible §2).
- **If "reduce camera motion" is on**: ritual moments still trigger their posture and audio, without the pull-back.
- **If Morale's state flickers across a threshold** (prevented by its hysteresis): easing hides any residual flicker.
- **If an event names an unknown beat**: ignore, log.
- **If a save is loaded**: blend weights start at their targets (no 3 s fade-in from neutral).

## Dependencies

**Upstream — hard:** Morale & Mental State (state, strains, events), Body Temperature (approved), Character Controller & Animation (approved — the overlay layer), Camera (approved — framings).

**Upstream — soft:** Needs & Weight, Mishaps & Failure, Fire, Time (night), Save/Load & Settings (accessibility, Alpha).

**Downstream:** Ambient & Foley Audio (wind emphasis, ducking), rendering (Compositor), Self-Filmed Diary (VS word pools).

**Bidirectional check:** the systems index lists Emotional Feedback → Morale, Body, Character, Camera (matches). Morale's Visual/Audio table is implemented row by row (Rule 3, Rules 5–8); Body's postures and 失温危险 vignette (Rules 2, 6); Needs' postures (Rule 2); Camera's framings table (Rule 4 — all requesters match Camera's table); Character's overlay layer and posture-set priority (Body → Needs → Morale) match its Rule 10. Morale's open question "should Breaking's plea ever make the survivor refuse an action" is answered here: **no** — Emotional Feedback only presents.

## Visual/Audio Requirements

*art-director + audio-director lenses applied, against `design/art/art-bible.md` §1, §2, §4, §5.*
- **Warm stays warm** (§1): the warm hue band (fire, tarp, collar, skin) is excluded from EF1 so the fire is always the warmest, brightest thing.
- **Read at 69 px** (§5): every posture set must differ in silhouette; beats exaggerate (full kneel, whole-body slump).
- **Mood table** (§2): 失温危险 = vignette toward trunk_navy + desaturation (Body); death = slow fade to snow white; tap-out = aerial with dusk-warm light.
- **Score direction:** one acoustic instrument (warm), a low cold pad, a single high line — never a full orchestra; long silences; nothing that sounds like a game "danger" cue.
- **Colourblind** (§4): no state is shown by colour alone; posture carries it.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:emotional-feedback` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Felt, not read** (Morale): "he's falling apart" from a 20-second clip with no HUD.
- **Quiet most of the time.** The default is ambience and wind; music is a visitor.
- **The fire is always warm.** However bad the mood, the flame is never greyed.
- **Never in the way.** Beats ≤ 1.2 s, cancelled by input; no effect hides the survivor or a hazard.

## UI Requirements

- **None in play** (no mood indicators).
- **Settings (Alpha):** "Reduce camera motion", "Reduce screen effects".
- **Debug overlay (dev only):** active posture set and its source, beat log with cooldowns, grade/vignette values, music gains, wind dB.

> **📌 UX Flag — Emotional Feedback**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2–8 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | Visual/Audio table, events, plea open question | in review — implements |
| Rules 2, 6 | Body Temperature (`design/gdd/body-temperature.md`) | stage postures, vignette | approved — matches |
| Rule 2 | Needs & Weight (`design/gdd/needs-and-weight.md`) | tired/exhausted/hungry postures, sleep | approved — matches |
| Rules 2–3 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | overlay layer, Tier A/B clips, posture priority | approved — matches |
| Rule 4 | Camera (`design/gdd/camera.md`) | standard framings | approved — matches |
| Rule 3 | Mishaps & Failure, Fire | causes, fire-lit beat | approved — matches |
| Rule 8, EF6 | Ambient & Foley Audio (`design/gdd/ambient-and-foley-audio.md`) | wind emphasis, ducking | not yet written — provisional |
| Implementation | `docs/engine-reference/godot/modules/rendering.md` | Compositor resource | exists |
| Visual | `design/art/art-bible.md` §1, §2, §4, §5 | warm rule, mood table, colourblind, readability | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** Cold + Tired + Fraying/L, **THEN** posture set = hunched (Body); **GIVEN** Warm + Rested + Fraying/L, **THEN** horizon-gazing; **GIVEN** Warm + Rested + Steady/L, **THEN** steady.
2. [A] **GIVEN** five failures in 6 s, **THEN** exactly one failure beat; another failure beat is allowed only after 20 s.
3. [A] **GIVEN** a failure beat playing, **WHEN** a loss event arrives, **THEN** the loss beat replaces it.
4. [A] **GIVEN** a beat playing, **WHEN** a move input arrives, **THEN** the beat is cancelled in the same frame.
5. [A] **GIVEN** Morale's fire ritual, **THEN** `ritual_wide` is requested and all music gains go to 0; with "reduce camera motion", no framing request.
6. [A] **GIVEN** Needs `is_asleep`, **THEN** `sleep_wide` is requested and no beats play.
7. [A] **GIVEN** `body_died`, **THEN** `end_rise`, music silent, grade fades to white over 8 s.

**States**
8. [A] **GIVEN** Steady → Fraying, **THEN** grade reaches −10 % over ≥ 3 s and warm/pad/thin reach 0/0.4/0.2 over 4 s.

**Formulas**
9. [A] EF1: Fraying → −0.10; Breaking + Grief → −0.20; Breaking + reduced effects → −0.075; a fire pixel's saturation is unchanged in all cases.
10. [A] EF2: Hypothermic → 0.25; Critical → 0.5; Critical + reduced effects → 0.25; Morale Breaking alone → 0.
11. [A] EF5: each table row's gains are reached within 4 ± 0.2 s.
12. [A] EF6: Fraying → +4 dB; Fraying + L dominant → other ambience −6 dB.

**Cross-system & feel**
13. [A] **GIVEN** a Mishaps strike failure with cause wind, **THEN** the wind cause beat (sparks blown) plays before the frustration beat (integration).
14. [P] **GIVEN** 20-second clips in each Morale state with no HUD, **THEN** ≥ 4 of 5 testers name the direction (calm / struggling / breaking) — Morale AC 23.
15. [P] **GIVEN** a Breaking-state screenshot at night, **THEN** the fire still reads as the warmest, brightest element.
16. [P] **GIVEN** 30 minutes of play, **THEN** testers do not describe the music as "constant" or the beats as "repetitive".

**Performance:** grade + vignette Compositor pass ≤ 0.5 ms per frame on min-spec; logic ≤ 0.05 ms per frame.

*QA gaps found and resolved: posture priority (1), cooldown and priority (2–3), input cancel (4), accessibility (5), sleep/death overrides (6–7), warm-hue exclusion (9). Feel lines moved to playtest criteria 14–16.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Music: a composer-led score or a few sparse stems? Budget and tone. | audio-director + owner | before VS | brief to a composer with EF5's table |
| Should hunger and weight loss thin the silhouette (VS)? | art-director | Needs open question | blend shapes on the survivor |
| Is the 20 s beat cooldown too sparse for strike failures (the most emotional moment)? | game-designer | MVP playtest | data |
| Gamepad rumble for shivering and failed strikes? | ux-designer | Alpha | — |
