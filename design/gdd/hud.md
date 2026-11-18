# HUD

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / ux-designer / art-director lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 苦中有美 · 冷是真的

## Summary

The HUD is almost nothing, on purpose: a hand-drawn body-temperature band that is the only always-present element, small need icons that appear only when hunger, thirst or tiredness become a problem, a sun/moon arc instead of a clock, and the context prompts that tell you what E and F will do. There is no morale meter, no thermometer, no numbers and no minimap — the world, the body and the sound carry the rest. It is drawn in the art bible's paper-and-ink style and fades back when nothing is changing.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Body Temperature, Needs & Weight, Time & Day Cycle, Item Database & Inventory`

## Overview

The HUD reads Body Temperature (core temperature as a band, stage, cooling/warming trend), Needs & Weight (warning stages), Time & Day Cycle (phase and sun progress), Interaction (target, verbs, refusals), Input (active device glyphs, hold-to-confirm progress) and Inventory (a minimal backpack list in the MVP), and draws them in screen space at the corners of the frame, away from the survivor in the centre. Its rules come from decisions already made: body temperature is "the most prominent element" (art bible §7, Body Temperature UI), needs appear "only in a warning stage" (Needs & Weight UI), time is a sun/moon arc "with no digital clock" (Time UI), morale is never shown (Morale UI), and there is no thermometer (Thermal UI).

For the player the HUD should almost disappear: on a calm afternoon only a faint band shows; when the cold starts to bite, the band brightens and an arrow says whether where they stand is warming or cooling them; a hungry icon appears on day 3. The first minute shows one line of guidance — "天黑前要有火" — and then gets out of the way. The HUD owns no gameplay; full screens (backpack, diary, results, menus) belong to Screens & Menus (VS).

## Detailed Design

### Core Rules

1. **Elements (MVP):**

   | Element | Position | Source | Visible when |
   |---|---|---|---|
   | Body-temperature band | bottom-left, the largest element | Body Temperature | always (faded when calm — Rule 3) |
   | Trend arrow | at the band's end | Body `rate_c_per_hour` | when |rate| ≥ 0.1 °C/h |
   | Need icons (energy, water, food) | row above the band | Needs & Weight stages | only in Tired/Exhausted, Thirsty/Parched, Hungry/Empty/Starving |
   | Sun/moon arc | top-right, small | Time `phase`, `sun_progress` | always (faint) |
   | Context prompt | world-anchored near the target | Interaction + Input glyphs | when a target has an available action |
   | Refusal line | near the survivor | Interaction | 1.5 s after a refusal |
   | First-minute hint | top-centre | run start | until the first fire is lit or 10 game minutes pass |
   | Minimal backpack list (MVP stand-in) | left panel on Tab | Inventory | while open |
   | Hold-to-confirm ring (VS) | around the `radio` glyph | Input | while holding |
   | Reconnect prompt | centre | Input | gamepad disconnected |

2. **Never shown:** morale, numbers of any kind (temperature, hunger, weight, day count, time), a thermometer, a minimap, quest markers, damage numbers.
3. **Calm fade.** The band and arc sit at 35 % opacity while the body is Warm and the trend is steady; any trend, stage change, need warning or prompt brings them to 100 % over 0.5 s; they fade back after 8 real seconds of calm (H3).
4. **Body band** (H1): a hand-drawn bar that fills from left (cold) to right (warm) between 30 °C and 37 °C; its ink runs blue at the cold end and orange at the warm end with a snowflake icon at the left and a flame at the right (art bible §4 colourblind rules: colour plus icon plus fill direction). Stage boundaries are faint tick marks; there is no number.
5. **Trend arrow** (H2): ◀ cooling, ▶ warming, hidden when steady; double arrow when |rate| ≥ 1.0 °C/h.
6. **Need icons** (H4): a small sketch per need (an axe-arm for energy, a cup for water, a bowl for food); one ink weight at the first warning stage, bolder and pulsing slowly (1 Hz, 10 % scale) at the second; never more than three icons.
7. **Sun/moon arc** (H5): a half-circle; a sun dot travels along it by `sun_progress` by day, a moon dot by night progress; Dawn and Dusk tint the arc; no hour numbers. The player reads "how much light is left".
8. **Prompts** follow Interaction (one or two verbs) with Input's device glyphs; world-anchored, kept 40 px clear of the survivor's silhouette.
9. **Style** (art bible §4, §7): warm off-white paper and ink, hand-drawn strokes, no low-poly elements; all text through localisation keys; minimum text height 18 px at 720p (accessibility floor); safe area 5 % from screen edges.
10. **Context-aware hiding.** During ritual framings and sleep the HUD fades to 0 except the body band at 35 %; during end shots everything fades.
11. **Scaling.** HUD scale setting 80–140 % (Alpha); MVP 100 %.

### States and Transitions

| Element | States | Transitions |
|---|---|---|
| Band / arc | calm (35 %) · active (100 %) · hidden (ritual/sleep/end) | activity → active in 0.5 s; 8 s calm → calm; framings/sleep → hidden |
| Need icon | hidden · warn · urgent | follows Needs stages |
| Hint | shown · gone | first fire lit or 10 game min → gone (never returns) |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Body Temperature (approved) | in | `core_temp_c`, `stage`, `rate_c_per_hour` | Body |
| Needs & Weight (approved) | in | energy, hydration, fullness stages | Needs |
| Time & Day Cycle (approved) | in | `phase`, `sun_progress` | Time |
| Interaction & Timed Actions (approved) | in | target, verbs, refusal reasons | Interaction |
| Input & Action Map | in | `active_device`, glyph sets, hold progress | Input |
| Item Database & Inventory (approved) | in | backpack contents, load band, wetness bands | Inventory |
| Fire (approved) | in | first fire lit (ends the hint) | Fire |
| Camera / Emotional Feedback (approved) | in | framing active, sleep, end shot (hide rules) | Camera / Emotional Feedback |
| Localization, Accessibility & Onboarding | out | text keys, scale | Localization |

## Formulas

**H1 — Band fill.** `fill = clamp((core_temp_c − 30) / (37 − 30), 0, 1)`. **Variables:** `core_temp_c` (Body, 30–37). **Output Range:** 0–1. **Examples:** 37 → **1.0**; 35.5 (Cold boundary) → **0.79**; 32 (Critical) → **0.29**.

**H2 — Trend.** `trend = rate ≥ +1.0 ? ▶▶ : rate ≥ +0.1 ? ▶ : rate ≤ −1.0 ? ◀◀ : rate ≤ −0.1 ? ◀ : none`. **Variables:** `rate` (Body B1, °C per game hour). **Examples:** standing idle on day 1 (−0.81) → **◀**; night with no fire (−1.49) → **◀◀**; 1 m from a fire (+1.6) → **▶▶**.

**H3 — Calm fade.** `opacity = calm_for ≥ calm_s ? calm_alpha : 1.0`, eased 0.5 s up / 1.5 s down. **Variables:** `calm_alpha` 0.35, `calm_s` 8 real s (data file); calm = Warm, no trend, no need warning, no prompt. **Output Range:** 0.35–1.0.

**H4 — Need icon level.** `level = stage ∈ {Tired, Thirsty, Hungry} ? warn : stage ∈ {Exhausted, Parched, Empty, Starving} ? urgent : hidden`. **Output:** hidden · warn · urgent (one per need).

**H5 — Arc position.** `angle = 180° × (phase in Dawn/Day/Dusk ? sun_progress : night_progress)`, `night_progress = (minutes since nightfall) / (night length)`. **Output Range:** 0–180°. **Example:** day 1 at 12:30 → **90°** (top of the arc).

*ux-designer + systems-designer lenses applied (Section D, high-risk in Lean mode): boundaries checked — band below 30 °C (dead) clamped; trend flicker around ±0.1 — Body's rate is smoothed per game minute and the arrow needs the threshold held for 2 real s; icons capped at three; night length never 0 (Time T1–T2). No feedback loops.*

## Edge Cases

- **If the body is Critical**: band at 100 %, ◀◀ or ▶▶, need icons stay; prompts show only Critical-allowed actions (Interaction).
- **If several refusals happen quickly**: the newest line replaces the old one.
- **If the gamepad disconnects mid-prompt**: the reconnect prompt overlays; glyphs switch to keyboard on the next key press.
- **If the hint's 10 game minutes pass with no fire**: the hint goes; it never returns this run.
- **If a ritual framing ends**: elements return over 0.5 s, not instantly.
- **If the window is ultrawide**: elements anchor to the 16:9 safe area centred on screen.
- **If text keys are missing**: show the key name in dev builds, an empty string in release, and log.

## Dependencies

**Upstream — hard:** Body Temperature, Needs & Weight, Time & Day Cycle, Item Database & Inventory (all approved).

**Upstream — soft:** Interaction, Input, Fire, Camera, Emotional Feedback.

**Downstream:** Screens & Menus (VS — shares the style), Localization/Accessibility/Onboarding.

**Bidirectional check:** the systems index lists HUD → Body, Needs, Time, Item DB (matches). Body asks for "a band/bar in blue to orange with snowflake/flame icons and fill direction, never a number" plus a trend arrow (Rules 4–5). Needs asks for icons only in warning stages and weight never on the HUD (Rules 1–2, 6). Time asks for a sun/moon arc and no digital clock (Rule 7). Morale and Thermal ask for no meter and no thermometer (Rule 2). Interaction's prompts and refusal lines and Input's glyphs and hold ring are drawn here (Rules 1, 8). The art bible §7 constraints (paper and ink, body temperature most prominent, all text via translation keys, finger-sized buttons for later mobile) are honoured.

## Visual/Audio Requirements

*art-director lens applied, against `design/art/art-bible.md` §4, §7.*
- Paper-white `#F4EEE3`-range background strips at low opacity behind ink strokes; ink is near-black, with only the band's ends tinted blue (snow_shadow family) and orange (warm_orange).
- Hand-drawn wobble in strokes; icons as small sketches; no gradients, no glow.
- Audio: none in play (Ambient & Foley Rule 10).

## Game Feel

- **Glance, then forget.** The player should look at the HUD only when the cold makes them.
- **The arrow answers "is this place safe?"** Standing still in the open shows ◀; by the fire shows ▶▶.
- **The world first.** Turning the HUD off (Alpha setting) should still leave the game playable by body language and sound.

## UI Requirements

- This GDD is the HUD's UI requirement; layouts and exact sizes go into the UX spec.
- **Settings (Alpha):** HUD scale 80–140 %, HUD off, high-contrast ink.

> **📌 UX Flag — HUD**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 4–5, H1–H2 | Body Temperature (`design/gdd/body-temperature.md`) | band, stage ticks, trend | approved — matches |
| Rules 1, 6, H4 | Needs & Weight (`design/gdd/needs-and-weight.md`) | warning-stage icons; weight not shown | approved — matches |
| Rule 7, H5 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | sun/moon arc | approved — matches |
| Rules 1, 8 | Interaction & Timed Actions, Input & Action Map | prompts, refusals, glyphs, hold ring | approved / in review — matches |
| Rule 1 | Item Database & Inventory | minimal backpack list | approved — matches |
| Rule 2 | Morale & Mental State, Thermal Environment | no meter, no thermometer | matches |
| Rule 10 | Camera, Emotional Feedback | hide during framings, sleep, end | approved — matches |
| Rules 4, 9 | `design/art/art-bible.md` §4, §7 | colourblind rules, paper and ink, body temperature most prominent | exists |
| Rule 1 | `design/game-brief.md` First minute | "天黑前要有火" one-line hint | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

1. [A] **GIVEN** a running game, **WHEN** the HUD tree is inspected, **THEN** no element displays a number, a morale value or a clock.
2. [A] H1: core 37 → fill 1.0; 35.5 → 0.786 ± 0.005; 32 → 0.286; 29 → 0.
3. [A] H2: rate −0.81 → ◀; −1.49 → ◀◀; +1.6 → ▶▶; +0.05 → none; a rate crossing ±0.1 for < 2 s does not change the arrow.
4. [A] H3: Warm, steady, no warnings for 8 s → band at 0.35; a ◀ trend → 1.0 within 0.5 s.
5. [A] H4: Tired → energy icon warn; Exhausted → urgent; Rested → hidden; at most three icons.
6. [A] H5: day 1 12:30 → arc 90°; nightfall → moon at 0°.
7. [A] **GIVEN** a new run, **THEN** the hint "天黑前要有火" shows; **WHEN** the first fire reaches Kindling flame, **THEN** it disappears and never returns.
8. [A] **GIVEN** `ritual_wide` or sleep, **THEN** everything fades to 0 except the band at 0.35.
9. [A] **GIVEN** a greyscale screenshot of the band at Cold and at Warm, **THEN** the fill position and the icons distinguish them (colourblind check).
10. [P] **GIVEN** a 10-minute session, **WHEN** testers are asked what the HUD showed, **THEN** they mention body warmth and little else.
11. [P] **GIVEN** the owner's first minute, **THEN** they understood the goal from the one-line hint and the prompts alone.

**Performance:** HUD draw ≤ 0.3 ms per frame.

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Should the body band hide entirely when Warm and calm (purer screen) instead of 35 %? | owner | MVP playtest | data |
| Is the MVP backpack list enough until the VS screen? | ux-designer | MVP playtest | — |
| Show the day number at dawn briefly ("第 3 天")? The show does it; numbers are otherwise banned. | owner | VS / Diary GDD | diegetic title card at dawn |
