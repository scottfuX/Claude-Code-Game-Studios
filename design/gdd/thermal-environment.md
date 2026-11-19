# Thermal Environment

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (systems-designer lens)
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-16
> **Implements Pillar**: 冷是真的 · 苦中有美

## Summary

Thermal Environment answers one question for any point in the world at any moment: how cold does it feel here? It combines the air temperature (which falls day after day — the run's cold ramp — and swings between afternoon and night), the place (lake, open snow, forest), the wind, and every registered heat source such as a fire or, later, a shelter. Body Temperature reads the result to cool or warm the survivor; Fire, Shelter and Weather plug into it without depending on each other.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Time & Day Cycle`

## Overview

Thermal Environment is a data layer: a function `effective_temp_c(position)` evaluated on demand, plus the components that build it — `air_temp_c`, `zone_offset_c`, `wind_chill_c` and `heat_c` — so consumers can explain *why* it is cold. It owns the air-temperature curve and the day-over-day cold ramp (handed over by the Time & Day Cycle GDD). Heat sources (Fire in the MVP, Shelter and others later) and chill sources (Weather in the VS) **register** into it through one interface; Thermal sums them, so Fire never needs to know about Shelter and Weather never needs to know about Fire.

For the player, this system is the difference the playtest asked for: "出去体温也没有怎么降". Away from the fire it should be cold enough to bite even on the first afternoon, colder at night and on the open lake, harsher every day; within a few steps of a burning fire it should be warm. The fire's *light* reaches about 6 m (art bible §2) but its *warmth* only about 3 m — the light invites you, the warmth makes you stay close.

What it does **not** own: how fast the body cools (Body Temperature), clothing insulation and wetness (Body Temperature), fire intensity, fuel and radius (Fire), wind speed and cold snaps from the VS onward (Weather & Cold Snaps), map zones (Map & Resource Distribution).

## Detailed Design

### Core Rules

1. **One question, one answer.** `effective_temp_c(p)` = air temperature + zone offset − wind chill + heat from sources at `p` (Formula TH5). It is a felt temperature in °C, not a physical simulation.
2. **Cold ramp.** The daily mean air temperature falls by a fixed amount each day from `t_start` to a floor `t_floor` (TH1). Thermal owns this ramp.
3. **Day and night swing.** Around the daily mean, air temperature follows a 24-hour cosine peaking `peak_lag` hours after solar noon (mid-afternoon) and lowest 12 hours later (TH2). Solar noon is read from Time (`(sunrise_hour + sunset_hour) / 2`).
4. **Zones.** Every point belongs to a zone supplied by Map & Resource Distribution, each with a `zone_offset_c` and a `wind_exposure` (0–1):

   | Zone | zone_offset_c | wind_exposure | Why |
   |---|---|---|---|
   | open snow (default) | 0 | 0.8 | the clearing — exposed |
   | forest | +1 | 0.4 | trees break the wind |
   | lake surface | −3 | 1.0 | the coldest, most exposed place (art bible §4: lake colder) |
   | lee of a rock or drift | 0 | 0.3 | small natural shelter |
   | drift field | 0 | 0.6 | deep drifts, lee faces (Map) |
   | scoured ridge | 0 | 1.0 | hill crest (Map) |

   Where zones meet, both values blend linearly over `zone_blend_m` (default 5 m) so the temperature never jumps on a line. A point with no zone data uses open snow.
5. **Wind.** `wind_speed` (m/s) is a world value. In the MVP Thermal supplies it as a data constant (`wind_base`, default 3 m/s); from the VS, Weather & Cold Snaps registers as the wind source and overrides it. Wind chill scales with wind speed × exposure and is capped (TH3).
6. **Heat sources.** A system registers a heat source with `{id, position, heat_c, radius_m, enabled}` and updates it when it changes. Each contributes heat that falls off to zero at its radius (TH4). All sources at a point are summed, then capped at `heat_cap_c`. Fire is the only MVP source; Fire owns `heat_c` and `radius_m` and publishes that same radius as `warm_radius` (the value Morale reads).
7. **Insulation volumes (VS contract).** A shelter registers a volume `{id, bounds, wind_exposure_override, bonus_c, heat_reflect_mult}`. Inside it, wind exposure is replaced by the override, `bonus_c` is added, and heat from sources inside or at the opening is multiplied by `heat_reflect_mult`. Shelter owns the values; Thermal applies them.
8. **Chill offsets (VS contract).** Weather registers `{air_offset_c, wind_speed}` (cold snaps lower air temperature; storms raise wind). Offsets are added to TH2's result.
9. **Evaluation.** Thermal holds no per-point state. Consumers query on demand; Body Temperature queries the player's position once per game minute (`minute_tick`). Results are deterministic for the same inputs.
10. **Published values:** `effective_temp_c(p)`, `components(p)` → `{air, zone, wind_chill, heat, shelter_bonus}`, `air_temp_c` (world), `wind_speed`, `wind_eff(p)`, `is_sheltered(p)`.

### States and Transitions

Thermal is stateless per point. The only world state is the registry of sources:

| Entity | States | Transitions |
|---|---|---|
| Heat source | enabled · disabled · removed | registered (enabled) → disabled when its owner reports `heat_c = 0` (e.g. fire out) → enabled when relit → removed when unregistered |
| Insulation volume (VS) | active · removed | registered → removed (e.g. shelter collapses) |
| Wind source | default (`wind_base`) · Weather-owned | Weather registers → Weather-owned; Weather unregisters → default |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Time & Day Cycle (approved) | in | `day`, `hour`, `sunrise_hour`, `sunset_hour`, `minute_tick` | Time |
| Map & Resource Distribution | in | zone id per position → `zone_offset_c`, `wind_exposure` | Map (data) / Thermal (table) |
| Fire | in | heat source `{position, heat_c, radius_m, enabled}` | Fire (values) / Thermal (registry) |
| Shelter (VS) | in | insulation volume | Shelter / Thermal |
| Weather & Cold Snaps (VS) | in | `air_offset_c`, `wind_speed` | Weather / Thermal |
| Body Temperature | out | `effective_temp_c(player)`, `wind_eff(player)`, `is_sheltered` | Thermal |
| Fire | out | `wind_eff(fire position)` (wind stokes or kills a fire — Fire owns the effect) | Thermal |
| Morale & Mental State | — | no direct link: Morale reads `warm_radius` from Fire (Fire publishes the radius it registers here) | Fire |
| Emotional Feedback / VFX | out | `wind_speed`, `wind_eff` for blowing-snow intensity; `heat_c` near the player for breath vapour | Thermal |
| HUD | out | none directly — HUD shows body state from Body Temperature | — |
| Save/Load (Alpha) | out | nothing — sources re-register from their owners on load | — |

Implementation note → becomes an ADR: spatial lookup for zones and sources (area queries vs a coarse grid) is an architecture choice.

## Formulas

**TH1 — Daily mean air temperature (the cold ramp).** The `daily_mean_temp_c` formula is defined as:

`daily_mean_temp_c = max(t_floor, t_start − t_ramp × (day − 1))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_start | float | −15 – +5 | data file | day-1 mean, °C (default −5) |
| t_ramp | float | 0.0–1.0 | data file | °C colder per day (default 0.4) |
| t_floor | float | −40 – −10 | data file | deep-winter floor, °C (default −25); must be ≤ t_start |
| day | int | 1–60 | calculated (Time) | current day (≤ `run_max_days`) |

**Output Range:** −5 to −25 °C at defaults; the floor is reached on day 51. **Example:** day 11 → **−9 °C**; day 31 → **−17 °C**.

**TH2 — Air temperature now.** The `air_temp_c` formula is defined as:

`air_temp_c = daily_mean_temp_c + t_swing × cos(2π × (hour − (solar_noon + peak_lag)) / 24) + weather_offset_c`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t_swing | float | 0–8 | data file | half the day–night difference, °C (default 4) |
| solar_noon | float | 11–13.5 | calculated (Time) | `(sunrise_hour + sunset_hour) / 2` — 12.5 at Time's defaults |
| peak_lag | float | 0–4 | data file | warmest hour after solar noon (default 2.0 → 14:30) |
| hour | float | 0–24 | calculated (Time) | current hour |
| weather_offset_c | float | −20 – +5 | calculated (Weather, VS) | 0 in the MVP |

**Output Range:** −9 to −1 °C on day 1; −21 to −13 °C on day 31 (MVP, no weather). **Examples:** day 1 at 13:00 → −5 + 4 × cos(−0.393) = **−1.3 °C** (the drop); day 1 at 02:30 → **−9.0 °C**; day 31 at 14:30 → **−13 °C**.

**TH3 — Wind chill.** The `wind_chill_c` formula is defined as:

`wind_chill_c = min(chill_cap, k_wind × wind_speed × wind_exposure_eff)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| k_wind | float | 0.5–2.0 | data file | °C of chill per effective m/s (default 1.2) |
| wind_speed | float | 0–25 | data file (MVP `wind_base` 3) / calculated (Weather, VS) | world wind, m/s |
| wind_exposure_eff | float | 0–1 | calculated | zone exposure (blended), or a shelter's override inside one |
| chill_cap | float | 5–25 | data file | maximum chill, °C (default 15) |

`wind_eff(p) = wind_speed × wind_exposure_eff` (m/s) is also published.

**Output Range:** 0–15 °C. **Examples:** MVP, open snow: 1.2 × 3 × 0.8 = **2.9 °C**; forest: **1.4 °C**; lake: **3.6 °C**; a VS storm at 15 m/s on the lake: 18 → capped **15 °C**.

**TH4 — Heat from one source.** The `heat_c` formula is defined as:

`heat_c(source, p) = d < radius_m ? heat_c_source × (1 − (d / radius_m)²) × reflect : 0`, with `d` = horizontal distance from the source to `p`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| heat_c_source | float | 0–40 | calculated (Fire) | heat at the centre, °C (a strong fire ≈ 25 — Fire GDD) |
| radius_m | float | 0.5–6.0 | calculated (Fire) | distance where heat reaches 0 (a strong fire ≈ 3 m — Fire GDD); must be > 0 |
| d | float | 0–∞ | calculated | distance, m |
| reflect | float | 1.0–1.5 | calculated | a shelter's `heat_reflect_mult` when the source warms its inside (VS), else 1.0 |

Total heat at a point: `heat_total = min(heat_cap_c, Σ heat_c)`, `heat_cap_c` (data file, default 30).

**Output Range:** 0–30 °C after the cap. The quadratic falloff keeps the warm core wide and the edge sharp. **Example:** a 25 °C / 3 m fire at 1.5 m → 25 × 0.75 = **18.75 °C**; at 2.5 m → **7.6 °C**; at 3 m → **0**.

**TH5 — Effective (felt) temperature.** The `effective_temp_c` formula is defined as:

`effective_temp_c(p) = air_temp_c + zone_offset_c(p) − wind_chill_c(p) + heat_total(p) + shelter_bonus_c(p)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| air_temp_c | float | −45 – +10 | calculated (TH2) | world air temperature |
| zone_offset_c | float | −5 – +3 | data file (zone table) | blended zone offset |
| wind_chill_c | float | 0–25 | calculated (TH3) | |
| heat_total | float | 0–30 | calculated (TH4) | |
| shelter_bonus_c | float | 0–10 | calculated (Shelter, VS) | 0 outside a shelter and in the MVP |

**Output Range:** MVP defaults ≈ −35.6 °C (day ≥ 51, 02:30, on the lake) to +28.6 °C (day 1, 14:30, in the forest, heat capped). VS worst case ≈ −67 °C (floor −25, night swing −4, cold snap −20, lake −3, chill 15) — Weather must keep its offsets well inside this. **Examples:**
- Day 1, 17:30, open snow, no fire: air −2.2, chill 2.9 → **−5.1 °C**. Same moment 1.5 m from a strong fire: **+13.7 °C**.
- Day 2, 02:30, out on the lake: air −9.4, lake −3, chill 3.6 → **−16.0 °C**.
- Day 31, 02:30, open snow, no fire: air −21, chill 2.9 → **−23.9 °C**.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: `radius_m = 0` → division by zero in TH4 — rejected at registration; many fires stacking to unbounded warmth — capped by `heat_cap_c`; `t_floor > t_start` would make the run warm up — rejected at load; zone seams causing temperature jumps — blended over 5 m; wind chill unbounded in storms — capped. No feedback loops inside Thermal; the loop "cold → build bigger fire → warmer" runs through Fire's fuel cost, which is Fire's to balance.*

## Edge Cases

- **If a heat source registers with `radius_m ≤ 0` or `heat_c_source < 0`**: reject the registration and log an error; the source contributes nothing.
- **If a source reports `heat_c_source = 0`** (fire out): it becomes disabled and contributes 0, without being removed, so relighting re-enables it.
- **If several sources overlap**: sum, then cap at `heat_cap_c` — two fires side by side warm a wider area, not a hotter one beyond the cap.
- **If `p` is exactly at `radius_m`**: heat is 0 (strict `<`).
- **If `p` has no zone data**: use open snow.
- **If `p` is near two or more zones**: blend all within `zone_blend_m` by distance weight.
- **If a point is inside two insulation volumes (VS)**: use the volume with the lowest `wind_exposure_override` and the highest `bonus_c` (best shelter wins); no stacking.
- **If Weather unregisters mid-storm (VS)**: wind returns to `wind_base` over 10 game minutes, not instantly.
- **If data gives `t_floor > t_start`, `t_swing < 0`, or `chill_cap ≤ 0`**: reject the thermal table at load, log, use defaults.
- **If the player is on the lake during the day with no wind source**: still colder than open snow (−3 °C offset, exposure 1.0) — the lake is never a safe shortcut.
- **If a fire sits inside a forest zone**: the zone's lower exposure also reduces the fire's `wind_eff` — sheltered fires burn steadier (Fire applies it).
- **If time is skipped (sleep)**: Body Temperature still queries every game minute; Thermal answers each query with that minute's air temperature, so the night's coldest hours are felt during the skip.
- **If a save is loaded**: Thermal restores nothing; Fire, Shelter and Weather re-register their current values on load before the first `minute_tick`.

## Dependencies

**Upstream — hard:**
- **Time & Day Cycle** (approved) — `day`, `hour`, `sunrise_hour`, `sunset_hour`.

**Upstream — soft** (Thermal works without them using defaults):
- **Map & Resource Distribution** — zone data; without it, everything is open snow.
- **Fire** — registers heat sources (MVP).
- **Shelter (VS)** — registers insulation volumes.
- **Weather & Cold Snaps (VS)** — registers wind and air offset; without it, `wind_base`.

**Downstream:**
- **Body Temperature** — hard: `effective_temp_c`, `wind_eff`, `is_sheltered`.
- **Fire** — `wind_eff` at the fire (soft).
- **Emotional Feedback** — wind and heat for VFX (soft).

**Bidirectional check:** the systems index lists Thermal → Time (matches); Time's GDD lists Thermal as a consumer of `hour`, `day`, `phase`, `sun_progress`, `daylight_hours` — Thermal uses `hour`, `day`, `sunrise_hour`, `sunset_hour`; it does **not** need `phase`, `sun_progress` or `daylight_hours` (flag for Time's next revision: harmless over-listing). Map, Fire, Shelter and Weather list Thermal as a dependency in the index (Fire, Shelter, Weather do; Map does not — Map is a soft input here, so no change needed).

## Visual/Audio Requirements

Optional for a Core system; written because warmth must be readable at the far camera.
- **Warmth must be visible where it is felt:** the snow within each fire's `radius_m` reads warmer at night (the art bible §4 "营地 6 m 内在夜里被火光染暖" covers the 6 m light; the warm core inside ~3 m is a slightly stronger tint, so the player sees where to stand).
- **Wind must be visible:** blowing-snow particles and pine sway scale with `wind_eff` at the camera's focus; the lake shows more drift than the forest.
- **Breath vapour** from the survivor is visible whenever `effective_temp_c` < 0 °C and fades inside the fire's warm core.
- **Audio:** wind loudness follows `wind_eff` at the player; the fire's crackle is the loudest sound inside its radius.

## Game Feel

- **Cold bites from minute one.** On the first afternoon, open snow is already about −4 °C felt; the player should see breath and hear wind immediately.
- **Where you stand matters.** Three steps from the fire is the difference between +14 °C and freezing; the lake is the coldest place on the map; the forest is a little kinder. A player should start choosing paths and fire spots by feel.
- **Every day is colder.** By week three, nights below −20 °C felt should make leaving the fire a decision, not a habit.

## UI Requirements

- **No thermometer in the HUD.** Players read cold through the body (Body Temperature, Emotional Feedback) and the world (breath, wind, warm snow).
- **Debug overlay (dev only):** components at the player (`air`, `zone`, `wind_chill`, `heat`, `shelter`), `effective_temp_c`, `wind_speed`, active sources; optional heat-map visualisation around the camera.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2–3, TH1–TH2 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | day, hour, sunrise/sunset; cold ramp handed over | approved — matches |
| Rule 6, TH4 | Fire (`design/gdd/fire.md`) | heat source values; `warm_radius` = registered radius | not yet written — provisional |
| Rule 6 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | reads `warm_radius` from Fire, not Thermal | exists — consistent |
| Rule 7 | Shelter (`design/gdd/shelter.md`) | insulation volume contract | VS — provisional |
| Rules 5, 8 | Weather & Cold Snaps (`design/gdd/weather-and-cold-snaps.md`) | wind and air offset | VS — provisional |
| Rule 4 | Map & Resource Distribution (`design/gdd/map-and-resource-distribution.md`) | zones | not yet written — provisional |
| Downstream | Body Temperature (`design/gdd/body-temperature.md`) | consumes effective temperature | not yet written (design order #4) |
| Overview, Visual | `design/art/art-bible.md` §2, §4 | fire light ~6 m, lake colder | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** no fires, open snow, day 1 at 13:00, MVP defaults, **WHEN** queried, **THEN** `effective_temp_c` = −4.2 ± 0.1 (air −1.3, chill 2.9).
2. [A] **GIVEN** a point with no zone data, **WHEN** queried, **THEN** the open-snow offset (0) and exposure (0.8) are used.
3. [A] **GIVEN** a point 2.5 m from the forest edge inside a 5 m blend, **WHEN** queried, **THEN** exposure is the 50/50 blend of open snow and forest (0.6) and offset +0.5.
4. [A] **GIVEN** a fire source registered then set to `heat_c = 0`, **WHEN** queried at its centre, **THEN** heat = 0 and the source is still listed (disabled); **WHEN** set back to 25, **THEN** heat = 25 at the centre.
5. [A] **GIVEN** a registration with `radius_m = 0`, **WHEN** made, **THEN** it is rejected and an error is logged.
6. [A] **GIVEN** the same inputs twice, **WHEN** queried, **THEN** the results are identical (deterministic).
7. [A] **GIVEN** two overlapping VS insulation volumes, **WHEN** queried inside both, **THEN** the lowest exposure override and the highest bonus apply, not their sum.

**Formulas**
8. [A] TH1: day 1 → −5; day 11 → −9; day 31 → −17; day 51 → −25; day 60 → −25.
9. [A] TH2: day 1 at 13:00 → −1.30 ± 0.05; 02:30 → −9.0 ± 0.05; day 31 at 14:30 → −13.0 ± 0.05.
10. [A] TH3: wind 3, open snow → 2.88; forest → 1.44; lake → 3.6; wind 15 on the lake → capped 15.
11. [A] TH4: 25 °C / 3 m source at d = 0 → 25; 1.5 → 18.75; 2.5 → 7.64 ± 0.01; 3.0 → 0; 4.0 → 0. Three such sources at one point → capped 30.
12. [A] TH5: day 1 17:30 open snow, no fire → −5.1 ± 0.1; 1.5 m from the fire → +13.7 ± 0.1; day 2 02:30 on the lake → −16.0 ± 0.1; day 31 02:30 open snow → −23.9 ± 0.1.
13. [A] Validation: data with `t_floor` −2 and `t_start` −5 is rejected and defaults are used.

**Cross-system & feel**
14. [A] **GIVEN** Body Temperature queries every `minute_tick` during a 10-hour sleep, **WHEN** the skip runs, **THEN** 600 queries are answered, each with that minute's air temperature (lowest value at 02:30).
15. [A] **GIVEN** Fire registers a 3 m source and Morale reads `warm_radius`, **THEN** both are 3 m (integration).
16. [P] **GIVEN** the MVP first afternoon, **WHEN** the owner walks away from camp, **THEN** they report that it "feels cold" outdoors before the first night (PIVOT check "出去体温也没有怎么降").
17. [P] **GIVEN** a night screenshot of camp, **WHEN** reviewed, **THEN** the warm core (~3 m) is distinguishable from the 6 m firelight ring.

**Performance:** O4 resolved by Scott (2026-11-19): profile the full Body path, including `effective_temp_c` with up to 8 sources and 4 zones nearby. Keep Body's inclusive ≤ 0.02 ms/tick budget. Tighten Thermal's per-query budget after profiling; the new number is pending profiling, not an independent 0.05 ms allowance. Occasional VFX queries must also be measured.

*QA gaps found and resolved: disabled-vs-removed sources (4), registration validation (5), zone blend (3), overlapping shelters (7), sleep-skip sampling (14). Feel lines moved to playtest criteria 16–17.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Are −5 °C (day 1) → −25 °C (day 51) and a ±4 °C swing harsh enough? Felt values reach about −24 °C by day 31 at night. | owner + systems-designer | MVP playtest (with Body Temperature drain rates) | tune `t_start`, `t_ramp`, `t_swing` |
| Should the fire's warmth reach further than 3 m (art bible light is 6 m)? Short warmth forces closeness but may feel stingy. | owner | Fire GDD | Fire owns `radius_m` |
| Should sunshine itself warm the player in open snow (clear-sky bonus by day)? | systems-designer | Weather GDD (VS) | add a sun term keyed on Time's `sun_progress` and cloud cover |
| Coldest hour falls at 02:30 (12 h after the peak), not at dawn as in reality. | systems-designer | MVP playtest | replace the cosine with a skewed curve if it matters to feel |
