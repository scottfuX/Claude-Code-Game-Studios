# Body Temperature

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / systems-designer lenses)
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-16
> **Implements Pillar**: 冷是真的 · 退赛是赌注

## Summary

Body Temperature tracks the survivor's core temperature, minute by minute, from how cold it feels where they stand (Thermal Environment), what they are doing, whether they are wet, and their clothing. It walks through five stages — Warm, Chilled, Cold, Hypothermic, Critical — each making the body visibly worse and clumsier, and ends the run at 30 °C. It is the first thing that can kill the player, the reason the fire matters, and the system that wakes you at 3 a.m. when the fire has gone out.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Thermal Environment, Time & Day Cycle`

## Overview

Body Temperature owns `core_temp_c` (37.0 °C at the drop) and `wetness` (0–1). Every game minute it reads the felt temperature at the player from Thermal Environment, adds the heat the body makes by working, walking or shivering, and moves the core temperature up or down (Formula B1). Below a neutral felt temperature the body cools — faster when wet, slower with better clothing; above it, the body rewarms, quickly at a good fire. The resulting stage drives what the player sees and can do: shivering, clumsy cold hands that make fire-lighting and chopping fail more often (through Mishaps), slower movement, and at the bottom a crawl in which only tending a fire, crawling and calling for extraction remain possible.

For the player this is the direct answer to the playtest note "出去体温也没有怎么降": on the first afternoon working outdoors keeps you roughly level, standing still does not, and the first night without a fire kills in about five game hours (≈ 5 real minutes). Later in the run even a fire alone stops being enough at night — that is where shelter (VS) and bigger fires come in. Body Temperature never decides that the player should leave; it makes the cost of staying physical (pillar 冷是真的) and keeps the tap-out radio usable even at the very end (pillar 退赛是赌注).

## Detailed Design

### Core Rules

1. **State.** The body has `core_temp_c` (float, starts 37.0) and `wetness` (float 0–1, starts 0). Clothing `insulation` comes from the kit (MVP: fixed 1.0).
2. **Tick.** On every `minute_tick` from Time, Body Temperature queries `effective_temp_c(player_position)` from Thermal Environment, computes the rate in °C per game hour (B1) and applies `rate / 60`. Ticks fire during sleep and waiting, so the body keeps cooling during skips.
3. **Cooling and warming are asymmetric.** Below `t_neutral` (5 °C felt) the body loses heat in proportion to the gap, multiplied by wetness and divided by insulation. Above it, the body regains heat at a faster rate per degree, so a good fire rewarms within one to two game hours. The core never rises above 37.0 °C (no overheating in the MVP).
4. **Activity heat.** The body adds heat by activity, reported by Character Controller (movement) and Interaction (work): idle 0 · walking +0.3 · wading deep snow +0.45 · light work +0.3 · heavy work (chopping, hauling) +0.6 °C per hour. The highest applicable value is used, not the sum. Sleep counts as idle.
5. **Shivering.** In Chilled and Cold the body shivers: +0.3 °C per hour and `is_shivering = true` (Needs & Weight charges energy for it). In Hypothermic and Critical shivering stops — the body has given up — so cooling speeds up. This is the quiet danger the player must learn.
6. **Wetness.** Wetness rises from events (`fell_in_water` from Mishaps → 1.0; wading deep snow +0.03 per hour; snowfall from Weather in the VS) and dries by warmth (B2). Wet doubles heat loss at wetness 1.0.
7. **Stages.** Core temperature maps to a stage (B3). Falling uses the threshold; rising needs threshold + 0.2 °C (hysteresis), so the stage does not flicker.

   | Stage | Core °C (falling) | Shiver | cold_hands_penalty | move_speed_mult | body_action_mult | What the player can do |
   |---|---|---|---|---|---|---|
   | Warm 暖 | ≥ 36.5 | no | 0.00 | 1.00 | 1.00 | everything |
   | Chilled 发冷 | < 36.5 | yes | 0.02 | 1.00 | 1.00 | everything |
   | Cold 冻 | < 35.5 | yes | 0.06 | 0.95 | 1.10 | everything |
   | Hypothermic 失温 | < 34.0 | no | 0.12 | 0.80 | 1.25 | everything; stumbles |
   | Critical 濒危 | < 32.0 | no | 0.20 | 0.40 (crawl) | 1.50 | only crawl, tend/add fuel to a fire within reach (add_fuel, blow_embers), sit and warm at a fire (sit_warm), drop items, and call extraction (tap-out) |
   | Dead | ≤ 30.0 | — | — | — | — | run ends: `body_died(cause = hypothermia)` |

8. **Effects out.** Body publishes `core_temp_c`, `stage`, `wetness`, `is_shivering`, `cold_hands_penalty` (Mishaps adds it to failure chance, alongside Morale's penalty, and clamps the total), `move_speed_mult` (Character Controller), `body_action_mult` (Interaction multiplies it with Morale's `action_duration_mult`), `allowed_actions` in Critical (Interaction), `stage_changed`, and `rate_c_per_hour` (debug, HUD trend).
9. **Waking and interrupting.** If the player is asleep or waiting and the stage worsens by one step — or reaches Cold while asleep — Body requests Time's `normal` mode and emits `wake_request(cause = cold)`; Needs & Weight clears `is_asleep`. The player wakes shivering with time to act.
10. **Tap-out is never blocked.** Calling extraction (Tap-out & Run Results, VS) stays available in every stage including Critical. In the MVP, which has no tap-out yet, Critical allows only crawl, fire tending (add_fuel, blow_embers, sit_warm), and dropping items.
11. **Death.** At `core_temp_c ≤ 30.0` emit `body_died(cause = hypothermia)` once. In the MVP the run ends and restarts; from the VS, Tap-out & Run Results applies the death penalty. Medical evacuation (VS) is a separate system and may end a run before death.

### States and Transitions

| From | To | Condition |
|---|---|---|
| Warm | Chilled | core < 36.5 |
| Chilled | Warm | core ≥ 36.7 |
| Chilled | Cold | core < 35.5 |
| Cold | Chilled | core ≥ 35.7 |
| Cold | Hypothermic | core < 34.0 |
| Hypothermic | Cold | core ≥ 34.2 |
| Hypothermic | Critical | core < 32.0 |
| Critical | Hypothermic | core ≥ 32.2 |
| Critical | Dead | core ≤ 30.0 |

- One stage step per tick in either direction; each emits `stage_changed`.
- Dead is terminal. The run starts Warm, dry, core 37.0.

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Thermal Environment (approved) | in | `effective_temp_c(player)`, `is_sheltered` | Thermal |
| Time & Day Cycle (approved) | in/out | in: `minute_tick`; out: `request_rate_mode(normal)` on wake/interrupt | Time |
| Character Controller & Animation | in/out | in: movement activity (idle / walk / wade); out: `move_speed_mult`, stage for shiver/stumble/crawl animation | Character (activity) / Body (mult) |
| Interaction & Timed Actions | in/out | in: work activity (light / heavy); out: `body_action_mult`, `allowed_actions` in Critical | Interaction (activity) / Body (mult) |
| Mishaps & Failure | in/out | in: `fell_in_water`; out: `cold_hands_penalty` (summed with Morale's `reliability_penalty`, clamped ≤ 0.90 by Mishaps) | Body (value) / Mishaps (clamp) |
| Needs & Weight | in/out | in: `is_asleep`; out: `is_shivering`, `stage` (energy cost of shivering and cold), `wake_request` | Needs (`is_asleep`) / Body |
| Morale & Mental State | out | `core_temp_c` for Pain (F5) and the fire-ritual condition (≥ 36.0) | Body |
| Emotional Feedback | out | `stage`, `is_shivering`, `wetness`, `stage_changed` | Body |
| HUD | out | `core_temp_c` (as a band, not a number), `stage`, `rate_c_per_hour` trend | Body |
| Item Database & Inventory / Kit Selection (VS) | in | `insulation` from worn clothing | Inventory / Kit |
| Weather & Cold Snaps (VS) | in | snowfall wetness gain | Weather |
| Injury & Pain (VS) | out | time spent Hypothermic or worse (frostbite risk) | Body |
| Medical Check-ins (VS) | out | lowest core temperature since the last check | Body |
| Tap-out & Run Results (VS) | out | `body_died` | Body |
| Save/Load (Alpha) | out | `core_temp_c`, `wetness`, `stage` | Body |

## Formulas

**B1 — Core temperature rate.** The `core_temp_rate` formula is defined as (°C per game hour):

`gap = effective_temp_c − t_neutral`
`exchange = gap < 0 ? k_cool × gap × (1 + w_wet × wetness) / insulation : k_warm × gap`
`core_temp_rate = clamp(exchange + heat_activity + heat_shiver, rate_min, rate_max)`, then 0 if `core_temp_c ≥ 37.0` and the rate is positive

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| effective_temp_c | float | −67 – +40 | calculated (Thermal TH5) | felt temperature at the player |
| t_neutral | float | 0–15 | data file | felt temperature at which a clothed body neither gains nor loses heat (default 5) |
| k_cool | float | 0.03–0.2 | data file | cooling per °C below neutral (default 0.088) |
| k_warm | float | 0.1–0.6 | data file | rewarming per °C above neutral (default 0.3) |
| w_wet | float | 0–2 | data file | extra loss at full wetness (default 1.0 → ×2) |
| wetness | float | 0–1 | calculated (B2) | |
| insulation | float | 0.5–2.0 | calculated (kit) | clothing; 1.0 in the MVP; must be > 0 |
| heat_activity | float | 0–0.6 | data file (activity table) | Rule 4 |
| heat_shiver | float | 0 or 0.3 | data file | 0.3 in Chilled and Cold, else 0 |
| rate_min / rate_max | float | −6 – 0 / 0 – 5 | data file | clamps (default −4.0 / +3.0) |

**Output Range:** −4.0 to +3.0 °C per game hour. **Examples:**
- Day 1, 13:00, open snow, chopping, dry (felt −4.2): −9.2 × 0.088 = −0.81 + 0.6 = **−0.21 °C/h**; once Chilled, shivering makes it **+0.09** — working keeps you level.
- Same, standing idle: **−0.81 °C/h**, then −0.51 once Chilled.
- Night 1, 02:30, open snow, idle, no fire (felt −11.9): −16.9 × 0.088 = **−1.49**, +0.3 shivering = **−1.19 °C/h**; below 34.0 shivering stops → −1.49.
- Night 1, 02:30, 1.5 m from a 25 °C / 3 m fire (felt +6.9): +1.9 × 0.3 = **+0.56 °C/h**; at 1.0 m (felt +10.3): **+1.6 °C/h**.
- Day 31, 02:30, 1.5 m from the same fire (felt −5.1): **−0.89 °C/h**, +0.3 shivering — a fire alone no longer holds the night.
- Day 1 afternoon, chopping after falling through the ice (wetness 1.0): −9.2 × 0.088 × 2 + 0.6 = **−1.02 °C/h**.

**B2 — Wetness change.** The `wetness_rate` formula is defined as (per game hour):

`wetness_rate = gain − (effective_temp_c ≥ dry_hot_c ? dry_fast : effective_temp_c ≥ 0 ? dry_slow : 0)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| gain | float | 0–0.2 | calculated | wading deep snow 0.03; snowfall (VS) from Weather; event gains apply instantly (fell in water → set to 1.0) |
| dry_hot_c | float | 5–20 | data file | felt temperature for fast drying (default 10 — at a fire) |
| dry_fast | float | 0.2–1.0 | data file | default 0.6 per hour |
| dry_slow | float | 0–0.2 | data file | default 0.1 per hour |

Wetness clamps to 0–1. Below 0 °C felt nothing dries — clothes freeze.

**Output Range:** −0.6 to +0.2 per hour. **Example:** soaked (1.0), crouched at a fire at felt +10.3: dry in **≈ 1.7 game hours**; in the open at −4 °C: never dries.

**B3 — Stage.** The `body_stage` lookup is defined as:

`stage = first of [Dead ≤ 30.0, Critical < 32.0, Hypothermic < 34.0, Cold < 35.5, Chilled < 36.5, Warm]` when falling; rising requires `threshold + hysteresis`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| thresholds | float[5] | 29–37 | data file | 36.5 · 35.5 · 34.0 · 32.0 · 30.0 (death) |
| hysteresis | float | 0–0.5 | data file | default 0.2 °C |

Thresholds must strictly decrease; otherwise the table is rejected at load.

**Output Range:** one of six stages. **Example:** core 34.1 cooling → Cold; at 33.99 → Hypothermic; warming back, it stays Hypothermic until 34.2.

**B4 — Stage effects** (lookup, the table in Core Rule 7): `cold_hands_penalty` 0–0.20, `move_speed_mult` 0.40–1.00, `body_action_mult` 1.00–1.50 — all data file values.

**Time to death (derived check).** From 37.0 at a constant felt −11.9 °C (night 1, open snow, idle, no fire): 0.34 h to Chilled at −1.49, 2.11 h through Chilled/Cold at −1.19, then 2.69 h to 30.0 at −1.49 → **≈ 5.1 game hours ≈ 5 real minutes** at the night rate. Day 31 at felt −23.9 °C: ≈ 2.9 game hours.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: `insulation = 0` → division by zero — rejected, floor 0.5; wetness multiplier × low insulation × −67 °C would give −27 °C/h — clamped at −4.0; positive rates above 37.0 — held; non-decreasing thresholds — rejected. Feedback loop named: colder → shivering stops below 34 → colder still (intended — the quiet slide); damped by the wake/interrupt rule and the Critical-stage fire-tending exception. A second loop, colder → clumsier hands → failed fire → colder, is the core tension of 冷是真的 and is bounded by Mishaps' 0.90 clamp.*

## Edge Cases

- **If the player is asleep when the stage reaches Cold**: request `normal`, emit `wake_request(cold)` — one wake per stage step, not every tick.
- **If the player is already awake in Cold and keeps sleeping attempts**: Needs & Weight decides whether sleep is allowed; Body still wakes them on the next worsening step.
- **If core is at 37.0 and the felt temperature is warm**: rate is 0; no overheating.
- **If `effective_temp_c` is exactly `t_neutral`**: exchange 0; only activity and shivering apply.
- **If the player stands at a fire while soaked**: drying and warming happen together; the wetness term only applies while `gap < 0`.
- **If the player falls into water while already wet**: wetness is set to 1.0 (no stacking above 1).
- **If several activities apply at once** (walking while carrying): use the highest heat value.
- **If core would drop past 30.0 in one tick** (clamped rate makes this ≤ 0.067 °C per tick): set exactly to 30.0, emit `body_died` once, stop ticking.
- **If the player is in Critical with no fire within reach**: crawling and dropping items are the only actions; fire tending is impossible until they reach one. In the VS, tap-out stays available.
- **If Thermal returns an invalid value** (NaN, missing): reuse last minute's value and log an error; never kill on bad data.
- **If insulation data is ≤ 0 or thresholds do not strictly decrease**: reject at load, use defaults.
- **If a save is loaded**: restore `core_temp_c`, `wetness`, `stage` exactly; no `stage_changed` is emitted for the restored stage.
- **If the player is in a shelter (VS) and asleep with the fire out**: they cool at the sheltered felt temperature; the wake rule still applies.

## Dependencies

**Upstream — hard:**
- **Thermal Environment** (approved) — `effective_temp_c`, `is_sheltered`.
- **Time & Day Cycle** (approved) — `minute_tick`; Body may request `normal` (Time Rule 7 lists Body Temperature as an interrupter).

**Upstream — soft:**
- **Character Controller & Animation** — movement activity (default idle).
- **Interaction & Timed Actions** — work activity (default none).
- **Mishaps & Failure** — `fell_in_water`.
- **Needs & Weight** — `is_asleep`.
- **Item Database & Inventory / Kit Selection** — `insulation` (default 1.0).
- **Weather & Cold Snaps (VS)** — snowfall wetness.

**Downstream:**
- **Morale & Mental State** — hard: `core_temp_c` (Pain, ritual condition).
- **Needs & Weight** — `is_shivering`, `stage`, `wake_request`.
- **Mishaps & Failure** — `cold_hands_penalty`.
- **Character Controller & Animation** — `move_speed_mult`, stage animations.
- **Interaction & Timed Actions** — `body_action_mult`, Critical `allowed_actions`.
- **[Food (three-day chapter)](food.md)** — respects Critical admission and cancellation through Interaction; Food has no direct Body writes.
- **Emotional Feedback, HUD** — presentation.
- **Injury & Pain, Medical Check-ins, Tap-out & Run Results (VS)**, **Save/Load (Alpha)**.

**Bidirectional check:** the systems index lists Body → Thermal, Time (matches). Thermal lists Body as its hard consumer (matches). Time lists Body as a downstream and as a `normal` requester (matches). Morale lists Body with `core_temp_c` (matches; Morale's `t_comfort` 36.5 equals the Warm/Chilled boundary and its 36.0 ritual threshold sits inside Chilled — consistent). Gaps to fix when written: Mishaps, Interaction, Character Controller and Needs & Weight must list Body as an input; the index rows for those systems do not yet name Body Temperature.

## Visual/Audio Requirements

*art-director lens applied (visual feedback is central: players read the body to survive), against `design/art/art-bible.md` §1–4.*
- **Readable at the far camera** (§1 大块面): each stage must read from silhouette and motion alone — Warm: upright, easy gait · Chilled: arms in, shoulders up, light shiver · Cold: hunched, hands under armpits when idle, strong shiver · Hypothermic: stumbles every few steps, no shiver, slow turns · Critical: on hands and knees, crawling.
- **Breath vapour** whenever felt temperature < 0 °C; thicker and faster when working, thin and slow in Hypothermic.
- **失温危险 treatment** (art bible §2): from Hypothermic, the screen edge darkens toward trunk_navy and desaturates; warm colours unaffected. Critical narrows it further. Distinct from Morale's Breaking (saturation only, no vignette).
- **Wet**: darker coat value (roof_slate a step darker) and a frost rim when wet below 0 °C.
- **Warming at the fire**: hands held out, posture loosens as the stage rises; the warm tint on the snow around the fire (Thermal visual note) frames it.
- **Audio**: teeth-chatter and shaky breathing in Chilled/Cold, silence of breath in Hypothermic (the absence is the warning), a single heavy exhale on each stage improvement.
- **Colourblind** (§4): stage never shown by colour alone — posture and the HUD's snowflake/flame icons back it up.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:body-temperature` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Felt in the body first.** A player should notice "he's getting cold" from posture and breath before checking the HUD.
- **Working keeps you warm, standing still doesn't.** On day 1 the difference between chopping (≈ level) and standing (≈ −0.8 °C/h) must be noticeable within a few real minutes — idleness outdoors is a mistake the body punishes.
- **The fire is relief you can feel.** Stepping from 2.5 m to 1 m of a fire should visibly speed the rewarm (posture loosening within ~30 real seconds).
- **The quiet slide.** When shivering stops in Hypothermic, the sudden silence should land as dread, not relief.
- **Never instant.** No single event kills; death always comes after at least two visible stage changes.

## UI Requirements

- **Body temperature is the most prominent HUD element** (art bible §7 constraint "体温状态最醒目") — shown as a band/bar in blue (cold) to orange (warm) with snowflake/flame icons and fill direction, never as a number in play. HUD GDD owns layout.
- **Trend arrow** from `rate_c_per_hour` (cooling / steady / warming) so the player knows whether where they stand is safe.
- **Critical stage prompt (VS):** the extraction radio prompt is reachable here (Tap-out owns it).
- **Debug overlay (dev only):** core °C, rate, wetness, stage, activity, insulation, felt temperature.

> **📌 UX Flag — Body Temperature**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 2, B1 | Thermal Environment (`design/gdd/thermal-environment.md`) | `effective_temp_c`, `is_sheltered`; fire 25 °C / 3 m example | approved — matches |
| Rules 2, 9 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | `minute_tick`, `request_rate_mode(normal)` | approved — matches |
| Rule 8, Interactions | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `core_temp_c` for F5 (t_comfort 36.5, t_max_pain 33.0) and the 36.0 ritual condition | in review — consistent |
| Rules 4, 8 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | work activity in; `body_action_mult` combined with Morale's multiplier | not yet written — provisional |
| Rules 6, 8 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | `fell_in_water`; `cold_hands_penalty` summed with Morale's penalty, clamp ≤ 0.90 | not yet written — provisional |
| Rules 5, 9 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `is_asleep`; energy cost of shivering | not yet written — provisional |
| Rules 4, 8 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | movement activity; stage animations; speed mult | not yet written — provisional |
| UI | `design/art/art-bible.md` §2, §4, §7 | 失温危险 look, blue/orange bar with icons, "体温状态最醒目" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a new run, **THEN** core 37.0, wetness 0, stage Warm, insulation 1.0.
2. [A] **GIVEN** felt +15 °C and core 37.0, **WHEN** 1 game hour passes, **THEN** core stays 37.0.
3. [A] **GIVEN** walking and chopping reported at once, **WHEN** the rate is computed, **THEN** heat_activity = 0.6 (highest), not 0.9.
4. [A] **GIVEN** core 36.0 (Chilled), **THEN** `is_shivering` = true and heat_shiver = 0.3; **GIVEN** core 33.5 (Hypothermic), **THEN** `is_shivering` = false.
5. [A] **GIVEN** asleep, core 35.6 and falling, **WHEN** core drops below 35.5, **THEN** exactly one `wake_request(cold)` and one `request_rate_mode(normal)` are emitted.
6. [A] **GIVEN** Critical stage, **WHEN** the player tries to chop, **THEN** the action is refused; **WHEN** they add fuel to a fire within reach, **THEN** it is allowed.
7. [A] **GIVEN** core 30.01 cooling at −1.49 °C/h, **WHEN** the next tick runs, **THEN** core = 30.0 and `body_died(hypothermia)` is emitted exactly once.
8. [A] **GIVEN** Thermal returns NaN for one tick, **THEN** the previous felt temperature is reused and an error is logged; core does not jump.

**States**
9. [A] **GIVEN** core falling through 36.5, 35.5, 34.0, 32.0, **THEN** stages Chilled, Cold, Hypothermic, Critical are entered in order with one `stage_changed` each; **GIVEN** core rising from 33.9 to 34.1, **THEN** still Hypothermic; at 34.2 → Cold.

**Formulas**
10. [A] B1: felt −4.2, heavy work, dry, Warm → −0.21 ± 0.01 °C/h; idle → −0.81 ± 0.01; Chilled + heavy work → +0.09 ± 0.01.
11. [A] B1: felt −11.9, idle, Chilled → −1.19 ± 0.01; Hypothermic → −1.49 ± 0.01.
12. [A] B1: felt +6.87, idle, core 36.0 → +0.86 ± 0.01 (0.56 exchange + 0.3 shiver); felt +10.32, Warm, core 36.8 → +1.60 ± 0.01.
13. [A] B1: felt −4.2, heavy work, wetness 1.0, Warm → −1.02 ± 0.01; felt −67, wetness 1.0, insulation 0.5 → clamped −4.0.
14. [A] B2: wetness 1.0 at felt +10.3 → 0 after 100 game minutes ± 2; at felt −4 → still 1.0 after 5 game hours.
15. [A] B3: data with thresholds 36.5, 35.5, 36.0 … is rejected and defaults are used.
16. [A] Derived: **GIVEN** core 37.0, a constant felt −11.9 °C (test fixture), idle, dry, never waking, **THEN** `body_died` fires 5.1 ± 0.1 game hours later.

**Cross-system & feel**
17. [A] **GIVEN** Fraying (Morale penalty 0.06) and Cold (penalty 0.06) and a strike with base 0.25, **WHEN** Mishaps resolves, **THEN** effective failure chance = 0.37 (integration).
18. [A] **GIVEN** a fire registered in Thermal giving felt +10.3 °C at 1.0 m and core 34.0, **WHEN** 1 game hour passes idle, **THEN** core ≥ 35.5 (rewarming visible within an hour).
19. [P] **GIVEN** the MVP first afternoon, **WHEN** the owner stands still outdoors for 3 real minutes, **THEN** the survivor's posture changes visibly (Chilled) and the owner notices the cold without the HUD.
20. [P] **GIVEN** five testers shown 10-second clips of each stage, **THEN** ≥ 4 order them correctly from posture alone.

**Performance:** ≤ 0.02 ms per tick (one Thermal query + arithmetic). O4 resolved by Scott (2026-11-19): profile this full inclusive path; retain this budget and tighten Thermal's per-query budget after profiling. Follow-up: measure inclusive/exclusive costs and set the tighter query allocation; no new query number is approved.

*QA gaps found and resolved: shiver cut-off (4), single wake per step (5), Critical action whitelist (6), exact death clamp (7), bad Thermal data (8), activity max-not-sum (3). Feel lines moved to playtest criteria 19–20.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Is ≈ 5 game hours (≈ 5 real minutes) from fire-out to death on night 1 the right harshness? | owner | MVP playtest | tune `k_cool`, `t_neutral` |
| By day 31 a 25 °C fire at 1.5 m still loses heat at night. Intended to force shelter (VS) and bigger fires — but does the MVP (no shelter) need a softer late curve? | owner + systems-designer | Fire GDD / MVP playtest | MVP covers ~day 1–3, so likely fine; revisit for the VS |
| Should hunger (Needs) reduce body heat production (thin people get cold faster)? | systems-designer | Needs & Weight GDD | add a fullness term to heat_activity if wanted |
| Should Critical let the player sit and wait to die (a "giving up" choice), or always push to act? | owner | Emotional Feedback GDD | default: no special option |
| Frostbite (hands, feet) from long Hypothermic exposure is left to Injury & Pain (VS). | systems-designer | Injury & Pain GDD | Body publishes exposure time |
