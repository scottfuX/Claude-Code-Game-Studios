# Weather & Cold Snaps

> **Status**: Provisional defaults — owner approved for the three-night run
> **Layer**: Feature · **Dependencies**: Time & Day Cycle, Thermal Environment

## Summary

Changing wind, falling snow and independent cold snaps make outdoor exposure costly. The first-night map and demo remain unchanged, with constant baseline wind and no live Weather producer.

## Overview

Weather is a run-owned minute model. It publishes wind speed, additive air offset, snowfall depth and exposed-body wetness gain; Thermal, Body and later Terrain own their effects. It never consumes cosmetic randomness or writes another owner's state.

## Detailed Design

### Core Rules

| State | Wind | Snowfall | Exposed wetness gain |
|---|---|---|---|
| Clear (initial) | 3 m/s | 0 | 0 |
| Windy | 7 m/s | 0 | 0 |
| Snowing | 4 m/s | 1.0 cm/game-hour | 0.05/game-hour |

Each state lasts a seeded uniform integer 120–360 game minutes. On expiry, choose a different state: Clear → Windy 0.5 / Snowing 0.5; Windy → Clear 0.4 / Snowing 0.6; Snowing → Clear 0.5 / Windy 0.5. A fresh dwell is drawn after selection.

Cold Snap is independent: at 06:00 on days 2 onward, roll 0.35; success applies −8 °C air offset for a seeded uniform integer 360–720 minutes. End is exclusive. State changes do not end a snap. There is no day-1 snap roll.

### Dispatch and Randomness

Coordinator dispatches every game minute, including sleep/wait, before Thermal inputs and Fire publication. Absolute minute zero is day 1 midnight. Initial Clear dwell starts on the first dispatched minute. Within a minute: expire snap, select expired state and draw dwell, then test 06:00 snap and draw its duration only on success. Duplicate/older minutes do nothing. All draws use the run's single RunRng; Map initialization precedes these draws.

### Effects and Boundaries

Thermal applies wind × blended zone exposure and the additive snap offset. Body receives Snowing gain only where no shelter bonus applies. Body's B2 drying remains independent. Terrain will consume snowfall through its own depth/compaction/mark port; this phase publishes the rate but does not change snow rendering or footprints. Weather has no authority over death, saves, food or shelter state.

## Formulas

`duration = min(max, min + floor(u × (max − min + 1)))`, uniform run draw `u`.

`snow_depth_gain_per_minute = snowfall_m_per_hour / 60`; `body_wetness_gain_per_minute = exposed ? wetness_per_hour / 60 : 0`.

Thermal TH3 and TH5, Body B1/B2 and Terrain's snowfall dilution formula remain authoritative; no direct extra water/snow damage is added.

## Edge Cases

Invalid tuning installs complete provisional defaults. Negative, duplicate or out-of-order minutes and missing RNG do not advance or draw. Snap expiry restores zero offset; unregistering the wind producer restores baseline wind immediately (scoped owner default overriding ADR-0006's ten-minute unregister transition). Pausing dispatch stops state time. New runs reset dwell and snap state; no persistence feature is introduced.

## Dependencies

Time owns minute delivery; RunSimulation owns dispatch and RNG injection; Thermal owns wind/air registration and zones; Body owns wetness. Terrain, shelter and presentation consume narrow ports, not Weather's mutable state. See ADRs 0003, 0004, 0006, 0008 and control-manifest.md.

## Presentation and Game Feel

Weather should read through wind and snow rather than numeric UI. Existing HUD has no weather-text slot; no new HUD region is added in this phase. Cosmetic snow/wind remain separate from authoritative weather until the presentation owner connects them. Cold snaps add pressure, not a death alarm or extra modal screen.

## Acceptance Criteria

- Identical seeds and minute inputs produce identical state/snap histories and draw counts.
- Dwells remain 120–360 minutes; next-state weights never select the current state.
- No snap roll on day 1; successful day-2 06:00 snap starts immediately and ends at its exclusive deadline.
- Clear/Windy have no snowfall/wetness gain; Snowing publishes 0.01 m/h and 0.05 wetness/h.
- Source removal restores defaults; invalid ports cannot introduce NaN into Body.
- First-night has no Weather model, draws or weather snapshot; the three-night profile enables Weather.
- Wetness gain/drying use per-minute integration and the pre-step wetness in B1; immersion events are idempotent.
