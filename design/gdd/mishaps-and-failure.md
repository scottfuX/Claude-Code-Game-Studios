# Mishaps & Failure

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (systems-designer / game-designer lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 越活越懂 · 苦中有美

## Summary

Mishaps & Failure decides when the survivor's work goes wrong — a strike that sparks but doesn't catch, embers that die when blown, a glancing chop, thin lake ice giving way — and, just as important, **why**. Every failure has a physical cause the player can see and learn to fix (damp tinder, wind at the fire, cold hands, exhaustion, poor tinder), and the survivor's mood only tips the odds quietly underneath. It is the engine of the show's 无力 and 失望 that Morale turns into feeling, and the place where the player's knowledge (pillar 越活越懂) pays off: dry tinder, a sheltered fire spot and warm hands make the next fire easier.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Interaction & Timed Actions`

## Overview

For each attempt Interaction sends (`attempt{action_id, mishap_profile, tool, target, …}`), Mishaps computes a failure chance from the action's profile — a base chance plus situational causes (wetness of the material from Inventory, wind at the spot from Thermal, tinder quality from the Item table) — plus the three state penalties already promised by approved GDDs (Morale's `reliability_penalty`, Body Temperature's `cold_hands_penalty`, Needs & Weight's `fatigue_penalty`), capped at 0.90 (Formula M1). It rolls once, names the **dominant visible cause** (M2 — morale is never the named cause), applies the profile's consequences (wasted tinder, a glancing blow that damages the hatchet), and emits `action_outcome` to Morale with the severity and the helplessness/disappointment tag Morale prices (Morale F2). A small bad-luck rule (M3) stops long streaks of *unexplained* fumbles, but never protects the player from a cause they could fix.

Mishaps also owns the one world mishap in the MVP: **thin lake ice** (M4). Terrain reports `ice_thickness_cm`; on each footfall on thin ice Mishaps rolls a break, which drops the survivor into the water (`fell_in_water` → Body Temperature soaks them, Inventory soaks the pack's tinder and fuel) and can lose a tool. It does not own fire behaviour after a successful strike (Fire), injuries (Injury & Pain, VS), how failures feel (Morale, Emotional Feedback), or how they look (Character, Emotional Feedback) — only that they happen and what caused them.

## Detailed Design

### Core Rules

1. **Profiles.** Each action that can fail names a `mishap_profile` (Interaction's action table). A profile defines: `base_fail`, its situational cause terms (which apply and their weights), `severity` on failure (minor / moderate / major — Morale's F2 values 4 / 8 / 15), `tag` (helplessness / disappointment), and `on_fail` consequences.
2. **MVP profiles** (provisional values; Fire and Gathering may refine their own):

   | Profile | base_fail | damp (k_damp × wetness of) | wind (k_wind above 2 m/s) | tinder (k_tinder × (1 − quality)) | severity | tag | on_fail |
   |---|---|---|---|---|---|---|---|
   | strike (ferro rod onto tinder) | 0.35 | 0.6 × tinder | 0.04 | 0.4 | minor | helplessness | no catch; nothing wasted |
   | blow_embers | 0.25 | 0.5 × kindling | 0.05 | — | moderate | disappointment | embers die; laid tinder consumed (Fire resets to "tinder needed") |
   | carve_feather_stick | 0.15 | 0.3 × stick | — | — | minor | helplessness | stick wasted; knife −5 durability |
   | chop_log | 0.10 | — | — | — | minor | helplessness | glancing blow: no log this completion; hatchet −10 durability |
   | strip_bark | 0.10 | — | — | — | minor | disappointment | half yield |
   | gather_sticks | 0.05 | — | — | — | minor | disappointment | half yield |
   | ice (world, per footfall) | M4 | — | — | — | major | helplessness | fall through (Rule 8) |

   Actions with no profile (clear_snow, place_stones, arrange_tinder, add_fuel, eat, eat_snow, sit_warm, rest, pick_up, drop) cannot fail and send no outcome.
3. **One roll per attempt.** Interaction sends one attempt per timed completion or per repeat attempt; Mishaps rolls once and returns `outcome{success, cause, severity, tag, p_fail}` to Interaction (which tells the resolver) and emits `action_outcome` to Morale (Morale §5): `{action_type, success, cause, severity, tag, base_fail_chance = base_fail}`. Morale computes streaks and decides which successes are meaningful (its constant 0.10).
4. **Failure chance** (M1) = base + situational causes + state penalties, clamped to [0, `p_cap`] with `p_cap` = 0.90 — the clamp Morale, Body Temperature and Needs & Weight already rely on. No action is ever impossible.
5. **Visible cause** (M2). The named cause is the largest contributor among the *physical* terms — damp, wind, tinder, cold_hands, fatigue — if it is ≥ `cause_min` (0.05); otherwise `fumble`. Morale's penalty is never named; it tips the odds silently ("Unfair never", Morale Game Feel). The cause is shown before the outcome lands (Emotional Feedback / Character): smoke and hiss for damp, sparks blown sideways for wind, a rod slipping from shaking hands for cold, a weak swing for fatigue, sparks dying on poor tinder, a plain fumble otherwise.
6. **Learnable causes.** Every situational term is something the player can change: dry the tinder at the fire (Inventory I4), build the fire in the lee of rocks or trees (Thermal zones), use birch bark over sticks (Item table quality), warm up before striking (Body), rest (Needs). This is where the player's knowledge across runs lives.
7. **Bad-luck protection** (M3). If the last `streak_guard` (4) attempts of the same action all failed with cause `fumble`, the next attempt's chance is halved. It never applies when the dominant cause is damp, wind, tinder, cold hands or fatigue — those are the player's to fix.
8. **Thin ice** (M4). On every footfall on a lake-ice cell thinner than `t_safe_cm` (15 cm), roll a break. On a break: the cell becomes broken (Terrain), emit `fell_in_water` (Body sets wetness 1.0; Inventory soaks backpack fuel and tinder), Character enters In-water and climbs out at the nearest edge, Morale receives a major helplessness failure, and with `p_tool_loss` (0.10) one carried tool (hatchet, knife or ferro rod, weighted 2 : 1 : 1) is lost → Inventory `loss{item_lost, tool}`. The darker, thinner ice is visible before it breaks (Terrain Visual).
9. **Consequences go to their owners.** Mishaps only *requests*: durability damage → Inventory; wasted items → Inventory; embers dying → Fire; ice break → Terrain; soak → Body and Inventory. It never changes another system's state directly.
10. **Randomness.** All rolls use one seeded random stream per run (seed saved), so a reloaded run repeats the same luck and QA can reproduce sequences.

### States and Transitions

Mishaps is stateless per attempt. It keeps, per action type, the last `streak_guard` outcomes and causes (for M3), and the run's random seed and position.

| Entity | States | Transitions |
|---|---|---|
| Fumble guard (per action type) | open · armed (4 fumble failures in a row) | armed → open on any success or any non-fumble failure; the halving applies only while armed |
| Ice cell (via Terrain) | solid · broken | solid → broken on an M4 break |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Interaction & Timed Actions (approved) | in/out | in: `attempt{action_id, mishap_profile, tool, target, material}`; out: `outcome{success, cause, severity, tag, p_fail}` | Interaction / Mishaps |
| Morale & Mental State | in/out | in: `reliability_penalty`; out: `action_outcome{action_type, success, cause, severity, tag, base_fail_chance}`, ice-break failure | Morale / Mishaps |
| Body Temperature (approved) | in/out | in: `cold_hands_penalty`; out: `fell_in_water` | Body / Mishaps |
| Needs & Weight (approved) | in | `fatigue_penalty` | Needs |
| Item Database & Inventory (approved) | in/out | in: wetness and `tinder_quality` of the material stack; out: durability damage, wasted units, `item_lost` on ice break, `fell_in_water` soak | Inventory / Mishaps |
| Thermal Environment (approved) | in | `wind_eff` at the attempt's position (the fire site) | Thermal |
| Terrain & Snow Surface (approved) | in/out | in: `ice_thickness_cm`, footfalls on ice (via Character); out: cell broken | Terrain / Mishaps |
| Character Controller & Animation (approved) | in/out | in: footfall, `carry_load_frac`, hurry; out: In-water trigger, cause beats | Character |
| Fire | out | outcome of strike / blow_embers (Fire reacts: catch, ember death) | Fire |
| Emotional Feedback | out | cause and outcome for the failure beat | Emotional Feedback |
| Injury & Pain (VS) | out | knife-slip and fall injuries (VS rolls) | Injury |
| Save/Load (Alpha) | out | seed, stream position, fumble guards | Mishaps |

## Formulas

**M1 — Failure chance.** The `p_fail` formula is defined as:

`p_fail = clamp(base_fail + c_damp + c_wind + c_tinder + reliability_penalty + cold_hands_penalty + fatigue_penalty, 0, p_cap)`
`c_damp = k_damp × wetness`, `c_wind = k_wind × max(0, wind_eff − wind_safe)`, `c_tinder = k_tinder × (1 − tinder_quality)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_fail | float | 0–0.6 | data file (profile) | |
| k_damp, k_wind, k_tinder | float | 0–1 | data file (profile) | 0 when the term does not apply |
| wetness | float | 0–1 | calculated (Inventory) | of the material used (tinder, kindling, stick) |
| wind_eff | float | 0–25 m/s | calculated (Thermal TH3) | at the attempt's position |
| wind_safe | float | 0–5 | data file | default 2 m/s |
| tinder_quality | float | 0–1 | data file (Item table) | birch 0.9 · grass 0.7 · stick 0.3 |
| reliability_penalty | float | 0–0.10 | calculated (Morale F7) | |
| cold_hands_penalty | float | 0–0.20 | calculated (Body B4) | |
| fatigue_penalty | float | 0–0.15 | calculated (Needs N6) | |
| p_cap | float | 0.5–0.95 | constant | 0.90 |

**Output Range:** 0–0.90. **Examples (strike):** day 1, open snow (wind_eff 2.4), dry birch bark, healthy → 0.35 + 0 + 0.016 + 0.04 = **0.406** (≈ 1.7 strikes to catch on average); same in the forest lee (wind_eff 1.2) → **0.39**; soaked bark → 0.35 + 0.6 + … → **0.90** (capped — dry it first); dry dead grass → **0.486**; Cold (0.06) + Fraying (0.06) on dry bark in the open → **0.526**; the worst state (0.10 + 0.20 + 0.15) with damp grass → capped **0.90**.

**M2 — Named cause.** The `cause` rule is defined as:

`cause = argmax(c_damp, c_wind, c_tinder, cold_hands_penalty, fatigue_penalty)` if that maximum ≥ `cause_min`, else `fumble`; ties broken damp > wind > cold_hands > fatigue > tinder

**Variables:** `cause_min` (data file, default 0.05). **Output:** damp · wind · tinder · cold_hands · fatigue · fumble. **Examples:** dry bark, open snow, healthy → contributions 0.016 / 0.04 → **fumble**; dry grass → tinder 0.12 → **tinder**; Cold stage → cold_hands 0.06 vs tinder 0.04 → **cold_hands**; soaked bark → **damp**.

**M3 — Fumble guard.** The `guarded_p_fail` rule is defined as:

`guarded_p_fail = guard_armed and cause_now == fumble ? p_fail × guard_mult : p_fail`

**Variables:** `streak_guard` (data file, default 4), `guard_mult` (data file, default 0.5). **Output Range:** 0–0.90. **Example:** four fumbled strikes in a row on dry bark (0.406) → the fifth fails at **0.203**; four failures caused by damp tinder → no help (dry the tinder).

**M4 — Ice break per footfall.** The `p_break` formula is defined as:

`p_break = thickness ≥ t_safe_cm ? 0 : k_ice × (t_safe_cm − thickness) / t_safe_cm × (1 + load_k × carry_load_frac) × (hurrying ? hurry_k : 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| thickness | float | 0–60 cm | calculated (Terrain) | ice under the foot |
| t_safe_cm | float | 8–25 | data file | default 15 |
| k_ice | float | 0–0.1 | data file | default 0.03 per footfall at zero thickness |
| load_k | float | 0–1 | data file | default 0.5 |
| carry_load_frac | float | 0–1 | calculated (Inventory I1) | |
| hurry_k | float | 1–3 | data file | default 2 |
| p_tool_loss | float | 0–0.5 | data file | default 0.10, on a break |

**Output Range:** 0 to 0.03 × 1.5 × 2 = **0.09** per footfall. **Examples:** 25 cm (default lake) → **0**; 8 cm, kit-only pack (0.276) → 0.03 × 0.467 × 1.138 = **0.016** per footfall (≈ 27 % over 20 steps ≈ 12 m); 5 cm → **0.023** (≈ 37 % over 20 steps); 5 cm with a full pack, hurrying → **0.06** (≈ 71 % over 20 steps).

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: the full penalty stack plus damp exceeds 1 — capped at 0.90; `t_safe_cm` = 0 divides by zero in M4 — floor 8; morale silently dominating the cause — excluded from M2; endless unexplained fumbles — M3, but only for fumbles, so the knowledge loop stays intact. Feedback loops named: fail → frustration → Morale penalty → more fails (Morale's loop, damped by its streak cap and lifts, bounded here by the 0.10 penalty and the 0.90 cap); cold → cold hands → failed fire → colder (Body's loop, bounded by the same cap and by fire tending being allowed in Critical); ice break → wet tinder → failed strikes (intended: falling through ice is a disaster with a lasting, fixable cost).*

## Edge Cases

- **If the material has no wetness** (a non-wettable item): `c_damp` = 0.
- **If the attempt's position has no Thermal data**: `c_wind` = 0 and log a warning.
- **If all penalties are 0 and base is 0**: success guaranteed; no outcome is sent to Morale unless the profile exists (it does — profiles with base 0 still report, as trivial successes Morale ignores).
- **If p_fail hits the 0.90 cap**: the roll still happens — one in ten wet strikes may catch; the UI never says "impossible".
- **If a tool breaks from failure damage**: Inventory removes it and emits `item_lost(tool)`; the current outcome still stands.
- **If the survivor falls through ice while carrying no tools**: no tool loss roll.
- **If a broken ice cell is walked into again**: it is open water (Terrain) — Character treats it as impassable except at the edge; no new break roll.
- **If two attempts arrive in the same frame** (should not happen — one action at a time): process in arrival order with separate rolls.
- **If a save is loaded**: restore seed, stream position and fumble guards; the next roll matches the pre-save sequence.
- **If a profile id is unknown**: treat as cannot-fail, return success, log an error (never invent a chance).
- **If the player keeps striking with soaked tinder**: each strike fails at 0.90 with cause damp shown every time — the game tells them what to fix, it does not stop them.

## Dependencies

**Upstream — hard:** Interaction & Timed Actions (approved — attempts).

**Upstream — soft (inputs to M1/M4):** Morale (`reliability_penalty`), Body Temperature (`cold_hands_penalty`), Needs & Weight (`fatigue_penalty`), Item Database & Inventory (wetness, tinder quality, load), Thermal Environment (`wind_eff`), Terrain & Snow Surface (`ice_thickness_cm`), Character Controller (footfalls, hurry).

**Downstream:** Morale & Mental State (hard: `action_outcome`), Fire (strike / ember outcomes), Gathering (yield outcomes), Inventory (damage, waste, loss), Body Temperature (`fell_in_water`), Terrain (broken ice), Emotional Feedback (cause beats), Injury & Pain (VS), Save/Load.

**Bidirectional check:** the systems index lists Mishaps → Interaction (matches) and lists Fire, Injury, Food, Morale, Diary as dependents (matches). Morale expects `action_outcome{action_type, success, cause, severity, tag, base_fail_chance}` and the ≤ 0.90 clamp — supplied. Body expects `fell_in_water` and its `cold_hands_penalty` summed with Morale's and clamped — supplied. Needs' `fatigue_penalty` summed — supplied. Inventory expects wetness/damage/loss events — supplied. Terrain left the ice-break roll to Mishaps — M4. Interaction sends `attempt` and receives `outcome` — matches. Index gaps: Mishaps' row should also list Terrain (ice) and Thermal (wind) as soft inputs; Morale, Body and Needs are inputs by contract (no cycle — values in, events out, per the index's resolution).

## Visual/Audio Requirements

*art-director lens applied (the cause must be seen before the outcome lands), against `design/art/art-bible.md` §1, §5.*
- **Cause beats** (≤ 1.2 s, before or with the outcome): damp — grey smoke and a hiss, no flame; wind — the spark shower bends sideways and blows out; cold hands — the rod slips, visible hand shake; fatigue — a slow, weak motion; poor tinder — sparks land and fade; fumble — a plain miss.
- **Success beats** contrast: the first curl of flame is the warmest, brightest thing on screen (art bible §1: ember_yellow only for fire).
- **Ice:** a crack line runs out from the foot for ~0.3 s before the break (readable warning even when it is too late); the plunge throws snow and dark water.
- **Audio:** a distinct sound per cause (hiss, gust, clatter, thud); the ice crack is the sharpest sound in the game.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:mishaps-and-failure` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Hard but fair.** Striking a fire on day 1 should take one to three tries; with wet tinder in the wind it should feel hopeless *and* the player should know why.
- **Knowledge pays.** A returning player who keeps bark dry and builds in the lee should fail far less than on their first run.
- **Disasters are rare and earned.** Falling through ice should happen to players who walked on visibly thin ice, mostly when hurrying or laden.
- **Never "for no reason".** Every failure shows its cause first.

## UI Requirements

- **None in play.** Causes are shown in the world. The diary (VS) may mention them in words.
- **Debug overlay (dev only):** last attempt's p_fail with every term, named cause, roll value, fumble-guard state, ice p_break under the foot.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 3–4, M1 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `reliability_penalty`; `action_outcome` fields; severity 4/8/15; meaningful-success constant 0.10 | in review — matches |
| M1, Rule 8 | Body Temperature (`design/gdd/body-temperature.md`) | `cold_hands_penalty`; `fell_in_water` | approved — matches |
| M1 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `fatigue_penalty` | approved — matches |
| M1, Rules 8–9 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | wetness, tinder_quality, durability damage, `item_lost` | approved — matches |
| M1 | Thermal Environment (`design/gdd/thermal-environment.md`) | `wind_eff` | approved — matches |
| M4 | Terrain & Snow Surface (`design/gdd/terrain-and-snow-surface.md`) | `ice_thickness_cm`, broken cells | approved — matches |
| Rules 1–3 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | `attempt` / `outcome`, profiles per action | approved — matches |
| Rule 2 | Fire, Gathering | outcomes of their actions; may refine profiles | not yet written — provisional |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** an add_fuel attempt (no profile), **THEN** success with no roll and no `action_outcome`.
2. [A] **GIVEN** a strike attempt, **THEN** exactly one roll, one `outcome` to Interaction and one `action_outcome` to Morale with severity minor, tag helplessness, `base_fail_chance` 0.35.
3. [A] **GIVEN** a failed chop, **THEN** Inventory receives hatchet −10 durability and Gathering receives no log for that completion.
4. [A] **GIVEN** a failed blow_embers, **THEN** Fire receives "embers died" and the laid tinder is consumed via Inventory.
5. [A] **GIVEN** Morale's penalty is the largest contributor, **THEN** the named cause is never "morale" (M2 picks the largest physical term or fumble).
6. [A] **GIVEN** the same seed and inputs, **THEN** two runs produce identical outcome sequences; after a save/load the next roll matches.
7. [A] **GIVEN** an unknown profile id, **THEN** success, error logged.

**States**
8. [A] **GIVEN** four fumbled strikes in a row, **THEN** the guard is armed and the fifth strike's p_fail is halved; **GIVEN** a success, **THEN** the guard opens; **GIVEN** four damp failures, **THEN** no guard.

**Formulas**
9. [A] M1 (strike): dry birch, wind_eff 2.4, healthy → 0.406 ± 0.001; wind_eff 1.2 → 0.39; dry grass → 0.486; Cold + Fraying → 0.526; soaked bark → 0.90 (cap).
10. [A] M2: the four examples in M2 return fumble, tinder, cold_hands, damp.
11. [A] M3: armed guard on a 0.406 fumble-dominated strike → 0.203.
12. [A] M4: 25 cm → 0; 8 cm, load 0.276 → 0.0159 ± 0.0005; 5 cm, load 1.0, hurrying → 0.06 ± 0.001; `t_safe_cm` 0 in data → rejected.
13. [A] **GIVEN** an ice break, **THEN** `fell_in_water` reaches Body and Inventory, the cell becomes broken, Morale gets a major failure, and over 1,000 simulated breaks with tools carried 10 ± 2 % lose a tool, hatchet about twice as often as knife or rod.

**Cross-system & feel**
14. [A] **GIVEN** Body Cold (0.06), Needs Tired (0.04), Morale Strained (0.03) and a dry-bark strike in the open, **THEN** p_fail = 0.536 ± 0.001 (sum of approved penalties, clamp untouched).
15. [P] **GIVEN** the owner's first MVP fire, **THEN** it takes 1–4 strikes and they can say why any failure happened.
16. [P] **GIVEN** a screenshot sequence of each cause beat, **WHEN** shown to testers, **THEN** ≥ 4 of 5 name damp, wind and cold correctly.

**Performance:** one attempt ≤ 0.02 ms; ice checks only on footfalls over ice cells.

*QA gaps found and resolved: no-profile actions (1), single roll and event (2), consequence routing (3–4), cause never morale (5), determinism (6), guard scope (8), tool-loss distribution (13). Feel lines moved to playtest criteria 15–16.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Is ~1.7 strikes per fire (dry bark, healthy) too easy for "无力", or right for day 1? | owner + systems-designer | MVP playtest | tune `base_fail` (data) |
| Should a failed chop sometimes mean a cut (Injury, VS)? | systems-designer | Injury & Pain GDD | VS roll on chop/carve failures |
| Can a lost tool ever be recovered (dropped in a drift, found later)? MVP: no. | game-designer | VS | add a findable-item rule |
| Should the fumble guard be visible to the player (it is invisible by design)? | game-designer | MVP playtest | — |
| Fire and Gathering may refine their profiles — keep values here as the source of truth or move them into those GDDs? | game-designer | Fire / Gathering GDDs | default: profiles stay here, owners propose changes |
