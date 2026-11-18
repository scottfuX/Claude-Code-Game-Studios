# Morale & Mental State

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / systems-designer lenses)
> **Last Updated**: 2026-11-16
> **Last Verified**: 2026-11-16
> **Implements Pillar**: 冷是真的 · 苦中有美 · 退赛是赌注

## Summary

Morale & Mental State tracks the survivor's mind through five strains — loneliness, frustration (helplessness and disappointment), grief, hunger distress and pain — and folds them into a hidden Resolve and four mental states. The player never sees a number: they feel it through posture, camera, sound and the diary, and at the low end through hands that fail a little more often and work that takes longer. It never kills or forces a tap-out; it makes leaving tempting, and it owns the game's feeling → show feature → mechanic map.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Time & Day Cycle, Body Temperature, Needs & Weight, Mishaps & Failure`

## Overview

Morale & Mental State models the survivor's mind the way 《荒野独居》 shows it: most contestants do not leave because the body fails first, they leave because the mind does. The system tracks five strains — **孤独 Loneliness**, **挫败 Frustration** (carrying both 无力 helplessness and 失望 disappointment), **伤心 Grief**, **饥饿感 Hunger distress** and **痛苦 Pain** — and folds them into one hidden **Resolve** value and four **mental states** (Steady → Strained → Fraying → Breaking). The player never sees a morale bar (pillar 苦中有美: the world, not a number); they feel it through the survivor's body, the camera, the sound, the diary and — at the low end — through hands that fumble more often and work that takes longer. Morale never kills and never forces a tap-out: it is the force that makes "leave now" tempting (pillar 退赛是赌注), and it gives the PIVOT playtest's missing feelings a mechanical home.

The player interacts with it indirectly and continuously: every failed strike, empty trap, cold night and lonely day pushes strains up; warm fires, hard-won successes, quiet ritual moments, the nightly self-filmed diary and keepsakes bring them down. Without this system the game is the thin chore loop the playtest rejected ("饥饿感，孤独感，无力，失望，伤心，痛苦…都需要体现出来").

This GDD also owns the project's **feeling → show feature → mechanic map** (Core Rules §1), which every later GDD answers to.

## Detailed Design

### Core Rules

**§1 Feeling map (owns the project-wide contract).** Each feeling the owner named has one mechanical home, the show features that feed it, what relieves it, and how it is shown. Systems marked VS arrive in the Vertical Slice; their inputs are absent (zero) in the MVP.

| Feeling | Strain (stored / derived) | Fed by (mechanics) | Show feature | Relieved by | Shown through (Emotional Feedback) |
|---|---|---|---|---|---|
| 饥饿感 Hunger | Hunger distress **H** — derived | Needs & Weight: low fullness, weight lost since day 1 | 体重流失 weight loss; 医疗检查 weigh-ins (VS) | eating, a catch | slower gait, hand-to-stomach idle, diary talks about food |
| 孤独感 Loneliness | Loneliness **L** — stored | hours alone, nights, day count; a rival leaving (VS) | 自拍日记 the camera is the only listener; 还剩几人 rivals (VS) | diary entry (VS), wildlife sighting (VS), ritual moment, keepsake | long silences in the mix, camera holds wider, survivor looks at the horizon |
| 无力 Helplessness | Frustration **F** (tag `helplessness`) — stored | consecutive failures of the same action; cold hands, wind, damp (via Mishaps) | 失败 failures | a hard-won success, rest | slumped shoulders, a kneel after a failed strike, heavier breathing |
| 失望 Disappointment | Frustration **F** (tag `disappointment`) — stored | expectation unmet: empty trap, lost fish, fire dead on return, bad medical news (VS) | 失败, 医疗检查 | meaningful success, watching the sunrise | head drop, a short stillness beat, a muted music sting |
| 伤心 Grief | Grief **G** — stored | loss of something built or carried; homesick milestone days | 10 件装备 (losing one of them), 日记 | diary entry (VS), ritual moment, keepsake | sitting longer, grade drifts greyer, quiet music state |
| 痛苦 Pain | Pain **P** — derived | Body Temperature: core temp below comfort; Injury & Pain (VS) | 医疗检查 (VS) | warmth, treatment (VS) | shivering, limping, breath vapour, the art bible's 失温危险 vignette |

Hope is not a sixth strain: it is the *falling* of strains — every relief event is a visible beat (Visual/Audio).

**§2 Strain values.** Each strain is a float 0–100 (0 = untouched, 100 = overwhelmed). L, F, G are stored and change by rate and by events (Formulas F1–F3). H and P are recomputed every tick from their source systems (F4–F5) and never stored.

**§3 Tick.** Morale updates once per game minute while the game is unpaused, using the game-hour rates in Formulas scaled by elapsed game time. While sleeping, the sleep multipliers apply. Paused time, menus and loading accrue nothing.

**§4 Resolve and state.** After strains update, Resolve R (F6) is recomputed and the mental state is re-evaluated with hysteresis (States and Transitions).

**§5 Events in.** Morale reacts to events, each applied once, in the fixed order Edge Cases defines (losses → failures → successes → comforts → rival/medical):
- `action_outcome` (Mishaps): failures raise F by severity × streak (F2); *meaningful* successes lower F. A success is meaningful when the action's base failure chance was ≥ 10 % or it ends a failure streak of ≥ 1. Trivial successes do nothing — success-farming is not a strategy. Any success on an `action_type` — meaningful or trivial — clears that type's failure streak; outcomes on other `action_type`s do not.
- `loss` (Fire, Inventory, Shelter VS): raise G by kind (F3); a `fire_died_unattended` loss also raises F (disappointment, moderate).
- `comfort` (Diary VS, Wildlife VS): lower L and G by kind — `diary_recorded`: L −15, G −5; `wildlife_sighted`: L −3 (no G effect).
- `rival_tapped_out` (VS): L +2, F −2 ("one fewer — I'm still here").
- `medical_check` (VS): a warning result is a disappointment failure, moderate.
- `homesick_milestone`: emitted by Morale itself at the dawn tick when `day` is 7, 14, 21, 28… — raise G by 8 (F3). No external system is involved.

**§6 Ritual moments (detected by Morale).** "Slow, ritual-like" beats are rewarded, never required:
- **Fire ritual** — the player is idle within a burning fire's warm radius for ≥ 20 continuous game minutes with core temp ≥ 36.0 °C: L −4, G −3, F −3. At most once per game hour and 3 times per day.
- **Sunrise** — the player is awake, outdoors and idle for ≥ 10 game minutes inside Time's sunrise window: F −5, G −2. Once per day.

**§7 Second wind.** The first time per day the state is Breaking and a meaningful success or a ritual moment occurs, apply an extra F −20 and L −10 on top of its normal effect. This is the show's "one small win saves you" and the damper on the despair spiral.

**§8 Effects out.** Morale publishes, every tick:
- `mental_state` (enum) and `resolve` (0–100, hidden — Emotional Feedback, Diary, debug only).
- `dominant_strain` — the strain with the highest weighted contribution (F6), ties broken L > F > G > H > P; Emotional Feedback picks body language from it, Diary picks what the entry is about.
- `reliability_penalty` — added to every action's failure chance by Mishaps (F7).
- `action_duration_mult` — multiplies timed-action durations in Interaction (F7).
- `tap_out_offer` (see §9) and `strain_spike(dimension, delta)` for any single event with |delta| ≥ 5, so Feedback can play a beat.

**§9 The tap-out offer.** At every nightfall (Time `is_night` turns true) on which the state is Fraying or Breaking, emit one `tap_out_offer`: `strength = "quiet"` normally, `"plea"` (the survivor says it: "我想回家") when this is at least the second consecutive nightfall in Breaking. The consecutive-Breaking count resets to zero at any nightfall spent below Breaking, including a Fraying one. At most one offer per night. Morale never ends a run and never forces the choice; Tap-out & Run Results (VS) owns the prompt and the decision. In the MVP, the offer only triggers its Feedback beat.

**§10 Keepsakes (VS/Alpha contract).** A carried keepsake multiplies the gain of one stored strain by `k_keepsake` (default 0.85). Multiple keepsakes on the same strain multiply but the product is floored at 0.70. Keepsakes affect Morale only — no direct survival effect (owner decision, 2026-11-16); their survival value is the indirect, bounded one of F7.

**§11 What Morale never does.** It never shows a number or bar in play, never kills, never triggers medical evacuation, never blocks an action outright, and never takes control from the player (ritual moments happen only because the player chose to stop).

### States and Transitions

| State | Enter (falling) | Leave upward when | reliability_penalty | action_duration_mult | What it means |
|---|---|---|---|---|---|
| **Steady** 平稳 | start of run; R ≥ 70 when rising from Strained | — | +0.00 | 1.00 | clear-headed, the work is hard but fine |
| **Strained** 吃力 | R < 65 | R ≥ 70 → Steady | +0.03 | 1.05 | tired, short-tempered, the first "why am I here" |
| **Fraying** 起毛边 | R < 40 | R ≥ 45 → Strained | +0.06 | 1.12 | hands shake, mistakes creep in; tap-out offers begin |
| **Breaking** 快撑不住 | R < 20 | R ≥ 25 → Fraying | +0.10 | 1.20 | everything is heavy; the survivor wants to go home |

- Falling thresholds are 65 / 40 / 20; rising thresholds are each +5 (hysteresis) so the state does not flicker on a boundary.
- One step per tick at most, in both directions: a large drop (e.g. R 70 → 15) walks Steady → Strained → Fraying → Breaking over consecutive ticks, and a large recovery climbs back through the rising thresholds the same way, so every transition's Feedback beat plays.
- The run starts in Steady with L = F = G = 0.
- Death, evacuation or tap-out end the run; Morale freezes its last values for Run Results and Diary.

### Interactions with Other Systems

All upstream systems are undesigned; every interface below is a **provisional contract** their GDDs must satisfy or flag.

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Time & Day Cycle | in | `hour` (0–24), `day` (≥ 1), `is_night`, `sunrise_window` (bool), game-minute tick | Time |
| Body Temperature | in | `core_temp_c` (°C, normal 37.0) | Body Temperature |
| Needs & Weight | in | `fullness` (0–100), `weight_kg`, `start_weight_kg`, `is_asleep` (drives `m_time` in F1 and the §3 sleep multipliers) | Needs & Weight |
| Mishaps & Failure | in | `action_outcome {action_type, success, cause, severity: minor/moderate/major, tag: helplessness/disappointment, base_fail_chance}` | Mishaps |
| Mishaps & Failure | out | `reliability_penalty` (0–0.10) — Mishaps adds it to failure chance and clamps the total | Morale (value) / Mishaps (clamp) |
| Interaction & Timed Actions | out | `action_duration_mult` (1.00–1.20); `is_idle` comes back in for ritual detection | Morale (value) / Interaction (idle flag) |
| Fire | in | `fire_burning`, `warm_radius` around a fire, `loss{kind: fire_died_unattended}` | Fire |
| Item Database & Inventory | in | `loss{kind: item_lost, item_class: tool/other}`; carried keepsakes (VS) | Inventory |
| Emotional Feedback | out | `mental_state`, `resolve`, `dominant_strain`, `strain_spike`, `state_changed`, ritual-moment and second-wind events | Morale |
| Self-Filmed Diary (VS) | in/out | in: `diary_recorded` (once per night); out: `dominant_strain`, day's strain history | Diary emits / Morale publishes |
| Tap-out & Run Results (VS) | out | `tap_out_offer(strength)`, final strain values | Morale |
| Injury & Pain (VS) | in | `injury_pain` (0–100) | Injury |
| Wildlife Behavior (VS) | in | `wildlife_sighted` (comfort) | Wildlife |
| Rival Simulation (VS) | in | `rival_tapped_out` | Rivals |
| Medical Check-ins (VS) | in | `medical_check{result: ok/warning}` | Medical |
| Shelter (VS) | in | `loss{kind: shelter_damaged}` | Shelter |
| Save/Load (Alpha) | out | L, F, G, state, nights-in-Breaking, per-day caps used | Morale |

Implementation note → becomes an ADR: how events reach Morale (signal bus vs direct signals) is an architecture decision, not a GDD rule.

## Formulas

All rates are per **game hour** and applied each game-minute tick as `rate × (1/60)`. All strains clamp to 0–100 after every change.

**F1 — Loneliness gain.** The `loneliness_gain` formula is defined as:

`loneliness_gain = l_base × (1 + l_day × (day − 1)) × m_time × k_keepsake_L`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| l_base | float | 0.3–1.2 | data file | base loneliness per game hour (default 0.6) |
| l_day | float | 0.0–0.15 | data file | growth per day survived (default 0.08) |
| day | int | 1–60 | calculated (Time) | current day of the run |
| m_time | float | 0.5 / 1.0 / 1.5 | data file | 0.5 asleep, 1.0 awake by day, 1.5 awake at night |
| k_keepsake_L | float | 0.70–1.0 | calculated | product of loneliness keepsakes, floored at 0.70 |

Loneliness has no passive decay: it only falls through comfort events (diary −15, wildlife −3, fire ritual −4, second wind −10).

**Output Range:** 0.21–5.15 per hour at default values (day 1 asleep with keepsakes floored at 0.70 → day 60 awake at night). Unbounded growth with `day` is prevented by the day cap of the run length (≤ 60).
**Example:** day 1, 8 h awake by day, 6 h awake at night, 10 h asleep: 8×0.6 + 6×0.9 + 10×0.3 = **13.2 per day**. Day 10 (factor 1.72): 22.7 per day; with one diary entry (−15) a net **+7.7 per day** — loneliness that creeps, then lands around the second week.

**F2 — Frustration from an outcome.** The `frustration_delta` formula is defined as:

`frustration_delta = failure ? sev × (1 + s_step × min(streak, s_cap)) × k_keepsake_F : −(streak_before ≥ 1 ? lift_hard : lift)`
(applied only for failures and for meaningful successes; see Core Rules §5)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| sev | float | minor 4 · moderate 8 · major 15 | data file | severity from Mishaps' event |
| streak | int | 0–∞ | calculated | prior consecutive failures of the same `action_type`, counting only those inside the last 2 game hours (sliding); reset to 0 by any success on that `action_type`, meaningful or trivial; unaffected by other `action_type`s |
| s_step | float | 0.1–0.4 | data file | extra weight per prior failure (default 0.25) |
| s_cap | int | 2–6 | data file | streak cap (default 4) |
| lift | float | 3–10 | data file | relief from a meaningful success (default 6) |
| lift_hard | float | 6–20 | data file | relief from a success that ends a streak (default 12) |
| streak_before | int | 0–∞ | calculated | streak at the moment of the success |
| k_keepsake_F | float | 0.70–1.0 | calculated | frustration keepsakes product |

Passive decay: F −1.0 per hour while awake and resting at a burning fire; −2.0 per hour asleep; otherwise none.

**Output Range:** +4 to +30 per failure before the keepsake factor (down to +2.8 with the 0.70 floor); −3 to −20 per success. The streak term is bounded by `s_cap`, so one failure can never add more than `15 × (1 + 0.25 × 4) = 30`.
**Example:** five failed strikes in a row (minor): 4 + 5 + 6 + 7 + 8 = **+30 F**; the next strike lands: **−12** → net +18. Fire found dead on return (moderate, disappointment): **+8 F** and **+10 G** (F3).

**F3 — Grief from a loss.** The `grief_delta` formula is defined as:

`grief_delta = g_kind × k_keepsake_G`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| g_kind | float | 2–25 | data file | fire_died_unattended 10 · item_lost (tool) 10 · item_lost (other) 6 · shelter_damaged 15 · homesick milestone (dawn of day 7, 14, 21, 28…) 8 |
| k_keepsake_G | float | 0.70–1.0 | calculated | grief keepsakes product |

Passive decay: G −0.4 per hour always. Diary entry −5; fire ritual −3; sunrise −2.

**Output Range:** +1.4 to +25 per loss event. **Example:** a tool lost through the ice with a grief keepsake carried: 10 × 0.85 = **+8.5 G**, gone again after ~21 game hours of passive decay.

**F4 — Hunger distress (derived).** The `hunger_distress` formula is defined as:

`hunger_distress = clamp(w_full × (100 − fullness) + (1 − w_full) × 100 × min(1, wl / wl_full), 0, 100)` where `wl = max(0, (start_weight_kg − weight_kg) / start_weight_kg)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| fullness | float | 0–100 | calculated (Needs) | current fullness |
| weight_kg | float | 30–150 | calculated (Needs) | current body weight |
| start_weight_kg | float | 40–150 | calculated (Needs) | weight at drop; must be > 0 |
| w_full | float | 0.3–0.8 | data file | share of momentary hunger vs. long weight loss (default 0.6) |
| wl_full | float | 0.08–0.25 | data file | fraction of body weight lost that counts as full distress (default 0.15) |

**Output Range:** 0 (full, no weight lost) to 100 (empty, ≥ 15 % lost). If `start_weight_kg ≤ 0`, `wl = 0` (guard; see Edge Cases). **Example:** fullness 40, 6 % lost: 0.6 × 60 + 0.4 × 100 × 0.4 = **52**.

**F5 — Pain (derived).** The `pain` formula is defined as:

`pain = max(clamp(100 × (t_comfort − core_temp_c) / (t_comfort − t_max_pain), 0, 100), injury_pain)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| core_temp_c | float | 28–40 | calculated (Body Temperature) | core temperature |
| t_comfort | float | 36.0–37.0 | data file | below this, cold starts to hurt (default 36.5) |
| t_max_pain | float | 32.0–35.0 | data file | at or below this, cold pain is total (default 33.0); must be < t_comfort |
| injury_pain | float | 0–100 | calculated (Injury, VS) | 0 in the MVP |

**Output Range:** 0–100. **Example:** core 35.1 °C: 100 × 1.4 / 3.5 = **40**.

**F6 — Resolve.** The `resolve` formula is defined as:

`resolve = 100 − (a_mean × Σ(wᵢ × sᵢ) / Σwᵢ + (1 − a_mean) × max(sᵢ))` for sᵢ ∈ {L, F, G, H, P}

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| sᵢ | float | 0–100 | calculated | the five strains |
| wᵢ | float | 0.05–0.5 each | data file | weights L 0.25 · F 0.25 · G 0.15 · H 0.20 · P 0.15; normalised by Σwᵢ so they need not sum to 1 |
| a_mean | float | 0.4–0.9 | data file | blend of the average strain vs. the single worst one (default 0.6) |

The `max` term is deliberate: one overwhelming feeling can break a person whose other strains are fine.

**Output Range:** 0 (every strain at 100) to 100 (every strain at 0). Σwᵢ > 0 is guaranteed by each wᵢ ≥ 0.05.
**Examples:** day 3 evening, L 30 · F 20 · G 10 · H 40 · P 0 → weighted mean 22, max 40 → R = 100 − (13.2 + 16) = **70.8 Steady**. A bad first night, L 30 · F 50 · G 20 · H 50 · P 100 → mean 48, max 100 → R = 100 − (28.8 + 40) = **31.2 Fraying**. Week three, L 90 · F 60 · G 50 · H 80 · P 50 → mean 68.5, max 90 → R = **22.9 Fraying**, one major failure (+30) from Breaking.

**F7 — Effects of state.** The `reliability_penalty` and `action_duration_mult` formulas are lookups:

`reliability_penalty = penalty_table[mental_state]` · `action_duration_mult = duration_table[mental_state]`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| penalty_table | float[4] | 0.0–0.15 each | data file | Steady 0.00 · Strained 0.03 · Fraying 0.06 · Breaking 0.10 |
| duration_table | float[4] | 1.0–1.3 each | data file | 1.00 · 1.05 · 1.12 · 1.20 |

**Output Range:** penalty 0–0.10, duration ×1.00–×1.20. Mishaps clamps the final failure chance to ≤ 0.90, so no action becomes impossible. **Example:** a strike with 25 % base failure in Fraying fails 31 % of the time and takes 12 % longer.

**Feedback loop (named, intended, damped).** Frustration → worse state → more failures → more frustration is a positive loop and is the 无力 the owner asked for. It is damped by: the streak cap (F2), the success lifts (F2), rest decay, the second wind (Core Rules §7), the small maximum penalty (+0.10, F7), and the one-step-per-tick state change.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: division by zero in F4 (`start_weight_kg = 0`) and F5 (`t_comfort = t_max_pain`) — guarded; Σwᵢ = 0 in F6 — prevented by the 0.05 floor; unbounded streak — capped; keepsake stacking to zero gain — floored at 0.70.*

## Edge Cases

- **If several events arrive in the same tick**: apply in this order — losses, failures, successes, comforts, rival/medical events — then rate changes, then recompute H, P, R and state once. Rationale: bad news first, so a success in the same tick visibly softens it.
- **If a strain would exceed 100 or drop below 0**: clamp; the excess is discarded, not banked.
- **If R crosses several thresholds in one tick**: move one state per tick (States and Transitions), emitting each `state_changed`.
- **If R sits exactly on a threshold**: falling uses strict `<` (R = 65.0 does not leave Steady), rising uses `≥` the +5 value (R = 70.0 returns to Steady).
- **If `start_weight_kg ≤ 0` or missing**: treat weight loss as 0 and log an error; H falls back to the fullness term only.
- **If `t_comfort ≤ t_max_pain` from bad data**: reject the data at load and use the defaults (36.5 / 33.0).
- **If the player gains weight above start weight**: `wl` is 0, never negative — weight gain does not create a happiness bonus.
- **If the player repeats a trivially easy action to farm successes**: no F relief — only meaningful successes lift F (Core Rules §5). A trivial success still clears that action's failure streak (F2), but a trivial action rarely fails, so this cannot be exploited.
- **If the player stands idle at the fire for hours**: fire rituals cap at one per game hour and three per day; the fire still burns fuel and the day still passes.
- **If the player records more than one diary entry a night (VS)**: only the first `diary_recorded` per night counts.
- **If second wind's conditions are met more than once a day**: only the first applies.
- **If the state is Breaking at nightfall for two consecutive nights, and the player refuses the plea**: no further penalty; the plea repeats at most once per night while Breaking continues.
- **If a Fraying (or lower) night falls between two Breaking nights**: the consecutive-Breaking count resets, so the next Breaking nightfall offers "quiet" again (Core Rules §9).
- **If the player dies or is evacuated while Fraying or Breaking**: no extra effect; final values are frozen for Results and Diary.
- **If the player sleeps through nightfall**: the tap-out offer for that night fires at wake-up if the state still qualifies; at most one per night.
- **If a game is loaded (Alpha)**: L, F, G, state, nights-in-Breaking and the per-day caps are restored exactly; H and P recompute from their sources on the first tick without emitting spikes.
- **If an event names an unknown `action_type`, `kind` or `severity`**: ignore it and log a warning — no default severity is guessed.
- **If time is skipped (sleep, waiting)**: accrual integrates over the skipped game minutes with the sleeping multipliers; ritual moments cannot occur during a skip.
- **If no Diary, Wildlife, Rivals or keepsakes exist (MVP)**: their comforts are simply absent; the MVP's reliefs are successes, fire rituals, sunrise, rest and sleep.

## Dependencies

**Upstream — hard** (Morale cannot run without them; all undesigned, contracts provisional):
- **Time & Day Cycle** — game-minute tick, `day`, `is_night`, `sunrise_window`.
- **Body Temperature** — `core_temp_c` for Pain (F5) and the fire-ritual condition.
- **Needs & Weight** — `fullness`, `weight_kg`, `start_weight_kg` for Hunger distress (F4); `is_asleep` for `m_time` (F1) and the §3 sleep multipliers.
- **Mishaps & Failure** — `action_outcome` events (F2).

**Upstream — soft** (Morale works without them; they add inputs):
- **Fire** — `fire_burning`, warm radius, `fire_died_unattended` loss (MVP).
- **Item Database & Inventory** — `item_lost` (MVP); keepsakes (VS/Alpha).
- **Interaction & Timed Actions** — `is_idle` for ritual detection (MVP).
- **Injury & Pain, Self-Filmed Diary, Wildlife Behavior, Rival Simulation & Ranking, Medical Check-ins, Shelter, Kit Selection, Meta Rewards** — VS/Alpha inputs listed in Interactions.

**Downstream** (depend on Morale):
- **Mishaps & Failure** — reads `reliability_penalty` through one modifier contract (cycle resolved per systems index).
- **Interaction & Timed Actions** — reads `action_duration_mult` (soft; Interaction must list Morale as a soft input — not yet in the systems index row).
- **Emotional Feedback** — hard: it is Morale's only in-play presentation.
- **Self-Filmed Diary (VS)** — reads `dominant_strain` and the day's history; emits `diary_recorded` (cycle resolved by event).
- **Tap-out & Run Results (VS)** — `tap_out_offer`, final values.
- **Save/Load & Settings (Alpha)** — persisted fields.

**Bidirectional check:** the systems index lists Morale → Time, Body Temperature, Needs & Weight, Mishaps (matches). Gaps to fix when those GDDs are written: Interaction does not list Morale (soft input); Fire and Inventory do not list Morale as a consumer of their loss events.

## Visual/Audio Requirements

*art-director lens applied (visual feedback is central to this system in Lean mode), against `design/art/art-bible.md` §1–4.* Morale defines **what** must be readable; Emotional Feedback (system 29) owns **how** it is built.

**Principles that apply:**
- **整个世界是冷的，只有活下去的东西是暖的** (§1) — low morale never adds warm colour; relief beats may briefly let warm light linger longer on the survivor.
- **大块面，少细节** (§1) — every morale cue must read at the ~50° far camera through silhouette, posture and motion, not faces or small props.
- **Mood table** (§2) — Breaking borrows the 失温危险 treatment only in saturation, never the vignette (that is Pain's), so cold and despair stay distinguishable.

**Required feedback per event:**
| Event | Visual | Audio |
|---|---|---|
| state worsens | posture shifts (shoulders drop, slower turn-in-place), grade −5 % saturation per step on cold colours only | music layer thins; ambience wind slightly louder in the mix |
| state improves | posture lifts, saturation restores over ≥ 3 s | a single warm instrument returns |
| failure spike (F ≥ +5) | 0.6–1.2 s stillness beat: kneel, head drop or a frustrated gesture by action type | breath out / quiet exhale, no UI sound |
| loss spike (G ≥ +5) | survivor stops and looks at what was lost | music sting, muted |
| relief (any strain −5 or more) | small upright beat, camera eases closer by a few percent | soft warm tone |
| fire ritual / sunrise | camera slowly pulls back to a wide, the show's framing; survivor's hands to the fire / face to the light | fire crackle and silence foregrounded; no music start |
| second wind | a visible "breath in" and straightening | one held chord |
| tap-out offer | the satellite radio on the pack catches the light | radio static, faint |
| dominant strain | idle set chosen by it: L looks at horizon, F rubs hands / kicks snow, G sits, H hand to stomach, P hugs self and shivers | — |

**Constraints:** all cues need skeletal animation (rig spike is a prerequisite — PIVOT finding); no morale cue may use red/green or rely on colour alone (§4 colourblind rules).

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:morale-and-mental-state` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Felt, not read.** A player should be able to say "he's falling apart" from the camera alone, without any HUD. Playtest target: 4 of 5 testers name the survivor's state correctly from a 20-second clip.
- **Never steal control.** Feedback beats are ≤ 1.2 s and are layered over control (the next input cancels the pose); only player-chosen idleness produces the long ritual shots.
- **Gradual mood, sharp moments.** State shifts blend over ≥ 3 s; event beats are immediate (≤ 100 ms after the outcome) so cause and feeling are linked.
- **Heavy, then ritual.** Low morale makes work *look* heavier (longer durations, slumped poses) — matching the owner's "Heavy effortful 为主"; relief comes in slow, quiet, deliberate beats — "加上时不时的 Slow ritual-like".
- **Unfair never.** Every morale-driven failure must still show its physical cause first (Mishaps); morale only tips the odds. A tester should never say "it failed for no reason".

## UI Requirements

- **No morale meter, number or icon in the HUD** (pillar 苦中有美; anti-pillar "数值条杂务循环").
- **Tap-out offer (VS):** diegetic — the satellite radio on the pack; one prompt per night with two choices (call / put it away). Owned by Tap-out & Run Results; Morale supplies `strength`.
- **Diary (VS):** each nightly page carries a few mood words drawn from `dominant_strain`, in the paper-and-ink UI style of the art bible §4.
- **Debug overlay (dev builds only):** live L, F, G, H, P, R, state, last 10 events — needed for tuning and QA.

> **📌 UX Flag — Morale & Mental State**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Core Rules §3, F1 | Time & Day Cycle (`design/gdd/time-and-day-cycle.md`) | tick, day, night, sunrise window | target not yet written — provisional |
| F5, §6 | Body Temperature (`design/gdd/body-temperature.md`) | `core_temp_c` | not yet written — provisional |
| F4 | Needs & Weight (`design/gdd/needs-and-weight.md`) | fullness, weight, start weight | not yet written — provisional |
| F2, F7 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | outcome events; failure-chance clamp ≤ 0.90 | not yet written — provisional |
| F7 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | duration multiplier, idle flag | not yet written — provisional |
| §5, F3 | Fire (`design/gdd/fire.md`) | warm radius, `fire_died_unattended` | not yet written — provisional |
| Visual/Audio | Emotional Feedback (`design/gdd/emotional-feedback.md`) | implements every cue table row | not yet written |
| Visual/Audio | `design/art/art-bible.md` §1, §2, §4 | colour rule, mood table, colourblind rules | exists |
| Overview, §1 | `design/gdd/game-concept.md` pillars | 冷是真的, 退赛是赌注, 苦中有美 | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* Type: **[A]** automated logic test · **[P]** playtest / screenshot evidence.

**Core rules**
1. [A] **GIVEN** a new run, **WHEN** the first tick runs, **THEN** L = F = G = 0, state = Steady, reliability_penalty = 0.00.
2. [A] **GIVEN** the game is paused for 10 real minutes, **WHEN** it resumes, **THEN** L, F, G are unchanged.
3. [A] **GIVEN** a success with base failure chance 0.05 and streak 0, **WHEN** it is reported, **THEN** F is unchanged.
4. [A] **GIVEN** a success with base failure chance 0.25 and streak 0, F = 20, **WHEN** reported, **THEN** F = 14.
5. [A] **GIVEN** the player idle in a burning fire's warm radius at core 36.5 °C, **WHEN** 20 game minutes pass, **THEN** L −4, G −3, F −3 once; **AND WHEN** another 20 minutes pass in the same game hour, **THEN** nothing more.
6. [A] **GIVEN** four fire rituals' conditions met in one day, **WHEN** counted, **THEN** only 3 applied.
7. [A] **GIVEN** state Breaking and no second wind yet today, **WHEN** a meaningful success occurs, **THEN** F drops by its lift + 20 and L by 10; a second qualifying event the same day gets no extra.
8. [A] **GIVEN** state Fraying at nightfall, **WHEN** `is_night` turns true, **THEN** exactly one `tap_out_offer("quiet")` is emitted that night.
9. [A] **GIVEN** Breaking at two consecutive nightfalls, **WHEN** the second arrives, **THEN** `tap_out_offer("plea")` is emitted; **GIVEN** a Fraying-or-better night between two Breaking nights, **THEN** the second Breaking nightfall emits `"quiet"`, not `"plea"`.
10. [A] **GIVEN** any state, **WHEN** any sequence of events runs, **THEN** the run never ends and no action is blocked by Morale.
11. [A] **GIVEN** a loss, a failure and a success in one tick, **WHEN** processed, **THEN** they apply in the order loss → failure → success and R is recomputed once.

**States**
12. [A] **GIVEN** R falls from 66 to 64.9, **WHEN** re-evaluated, **THEN** Steady → Strained; **WHEN** R then rises to 69.9, **THEN** still Strained; at 70.0 → Steady.
13. [A] **GIVEN** Steady and R drops to 15 in one tick, **WHEN** the next 3 ticks run, **THEN** the state passes Strained, Fraying, Breaking on consecutive ticks with three `state_changed` events.

**Formulas**
14. [A] F1: **GIVEN** day 1, awake by day, no keepsake, **WHEN** 1 game hour passes, **THEN** L = 0.60 ± 0.01; **GIVEN** day 10 awake at night, **THEN** +1.548 ± 0.01 per hour; **GIVEN** asleep, day 1, **THEN** +0.30.
15. [A] F2: **GIVEN** five consecutive minor failures of the same action within 2 game hours from F = 0, **WHEN** applied, **THEN** F = 30; **GIVEN** a sixth to tenth, **THEN** each adds 8 (streak capped at 4).
16. [A] F3: **GIVEN** `fire_died_unattended`, no keepsake, **THEN** G +10 and F +8; **GIVEN** G = 10 and no events, **WHEN** 25 game hours pass, **THEN** G = 0 (clamped, not negative).
17. [A] F4: **GIVEN** fullness 40, start 70 kg, now 65.8 kg, **THEN** H = 52 ± 0.5; **GIVEN** fullness 100 and weight above start, **THEN** H = 0; **GIVEN** start weight 0, **THEN** H = 0.6 × (100 − fullness) and an error is logged.
18. [A] F5: **GIVEN** core 37.0 → P = 0; 35.1 → 40 ± 0.5; 33.0 → 100; 30.0 → 100.
19. [A] F6: **GIVEN** all strains 0 → R = 100; all 100 → R = 0; L 30 · F 50 · G 20 · H 50 · P 100 → R = 31.2 ± 0.5.
20. [A] F7: **GIVEN** Fraying and an action with base failure 0.25, **WHEN** Mishaps resolves it, **THEN** effective failure chance = 0.31 and duration ×1.12; **GIVEN** Breaking and base 0.85, **THEN** effective chance is clamped to 0.90.
21. [A] Keepsakes: **GIVEN** three loneliness keepsakes at 0.85, **THEN** k_keepsake_L = 0.70 (floored), not 0.614.

**Cross-system & feel**
22. [A] **GIVEN** Body Temperature reports 35.1 °C and Needs fullness 40 / 6 % lost, **WHEN** Morale ticks, **THEN** P = 40 and H = 52 appear in the debug overlay within one tick.
23. [P] **GIVEN** a 20-second gameplay clip in each state, **WHEN** shown to 5 testers with no HUD, **THEN** ≥ 4 name the state's direction correctly (calm / struggling / breaking).
24. [P] **GIVEN** the MVP first day and night played by the owner, **WHEN** asked afterwards, **THEN** they report at least three of the six named feelings without prompting (PIVOT kill-check).
25. [P] **GIVEN** any morale-driven failure, **WHEN** a tester watches it, **THEN** they can name a physical cause shown on screen.

**Performance:** Morale's tick costs ≤ 0.05 ms per game-minute tick on the min-spec target (rule-only system; no per-frame work).

*QA gaps found and resolved: rising-threshold hysteresis (12), multi-step drop (13), keepsake floor (21), F4 guard (17), event order (11). Untestable feel lines moved to playtest criteria 23–25.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Are the default rates right — does loneliness "land" in week two, and does a bad first night reach Fraying? | systems-designer + owner | MVP playtest | debug overlay numbers vs. owner's feel notes |
| Should Breaking's `plea` ever make the survivor refuse an action (a show-like breakdown), or is that too much loss of control? | owner | before Emotional Feedback GDD | paper discussion; default is no (Core Rules §11) |
| Keepsakes help survival indirectly through F7 — does that break "纪念而非实质帮助"? | owner | Kit Selection / Meta Rewards GDD | if yes, exclude keepsakes from F7 by applying their factor only to rates, not to the state penalty |
| Does a rival tapping out comfort or deepen loneliness? Currently both (L +2, F −2). | game-designer | Rival Simulation GDD | playtest the tap-out gamble on paper |
| ~~Time scale: how many real minutes is a game hour?~~ **Resolved 2026-11-16** by `design/gdd/time-and-day-cycle.md` T3: 90 real s per daylight hour, 60 s per night hour, 3 s asleep. | Time & Day Cycle GDD | done | — |
| ~~Day length (8 h day / 16 h night assumed in F1's example)~~ **Resolved 2026-11-16** by Time T1–T2: 8.0 h daylight on day 1 shrinking to 5.0 h by day 31, plus 0.75 h dawn and dusk. F1's example stays representative. | Time & Day Cycle GDD | done | — |
| In the MVP, L relief tops out near −12/day (3 fire rituals) against +13–23/day accrual, so L saturates around week two. Bleak-by-design, or does the MVP need a small L relief (e.g. quality sleep)? | game-designer + owner | MVP playtest | debug overlay + owner feel notes; if it reads as broken rather than bleak, add a relief valve |
