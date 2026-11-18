# Time & Day Cycle

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (systems-designer / game-designer lenses)
> **Last Updated**: 2026-11-16
> **Last Verified**: 2026-11-16
> **Implements Pillar**: 冷是真的 · 苦中有美

## Summary

Time & Day Cycle is the game's clock: it advances game time at a pace that depends on what the player is doing (working by day, tending the fire at night, waiting, sleeping), counts the days of the run, and shortens the winter daylight a little every day. It publishes the hour, the day, the phase (dawn / day / dusk / night) and events such as nightfall and sunrise that every pressure system keys off. It owns pacing — when the dark comes and how long a day feels — but not temperature, which belongs to Thermal Environment.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Time & Day Cycle is a data layer that every other system reads: a single authoritative game clock, ticked once per game minute, with a day counter and a four-phase day (Dawn, Day, Dusk, Night) computed from a daylight length that shrinks as the run goes deeper into winter. Game time runs at different real-time rates by *mode* — normal play by day, normal play at night, waiting, sleeping — so that daylight work has room to breathe, nights at the fire stay short enough not to drag, and sleep is a quick, interruptible skip. For the player the effect is direct: the light drains away across the afternoon, the first day leaves only about six real minutes before dark ("天黑前要有火"), and each day is a little shorter than the last. The fire-before-dark playtest found time "过的特别慢" because nothing happened in it; this system keeps the clock moving and makes the remaining light a readable, shrinking resource, while the systems that fill that time (Mishaps, Gathering, Fire, Morale) own the events.

What Time does **not** own: air temperature and the day-over-day cold ramp (Thermal Environment), whether the player is asleep (Needs & Weight owns `is_asleep`), what interrupts sleep or waiting (the systems that raise the alarm), and action durations (Interaction & Timed Actions, which reads Time's conversion).

## Detailed Design

### Core Rules

1. **One clock.** Game time is a single value: `day` (int, ≥ 1) and `minute_of_day` (0–1439). `hour` = `minute_of_day / 60` (float, 0–24). No other system keeps its own clock.
2. **The tick.** Time emits `minute_tick` once per game minute, in order, never skipping a minute — including during waiting and sleep. Systems integrate their per-game-hour rates on this tick (Morale §3 relies on this).
3. **Day boundary.** `day` increments when `minute_of_day` wraps from 1439 to 0 (midnight), emitting `day_changed(day)`. "Per day" caps in other systems (e.g. Morale's 3 fire rituals per day) reset at this boundary.
4. **Run start.** A run starts on day 1 at `start_hour` (default 13:00) — the drop happens in the early afternoon, so the first day is short and the brief's "天黑前要有火" is a real deadline.
5. **Daylight shrinks.** Each day has a daylight length D (Formula T1) that shrinks from 8.0 h on day 1 toward a 5.0 h floor — the run goes from late autumn into deep winter. Sunrise and sunset sit symmetrically around a fixed solar noon (T2).
6. **Phases.** Every minute belongs to exactly one phase:
   - **Dawn** — from `sunrise − twilight` to `sunrise`
   - **Day** — from `sunrise` to `sunset`
   - **Dusk** — from `sunset` to `sunset + twilight`
   - **Night** — all other minutes
   `is_night` is true only in Night. **Nightfall** is the minute Dusk ends (`is_night` turns true); **sunrise** is the minute Day starts. `sunrise_window` is true from 30 game minutes before to 30 after sunrise.
7. **Rate modes.** How many real seconds a game minute lasts (T3):
   - `normal` — resolves to the *day rate* in Dawn, Day and Dusk and the *night rate* in Night.
   - `wait` — the player chose to wait/rest (e.g. by the fire); faster.
   - `sleep` — the player is asleep; much faster, a skip.
   Other systems request a mode with `request_rate_mode(mode, reason)`; Time applies it at the next minute boundary. Needs & Weight requests `sleep` when `is_asleep` turns true and `normal` when it turns false; Interaction requests `wait`. Any system may request `normal` to interrupt (fire going out, dangerous cold) — `normal` always wins over `wait` and `sleep` in the same minute.
8. **Pause.** While the game is paused, in a menu, loading, or in a full-screen UI, game time does not advance and no ticks are emitted. Whether the Diary's recording screen (VS) pauses time is the Diary GDD's call; the default is *paused*.
9. **Catch-up on hitches.** Real elapsed time is accumulated; each frame emits one `minute_tick` per whole game minute owed, up to `max_ticks_per_frame` (default 120). Any remainder carries to the next frame, so a hitch never drops or reorders minutes.
10. **Published values** (read any time): `day`, `hour`, `minute_of_day`, `phase`, `is_night`, `sunrise_window`, `daylight_hours` (today's D), `sunrise_hour`, `sunset_hour`, `sun_progress` (T5), `rate_mode`.
11. **Events** (signals): `minute_tick`, `hour_changed(hour)`, `day_changed(day)`, `phase_changed(phase)`, `nightfall`, `sunrise`, `rate_mode_changed(mode)`.
12. **Run end is not Time's.** Time keeps counting until Tap-out & Run Results ends the run. `day` never exceeds `run_max_days` (default 60): at the midnight that would start day 61, Time emits `run_day_cap_reached` and holds at the last minute of day 60 until the run ends (normally Results ends it long before).

### States and Transitions

**Phase cycle** (repeats daily; times shown for day 1, D = 8.0 h, twilight 0.75 h):

| Phase | From | To | Next | Event on entry |
|---|---|---|---|---|
| Night | 17:15 (previous day) | 07:45 | Dawn | `nightfall` (on entry from Dusk) |
| Dawn | 07:45 | 08:30 | Day | `phase_changed(Dawn)` |
| Day | 08:30 | 16:30 | Dusk | `sunrise` |
| Dusk | 16:30 | 17:15 | Night | `phase_changed(Dusk)` |

**Rate mode** (independent of phase):

| Mode | Entered by | Left by | Real seconds per game minute |
|---|---|---|---|
| normal | run start; any `request_rate_mode(normal)`; end of sleep/wait | a `wait` or `sleep` request | day rate 1.5 (Dawn/Day/Dusk), night rate 1.0 (Night) |
| wait | Interaction request | player input, or any `normal` request | 0.25 |
| sleep | Needs & Weight request (`is_asleep` true) | Needs & Weight request (`is_asleep` false), or any `normal` request | 0.05 |

Valid transitions: normal ↔ wait, normal ↔ sleep, wait → sleep (falling asleep while resting). sleep → wait is not valid (waking always returns to normal first). Run start begins in normal.

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Morale & Mental State | out | `minute_tick`, `hour`, `day`, `is_night`, `nightfall`, `sunrise_window`, `day_changed` (per-day caps, homesick milestone at the dawn tick) | Time |
| Needs & Weight | in/out | in: `request_rate_mode(sleep / normal)` from `is_asleep`; out: tick, phase | Time (modes) / Needs (`is_asleep`) |
| Interaction & Timed Actions | in/out | in: `request_rate_mode(wait / normal)`; out: `real_seconds_per_game_minute` so action durations (authored in game minutes) can be shown in real time | Time |
| Thermal Environment | out | `hour`, `day`, `phase`, `sun_progress`, `daylight_hours` — Thermal owns the air-temperature curve and the cold ramp | Time (values) / Thermal (temperature) |
| Body Temperature | out | tick | Time |
| Fire | in/out | out: tick (fuel burn per game minute); in: may request `normal` to wake/interrupt when the fire is nearly out | Time |
| Emotional Feedback / lighting | out | `phase`, `sun_progress`, `hour` for sun angle and the day → dusk → night look blend | Time |
| HUD | out | `phase`, `sun_progress` (sun/moon arc, no digital clock) | Time |
| Weather & Cold Snaps (VS) | out | tick, `day` | Time |
| Medical Check-ins (VS) | out | `day_changed` (check-in schedule) | Time |
| Rival Simulation (VS) | out | `day_changed`, tick | Time |
| Self-Filmed Diary (VS) | in/out | out: `nightfall`, `day`; in: pause request while recording | Time |
| Tap-out & Run Results (VS) | out | `day`, `run_day_cap_reached` | Time |
| Save/Load (Alpha) | out | `day`, `minute_of_day`, fractional accumulator, `rate_mode` | Time |

Implementation note → becomes an ADR: whether Time is an autoload singleton and how its signals are routed is an architecture decision.

## Formulas

**T1 — Daylight length.** The `daylight_hours` formula is defined as:

`daylight_hours = max(d_min, d_start − d_shrink × (day − 1))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| d_start | float | 6.0–10.0 | data file | daylight on day 1, hours (default 8.0) |
| d_shrink | float | 0.0–0.3 | data file | hours lost per day (default 0.1 = 6 min/day) |
| d_min | float | 3.0–8.0 | data file | deep-winter floor, hours (default 5.0); must be ≤ d_start |
| day | int | 1–60 | calculated | current day |

**Output Range:** 5.0–8.0 h at defaults; the floor is reached on day 31 and holds. **Example:** day 11 → 8.0 − 1.0 = **7.0 h**; day 40 → **5.0 h**.

**T2 — Sunrise and sunset.** The `sunrise_hour` / `sunset_hour` formulas are defined as:

`sunrise_hour = solar_noon − daylight_hours / 2` · `sunset_hour = solar_noon + daylight_hours / 2`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| solar_noon | float | 11.0–13.5 | data file | hour of highest sun (default 12.5) |
| daylight_hours | float | 3.0–10.0 | calculated (T1) | today's daylight |
| twilight | float | 0.25–1.5 | data file | length of Dawn and of Dusk, hours (default 0.75) |

Validation at load: `solar_noon − d_start/2 − twilight ≥ 0` and `solar_noon + d_start/2 + twilight ≤ 24`; otherwise reject and use defaults.

**Output Range:** sunrise 08:30–10:00, sunset 15:00–16:30 at defaults. **Example:** day 1 → sunrise **08:30**, sunset **16:30**, nightfall **17:15**; day 31 → sunrise **10:00**, sunset **15:00**, nightfall **15:45**.

**T3 — Real time per game minute.** The `real_seconds_per_game_minute` formula is defined as:

`real_seconds_per_game_minute = rate[mode, phase]` = `s_day` (normal, Dawn/Day/Dusk) · `s_night` (normal, Night) · `s_wait` (wait) · `s_sleep` (sleep)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| s_day | float | 0.5–3.0 | data file | default 1.5 → a daylight game hour lasts 90 real s |
| s_night | float | 0.5–3.0 | data file | default 1.0 → a night game hour at camp lasts 60 real s |
| s_wait | float | 0.1–1.0 | data file | default 0.25 → 15 real s per game hour |
| s_sleep | float | 0.02–0.5 | data file | default 0.05 → 3 real s per game hour; must be > 0 |

All four must be > 0 (a zero rate would freeze time; rejected at load).

**Output Range:** 0.05–1.5 real s per game minute at defaults. **Example:** the first day, drop at 13:00: 3.5 h to sunset + 0.75 h of dusk = 255 game min × 1.5 = **382.5 real s ≈ 6.4 min to nightfall** (the playtest had ≈ 6).

**T4 — Real length of a game day (derived check, not a runtime rule).** The `real_minutes_per_day` formula is defined as:

`real_minutes_per_day = (h_light × 60 × s_day + h_night_awake × 60 × s_night + h_sleep × 60 × s_sleep) / 60`, with `h_light = daylight_hours + 2 × twilight`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| h_light | float | 3.5–13 | calculated | hours in Dawn + Day + Dusk |
| h_night_awake | float | 0–20 | calculated | night hours the player is awake |
| h_sleep | float | 0–14 | calculated | hours asleep |

**Output Range:** ≈ 17.5–19.5 real minutes per game day for a player awake 07:00–21:00 who sleeps 10 h. **Examples:** day 1: (9.5 × 90 + 4.5 × 60 + 10 × 3) / 60 = **19.25 min**. Day 31: (6.5 × 90 + 7.5 × 60 + 10 × 3) / 60 = **17.75 min**. A 30-day run ≈ **9 h** of play; a 45–90 min session ≈ 2.3–5 days.

**T5 — Sun progress.** The `sun_progress` formula is defined as:

`sun_progress = clamp((hour − sunrise_hour) / (sunset_hour − sunrise_hour), 0, 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hour | float | 0–24 | calculated | current hour |
| sunrise_hour, sunset_hour | float | — | calculated (T2) | today's sun times; their difference = daylight_hours ≥ d_min ≥ 3.0, so never 0 |

**Output Range:** 0 at and before sunrise, 1 at and after sunset. **Example:** day 1 at 12:30 → **0.5**.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: a zero rate (T3) would freeze time — rejected at load; `d_min > d_start` would make daylight grow — rejected; twilight pushing dawn before 00:00 or dusk past 24:00 — validated (T2); T5 division by zero — impossible because daylight ≥ d_min ≥ 3.0. No feedback loops: Time reads nothing back except mode requests.*

## Edge Cases

- **If `wait`/`sleep` and `normal` are requested in the same minute**: `normal` wins (an alarm always beats a skip).
- **If `sleep` is requested during `wait`**: switch to sleep (valid transition). **If `wait` is requested during `sleep`**: ignore it and log a warning.
- **If the player sleeps across midnight or across sunrise**: every minute tick still fires in order; `day_changed`, `sunrise` and any per-day resets happen inside the skip exactly as when awake. Morale's homesick milestone at the dawn tick and its "tap-out offer at wake-up if nightfall was slept through" rule rely on this.
- **If a frame owes more than `max_ticks_per_frame` minutes** (hitch, or a very fast sleep rate): emit 120 ticks and carry the remainder; game time may lag real time briefly but never skips or reorders minutes.
- **If the run starts after sunset** (a future start option): the first `nightfall` is not emitted that day (it already passed); the next one is.
- **If the game is paused during Dusk**: no ticks; nightfall fires on the first unpaused minute it is due.
- **If daylight has reached `d_min`**: it stays there; sunrise/sunset stop moving.
- **If day 61 would begin**: emit `run_day_cap_reached`, hold the clock at 23:59 of day 60 until Results ends the run.
- **If bad data fails validation** (zero rate, `d_min > d_start`, twilight out of 0–24): reject the whole time table, log an error, use defaults.
- **If a save is loaded mid-sleep**: restore `rate_mode = sleep` and the fractional accumulator; Needs & Weight re-asserts `is_asleep` on the first tick.
- **If two systems request `normal` in the same minute**: one change, one `rate_mode_changed`; both reasons are logged.

## Dependencies

**Upstream — hard:** none (Foundation).

**Upstream — soft (mode requests only):**
- **Needs & Weight** — requests `sleep` / `normal` from `is_asleep` (owner of that flag).
- **Interaction & Timed Actions** — requests `wait` / `normal`.
- **Fire, Body Temperature, Weather (VS)** — may request `normal` to interrupt a skip.
- **Self-Filmed Diary (VS)** — may request a pause while recording.

**Downstream (depend on Time):** Thermal Environment, Body Temperature, Needs & Weight, Fire, Morale & Mental State, Emotional Feedback (lighting), HUD, Interaction (time conversion), Weather & Cold Snaps, Medical Check-ins, Rival Simulation & Ranking, Self-Filmed Diary, Tap-out & Run Results, Save/Load & Settings.

**Bidirectional check:** Morale & Mental State lists Time as a hard upstream with `hour`, `day`, `is_night`, `sunrise_window` and the game-minute tick — all provided here (matches). Morale's `day ≤ 60` assumption is guaranteed by `run_max_days`. The systems index row for Time lists no dependencies — consistent (mode requests are inputs, not dependencies). The index overview's "day-over-day cold ramp" belongs to Thermal Environment — index note corrected.

## Visual/Audio Requirements

Optional for a Core system; written because Time drives the day/night look the art bible defines.
- **Lighting blend by phase** (`design/art/art-bible.md` §2): Day = the day baseline preset (sun `#FFF3D0`, 1.5, elevation 22°; ambient `#E7EBF3`, 1.3); Dusk → Night blends toward the dusk preset (sun `#FFA764`, 0.08; ambient deep blue `(0.02, 0.10, 0.26)`, 1.6) over the twilight hour. Sun azimuth follows `sun_progress`; elevation peaks at solar noon and never exceeds the 22° baseline (long blue shadows are the look).
- **Night = only the fire is warm** (§1): no warm ambient at night.
- **Audio:** ambience crossfades day (wind, distant birds) → night (wind, ice creaks) across Dusk; no clock or chime sounds.

## Game Feel

- **The light is the timer.** The player should read "how long until dark" from the sky and shadow length, not a number — the long blue shadows stretch and warm through Dusk.
- **Days keep moving.** Daylight work at 90 s per game hour, camp nights at 60 s per hour; sleep is a ~30 s skip that can be cut short. Target: no stretch of > 3 real minutes where the player is only waiting for time to pass (playtest complaint "时间过的特别慢").
- **Shrinking days are felt.** By the third week the player should notice "the dark comes sooner" without being told (6 minutes less light per day, 3 h less by day 31).

## UI Requirements

- **No digital clock** in play. The HUD shows a sun/moon arc driven by `phase` and `sun_progress` (owned by the HUD GDD).
- **Day number** appears on the diary page and in Results (VS), not on the HUD.
- **Debug overlay (dev only):** day, hh:mm, phase, rate mode, real s per game minute, ticks this frame.

> **📌 UX Flag — Time & Day Cycle**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2, 3, 6, 12 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | tick, per-day caps, nightfall, sunrise window, day ≤ 60 | exists — matches |
| Rule 7 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `is_asleep` drives sleep mode | not yet written — provisional |
| Rule 7, Interactions | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | wait mode; durations in game minutes | not yet written — provisional |
| Overview, Interactions | Thermal Environment (`design/gdd/thermal-environment.md`) | owns temperature and the cold ramp | not yet written |
| Visual/Audio | `design/art/art-bible.md` §1, §2 | day and dusk presets | exists |
| Rule 4 | `design/game-brief.md` First minute | "天黑前要有火" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a new run, **WHEN** it starts, **THEN** day = 1, hour = 13.0, phase = Day, rate mode = normal.
2. [A] **GIVEN** normal mode in Day, **WHEN** 90 real seconds pass, **THEN** exactly 60 `minute_tick`s are emitted, in order, with no duplicate or missing minute.
3. [A] **GIVEN** 23:59 of day 3, **WHEN** one game minute passes, **THEN** day = 4, minute_of_day = 0, one `day_changed(4)` emitted.
4. [A] **GIVEN** day 1, **WHEN** the clock passes 17:15, **THEN** `nightfall` fires once and `is_night` becomes true; **WHEN** day 2 (D = 7.9 h) reaches 07:48, **THEN** phase = Dawn and `is_night` false; at 08:33 `sunrise` fires.
5. [A] **GIVEN** day 1, **THEN** `sunrise_window` is true from 08:00 to 09:00 and false at 07:59 and 09:01.
6. [A] **GIVEN** the game paused for 10 real minutes, **WHEN** unpaused, **THEN** game time has not advanced and no ticks were emitted.
7. [A] **GIVEN** sleep mode, **WHEN** a `normal` request arrives in the same minute as a `wait` request, **THEN** the mode becomes normal.
8. [A] **GIVEN** sleep mode, **WHEN** a `wait` request arrives, **THEN** the mode stays sleep and a warning is logged.
9. [A] **GIVEN** sleep from 21:00 day 2, **WHEN** 12 game hours pass (to 09:00 day 3), **THEN** 720 ticks fired in order, and `day_changed(3)` at midnight and `sunrise` at 08:36 (day 3, D = 7.8 h) were both emitted inside the skip.
10. [A] **GIVEN** a simulated 10-second hitch in sleep mode (200 minutes owed), **WHEN** the next frames run, **THEN** at most 120 ticks are emitted per frame and all 200 are emitted within 2 frames, in order.
11. [A] **GIVEN** day 60 at 23:59, **WHEN** a minute passes, **THEN** `run_day_cap_reached` fires and day stays 60.

**Formulas**
12. [A] T1: day 1 → 8.0 h; day 11 → 7.0 h; day 31 → 5.0 h; day 40 → 5.0 h.
13. [A] T2: day 1 → sunrise 08:30, sunset 16:30; day 31 → 10:00 / 15:00; data with `solar_noon` 1.0 fails validation and defaults are used.
14. [A] T3: normal/Day → 1.5 s; normal/Night → 1.0 s; wait → 0.25 s; sleep → 0.05 s; data with `s_sleep = 0` is rejected.
15. [A] T3 example: **GIVEN** a new run, **WHEN** played in normal mode without waiting or sleeping, **THEN** `nightfall` fires 382.5 ± 1 real seconds after start.
16. [A] T5: day 1 at 08:00 → 0; 12:30 → 0.5; 16:30 → 1; 20:00 → 1.

**Cross-system & feel**
17. [A] **GIVEN** Needs & Weight sets `is_asleep` true, **WHEN** the next minute starts, **THEN** rate mode = sleep; **WHEN** Fire requests `normal`, **THEN** mode = normal and `rate_mode_changed(normal)` is emitted once.
18. [A] **GIVEN** Morale's per-day fire-ritual cap used up, **WHEN** `day_changed` fires, **THEN** Morale's cap counter is 0 again (integration test).
19. [P] **GIVEN** the MVP first day, **WHEN** the owner plays it, **THEN** they can say roughly how much daylight is left from the sky alone, and report the day did not feel slow (PIVOT check).
20. [P] **GIVEN** a captured day-1 and day-31 dusk at the same game hour, **WHEN** compared, **THEN** the day-31 screenshot is visibly darker (evidence pair).

**Performance:** ≤ 0.02 ms per tick for Time itself; at sleep rate ≤ 20 ticks per real second, so the per-tick cost of all subscribers must stay ≤ 0.5 ms combined (budget passed to Architecture).

*QA gaps found and resolved: tick ordering during skip (9), hitch catch-up (10), mode conflicts (7, 8), validation of bad data (13, 14). Feel lines moved to playtest criteria 19–20.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Are 90 s (day) / 60 s (night) per game hour right? The playtest felt slow at 120 s/hour, but the cause was emptiness. | owner + game-designer | MVP playtest | tune `s_day`/`s_night` (data) from owner notes |
| Should the player be able to sleep by day (nap) to skip a cold snap? | game-designer | Needs & Weight GDD | Needs owns `is_asleep`; Time supports it either way |
| Does sleep ever happen without shelter or fire, and how dangerous is it? | systems-designer | Body Temperature / Needs GDDs | interrupt rules are theirs |
| Session-length target: the concept says 45–90 min ≈ 2–3 days; T4 gives ≈ 2.3–5 days. | owner | before Vertical Slice | update concept text or slow `s_day` |
| Does the Diary recording screen pause time? Default paused. | narrative-director | Diary GDD (VS) | — |
