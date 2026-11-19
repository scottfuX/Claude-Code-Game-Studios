# Needs & Weight

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / systems-designer / economy-designer lenses)
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-16
> **Implements Pillar**: 冷是真的 · 退赛是赌注

## Summary

Needs & Weight tracks the survivor's slow body: how full the stomach is, how much water they have drunk, how much energy is left, and — underneath it all — body weight, which falls whenever the calories burnt by cold and work exceed what was eaten. It owns sleep (when the survivor falls asleep, how well they recover, when they wake) and the two quiet killers besides cold: dehydration, and the weight loss that later makes medics pull you out. Weight is the lifeline the brief promised — "体重是慢慢流失的生命线".

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Time & Day Cycle, Body Temperature, Item Database & Inventory`

## Overview

Every game minute the body burns calories — more when working, wading or shivering (Formula N1). The burn is paid first from the stomach (`fullness`, 0–100, holding up to 1,500 kcal) and, once it is empty, from the body itself: `weight_kg` falls by 1 kg per 7,700 kcal (N2). A hard working day in the cold costs about 3,500 kcal; with no food that is close to half a kilo a day, which over a season becomes the visible thinning the show is known for. Hydration drains on its own clock and is restored by drinking — in the MVP only by eating snow, which is slow and tiring (N3). Energy (体力) drains with effort and comes back by sleeping, recovering less when cold or hungry (N4); at zero the survivor collapses asleep where they stand.

For the player this system supplies the 饥饿感 that Morale turns into feeling, the "第 3 天起饱腹不够，体重开始下降" pressure from the brief, and the trade-offs that make a day: chop more wood (burn more, get tired, get thirsty) or rest; eat the last ration tonight or keep it; sleep now by a dying fire or stay up to tend it. Needs & Weight owns `is_asleep` (the contract Morale, Body Temperature and Time already rely on). It does not own food sources or cooking (Food, VS), water sources (Water, VS), medical evacuation (Medical Check-ins, VS) or item values (Item Database & Inventory).

## Detailed Design

### Core Rules

1. **State.** `stomach_kcal` (0–1,500; `fullness = stomach_kcal / 15`, 0–100), `weight_kg` (start = `start_weight_kg`, default 72.0), `hydration` (0–100, start 100), `energy` (0–`energy_cap`, start 90), `is_asleep` (bool, start false). The run starts with `stomach_kcal` 1,200 (fullness 80 — the survivor ate before the drop).
2. **Tick.** On every `minute_tick` from Time, apply N1–N4 for one game minute, including during sleep and waiting.
3. **Burn.** Calories burnt per hour = base (awake 110 / asleep 65) + the highest activity extra (walking 60 · wading deep snow 120 · light work 80 · heavy work 200) + shivering 80 when Body Temperature reports `is_shivering`. Activity comes from Character Controller and Interaction (the same reports Body Temperature uses).
4. **Stomach first, then the body.** Each minute's burn is taken from `stomach_kcal`; any shortfall is taken from body reserve and lowers `weight_kg` (N2). Weight never rises above `start_weight_kg`; in the MVP it never rises at all (open question).
5. **Eating.** Eating a food item (Interaction) adds its `food_kcal` (Item Database) to the stomach. If it would exceed 1,500 kcal, eating is refused ("吃不下") and the item is kept. Eating takes the item's `eat_minutes` (default 5 game minutes).
6. **Drinking.** Drinking adds the item's `drink_hydration`. **MVP stand-in — eating snow:** an action available anywhere on snow except in Critical (Body's whitelist applies): +3 hydration, 3 game minutes, −1 energy per handful. It is slow and tiring on purpose; melting and boiling water (Water, VS) is the good way.
7. **Hydration drain** (N3): −1.4 per hour awake, −0.7 asleep, ×1.5 while wading or doing heavy work.
8. **Energy** (N4): drains by activity (idle 1.0 · walking 2.0 · light work 2.5 · wading 3.5 · heavy work 5.0 per hour, highest applies) + 1.5 while shivering; resting by a burning fire in `wait` mode restores +1.5 per hour instead of draining; sleep restores 8 per hour × warmth quality × food quality. Energy cannot exceed `energy_cap`, which falls as weight is lost (N5).
9. **Sleep.**
   - The player may start sleeping (Interaction "sleep") when energy < 90 at night or < 50 by day (a nap). Otherwise refused ("还不困").
   - On sleep: `is_asleep = true`, request Time `sleep` mode.
   - The survivor wakes when energy reaches `energy_cap` (natural wake), when Body Temperature emits `wake_request(cold)`, or when Time reports `rate_mode_changed(normal)` from a valid interruption while asleep. On wake: `is_asleep = false`, request Time `normal` if not already normal. Fire going Out changes felt temperature through Thermal; only Body Temperature can turn the resulting cold into a wake request. Fire never requests wake or `normal` ([ADR-0011](../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md#decision)).
   - **Collapse:** if energy reaches 0 while awake, the survivor collapses asleep where they stand (`is_asleep = true`, cause `exhaustion`), regardless of place or cold. After a forced wake, energy is raised to at least 5 so collapse does not repeat instantly.
10. **Stages and effects** (N6): energy, hydration and fullness each map to a stage whose effects feed other systems:

    | Need | Stage | At | fatigue_penalty (→ Mishaps) | needs_action_mult (→ Interaction) | needs_move_speed_mult (→ Character) | Other |
    |---|---|---|---|---|---|---|
    | Energy | Rested | ≥ 25 | 0.00 | 1.00 | 1.00 | — |
    | Energy | Tired 疲惫 | < 25 | 0.04 | 1.10 | 0.95 | — |
    | Energy | Exhausted 力竭 | < 10 | 0.10 | 1.25 | 0.85 | heavy work refused |
    | Hydration | OK | ≥ 30 | — | — | — | — |
    | Hydration | Thirsty 口渴 | < 30 | — | — | — | energy drain ×1.2 |
    | Hydration | Parched 干渴 | < 10 | +0.05 | ×1.10 | — | energy drain ×1.2 |
    | Hydration | Dehydrated | = 0 | — | — | — | death after 6 game hours at 0 |
    | Fullness | Fed | ≥ 30 | — | — | — | — |
    | Fullness | Hungry 饿 | < 30 | — | — | — | — |
    | Fullness | Empty 空腹 | = 0 | — | — | — | burning body reserve (weight falls) |
    | Fullness | Starving 断粮 | 0 for ≥ 24 game h | — | — | — | energy drain ×1.2 |

    Penalties from the same column add; multipliers multiply (Parched and Exhausted → fatigue 0.15, action ×1.375). Mishaps sums `fatigue_penalty` with Body's `cold_hands_penalty` and Morale's `reliability_penalty` and clamps the total chance ≤ 0.90. Interaction multiplies `needs_action_mult` with Body's `body_action_mult` and Morale's `action_duration_mult` (Interaction owns any overall cap).
11. **Dehydration death.** If hydration stays at 0 for `dehydration_grace_h` (6 game hours), emit `needs_died(cause = dehydration)` once. Any drink resets the grace timer.
12. **Weight is the long clock.** Needs publishes `weight_kg`, `start_weight_kg` and `weight_lost_frac`; Medical Check-ins (VS) decides evacuation thresholds, Morale turns loss into 饥饿感 (F4), Emotional Feedback (VS option) may thin the silhouette.

### States and Transitions

| Machine | States | Transitions |
|---|---|---|
| Sleep | Awake · Asleep (chosen) · Asleep (collapsed) | Awake → Asleep(chosen) on a permitted sleep action; Awake → Asleep(collapsed) at energy 0; either Asleep → Awake on natural wake, Body's `wake_request(cold)`, or Time `normal`; Asleep(collapsed) → Awake sets energy ≥ 5 |
| Energy stage | Rested · Tired · Exhausted | down at < 25, < 10; up at ≥ 27, ≥ 12 (hysteresis 2) |
| Hydration stage | OK · Thirsty · Parched · Dehydrated | down at < 30, < 10, = 0; up at ≥ 32, ≥ 12, > 0 |
| Fullness stage | Fed · Hungry · Empty · Starving | down at < 30, = 0, 24 h at 0; up at ≥ 32; any food leaves Empty/Starving |

One step per tick in each machine; each change emits `needs_stage_changed(need, stage)`.

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Time & Day Cycle (approved) | in/out | in: `minute_tick`, `is_night`, `rate_mode_changed`; out: `request_rate_mode(sleep / normal)` | Time |
| Body Temperature (approved) | in/out | in: `is_shivering`, `stage` (sleep warmth quality), `wake_request(cold)`; out: `is_asleep` | Body / Needs |
| Character Controller & Animation | in/out | in: movement activity; out: `needs_move_speed_mult` (multiplied with Body's), collapse and sleep animation triggers | Character / Needs |
| Interaction & Timed Actions | in/out | in: work activity, eat / drink / eat-snow / sleep actions; out: `needs_action_mult`, refusals ("吃不下", "还不困", heavy work refused) | Interaction / Needs |
| Item Database & Inventory | in | `food_kcal`, `drink_hydration`, `eat_minutes` per item; consumes the item | Item DB |
| Mishaps & Failure | out | `fatigue_penalty` | Needs (value) / Mishaps (clamp) |
| Morale & Mental State | out | `fullness`, `weight_kg`, `start_weight_kg`, `is_asleep` | Needs |
| Emotional Feedback | out | stages, collapse, `weight_lost_frac` | Needs |
| HUD | out | stages for need icons | Needs |
| Food (VS), Water (VS) | in | food and water items through Item DB | Item DB |
| Medical Check-ins (VS) | out | `weight_kg`, `weight_lost_frac`, hydration | Needs |
| Tap-out & Run Results (VS) | out | `needs_died(dehydration)`, final weight | Needs |
| Save/Load (Alpha) | out | all state fields, grace timer, starving timer | Needs |

## Formulas

**N1 — Calorie burn.** The `burn_kcal_per_hour` formula is defined as:

`burn_kcal_per_hour = (is_asleep ? base_asleep : base_awake) + max(activity_extra) + (is_shivering ? shiver_extra : 0)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_awake | float | 60–160 | data file | default 110 kcal/h |
| base_asleep | float | 40–100 | data file | default 65 kcal/h |
| activity_extra | float | 0–300 | data file | walk 60 · wade 120 · light work 80 · heavy work 200; 0 asleep |
| shiver_extra | float | 0–150 | data file | default 80 kcal/h |

**Output Range:** 65–390 kcal per hour. **Example:** a typical day 1 — 4 h heavy work, 5 h walking, 5 h idle, 3 h of them shivering, 10 h asleep: 14 × 110 + 4 × 200 + 5 × 60 + 3 × 80 + 10 × 65 = **3,530 kcal**.

**N2 — Stomach and weight.** The `stomach_and_weight` update is defined as (per game minute):

`burn = burn_kcal_per_hour / 60`
`stomach_kcal' = max(0, stomach_kcal − burn)`
`weight_kg' = weight_kg − max(0, burn − stomach_kcal) / kcal_per_kg`
`fullness = stomach_kcal / kcal_per_fullness`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| stomach_capacity | float | 800–2500 | data file | max stomach, kcal (default 1,500) |
| kcal_per_fullness | float | — | calculated | `stomach_capacity / 100` (15) |
| kcal_per_kg | float | 7000–8000 | constant | 7,700 kcal per kg of body reserve |
| start_weight_kg | float | 50–100 | data file | default 72.0 |
| weight_floor_kg | float | 30–60 | data file | weight never drops below this (default 40); Medical (VS) evacuates long before |

**Output Range:** weight change 0 to −0.05 kg per game hour. **Examples:** a fasting working day (3,530 kcal, empty stomach): **−0.46 kg**; a fasting idle day (2,190 kcal): **−0.28 kg**; 30 working days on half rations: ≈ **−7 kg (≈ 10 %)**. Starting stomach 1,200 kcal, one idle awake hour → 1,090 kcal, fullness **72.7**.

**N3 — Hydration.** The `hydration_rate` formula is defined as (per game hour):

`hydration_rate = −(is_asleep ? h_asleep : h_awake) × (heavy_or_wading ? h_work_mult : 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| h_awake | float | 0.5–3 | data file | default 1.4 per hour |
| h_asleep | float | 0.2–2 | data file | default 0.7 per hour |
| h_work_mult | float | 1–2 | data file | default 1.5 |
| drink_hydration | float | 0–50 | data file (Item DB) | per drink; snow handful +3 (MVP) |
| dehydration_grace_h | float | 2–24 | data file | default 6 game hours at 0 before death |

**Output Range:** −2.1 to −0.7 per hour. **Example:** a day with 4 h heavy work, 10 h other awake, 10 h asleep: 4 × 2.1 + 10 × 1.4 + 10 × 0.7 = **−29.4 per day** → from 100 with nothing to drink, hydration hits 0 on day 4 and death follows 6 game hours later. Ten handfuls of snow (+30) cost 30 game minutes and 10 energy.

**N4 — Energy.** The `energy_rate` formula is defined as (per game hour):

`energy_rate = is_asleep ? e_sleep × q_warm[body_stage] × q_food : (resting_at_fire ? +e_rest : −(max(e_activity) + (is_shivering ? e_shiver : 0)) × thirst_mult × starve_mult)`
`q_food = q_food_min + (1 − q_food_min) × min(1, fullness / q_food_full)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| e_sleep | float | 4–12 | data file | default 8 per hour |
| q_warm | float[5] | 0–1 | data file | Warm 1.0 · Chilled 0.7 · Cold 0.4 · Hypothermic 0.2 · Critical 0 |
| q_food_min | float | 0.2–0.8 | data file | recovery on an empty stomach (default 0.5) |
| q_food_full | float | 20–100 | data file | fullness for full recovery (default 50) |
| e_activity | float | 0–8 | data file | idle 1.0 · walk 2.0 · light 2.5 · wade 3.5 · heavy 5.0 |
| e_shiver | float | 0–3 | data file | default 1.5 |
| e_rest | float | 0–4 | data file | resting by a burning fire in `wait` mode, default 1.5 |
| thirst_mult | float | 1–1.5 | data file | 1.2 when Thirsty or Parched, else 1 |
| starve_mult | float | 1–1.5 | data file | 1.2 when Starving, else 1 |

**Output Range:** −9.4 ((5.0 + 1.5) × 1.2 × 1.2: heavy work, shivering, thirsty and starving) to +8 per hour. **Examples:** the day-1 schedule above drains about **−40 energy**; 10 h of warm, fed sleep restores **+80**; the same sleep on an empty stomach **+40**; sleeping Chilled and empty: **+28**. A hungry, cold run cannot fully recover — the long slide.

**N5 — Energy cap.** The `energy_cap` formula is defined as:

`energy_cap = max(cap_floor, 100 × (1 − cap_loss_mult × weight_lost_frac))`, `weight_lost_frac = (start_weight_kg − weight_kg) / start_weight_kg`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| cap_loss_mult | float | 0–4 | data file | default 2.0 |
| cap_floor | float | 30–90 | data file | default 60 |
| weight_lost_frac | float | 0–0.45 | calculated | |

**Output Range:** 60–100. **Example:** 10 % lost → **80**; 20 % lost → **60** (floor). Thinner bodies have less in them.

**N6 — Stages** (lookup, Core Rule 10): thresholds and effects are data-file values; thresholds strictly decreasing per need, hysteresis +2.

*systems-designer + economy-designer lenses applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: weight falling forever — floored at 40 kg; eating past capacity — refused, so no "fill up then fast" exploit beyond 1,500 kcal; snow as free unlimited water — costs time and energy; `start_weight_kg = 0` (division in N5 and Morale F4) — rejected at load, floor 50; collapse loop after a forced wake — energy floor 5. Faucets/sinks: kcal faucet = food items only (kit in the MVP; Food in the VS); sinks = burn (N1). With no faucet the stomach empties in under 10 hours of work — the brief's "第 3 天起饱腹不够" holds as long as the MVP kit carries roughly 2 days of food (Item DB). Feedback loops named: hungry → poor sleep → tired → clumsy (more failures, Mishaps) → slower work → less food (VS) — intended slow slide, damped by naps by the fire (+1.5/h) and the 0.5 recovery floor; weight loss → lower energy cap → less work — intended, floored at 60.*

## Edge Cases

- **If the player tries to eat with the stomach nearly full**: refuse if `stomach_kcal + food_kcal > stomach_capacity`; the item is kept, and the refusal is shown ("吃不下").
- **If the player tries to sleep with energy ≥ 90 at night or ≥ 50 by day**: refuse ("还不困").
- **If energy hits 0 in deep cold**: collapse anyway; Body Temperature's wake rule will wake them at Cold, energy is floored at 5, and they have minutes to act — collapse in the cold is a real danger by design.
- **If several wake causes arrive in the same minute**: one wake, causes logged.
- **If Time reports `normal` while the player is awake**: nothing changes.
- **If the player is asleep and energy reaches the cap**: natural wake, `request_rate_mode(normal)`.
- **If hydration reaches 0 and the player drinks within the grace**: timer resets; no damage carries over.
- **If hydration is 0 for exactly 6.0 game hours**: `needs_died(dehydration)` fires once on that tick; Body's hypothermia death takes precedence if both happen in the same tick (one death, cold cause).
- **If weight reaches `weight_floor_kg`**: hold there; burn shortfall is ignored (Medical should have evacuated — log a warning).
- **If the player eats while Empty or Starving**: the stage returns to Hungry or Fed at once and the 24-hour starving timer resets.
- **If an item has no `food_kcal`/`drink_hydration`**: it cannot be eaten/drunk; no default value is assumed.
- **If `start_weight_kg` ≤ 0 or `stomach_capacity` ≤ 0 in data**: reject at load, use defaults.
- **If the player eats snow while Hypothermic**: allowed, but refused in Critical by Body's whitelist (O1 resolved by Scott, 2026-11-19); see Open Questions about a core-temperature cost.
- **If a save is loaded mid-sleep**: restore `is_asleep` and request Time `sleep` on the first tick (matches Time's load rule).

## Dependencies

**Upstream — hard:**
- **Time & Day Cycle** (approved) — tick, `is_night`, rate modes.
- **Body Temperature** (approved) — `is_shivering`, `stage`, `wake_request`.
- **Item Database & Inventory** — food and drink values, item consumption (not yet written — provisional fields `food_kcal`, `drink_hydration`, `eat_minutes`).

**Upstream — soft:** Character Controller (movement activity), Interaction (work activity and eat/drink/sleep actions), Food and Water (VS, through Item DB).

**Downstream:** Morale & Mental State (hard: `fullness`, `weight_kg`, `start_weight_kg`, `is_asleep`), Body Temperature (`is_asleep`), Time (mode requests), Mishaps (`fatigue_penalty`), Interaction (`needs_action_mult`, refusals), Character Controller (`needs_move_speed_mult`), Emotional Feedback, HUD, Medical Check-ins (VS), Tap-out & Run Results (VS), Save/Load (Alpha).

**Bidirectional check:** the systems index lists Needs → Time, Body Temperature, Item DB (matches). Morale lists Needs for `fullness`, `weight_kg`, `start_weight_kg`, `is_asleep` (all provided). Body lists Needs for `is_asleep` and as consumer of `is_shivering`, `stage`, `wake_request` (matches). Time lists Needs as the `sleep`/`normal` requester and states that `is_asleep` is Needs' contract (matches — Rule 9 also handles Time `normal` interrupts). Gaps for later GDDs: Mishaps, Interaction and Character Controller must list Needs as an input (index rows do not yet).

## Visual/Audio Requirements

*art-director lens applied (the player reads tiredness and hunger from the body), against `design/art/art-bible.md` §1–4.*
- **Tired:** slower walk cycle, a hand on the knee when stopping. **Exhausted:** dragging feet, sways when idle. **Collapse:** a slow kneel then lying in the snow, camera holds wide (the show's framing) — readable at the far camera (§1 大块面).
- **Hungry:** hand-to-stomach idle (shared with Morale's H cue). **Thirsty / Parched:** wipes mouth, cracked breath sound; eating snow is a visible kneel-and-scoop.
- **Sleep:** lying by the fire, fire glow on the figure; waking is a sit-up beat.
- **Weight (VS option):** a thinner silhouette blend at 10 % and 20 % lost; until then, weight is seen only at weigh-ins and in the diary.
- **Audio:** stomach growl (rare, ~once per game hour when Hungry), heavy breathing when Exhausted, the crunch of snow being eaten.
- **Colourblind** (§4): need icons use shapes, not colours alone.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:needs-and-weight` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Choices, not chores.** Needs should create decisions (work more vs rest; eat now vs keep the ration; sleep now vs tend the fire) — never a list of bars to refill. No need should demand attention more than about once per game hour.
- **Slow pressure.** Hunger and weight act over days, thirst over half a day, energy over hours: three different clocks.
- **Collapse is a story.** Collapsing exhausted in the snow should be one of the most memorable bad moments of a run, not a punishment out of nowhere — Tired and Exhausted posture must give a clear warning first.
- **Snow is a desperate drink.** Eating snow should feel like the wrong but necessary thing — slow and tiring.

## UI Requirements

- **Need icons, not bars:** a small icon for each need appears on the HUD only when that need is in a warning stage (Tired, Thirsty, Hungry) and grows more prominent at the next stage. Body temperature stays the most prominent element (art bible §7). HUD GDD owns layout.
- **Weight is not on the HUD.** It appears in the diary (VS) and at weigh-ins (Medical, VS) — the slow reveal is the drama.
- **Refusal feedback:** "吃不下", "还不困", heavy-work refusal shown as short diegetic lines or gestures.
- **Debug overlay (dev only):** stomach kcal, fullness, weight, weight lost %, hydration, energy and cap, burn per hour, stages, sleep state, timers.

> **📌 UX Flag — Needs & Weight**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2, 9 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | tick, `sleep`/`normal` requests, `rate_mode_changed` | approved — matches |
| Rules 3, 8, 9 | Body Temperature (`design/gdd/body-temperature.md`) | `is_shivering`, `stage`, `wake_request`; `is_asleep` out | approved — matches |
| Rule 12 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `fullness`, `weight_kg`, `start_weight_kg`, `is_asleep` (F4, F1) | in review — matches |
| Rules 5, 6 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | `food_kcal`, `drink_hydration`, `eat_minutes`; MVP kit ≈ 2 days of food | not yet written — provisional |
| Rules 3, 10 | Interaction & Timed Actions, Mishaps & Failure, Character Controller & Animation | activity reports; `fatigue_penalty`, `needs_action_mult`, `needs_move_speed_mult` | not yet written — provisional |
| Rule 12 | Medical Check-ins (`design/gdd/medical-check-ins.md`) | weight thresholds for evacuation | VS |
| Summary | `design/game-brief.md` | "体重是慢慢流失的生命线", "第 3 天起饱腹不够" | exists |

## Acceptance Criteria

Owner decision O1 (2026-11-19): verify snow intake is allowed in Hypothermic on snow and refused in Critical, with no hydration/energy change on refusal. No new core-temperature cost.

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a new run, **THEN** stomach 1,200 kcal (fullness 80), weight 72.0, hydration 100, energy 90, awake.
2. [A] **GIVEN** stomach 1,400 kcal and a 400 kcal ration, **WHEN** eating, **THEN** refused and the ration stays in the inventory; **GIVEN** stomach 1,000, **THEN** stomach 1,400 and the ration is consumed.
3. [A] **GIVEN** energy 95 at night, **WHEN** sleep is requested, **THEN** refused; **GIVEN** energy 45 by day, **THEN** allowed, `is_asleep` true and Time mode `sleep`.
4. [A] **GIVEN** asleep below the energy cap, **WHEN** Fire goes Out and Body does not emit a cold wake and no other valid interruption occurs, **THEN** remain asleep. **WHEN** Body emits `wake_request(cold)`, **THEN** clear `is_asleep` and return Time to `normal` before the next owed minute; **WHEN** instead Time reports `rate_mode_changed(normal)` from a valid interruption, **THEN** also awake.
5. [A] **GIVEN** awake with energy 0.1 and heavy work, **WHEN** energy reaches 0, **THEN** collapse: `is_asleep` true with cause `exhaustion`; **WHEN** woken by Body, **THEN** energy ≥ 5.
6. [A] **GIVEN** hydration 0, **WHEN** 6 game hours pass without drinking, **THEN** `needs_died(dehydration)` once; **GIVEN** a snow handful at 5 h 59 min, **THEN** no death and the timer resets.
7. [A] **GIVEN** Exhausted, **WHEN** the player starts chopping (heavy work), **THEN** refused.
8. [A] **GIVEN** Exhausted and Parched, **THEN** `fatigue_penalty` = 0.15 and `needs_action_mult` = 1.375.

**States**
9. [A] **GIVEN** energy falling through 25 and 10, **THEN** Tired then Exhausted with one `needs_stage_changed` each; rising, Exhausted holds until 12 and Tired until 27.
10. [A] **GIVEN** fullness 0 for 24 game hours, **THEN** Starving; **WHEN** any food is eaten, **THEN** not Starving and the timer resets.

**Formulas**
11. [A] N1: awake + heavy work + shivering → 390 kcal/h; asleep → 65; awake idle → 110; walking and heavy work reported together → 310 (highest, not sum).
12. [A] N2: stomach 0, burn 3,530 kcal over 24 h → weight −0.458 ± 0.002 kg; stomach 1,200 + one idle hour → 1,090 and fullness 72.7 ± 0.1; weight at the 40 kg floor stays 40.
13. [A] N3: 1 h awake idle → −1.4; 1 h heavy work → −2.1; 1 h asleep → −0.7.
14. [A] N4: 10 h sleep, Warm, fullness ≥ 50 → +80 (capped at `energy_cap`); fullness 0 → +40; Chilled and fullness 0 → +28; 1 h resting at a burning fire → +1.5.
15. [A] N5: 10 % weight lost → cap 80; 20 % → 60; 30 % → 60 (floor).
16. [A] Snow: one handful → hydration +3, energy −1, 3 game minutes.

**Cross-system & feel**
17. [A] **GIVEN** Needs reports fullness 40 and 6 % weight lost, **WHEN** Morale ticks, **THEN** Morale's H = 52 (integration with F4).
18. [A] **GIVEN** a full simulated day 1 (the N1 schedule, one 400 kcal ration eaten at 18:00, 10 snow handfuls), **THEN** end-of-day weight ≥ 71.7 kg, hydration ≥ 70, energy ≥ 50 after sleep.
19. [P] **GIVEN** the MVP's first three days, **WHEN** the owner plays, **THEN** they report feeling hunger by day 3 and making at least one eat-or-keep decision (brief: "第 3 天起饱腹不够").
20. [P] **GIVEN** an exhaustion collapse, **WHEN** watched, **THEN** testers saw Tired/Exhausted posture before it (no "out of nowhere").

**Performance:** ≤ 0.02 ms per tick.

*QA gaps found and resolved: eat refusal (2), sleep permission (3), double wake path (4), collapse floor (5), grace reset (6), combined stage effects (8), weight floor (12). Feel lines moved to playtest criteria 19–20.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Should eating snow also cost core temperature (realistic)? Needs a new `cold_intake` input on Body Temperature (approved GDD — would need a revision). | owner + systems-designer | before Water GDD (VS) | if yes, revise Body Temperature with a small instant core drop per handful |
| Can weight ever be regained (big catch, feast)? MVP: never. | game-designer | Food GDD (VS) | allow slow regain above fullness 80 if wanted |
| Is 3,500 kcal/day for a working day right, and does the MVP kit hold ~2 days of food? | economy-designer | Item DB / Kit Selection GDDs | the kit sets the "day 3" hunger beat |
| Should low fullness reduce body heat production (thin people get colder)? Raised by Body Temperature. | systems-designer | MVP playtest | add a fullness factor to Body's activity heat via a new input |
| Does the thinner silhouette (VS) justify the art cost? | art-director | Emotional Feedback GDD | — |
