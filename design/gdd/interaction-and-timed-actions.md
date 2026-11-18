# Interaction & Timed Actions

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / systems-designer / ux-designer lenses)
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 亲手做

## Summary

Interaction & Timed Actions is how the survivor does things: it finds what is in reach (a deadfall, the fire pit, a pile of sticks, the snow underfoot), offers the one or two verbs that make sense there, and runs the chosen action as a piece of work with a duration, an animation, a chance to fail and a result. Every slow-down from cold, hunger and despair lands here as longer work; every attempt goes to Mishaps for its outcome; every result goes to the system that owns it. It is the fix for the playtest's "几乎没有动作，所有就看到任务动动就干完了": work now takes time, effort and sometimes several tries.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input & Action Map, Character Controller & Animation`

## Overview

Interaction owns three things. **Targeting** (Formula IA2): each frame it picks the best interactable within reach in front of the survivor and shows up to two verbs — `interact` (E) for the primary, `secondary` (F) for the second. **Actions**: each verb starts an action defined as data (Core Rule 3) — its mode (timed work, repeated attempts, continuous rest, or instant), base duration in game minutes, effort intensity, required tool, animation, cancel rules, and which system resolves its outcome. **Running them**: a timed action's real duration is its base duration × the combined slow-downs from Morale, Body Temperature and Needs & Weight, capped (IA1); Character plays it by looping the effort (Character C7); when an attempt completes, Mishaps & Failure rolls the outcome; the owning system (Gathering, Fire, Needs & Weight, Inventory) applies the result.

Decisions this GDD settles for its neighbours: actions **start on a tap** and run on their own — except repeated attempts such as striking the ferro rod, where **each tap is one try** (the player's hands are in the moment that matters most); **moving or `cancel_action` stops** an action; Interaction reports **work intensity** to Body Temperature and Needs & Weight, **tool uses** to Inventory, **`is_idle`** to Morale and **`resting_at_fire`** to Needs & Weight (the input source the Needs review asked for). It does not own what an action produces (Gathering, Fire, Needs), whether it fails (Mishaps), or how it animates (Character).

## Detailed Design

### Core Rules

1. **Interactables.** Any world object or ground cell that can be acted on registers as an interactable with a `kind` (deadfall, dead_bush, birch, fire_site, fire, pile, item, snow_ground, bedroll …) and the action ids it offers, in priority order. The owning system (Gathering, Fire, Inventory, Terrain) decides which actions are currently available on it (e.g. "light" only when tinder is arranged).
2. **Targeting.** The target is the best interactable within `reach_m` (1.5 m) inside a ±50° cone in front of the survivor (IA2). `snow_ground` is the fallback target when nothing else is in reach and the survivor stands on snow. The HUD prompt shows the target's first available action on `interact` and its second on `secondary`.
3. **Action definition** (data file, one row per action):

   | Field | Meaning |
   |---|---|
   | `id`, `verb_key` | identity; localised verb for the prompt |
   | `mode` | `timed` (one tap starts work that runs to completion) · `repeat` (each tap is one attempt) · `continuous` (runs until cancelled) · `instant` |
   | `base_game_min` | duration of one completion or one attempt, in game minutes (Time converts to real time) |
   | `intensity` | none · light · heavy — reported to Body Temperature and Needs & Weight while running |
   | `tool` | item id required in the backpack (hatchet, knife, ferro_rod) or none; one *use* reported to Inventory per completion/attempt |
   | `animation` | Character clip id |
   | `cancellable`, `progress_kept` | whether movement/cancel can stop it and whether partial progress stays on the target |
   | `resolver` | the system that applies the result (Gathering, Fire, Needs, Inventory, Time) |
   | `mishap_profile` | id Mishaps uses to roll failure (none = cannot fail) |
   | `critical_allowed` | usable in Body Temperature's Critical stage — implements Body Temperature's `allowed_actions` whitelist (Body owns it) |
   | `counts_as_idle` | true for quiet actions (sit, warm hands, rest) — Morale's ritual detection |
4. **MVP action catalogue** (base values provisional for the owning GDDs to confirm):

   | id | target | mode | base_game_min | intensity | tool | resolver | critical |
   |---|---|---|---|---|---|---|---|
   | pick_up | pile / item | instant | — | none | — | Inventory | no |
   | drop | self (backpack UI) | instant | — | none | — | Inventory | yes |
   | gather_sticks | dead_bush / deadfall | timed | 3 | light | — | Gathering | no |
   | gather_grass | grass tuft | timed | 2 | light | — | Gathering | no |
   | gather_stones | stone pile | timed | 1 | heavy | — | Gathering | no |
   | strip_bark | birch | timed | 4 | light | knife | Gathering | no |
   | chop_log | deadfall trunk | timed | 4 | heavy | hatchet | Gathering | no |
   | clear_snow | fire_site | timed | 5 | heavy | — | Fire | no |
   | place_stones | fire_site | timed | 3 | light | — (needs stones) | Fire | no |
   | arrange_tinder | fire_site | timed | 2 | light | — | Fire | no |
   | carve_feather_stick | fire_site / self | timed | 3 | light | knife | Fire | no |
   | strike | fire_site (tinder laid) | repeat | 0.5 per strike | light | ferro_rod | Fire | no |
   | blow_embers | fire (embers) | timed | 1 | light | — | Fire | yes |
   | add_fuel | fire | timed | 0.5 | light | — | Fire | yes |
   | sit_warm | fire | continuous | — | none | — | Morale/Body (via idle) | yes |
   | rest | fire | continuous | — | none | — | Time (`wait`) | no |
   | sleep | bedroll / fire | instant (hands to Needs) | — | none | — | Needs & Weight | no |
   | eat | item (backpack UI) | timed | item `eat_minutes` (5) | none | — | Needs & Weight | no |
   | eat_snow | snow_ground | repeat | 3 per handful | none | — | Needs & Weight | no |

5. **Starting.** Pressing `interact`/`secondary` (a tap — Input IN2) on an available action starts it if: the tool is in the backpack, Body allows it (`critical_allowed` in Critical), Needs allows it (no heavy actions when Exhausted), and no other action is running. Otherwise the action is refused with a short diegetic reason ("没有斧头", "手抬不起来了", "太累了").
6. **Running.**
   - `timed`: the action runs for its real duration (IA1) with the animation looping its effort (Character C7). At completion: one tool use → Inventory; outcome roll → Mishaps (if a profile exists); result → resolver.
   - `repeat`: each tap performs one attempt of `base_game_min`; taps during an attempt are buffered (Input IN3, one at most). Each attempt gets its own tool use and Mishaps roll. The player stops by not tapping, moving, or `cancel_action`.
   - `continuous`: runs until cancelled; `rest` requests Time's `wait` mode and releases it on stop.
   - `instant`: applies immediately (pick-ups, sleep hand-off).
7. **Cancelling.** Movement input or `cancel_action` stops a `cancellable` action. If `progress_kept`, progress fraction stays on the target (a half-chopped log resumes where it stopped); otherwise it is lost (an interrupted meal eats nothing). Collapse (Needs), entering Critical (unless `critical_allowed`), falling into water (Mishaps `fell_in_water`), the target disappearing, or the tool breaking/being lost cancel at once. On `fell_in_water` the cancel applies even to non-`cancellable` actions: no result, tool use or Mishaps roll is sent for the interrupted work or attempt, progress follows `progress_kept`, and control passes to Character's In-water state.
8. **Effort reporting.** While an action runs, Interaction reports its `intensity` as the work activity (`light` / `heavy`) to Body Temperature and Needs & Weight; they take the highest of work and Character's movement activity.
9. **Idle and resting.** `is_idle` = no movement for ≥ 2 real seconds and (no action running, or the running action has `counts_as_idle`). `resting_at_fire` = the `rest` action is running and the survivor is inside a burning fire's `warm_radius` — the input Needs & Weight's `e_rest` uses.
10. **Duration multipliers.** All slow-downs multiply and are capped at `max_duration_mult` (2.0) (IA1). Real duration uses the Time rate at the action's start.
11. **One action at a time.** No queueing beyond Input's 0.15 s buffer; the survivor's hands do one thing.

### States and Transitions

| State | Enter | Leave |
|---|---|---|
| Free | default; action ended | a permitted action starts |
| Working (timed) | timed action starts | completion → Free (result applied) · cancel → Free (progress kept or lost) · forced cancel |
| Attempting (repeat) | first tap | each attempt completes → Attempting (awaiting next tap) · 3 real seconds without a tap, movement, or cancel → Free |
| Continuous | sit_warm / rest starts | movement, cancel, fire out (for rest/sit) → Free |
| Refused (momentary) | a start condition fails | prompt shows the reason for 1.5 s → Free |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Input & Action Map | in | `interact`, `secondary`, `cancel_action` taps/holds; buffered presses | Input |
| Character Controller & Animation (approved) | in/out | out: `play_action(id, duration_s)`, cancel; in: movement (cancels), position/facing for targeting, action finished | Interaction / Character |
| Camera (approved) | in | yaw (not needed for targeting — targeting uses the survivor's facing) | Camera |
| Morale & Mental State | in/out | in: `action_duration_mult`; out: `is_idle` | Morale / Interaction |
| Body Temperature (approved) | in/out | in: `body_action_mult`, `allowed_actions` (Critical); out: work intensity | Body / Interaction |
| Needs & Weight (approved) | in/out | in: `needs_action_mult`, heavy-work refusal, sleep permission; out: work intensity, eat/eat_snow/sleep requests, `resting_at_fire` | Needs / Interaction |
| Item Database & Inventory (approved) | in/out | in: tool presence, item data; out: pick up / drop / use / consume requests | Inventory |
| Mishaps & Failure | in/out | out: `attempt{action_id, mishap_profile, tool, target, base_fail_inputs}`; in: outcome (success / failure + cause, severity), `fell_in_water` (forced cancel, Rule 7) | Mishaps |
| Gathering, Fire | out | completed action → resolver applies the result; they register interactables and available actions | Gathering / Fire |
| Time & Day Cycle (approved) | in/out | in: `real_seconds_per_game_minute`; out: `request_rate_mode(wait / normal)` for `rest` | Time |
| HUD | out | target, available verbs, progress, refusal reason | Interaction |
| Save/Load (Alpha) | out | nothing (no action survives a save); progress lives on targets | — |

## Formulas

**IA1 — Action duration.** The `action_duration` formula is defined as:

`dur_mult = min(max_duration_mult, action_duration_mult × body_action_mult × needs_action_mult)`
`game_minutes = base_game_min × dur_mult`; `real_seconds = game_minutes × real_seconds_per_game_minute(at start)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_game_min | float | 0.25–30 | data file (action table) | |
| action_duration_mult | float | 1.00–1.20 | calculated (Morale F7) | |
| body_action_mult | float | 1.00–1.50 | calculated (Body B4) | |
| needs_action_mult | float | 1.00–1.375 | calculated (Needs N6) | |
| max_duration_mult | float | 1.5–3.0 | data file | default 2.0 |
| real_seconds_per_game_minute | float | 0.05–1.5 | calculated (Time T3) | day 1.5 · night 1.0 |

**Output Range:** game minutes = base × 1.0–2.0. **Examples:** chop_log by day, healthy → 4 game min = **6.0 s**; Fraying (1.12) + Cold (1.10) → 4.93 game min = **7.4 s**; the worst stack 1.2 × 1.5 × 1.375 = 2.475 → capped **2.0** → 8 game min = **12 s**; the same chop at night → **4.0 s** healthy.

**IA2 — Target score.** The `target_score` formula is defined as (lower is better):

`score = d / reach_m + w_angle × |angle| / cone_half_deg − priority_bonus[kind]`, candidates only if `d ≤ reach_m` and `|angle| ≤ cone_half_deg`; `snow_ground` only when no other candidate

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| d | float | 0–reach_m | calculated | distance to the interactable's interaction point |
| angle | float | −180–180° | calculated | between survivor facing and the target |
| reach_m | float | 0.8–3.0 | data file | default 1.5 m; must be > 0 |
| cone_half_deg | float | 20–90 | data file | default 50°; must be > 0 |
| w_angle | float | 0–2 | data file | default 0.5 |
| priority_bonus | float | 0–0.5 | data file | fire 0.3 (so tending the fire wins near camp), others 0 |

Target switches only when another candidate beats the current one by `hysteresis` 0.15, so the prompt does not flicker.

**Output Range:** −0.5 to 1.5. **Example:** a deadfall at 1.2 m, 30° off → 0.8 + 0.3 = **1.1**; the fire at 1.4 m, 40° off → 0.933 + 0.4 − 0.3 = **1.03** → the fire is targeted.

**IA3 — Kept progress.** The `progress` update is defined as:

`progress' = progress + dt_game / game_minutes` (0–1); on cancel with `progress_kept`, the target stores `progress`; resuming needs `game_minutes × (1 − progress)` more

**Output Range:** 0–1. **Example:** chopping cancelled at 60 % → resuming takes 40 % of the (current) duration.

**IA4 — Attempt rhythm** (`repeat` mode). Minimum time between attempts = `base_game_min × dur_mult × real_seconds_per_game_minute`; strike by day, healthy → **0.75 s** per strike; Hypothermic (1.25) + Tired (1.10) → **1.03 s**. The 3-second idle timeout returns to Free.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: the duration stack reaching 2.475× — capped at 2.0 (Needs left the cap to Interaction); `reach_m` or `cone_half_deg` = 0 → no target or division by zero — rejected at load; a Time rate change mid-action shortening work — the start rate is used; repeat spam faster than an attempt — bounded by IA4 plus Input's one-press buffer. Feedback loop (slower work → more time in the cold → colder → slower work) is the intended 冷是真的 pressure, bounded by the 2.0 cap.*

## Edge Cases

- **If the target disappears mid-action** (a pile emptied by another action, a fire going out during add_fuel): cancel; progress is discarded.
- **If the tool breaks on the use that completes an action**: the result still applies; the next start is refused ("没有斧头").
- **If the player moves during a non-cancellable action** (none in the MVP): movement is ignored until it ends.
- **If Body enters Critical during a non-critical action**: cancel immediately; only `critical_allowed` actions remain.
- **If Needs collapses the survivor**: cancel and hand to the collapse override (Character).
- **If the survivor falls through ice mid-action** (`fell_in_water`): cancel immediately, the same way Critical entry does, including non-`cancellable` and `critical_allowed` actions; the interrupted work or attempt sends no result, tool use or Mishaps roll; kept progress stays on the target; Character takes over with In-water. If `fell_in_water` and a death event arrive in the same tick, the death event wins.
- **If two interactables tie on score**: keep the current target; else the nearer.
- **If day turns to night during an action**: the start rate is kept until the action ends.
- **If the player taps `interact` on a repeat action faster than the attempt rhythm**: one press is buffered; extra presses are dropped.
- **If the backpack is full when an action produces items** (chop_log): the resolver drops the produce on the ground at the survivor's feet as a pile (Inventory); no item is lost.
- **If `rest` is running and the fire goes out**: stop and request Time `normal`.
- **If the game is saved during an action**: the action is not saved; on load the survivor is Free and any kept progress is on the target.
- **If eating is cancelled**: nothing is consumed and no calories are added.
- **If the backpack opens during an action**: the backpack does not pause time, so the action keeps running; opening it does not cancel. The pause menu pauses everything, including the action.

## Dependencies

**Upstream — hard:** Input & Action Map (taps, cancel); Character Controller & Animation (approved — position, facing, animation playback).

**Upstream — soft:** Morale, Body Temperature, Needs & Weight (multipliers, permissions), Item Database & Inventory (tools, items), Time (rate, wait mode), Mishaps (outcomes), Gathering and Fire (interactables and results).

**Downstream:** Mishaps & Failure (hard: attempts to roll), Gathering, Fire, Needs & Weight (eat, sleep, `resting_at_fire`), Inventory (uses, pick-ups), Morale (`is_idle`), Body Temperature and Needs & Weight (work intensity), HUD (prompts), Shelter, Water, Food (VS).

**Bidirectional check:** the systems index lists Interaction → Input, Character (matches) and Mishaps, Gathering, Fire, Shelter, Water, Food as dependents (matches). Morale lists Interaction for `action_duration_mult` out / `is_idle` in (matches — Rule 9). Body lists `body_action_mult` and the Critical whitelist (matches — `critical_allowed` = add_fuel, blow_embers, sit_warm, drop; crawl is Character's; tap-out is Input/Tap-out's). Needs lists work activity, eat/drink/sleep actions, refusals, and left `e_rest`'s source open — resolved (`resting_at_fire`, Rule 9). Inventory lists pick up / drop / use / consume (matches). Character lists `play_action(id, duration_s)` and move-cancels (matches). Time lists Interaction as the `wait` requester (matches). Input left "tap vs hold" to Interaction — resolved: tap to start; repeat actions tap per attempt.

## Visual/Audio Requirements

*art-director lens applied (players read work and failure from the figure), against `design/art/art-bible.md` §1, §5.*
- **Every action is visible work** (§5 "慢、重、费力；肢体动作要大"): the effort loop shows each swing, scrape and breath; progress is read from the work itself (chips flying, the log splitting, snow cleared to the ground), not from a bar.
- **Prompts** (art bible §4 paper-and-ink): a hand-drawn glyph and verb near the target, one or two lines; the target gets a faint warm outline only when it is the current target (warm = "this can help you", §1).
- **Refusals** are shown by a gesture (shaking hand, slump) plus the short line.
- **Audio:** each effort beat has a sound (thock, scrape, hiss of a spark); a completed action ends on a distinct beat (a log falls apart, bark tears free).

## Game Feel

- **Work takes time, and you feel why.** A chop is ~6 s healthy, up to 12 s in the worst state — more swings, never slow motion.
- **The hands are yours at the critical moment.** Striking for a fire is tap-by-tap: each strike is a small hope.
- **Never a menu for doing.** One target, one or two verbs, E or F.
- **Stopping is always possible.** Moving stops work; the half-done log waits for you.

## UI Requirements

- **Context prompt:** current target's verbs for E/F with device glyphs (Input), shown only when available.
- **Progress:** no bar by default; an optional thin progress arc under the prompt (accessibility setting, Alpha).
- **Refusal line:** 1.5 s diegetic text near the survivor.
- **Debug overlay (dev only):** target and scores, running action, mode, dur_mult components, real/game durations, attempts, last Mishaps outcome.

> **📌 UX Flag — Interaction & Timed Actions**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 5–6, IA1 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `action_duration_mult`; `is_idle` with `counts_as_idle` | in review — matches |
| Rules 5, 10 | Body Temperature (`design/gdd/body-temperature.md`) | `body_action_mult`; Critical whitelist | approved — matches |
| Rules 5, 9 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `needs_action_mult`, refusals, eat/eat_snow/sleep, `resting_at_fire` for `e_rest` | approved — resolves its review note |
| Rules 4, 6 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | tools, uses, pick-up, overflow to ground | approved — matches |
| Rule 6, IA1 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | `play_action`, C7 looping | approved — matches |
| IA1, Rule 6 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | `real_seconds_per_game_minute`, `wait` | approved — matches |
| Rules 2, 6 | Input & Action Map (`design/gdd/input-and-action-map.md`) | taps, buffer, cancel | in review — matches |
| Rules 3–4 | Mishaps & Failure, Gathering, Fire | profiles, results, base durations | not yet written — provisional |
| Summary | `prototypes/firebeforedark-concept/REPORT.md` | "几乎没有动作…动动就干完了" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a deadfall at 1.2 m straight ahead and no other target, **THEN** it is targeted and the prompt shows "chop" on E.
2. [A] **GIVEN** a deadfall 1.2 m at 30° and the fire 1.4 m at 40°, **THEN** the fire is targeted (score 1.03 < 1.1).
3. [A] **GIVEN** no interactable in reach while standing on snow, **THEN** the target is `snow_ground` with "eat snow" on F.
4. [A] **GIVEN** no hatchet in the backpack, **WHEN** chop is pressed, **THEN** refused with "没有斧头".
5. [A] **GIVEN** Exhausted, **WHEN** chop (heavy) is pressed, **THEN** refused; gather_sticks (light) is allowed.
6. [A] **GIVEN** Body Critical, **THEN** only add_fuel, blow_embers, sit_warm and drop can start.
7. [A] **GIVEN** a chop at 60 % progress, **WHEN** the player moves, **THEN** the action stops and the log stores 0.6; resuming completes after 40 % of the duration.
8. [A] **GIVEN** eating cancelled halfway, **THEN** the item remains and no kcal are added.
9. [A] **GIVEN** a chop completes, **THEN** exactly one hatchet use goes to Inventory, one attempt to Mishaps, and (on success) one result to Gathering.
10. [A] **GIVEN** strike (repeat) and 5 taps, **THEN** 5 attempts, 5 ferro-rod uses and 5 Mishaps rolls; no tap for 3 s → Free.
11. [A] **GIVEN** `rest` at a burning fire, **THEN** Time is in `wait` and `resting_at_fire` is true; **WHEN** the fire goes out, **THEN** rest stops and Time returns to `normal`.
12. [A] **GIVEN** standing still 2 s with no action, **THEN** `is_idle` true; during sit_warm, true; during chop, false.

**States**
13. [A] **GIVEN** a refused start, **THEN** the reason shows for 1.5 s and the state returns to Free.

**Formulas**
14. [A] IA1: chop by day healthy → 6.0 s; Fraying + Cold → 7.39 ± 0.02 s; Breaking + Critical + Exhausted + Parched → capped 2.0 → 12.0 s; the same chop starting at 16:59 by day and crossing into night keeps 1.5 s per game minute.
15. [A] IA2: target switching requires a better score by ≥ 0.15 (no flicker when two targets are within 0.1).
16. [A] IA4: strike by day healthy → minimum 0.75 s between attempts; Hypothermic + Tired → 1.03 ± 0.01 s.
17. [A] Data with `reach_m` 0 or `cone_half_deg` 0 is rejected.

**Cross-system & feel**
18. [A] **GIVEN** chop running, **THEN** Body receives work `heavy` (+0.6 heat) and Needs burns +200 kcal/h for its duration (integration).
19. [P] **GIVEN** the owner gathers wood and lights the first fire in the MVP, **THEN** they describe the work as taking effort and time — not "动动就干完了" (PIVOT check).
20. [P] **GIVEN** five testers, **WHEN** they first reach the fire pit, **THEN** ≥ 4 find the next step from the prompts alone.
21. [A] **GIVEN** a chop at 60 % progress (or a strike attempt in flight), **WHEN** `fell_in_water` arrives, **THEN** the action cancels in the same tick, no Inventory use, Mishaps roll or Gathering result is sent, the log stores 0.6, and Character enters In-water.

**Performance:** targeting ≤ 0.1 ms per frame with up to 30 interactables in range.

*QA gaps found and resolved: fallback snow target (3), Critical whitelist (6), kept vs lost progress (7–8), one use/roll per completion (9), repeat-mode idle timeout (10), rest stop on fire out (11), day/night rate lock (14). Feel lines moved to playtest criteria 19–20.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Durations are in game minutes (contract with Needs/Inventory), so work takes ⅓ less real time at night (1.0 vs 1.5 s per game minute). Acceptable, or should night actions author their real time? | game-designer | MVP playtest | if it feels wrong, add a per-action real-time floor |
| Should chopping be tap-per-swing (more physical) instead of timed? | owner | MVP playtest | data change: `mode` = repeat |
| Base durations and the catalogue are placeholders. | Gathering / Fire GDDs | next GDDs | confirm or change |
| Does the backpack screen pause actions? Default: no (time keeps running). | ux-designer | Screens & Menus GDD (VS) | — |
| Optional progress arc for accessibility. | accessibility-specialist | Alpha | — |
