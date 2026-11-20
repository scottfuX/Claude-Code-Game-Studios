# Fire

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / systems-designer / art-director lenses)
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 苦中有美 · 亲手做 · 越活越懂

## Summary

Fire is the game's heart: the only warm thing in a cold world. The survivor builds it by hand in steps — clear the snow, ring it with stones, lay tinder and kindling, strike the ferro rod, blow the ember into flame, feed it logs — and then keeps it alive through the night against wind, damp wood and their own need to sleep. A fire's size sets how much heat and light it gives and how fast it eats wood; when it runs low it sinks to embers that can still be saved, and when it dies while you are away or asleep, it is a small grief. It is the reason to gather, the place to rest, and the image of "活下去的东西是暖的".

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Interaction & Timed Actions, Item Database & Inventory, Thermal Environment, Mishaps & Failure, Time & Day Cycle`

## Overview

A fire is a world object at a fire site with a **stage** (Core Rule 3), a **fuel load** `F` in fuel units (the sum of what has been added, Formula FI5), and a **burning wetness**. Every game minute it burns fuel at a rate set by its size and the wind at the spot (FI4), and from its fuel it derives its heat and warm radius (FI1–FI3), which it registers with Thermal Environment as a heat source — the `warm_radius` Morale reads — and its light radius (FI6), which rendering uses. The build is a sequence of Interaction actions whose outcomes Mishaps rolls (strike and blow have real failure chances, driven by damp tinder, wind and poor tinder); the player learns to make each step reliable: birch bark over grass, dry kindling from standing bushes, a stone ring and a site in the lee.

For the player it is the first goal ("天黑前要有火"), the evening ritual (sit, warm hands, the camera pulling back), and the night's quiet worry: four logs at bedtime last about five game hours before the fire sinks to embers, and the coals hold for another hour and a half before they die. At the default numbers a night needs about eight logs (two loads from the near wood — Gathering G4), and the near ring of the map holds about the first night (Map MR4). Fire owns none of the body's warming (Body Temperature, through Thermal), the gathering (Gathering), the failure odds (Mishaps) or the cooking and water boiling of the VS (Food, Water).

## Detailed Design

### Core Rules

1. **Fire sites.** A fire can be built on ground that is flat (≤ 8°), not ice, not drift deeper than 0.6 m, and inside the map (Terrain, Map). Bare rock needs no clearing. Up to 2 fires may exist at once (Thermal sums them under its heat cap). Map's three unlabelled lee sites are simply good places.
2. **The build sequence** (each step is an Interaction action; the site's first available action changes as the stage advances):

   | Step | Action (Interaction) | Needs | Result |
   |---|---|---|---|
   | 1 | clear_snow (5 game min, heavy) | a valid site | stage Cleared |
   | 2 (optional) | place_stones (3 min, light) | 6 stones in the pack | Ringed: wind on this fire ×0.6 (FI4) |
   | 3 | carve_feather_stick (3 min, light, knife) — optional, any time | 1 dry stick | 1 feather stick (tinder) |
   | 4 | arrange_tinder (2 min, light) | tinder (2 birch bark, or 3 dry grass, or 1 feather stick) + kindling (4 dry sticks) | stage Laid; the items move into the fire, their wetness recorded |
   | 5 | strike (repeat, 0.5 min per strike, ferro rod) | Laid | Mishaps `strike` (tinder wetness and quality, wind): success → Smoldering |
   | 6 | blow_embers (1 min, light) | Smoldering, within `ember_window` (3 game min) | Mishaps `blow_embers` (kindling wetness, wind): success → Kindling flame; failure → tinder consumed, back to Cleared/Ringed (kindling kept) |
   | 7 | add_fuel (0.5 min, light) | Kindling flame or Burning or Embers; a fuel item | fuel added (FI5) |

   If no blow happens within the ember window, the ember dies the same way as a failed blow. The tinder used by a successful light is consumed into the fire's fuel.
3. **Stages by fuel** (after lighting):

   | Stage | Fuel F (units) | What it does |
   |---|---|---|
   | Kindling flame 小火 | 5 ≤ F < 30 | small flame; heat and radius per FI1–FI3; a damp log can smother it (Rule 6) |
   | Burning 燃烧 | F ≥ 30 | the real fire; up to `F_max` 300 units (≈ 5 logs) |
   | Embers 余烬 | F < 5, or F reached 0 within the last `ember_life` (90 game min) | red coals: heat 4 °C, radius 1.0 m, light 1.5 m; add fuel + blow_embers relights without new tinder |
   | Out 熄灭 | embers expired | cold; must be re-laid from step 4 (the site stays Cleared/Ringed) |

   Pre-light stages: Site → Cleared → (Ringed) → Laid → Smoldering.
4. **Burning.** Each game minute the fire burns `burn_rate` units (FI4). Wind at the fire (Thermal `wind_eff` at its position, ×0.6 if Ringed) makes it burn faster.
5. **Fuel and wetness.** Adding an item adds its effective fuel (FI5: damp wood gives less) and mixes its wetness into the fire's burning wetness, which dries at 0.05 per game minute while burning. Burning wetness lowers heat (FI2) and makes the fire smoke.
6. **Smothering.** Adding a log with wetness > 0.6 to a fire in Kindling flame (F < 30) smothers it to Embers (hiss, white smoke) — the cause is visible; dry the log at the fire first (Inventory camp piles) or build the flame up with sticks.
7. **Too big.** Adding fuel that would push F above `F_max` is refused ("火已经够大了").
8. **Heat and light** (FI1–FI3, FI6) update each game minute. Exact heat/radius/enabled values are published to Thermal via `register_heat_source` / `update_heat_source` before Body queries that minute, regardless of change magnitude; rendering reads the visual values. Source records contain `{position, heat_c, radius_m, enabled}` (`enabled` false at Out). `warm_radius` = the registered `radius_m` (Morale's contract). Inventory piles within `warm_radius` are camp piles and dry.
9. **Unattended death.** When a fire goes Out while the survivor is asleep or more than 15 m away, emit `loss{kind: fire_died_unattended}` (Morale: G +10, F +8). Watching it die while awake and near is not a loss event.
10. **No wake-up from Fire.** Fire does not wake the sleeping survivor; the body does (Body Temperature wakes them when Cold). The dying fire and the cold that follows are the night's story.
11. **Fire tending in Critical.** `add_fuel` and `blow_embers` are `critical_allowed` (Interaction): a crawling survivor can still save the fire.
12. **Rest and ritual.** `sit_warm` and `rest` target a Burning fire (Interaction); Morale's fire ritual uses `fire_burning` (stage Kindling flame or Burning) and `warm_radius`.
    The [Food chapter proposal](food.md#core-rules) uses a Burning campfire's existing context verbs and read-only interaction state. Fire burns normally and does not own the cooking transaction.

### States and Transitions

| From | To | Condition |
|---|---|---|
| Site | Cleared | clear_snow completes (or rock: immediate) |
| Cleared | Ringed | place_stones completes (optional) |
| Cleared / Ringed | Laid | arrange_tinder completes |
| Laid | Smoldering | a successful strike |
| Smoldering | Kindling flame | a successful blow_embers within `ember_window` |
| Smoldering | Cleared / Ringed | blow fails or the window expires (tinder consumed) |
| Kindling flame | Burning | F ≥ 30 |
| Burning | Kindling flame | F < 30 |
| Kindling flame | Embers | F < 5, or smothered (Rule 6) |
| Embers | Kindling flame / Burning | fuel added and a successful blow_embers |
| Embers | Out | `ember_life` passes with no relight (→ `fire_died_unattended` if unattended) |
| Out | Laid | arrange_tinder again (site keeps Cleared/Ringed) |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Interaction & Timed Actions (approved) | in/out | in: completed fire actions (resolver = Fire); out: available actions per stage on the fire's interactable | Interaction / Fire |
| Mishaps & Failure (approved) | in/out | out: material for `strike` (tinder wetness, quality) and `blow_embers` (kindling wetness), fire position; in: outcomes | Mishaps |
| Item Database & Inventory (approved) | in/out | in: fuel_value, tinder_quality, wetness of items; out: consume items; `warm_radius` for camp piles | Inventory |
| Thermal Environment (approved) | in/out | in: `wind_eff` at the fire; out: heat source `{position, heat_c, radius_m, enabled}` | Thermal (registry) / Fire (values) |
| Time & Day Cycle (approved) | in | `minute_tick` | Time |
| Morale & Mental State | out | `fire_burning`, `warm_radius`, `loss{fire_died_unattended}` | Fire |
| Gathering | — | supplies fuel and tinder via Inventory | — |
| Terrain / Map (approved) | in | site validity (slope, type), good lee sites; proposed Chapter 2 reservation input below | Terrain / Map |
| Body Temperature (approved) | — | warmed through Thermal only | — |
| Emotional Feedback / rendering | out | stage, light radius, smoke (burning wetness), smother and ember-death events | Fire |
| Camera (approved) | — | ritual framing is requested by Emotional Feedback | — |
| Food, Water, Shelter (VS) | out | burning fire for cooking/boiling; shelter reflects heat (Thermal) | Fire |
| Save/Load (Alpha) | out | stage, F, burning wetness, ember timer, position, ring | Fire |

## Formulas

**FI1 — Size factor.** The `fire_size` formula is defined as:

`s = 1 − exp(−F / f_scale)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| F | float | 0–300 | calculated | fuel units on the fire |
| f_scale | float | 30–120 | data file | default 60 (one dry log) |

**Output Range:** 0–0.993. **Examples:** F 26 (kindling) → **0.35**; 60 → **0.632**; 120 → **0.865**; 240 → **0.982**.

**FI2 — Heat at the centre.** The `heat_c` formula is defined as:

`heat_c = Embers ? heat_embers : h_max × s × (1 − w_pen × w_burn)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| h_max | float | 15–35 | data file | default 28 °C (below Thermal's 30 cap) |
| w_pen | float | 0–0.6 | data file | default 0.4 |
| w_burn | float | 0–1 | calculated (FI5) | burning wetness |
| heat_embers | float | 0–8 | data file | default 4 °C |

**Output Range:** 0–27.8 °C. **Examples:** F 120 dry → **24.2 °C**; F 120 at w_burn 0.3 → **21.3 °C**; F 26 → **9.8 °C**; Embers → **4 °C**.

**FI3 — Warm radius.** The `radius_m` formula is defined as:

`radius_m = Embers ? r_embers : r_min + r_span × s`

**Variables:** `r_min` 0.8 m, `r_span` 2.6 m, `r_embers` 1.0 m (data file). **Output Range:** 0.8–3.38 m (≤ Thermal's 6 m limit, > 0). **Examples:** F 120 → **3.05 m**; F 26 → **1.71 m**. A "strong fire" of 2–3 logs on (F 120–180) gives **24–27 °C / 3.0–3.3 m** — Thermal's and Body Temperature's 25 °C / 3 m example sits inside.

**FI4 — Burn rate.** The `burn_rate` formula is defined as (fuel units per game minute):

`burn_rate = (b0 + F / b_div) × (1 + k_wind × wind_eff × (ringed ? ring_mult : 1))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| b0 | float | 0.05–1.0 | data file | idle burn (default 0.25) |
| b_div | float | 60–600 | data file | default 240 (bigger fires burn faster) |
| k_wind | float | 0–0.3 | data file | default 0.08 per m/s |
| wind_eff | float | 0–25 | calculated (Thermal) | at the fire |
| ring_mult | float | 0.3–1 | data file | default 0.6 |

Solved, the fuel falls as `F(t) = (F0 + b0·b_div) · e^(−t·w/b_div) − b0·b_div`, `w` = the wind factor.

**Output Range:** 0.25–2.2 units/min. **Examples:** F 120, open snow (wind_eff 2.4), ringed (×0.6 → 1.44) → (0.25 + 0.5) × 1.115 = **0.84 /min ≈ 0.84 dry logs per game hour**. **Bedtime 4 dry logs (F 240), ringed, open snow:** reaches Kindling (F 30) after **4.3 game h**, Embers (F 5) after **5.5 h**, Out after **7.0 h** (+ 90 min of coals) — laid at 21:00, the flame shrinks to a small fire around 01:20, sinks to embers around 02:30, and the coals die around 04:00. Unringed: Embers after **5.1 h**.

**FI5 — Adding fuel.** The `add_fuel` update is defined as:

`F' = min(F_max, F + fuel_value × (1 − k_damp_fuel × wetness))`
`w_burn' = (w_burn × F + wetness × added) / F'`, then while burning `w_burn −= w_dry` per game minute (floor 0)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| fuel_value | float | 0–100 | data file (Item table) | stick 6 · log 60 · birch bark 1 · grass 0.5 · feather stick 3 |
| wetness | float | 0–1 | calculated (Inventory) | of the item |
| k_damp_fuel | float | 0–0.6 | data file | default 0.3 |
| F_max | float | 120–600 | data file | default 300 |
| w_dry | float | 0–0.2 | data file | default 0.05 per game minute |

**Output Range:** F 0–300. **Examples:** a deadfall log at 0.3 → **54.6 units**; 4 kindling sticks + 2 bark (dry) at light → **F 26**; adding a 0.3 log to F 120 → F 174.6, w_burn **0.094**, dry again in **≈ 2 game min**.

**FI6 — Light radius.** The `light_radius_m` formula is defined as:

`light_radius_m = Embers ? 1.5 : 1.5 + 5.0 × s`

**Output Range:** 1.5–6.5 m. **Example:** F 120 → **5.8 m** (art bible §2: "火光是唯一暖光，半径约 6 m").

**Night need (derived check).** Keeping F ≈ 120 from nightfall (17:15) to bedtime (21:00) costs ≈ 3.2 dry logs; 4 logs at bedtime; ≈ 7–8 logs a night plus the first fire's kindling — matching Gathering's G4 ("a night's 8 logs") and Map's near ring (18 logs ≈ the first two nights).

*systems-designer + economy-designer lenses applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: unbounded fuel stacking — `F_max` 300; `b_div` = 0 — rejected at load (≥ 60); heat above Thermal's 30 cap — `h_max` 28; radius 0 would be rejected by Thermal — `r_min` 0.8 / embers 1.0; wet wood farming a "free" smoky fire — `k_damp_fuel` 0.3 and heat penalty; infinite embers — `ember_life` 90 min. Feedback loops: bigger fire → burns faster (negative loop, damps hoarding fuel on the fire); wind → faster burn → more wood → more trips in the cold (intended; the stone ring and lee sites are the player's answer).*

## Edge Cases

- **If the survivor tries to build on ice, a drift or a slope > 8°**: refused ("这里不能生火").
- **If arrange_tinder lacks tinder or 4 sticks**: refused with what is missing ("缺引火物" / "缺细柴").
- **If the ember window expires while the player is moving or cancels**: the ember dies, tinder consumed.
- **If a damp log is added to a Kindling flame**: smothered to Embers (Rule 6), log kept as fuel in the embers.
- **If fuel would exceed 300**: refused, item kept.
- **If two fires overlap**: each registers its own source; Thermal sums under its 30 °C cap.
- **If the fire goes Out while the survivor is asleep 2 m away**: `fire_died_unattended` (asleep counts as unattended).
- **If strong wind (VS storms, wind_eff 15) hits an unringed small fire**: burn rate rises ×2.2; a Kindling flame burns through in minutes — protect it first.
- **If the survivor is in Critical**: add_fuel and blow_embers still work; striking and laying tinder do not.
- **If a save is loaded**: stage, F, burning wetness and ember timer restore; Thermal source re-registers before the first tick (Thermal load rule).
- **If the fire's site is snowed over (VS) while Out**: the site reverts to uncleared.
- **If the player relights from Embers with a damp log and fails the blow**: still Embers (no tinder at stake); try again until `ember_life` runs out.

## Dependencies

**Upstream — hard:** Interaction & Timed Actions, Item Database & Inventory, Thermal Environment, Mishaps & Failure, Time & Day Cycle (all approved).

**Upstream — soft:** Gathering (fuel and tinder), Terrain / Map (sites), Weather (VS).

**Chapter 2 forward link:** [Map](map-and-resource-distribution.md#interactions-with-other-systems) owns the proposed query for the authored [Shelter](shelter.md#cross-references) reservation. After the Shelter architecture gate, FireController adds the query to Rule 1's new-site validation for this chapter only: refuse a fire footprint that touches or overlaps the reservation, even before framing. The apron still uses ordinary site checks. No first-night or Fire stage, heat or sleep rule changes.

**Downstream:** Thermal (heat source), Body Temperature (via Thermal), Morale (`fire_burning`, `warm_radius`, unattended loss), Inventory (camp piles), Needs & Weight (`resting_at_fire` via Interaction), Emotional Feedback / rendering (light, smoke), Ambient & Foley Audio (crackle), Food / Water / Shelter (VS), Save/Load.

**Bidirectional check:** the systems index lists Fire → Interaction, Item DB, Thermal, Mishaps, Time (matches). Thermal expects heat sources with `heat_c` ≤ cap and `radius_m` > 0 and Fire's `warm_radius` = registered radius (matches FI2–FI3, Rule 8). Morale expects `fire_burning`, `warm_radius`, `fire_died_unattended` (matches Rules 9, 12). Mishaps' `strike` and `blow_embers` profiles and their on-fail effects (ember dies, tinder consumed) are implemented here (matches). Inventory's provisional `fuel_value` (stick 6, log 60, bark 1, grass 0.5) are **confirmed**; `tinder_quality` confirmed; a new item `feather_stick` (tinder, quality 0.8, fuel 3, mass 0.2, wetness = source stick × 0.5) is needed — flag for Inventory's table. Interaction's catalogue (clear_snow, place_stones, arrange_tinder, carve_feather_stick, strike, blow_embers, add_fuel, sit_warm, rest) matches. Body Temperature and Needs & Weight listed Fire as an optional low-fire waker — decided no (Rule 10). Gathering G4 and Map MR4 fuel estimates match the night need.

## Visual/Audio Requirements

*art-director lens applied (fire is the warmest, brightest thing on screen), against `design/art/art-bible.md` §1, §2, §4, §6.*
- **The only warm light** (§1): ember_yellow `#FFC66B` core and warm_orange `#F08A4B` outer flame; the fire is the only self-lit object (§4). Light radius tracks FI6 (≈ 6 m at a good fire, §2); the warm core ≤ 3 m reads as a slightly stronger tint on the snow (Thermal visual note).
- **Every build step is visible** (§3 人造物都是临时的, 亲手做): a dark disk of cleared ground, a crooked ring of grey stones, a small tepee of sticks over pale bark, sparks on each strike, a thin smoke thread when smoldering, the first curl of flame.
- **Size reads from silhouette**: flame height and flicker scale with `s`; embers are a dull red glow without flame.
- **Wetness reads**: grey-white smoke rises with `w_burn`; a smother is a hiss and a burst of white smoke.
- **Wind reads**: flames lean with wind; the ring visibly shields them.
- **Audio:** crackle loudness with `s`; pops from damp wood; the hiss of a smother; the silence when it goes out.
- **Ritual frame** (Morale / Camera): the camera's slow pull-back on a fire ritual keeps the fire as the composition's warm centre.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:fire` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Lighting a fire is the best moment of a day.** The struggle (strikes, a held breath while blowing) ends in warm light spreading over the snow — the brief's "火苗燃起时画面里第一次出现暖光".
- **Keeping it is a responsibility.** A fire left alone for an hour shrinks visibly; at night the player chooses between sleeping and feeding it.
- **Craft pays.** A ringed fire in the lee with dry bark and standing sticks lights in one or two strikes and lasts; a careless fire in the open wind eats wood and dies.
- **Losing it hurts, saving it heals.** Coming back to embers and blowing them back to flame should feel like a small rescue.

## UI Requirements

- **None in play.** Stage, size and health are read from flame, light, smoke and sound. Prompts come from Interaction ("清雪", "围石", "放引火物", "打火", "吹", "添柴").
- **Debug overlay (dev only):** stage, F, burn rate, w_burn, heat, radius, light radius, ember timer, wind at fire.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 8, FI2–FI3 | Thermal Environment (`design/gdd/thermal-environment.md`) | heat source contract; 25 °C / 3 m example; heat cap 30 | approved — matches |
| Rules 2, 6 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | strike and blow_embers profiles, on-fail effects | approved — matches |
| FI5, Rule 2 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | fuel_value / tinder_quality confirmed; new item feather_stick | approved — flag item addition |
| Rule 2 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | fire actions and their availability by stage | approved — matches |
| Rules 9, 12 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `fire_burning`, `warm_radius`, `fire_died_unattended` | in review — matches |
| Rule 10 | Body Temperature, Needs & Weight | no Fire wake-up | approved — consistent |
| Night need | Gathering (`design/gdd/gathering.md`), Map (`design/gdd/map-and-resource-distribution.md`) | 8 logs per night; near ring 18 logs | designed / approved — matches |
| Visual | `design/art/art-bible.md` §1, §2, §4 | warm palette, 6 m light, fire the only light source | exists |
| Summary | `design/game-brief.md` | "天黑前要有火", first warm light | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a flat open-snow site, **WHEN** clear_snow completes, **THEN** Cleared; **GIVEN** lake ice, **THEN** refused.
2. [A] **GIVEN** Cleared and 2 birch bark + 4 dry sticks, **WHEN** arrange_tinder completes, **THEN** Laid and those items leave the backpack; **GIVEN** only 3 sticks, **THEN** refused "缺细柴".
3. [A] **GIVEN** Laid, **WHEN** a strike succeeds, **THEN** Smoldering; **WHEN** no blow within 3 game minutes, **THEN** back to Cleared, tinder consumed, sticks kept.
4. [A] **GIVEN** Smoldering, **WHEN** blow_embers succeeds, **THEN** Kindling flame with F = 26 ± 0.5 (dry bark + sticks).
5. [A] **GIVEN** Kindling flame (F 26), **WHEN** a log at wetness 0.8 is added, **THEN** Embers (smothered).
6. [A] **GIVEN** F 280, **WHEN** a log is added, **THEN** refused "火已经够大了".
7. [A] **GIVEN** a Burning fire, **THEN** Thermal holds a source at its position with heat and radius per FI2–FI3, and Morale's `warm_radius` equals that radius.
8. [A] **GIVEN** the survivor asleep 2 m away, **WHEN** the fire goes Out, **THEN** one `loss{fire_died_unattended}`; **GIVEN** awake 2 m away, **THEN** none.
9. [A] **GIVEN** Body Critical and Embers, **WHEN** add_fuel and blow_embers are used, **THEN** both are allowed.

**States**
10. [A] **GIVEN** Embers, **WHEN** 90 game minutes pass without relight, **THEN** Out; **WHEN** fuel is added and a blow succeeds before that, **THEN** Kindling flame or Burning.

**Formulas**
11. [A] FI1–FI3: F 120 dry → heat 24.2 ± 0.1, radius 3.05 ± 0.01; F 26 → 9.8 ± 0.1 / 1.71 ± 0.01; Embers → 4.0 / 1.0.
12. [A] FI2: F 120 at w_burn 0.3 → 21.3 ± 0.1.
13. [A] FI4: F 120, wind_eff 2.4, ringed → 0.836 ± 0.005 /min; F 240 ringed open → Kindling at 4.3 ± 0.1 h, Embers at 5.5 ± 0.1 h, Out at 7.0 ± 0.1 h; unringed → Embers at 5.1 ± 0.1 h.
14. [A] FI5: a 0.3 log → +54.6 units; added to F 120 → F 174.6, w_burn 0.094 ± 0.002, 0 after 2 game min of burning.
15. [A] FI6: F 120 → 5.8 ± 0.05 m light; Embers → 1.5 m.
16. [A] Data with `b_div` < 60 or `h_max` ≥ 30 is rejected.

**Cross-system & feel**
17. [A] **GIVEN** a Burning fire at F 120 and the survivor 1.5 m away on night 1 at 02:30 (open snow), **THEN** Thermal reports felt ≈ +6.5 °C (−11.9 + 18.4) and Body warms (integration with Thermal TH5 and Body B1).
18. [P] **GIVEN** the owner's first MVP afternoon, **THEN** they light the first fire before dark and describe the moment of flame as a relief (brief's first minute).
19. [P] **GIVEN** a night left with 4 logs at 21:00, **THEN** the owner wakes cold to embers or a dead fire and relights or rebuilds it.
20. [P] **GIVEN** night screenshots of a strong fire, embers and a smoking damp fire, **THEN** testers tell the three apart.

**Performance:** ≤ 0.02 ms per fire per tick; the > 0.1 heat/radius update threshold applies to visuals only. Exact authoritative heat/radius is published to Thermal and available to Body every game minute, including changes ≤ 0.1 (O3 resolved by Scott, 2026-11-19).

*QA gaps found and resolved: site validity (1), missing materials (2), ember window (3), smother (5), fuel cap (6), Thermal/Morale contract (7), unattended rule (8), Critical tending (9), ember life (10). Feel lines moved to playtest criteria 18–20.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Is ~8 logs per night (2 loads) the right cost, and does a 4-log bedtime that dies around 02:30 feel harsh-but-fair? | owner | MVP playtest | tune `b0`, `b_div` (data) |
| Should the stone ring be required (brief: "围石、引火") or optional as here? | owner | MVP playtest | data toggle |
| A banked fire (cover embers with ash for a slow night burn) as a learned technique? | game-designer | VS | add an action |
| Cooking and boiling (VS) need a "pot on fire" state. | game-designer | Food / Water GDDs | — |
| Item DB must add `feather_stick` (tinder 0.8, fuel 3, 0.2 kg). | game-designer | Item DB's next revision | — |
