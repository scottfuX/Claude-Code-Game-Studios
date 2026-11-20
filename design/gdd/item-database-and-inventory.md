# Item Database & Inventory

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (economy-designer / systems-designer / game-designer lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 亲手做 · 退赛是赌注

## Summary

Item Database & Inventory defines every thing the survivor can carry — tools, fuel, tinder, food, clothing, later keepsakes — as data, and holds where each one is: in the backpack, worn, or lying in a pile in the world (the woodpile by the fire). It enforces a carrying limit by weight that makes hauling wood heavy work, tracks which wood and tinder are damp, wears tools down, and reports losses — the axe through the ice is a real, felt event. It also fixes the MVP's starting kit of 10 items, with about two days of food so that hunger arrives on day 3 as the brief asks.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

The **Item Database** is a read-only table of item definitions (Core Rule 2) that every gameplay system reads: Needs & Weight reads `food_kcal` and `drink_hydration`, Fire reads fuel and tinder values, Gathering produces resource items, Body Temperature reads clothing insulation through Inventory. The **Inventory** holds item *stacks* in three kinds of container — the backpack (weight-limited), worn slots, and world piles (unlimited, at a location) — and owns per-stack state: count, wetness (0–1) and, for tools, durability. It reports two numbers that shape how the game feels: how loaded the survivor is (which slows them — Formula I2) and the clothing insulation (I3).

For the player this system is mostly invisible except in three moments that matter to the fantasy: deciding what to carry back (a full pack of logs is slow and tiring — "Heavy effortful 为主"), finding that the tinder got wet (a cause the player can read and fix by drying it at the fire), and losing something they cannot replace. The MVP kit is fixed (Kit Selection lets the player choose 10 items from the VS on). This GDD does not own how items are *used* — fuel burn belongs to Fire, eating to Needs & Weight, chopping to Gathering, failure rolls to Mishaps.

## Detailed Design

### Core Rules

1. **Items are data.** Every item is a row in a data file. Systems refer to items by `id` only; no system hard-codes item values.
2. **Item fields:**

   | Field | Type | Meaning | Used by |
   |---|---|---|---|
   | `id` | string | unique key | all |
   | `name_key` | string | localisation key (no literal text) | UI, Localization |
   | `category` | enum | tool · fuel · tinder · food · container · clothing · shelter_material · keepsake · misc | all |
   | `mass_kg` | float | mass of one unit | Inventory (I1) |
   | `stack_max` | int | units per stack in the backpack | Inventory |
   | `food_kcal` | float or none | calories when eaten | Needs & Weight |
   | `drink_hydration` | float or none | hydration when drunk | Needs & Weight |
   | `eat_minutes` | float | game minutes to eat/drink (default 5) | Needs & Weight, Interaction |
   | `fuel_value` | float or none | fuel units (provisional — semantics owned by Fire) | Fire |
   | `tinder_quality` | float or none | 0–1, how easily it catches (provisional — Fire / Mishaps) | Fire, Mishaps |
   | `can_get_wet` | bool | whether stacks track wetness | Inventory, Fire, Mishaps |
   | `durability_max` | int or none | uses before breaking (tools) | Inventory, Interaction |
   | `insulation` | float or none | clothing insulation when worn | Inventory (I3) → Body Temperature |
   | `sleep_insulation_bonus` | float or none | extra insulation while asleep (sleeping bag) — active from the VS (see Open Questions) | Inventory (I3) |
   | `keepsake_strain`, `keepsake_factor` | enum, float | VS: which Morale strain it eases and by how much (Morale §10) | Morale |
   | `kit_eligible` | bool | can be one of the 10 kit items (VS) | Kit Selection |
   | `world_model`, `icon` | refs | presentation | rendering, UI |

   Fields marked "provisional" may be renamed by the owning GDD; Inventory only stores them.
3. **Containers.**
   - **Backpack** — weight-limited (`carry_capacity_kg`, default 25 kg), stacks up to `stack_max`.
   - **Worn** — clothing slots (MVP: one "winter clothing" set, always worn) plus the satellite radio and camera, which are provided by the show and never count against the kit or the weight limit.
   - **World pile** — a location in the world holding any number of stacks, no weight limit. Dropping items creates or joins the nearest pile within 1.5 m. A pile within a fire's `warm_radius` is a *camp pile* (dries; see I4). Piles persist across the run.
4. **Picking up and dropping.** Picking up adds to the backpack only if the new total mass ≤ `carry_capacity_kg`; otherwise the pick-up takes as many units as fit and refuses the rest ("背不动了"). Dropping is always allowed. Both are Interaction actions; this GDD defines the result.
5. **Stacks and wetness.** Each stack of a `can_get_wet` item has one `wetness` (0–1). Merging two stacks gives the mass-weighted average wetness. Wetness rises from events (`fell_in_water` → backpack fuel and tinder set to 1.0; snowfall on uncovered world piles, VS) and dries by I4. Fire and Mishaps read wetness (damp tinder fails; wet wood smokes).
6. **Durability.** Each tool stack (always `stack_max` 1) has `durability` from `durability_max`. Interaction reports a *use* (one swing, one strike); durability falls by 1. Mishaps may report a *damage* event (e.g. −50 for a bad swing into frozen wood). At 0 the tool breaks: it is removed and emits `loss{kind: item_lost, item_class: tool}`.
7. **Losses.** Any removal not by use, eating or burning — a tool through the ice, a dropped item lost in deep snow (Mishaps decides when) — emits `loss{kind: item_lost, item_class: tool | other}` with the item id. Morale & Mental State turns it into grief (F3).
8. **Consumption.** Eating, drinking and burning remove units at the request of the consuming system (Needs & Weight, Fire); they never emit `loss`.
9. **Load and speed.** Inventory publishes `carry_load_frac` (I1) and `carry_speed_mult` (I2). Character Controller multiplies it with Body Temperature's and Needs & Weight's movement multipliers. A full pack also adds the "hauling" activity flag, which Body Temperature and Needs & Weight treat as heavy work while walking (heat +0.6, energy −5 per hour, burn +200 kcal per hour).
10. **Insulation.** Inventory publishes `insulation` (I3) to Body Temperature: the worn clothing's value; the sleeping bag's bonus is defined but **inactive in the MVP** (Body Temperature, approved, fixes MVP insulation at 1.0).
11. **The MVP kit** (fixed; Kit Selection replaces it in the VS):

    | # | Item | Units | Why in the MVP |
    |---|---|---|---|
    | 1 | hatchet 斧头 | 1 | chopping (Gathering) |
    | 2 | knife 刀 | 1 | carving feather sticks, prep (Gathering, Fire) |
    | 3 | ferro rod 打火棒 | 1 | striking (Fire) |
    | 4 | pemmican 肉糜饼 | 8 portions | ≈ 2 days of food with the starting stomach (Needs) |
    | 5 | cooking pot 锅 | 1 | carried for continuity; used from the VS (Water) |
    | 6 | tarp 篷布 | 1 | VS (Shelter) |
    | 7 | sleeping bag 睡袋 | 1 | carried; bonus active from the VS |
    | 8 | paracord 伞绳 | 1 | VS (Shelter, Food) |
    | 9 | fishing kit 渔具 | 1 | VS (Food) |
    | 10 | snare wire 套索线 | 1 | VS (Food) |

    Total kit mass ≈ 6.9 kg — about a quarter of the backpack, leaving room for ~7 logs.
12. **MVP item table** (data-file defaults; register in `design/registry/entities.yaml`):

    | id | category | mass_kg | stack_max | food_kcal | fuel_value | tinder_quality | can_get_wet | durability_max | insulation |
    |---|---|---|---|---|---|---|---|---|---|
    | hatchet | tool | 1.0 | 1 | — | — | — | no | 600 | — |
    | knife | tool | 0.2 | 1 | — | — | — | no | 800 | — |
    | ferro_rod | tool | 0.1 | 1 | — | — | — | no | 1000 | — |
    | pemmican | food | 0.1 | 8 | 500 | — | — | no | — | — |
    | cooking_pot | container | 0.8 | 1 | — | — | — | no | — | — |
    | tarp | shelter_material | 1.2 | 1 | — | — | — | yes | — | — |
    | sleeping_bag | clothing | 2.0 | 1 | — | — | — | yes | — | (sleep bonus 0.5, VS) |
    | paracord | shelter_material | 0.4 | 1 | — | — | — | no | — | — |
    | fishing_kit | tool | 0.2 | 1 | — | — | — | no | 300 | — |
    | snare_wire | tool | 0.2 | 1 | — | — | — | no | 50 | — |
    | winter_clothing | clothing (worn) | — | 1 | — | — | — | yes | — | 1.0 |
    | birch_bark 桦树皮 | tinder | 0.05 | 30 | — | 1 | 0.9 | yes | — | — |
    | dry_grass 枯草 | tinder | 0.02 | 30 | — | 0.5 | 0.7 | yes | — | — |
    | feather_stick 羽毛棒 | tinder | 0.2 | 10 | — | 3 | 0.8 | yes | — | — |
    | dry_stick 枯枝 | fuel | 0.2 | 20 | — | 6 | 0.3 | yes | — | — |
    | log 柴 | fuel | 2.5 | 8 | — | 60 | — | yes | — | — |
    | stone 石头 | misc | 2.0 | 5 | — | — | — | no | — | — |

    `fuel_value` and `tinder_quality` are provisional placeholders sized for Fire to confirm. `feather_stick` is made by `carve_feather_stick` (Fire); wetness = source stick × 0.5.

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Stack | in backpack · worn · in world pile · consumed · lost · broken | pick up (pile → backpack, if it fits) · drop (backpack → pile) · equip (backpack ↔ worn) · consume (→ consumed) · loss event (→ lost) · durability 0 (→ broken) |
| Stack wetness | dry (< 0.2) · damp (0.2–0.7) · wet (> 0.7) | continuous via I4 and events; the bands are what Fire / Mishaps and the UI read |
| World pile | open · camp pile (within a burning fire's `warm_radius`) | fire lit nearby / fire out or moved |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Interaction & Timed Actions | in/out | in: pick up, drop, use, eat, drink requests; out: results and refusals ("背不动了") | Interaction / Inventory |
| Gathering | in | adds resource stacks (birch_bark, dry_grass, dry_stick, log, stone) | Gathering |
| Fire | in/out | out: fuel and tinder stacks with `fuel_value`, `tinder_quality`, `wetness`; in: consume units, `warm_radius` (camp piles) | Fire / Inventory |
| Needs & Weight (approved) | in/out | out: `food_kcal`, `drink_hydration`, `eat_minutes`; in: consume one unit | Item DB / Needs |
| Body Temperature (approved) | out | `insulation` (MVP 1.0) | Inventory |
| Character Controller & Animation | out | `carry_load_frac`, `carry_speed_mult`, hauling flag | Inventory |
| Mishaps & Failure | in/out | in: `fell_in_water`, tool damage, item-lost events; out: wetness and durability of the stack in use | Mishaps / Inventory |
| Morale & Mental State | out | `loss{item_lost}`; carried keepsakes (VS) | Inventory |
| Thermal Environment (approved) | in | `effective_temp_c` at a pile (drying, I4) | Thermal |
| Time & Day Cycle (approved) | in | `minute_tick` (drying) | Time |
| Kit Selection (VS) | in | the chosen 10 items replace Rule 11 | Kit |
| HUD / Screens & Menus | out | backpack contents, load, wetness bands | Inventory |
| Save/Load (Alpha) | out | all stacks, containers, piles and their state | Inventory |

## Formulas

**I1 — Load.** The `carry_load_frac` formula is defined as:

`carry_load_frac = Σ(mass_kg × count) over backpack stacks / carry_capacity_kg`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| mass_kg | float | 0.01–10 | data file | per unit |
| count | int | 0–stack_max | calculated | units in the stack |
| carry_capacity_kg | float | 10–40 | data file | default 25; must be > 0 |

**Output Range:** 0–1 (pick-ups beyond 1 are refused). **Example:** MVP kit (6.9 kg) + 6 logs (15 kg) + 10 sticks (2 kg) = 23.9 kg → **0.956**.

**I2 — Carry speed.** The `carry_speed_mult` formula is defined as:

`carry_speed_mult = 1 − s_load × max(0, (carry_load_frac − l_free) / (1 − l_free))`; hauling flag = `carry_load_frac > l_haul`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| s_load | float | 0–0.6 | data file | slow-down at a full pack (default 0.3) |
| l_free | float | 0–0.9 | data file | load carried without slowing (default 0.5); must be < 1 |
| l_haul | float | 0.3–1.0 | data file | load at which walking counts as heavy work (default 0.7) |

**Output Range:** 0.70–1.00. **Example:** load 0.956 → 1 − 0.3 × 0.912 = **0.73**, and hauling (heavy work). The kit alone (0.276) → **1.00**.

**I3 — Insulation.** The `insulation` formula is defined as:

`insulation = clamp(Σ worn insulation + (is_asleep and sleep_bonus_active ? sleep_insulation_bonus : 0), ins_min, ins_max)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| worn insulation | float | 0–2 | data file | winter_clothing 1.0 |
| sleep_insulation_bonus | float | 0–1 | data file | sleeping_bag 0.5 |
| sleep_bonus_active | bool | — | data file | false in the MVP (Body Temperature fixes MVP insulation at 1.0) |
| ins_min / ins_max | float | — | constant | 0.5 / 2.0 (Body Temperature's valid range) |

**Output Range:** 0.5–2.0; MVP always **1.0**. **Example (VS):** asleep in the bag → **1.5**.

**I4 — Stack drying.** The `stack_wetness_rate` formula is defined as (per game hour):

`stack_wetness_rate = −(T ≥ dry_hot_c ? dry_fast : T ≥ 0 ? dry_slow : 0)` with `T = effective_temp_c` at the stack (in the backpack: at the player)

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| dry_hot_c | float | 5–20 | data file | default 10 (by a fire) — same threshold as Body Temperature's B2 |
| dry_fast | float | 0.2–1.0 | data file | default 0.5 per hour |
| dry_slow | float | 0–0.2 | data file | default 0.05 per hour |

**Output Range:** −0.5 to 0 per hour; wetness clamps 0–1. **Example:** soaked birch bark (1.0) on a camp pile at felt +12 °C: dry (< 0.2) in **1.6 game hours**; in the backpack outdoors at −4 °C: **never**.

**I5 — Durability.** The `durability` update is defined as:

`durability' = max(0, durability − uses × 1 − damage)`; broken when `durability' = 0`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| durability_max | int | 1–5000 | data file | hatchet 600 · knife 800 · ferro_rod 1000 · fishing_kit 300 · snare_wire 50 |
| uses | int | ≥ 0 | calculated | reported by Interaction |
| damage | int | 0–durability_max | calculated (Mishaps) | bad-use damage |

**Output Range:** 0 to `durability_max`. **Example:** a hatchet at ~40 swings per log and ~3 logs per day lasts **≈ 5 days of chopping** before Mishaps damage — wear is felt over a season, not in the MVP's first three days.

*economy-designer + systems-designer lenses applied (Section D, high-risk in Lean mode): every variable worked at min, max and 0. Findings folded in: `carry_capacity_kg = 0` → division by zero (I1) — rejected at load; `l_free = 1` → division by zero (I2) — rejected; negative wetness or durability — clamped. Faucets and sinks: food faucet in the MVP = the 8 pemmican portions only (4,000 kcal + 1,200 in the stomach = 5,200 kcal against ≈ 1,900 on the half first day and ≈ 3,500 on day 2 — the stomach first stays empty in the night of day 2, so hunger lands on day 3 as the brief asks; with 6 portions it lands on day 2); fuel faucet = Gathering (finite per Map); fuel sink = Fire. No dominant item: there is no currency and no trading. A hatchet hauling-and-chopping loop is bounded by weight, energy and daylight. Hatchet durability (≈ 5 days at a hard pace) is the first replaceable-not-replaceable pressure; tuning flagged as an open question.*

## Edge Cases

- **If a pick-up would exceed capacity**: take as many units as fit; refuse the rest with "背不动了"; the rest stays in the pile.
- **If an item's single unit is heavier than the free capacity** (a log with 1 kg free): refuse entirely.
- **If two stacks of the same item merge with different wetness**: mass-weighted average wetness.
- **If a stack would exceed `stack_max`**: overflow opens a new stack.
- **If the player falls into water**: backpack fuel and tinder stacks → wetness 1.0; food and tools unaffected; worn clothing wetness is Body Temperature's (B2).
- **If the last ferro rod is lost or breaks**: no special rule here — Fire decides whether another ignition source exists; Morale receives `item_lost(tool)`.
- **If a camp pile's fire goes out**: the pile stops being a camp pile; drying falls to the ambient rate.
- **If a dropped item lands within 1.5 m of two piles**: it joins the nearest.
- **If an item id is unknown or a field is missing**: refuse the operation and log an error; never invent values.
- **If data gives `carry_capacity_kg ≤ 0`, `l_free ≥ 1` or negative masses**: reject at load, use defaults.
- **If the inventory is loaded from a save**: restore every stack, its container, count, wetness and durability exactly; camp-pile status recomputes from Fire on the first tick.
- **If the player tries to drop a worn item, the radio or the camera**: refused in the MVP (they are part of the show's kit).

## Dependencies

**Upstream — hard:** none (Foundation; the item table is data).

**Upstream — soft:** Time & Day Cycle (`minute_tick` for drying), Thermal Environment (`effective_temp_c` at piles and at the player), Fire (`warm_radius` for camp piles), Mishaps (wetness, damage and loss events), Needs & Weight (`is_asleep` for I3, VS only).

**Downstream:** Gathering, Fire, Needs & Weight (hard: food values), Body Temperature (`insulation`), Character Controller (load, speed, hauling flag), Interaction, Mishaps, Morale (`item_lost`), Shelter, Water, Food, Kit Selection (VS), HUD, Screens & Menus, Save/Load.

The [Food chapter proposal](food.md#core-rules) reuses Rule 11's pemmican count and wire. It supplies two chapter-only item rows; Inventory owns the wear, catch transfer, batch replacement and consumption plans.

**Bidirectional check:** the systems index lists Item DB with no dependencies (matches: its upstreams are soft). Needs & Weight lists `food_kcal`, `drink_hydration`, `eat_minutes` and "MVP kit ≈ 2 days of food" as provisional on this GDD — all supplied (pemmican 8 × 500 kcal). Body Temperature lists `insulation` from Item DB / Kit with MVP 1.0 — matches (I3, sleep bonus inactive). Morale lists `loss{item_lost, item_class}` and keepsakes — matches. Gap: the index row for Character Controller does not list Item DB (load and speed are soft inputs — fix when that GDD is written).

## Visual/Audio Requirements

Optional for an Economy system; written for the three readable moments.
- **Load is visible:** the backpack silhouette grows with load; a hauling survivor leans forward with a shorter stride (art bible §1 大块面 — read at the far camera).
- **Piles are readable:** the woodpile by the fire is a hand-stacked, slightly crooked cone (art bible §3, 人造物都是临时的; colour wood_brown). Wet stacks read a step darker with a frost rim.
- **Loss lands:** an item lost through ice or into deep snow gets a short, clear beat (it slips, sinks) — the cause must be visible (Mishaps), the grief is Morale's.
- **Audio:** the clack of logs set down, the thud of a full pack, the dull crack of a breaking tool.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:item-database-and-inventory` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **What you carry is a choice.** Bringing back seven logs should feel heavy and slow but worth it; two trips should feel safer but cost daylight.
- **Damp is a puzzle, not a lottery.** The player should learn to keep tinder dry and dry it at the fire — wetness is always visible on the item.
- **Losses hurt because things are few.** Ten items and no shop: every loss is personal.

## UI Requirements

- **Backpack screen (Tab)** in the art bible's paper-and-ink style (§4, §7 constraint): items drawn as small sketches with counts, a load gauge (no exact kg — a hand-drawn bar), wetness shown by a droplet icon and darker sketch (never colour alone). MVP may ship a minimal list version; the full screen is Screens & Menus (VS).
- **Pick-up feedback:** "背不动了" when refused.
- **Debug overlay (dev only):** all stacks with mass, wetness, durability; load; piles near the player.

> **📌 UX Flag — Item Database & Inventory**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2, 11, 12 | Needs & Weight (`design/gdd/needs-and-weight.md`) | `food_kcal`, `drink_hydration`, `eat_minutes`; stomach 1,500 kcal; hunger on day 3 | approved — matches |
| Rules 9, 10, I3 | Body Temperature (`design/gdd/body-temperature.md`) | `insulation` 1.0 in the MVP; heavy-work heat for hauling | approved — matches |
| Rules 6, 7 | Morale & Mental State (`design/gdd/morale-and-mental-state.md`) | `loss{item_lost, item_class}`; keepsake fields (§10) | in review — matches |
| I4 | Thermal Environment (`design/gdd/thermal-environment.md`) | `effective_temp_c` at a stack | approved — matches |
| Rules 2, 12 | Fire (`design/gdd/fire.md`) | `fuel_value`, `tinder_quality`, wetness semantics | not yet written — provisional |
| Rules 5–7 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | wetness, damage, loss events | not yet written — provisional |
| Rules 4, 12 | Gathering (`design/gdd/gathering.md`) | produces resource items | not yet written |
| Rule 11 | Kit Selection (`design/gdd/kit-selection.md`) | replaces the fixed MVP kit | VS |
| Rule 11 | `design/gdd/game-concept.md` / `design/game-brief.md` | 10 items; "第 3 天起饱腹不够" | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a new MVP run, **THEN** the backpack holds exactly the 10 kit items of Rule 11 (pemmican × 8), winter clothing is worn, and the load is 6.9 ± 0.05 kg.
2. [A] **GIVEN** 24.0 kg carried, **WHEN** picking up a 2.5 kg log, **THEN** refused with "背不动了"; **GIVEN** 20 kg carried and a pile of 4 logs, **THEN** 2 logs are taken and 2 remain.
3. [A] **GIVEN** a dry birch-bark stack (0.0, 10 units) merged with a wet one (1.0, 10 units), **THEN** one stack of 20 at wetness 0.5.
4. [A] **GIVEN** `fell_in_water`, **THEN** every backpack fuel and tinder stack has wetness 1.0 and pemmican/tools are unchanged.
5. [A] **GIVEN** a hatchet at durability 1, **WHEN** one use is reported, **THEN** it is removed and one `loss{item_lost, tool}` is emitted; **GIVEN** a pemmican eaten, **THEN** no `loss` is emitted.
6. [A] **GIVEN** Mishaps reports a hatchet lost through ice, **THEN** it is removed and `loss{item_lost, tool, hatchet}` is emitted once.
7. [A] **GIVEN** items dropped 1.0 m from an existing pile, **THEN** they join it; at 2.0 m, a new pile is created.
8. [A] **GIVEN** an unknown item id in a pick-up request, **THEN** refused and an error logged.

**States**
9. [A] **GIVEN** a pile within a burning fire's `warm_radius`, **THEN** it is a camp pile; **WHEN** the fire goes out, **THEN** it is not.

**Formulas**
10. [A] I1: kit + 6 logs + 10 sticks → 0.956 ± 0.002.
11. [A] I2: load 0.956 → 0.727 ± 0.005 and hauling = true; load 0.276 → 1.00 and hauling = false; load 0.7 → 0.88, hauling false; load 0.71 → hauling true.
12. [A] I3: MVP awake → 1.0; MVP asleep → 1.0 (bonus inactive); VS asleep with bag → 1.5.
13. [A] I4: wetness 1.0 at felt +12 °C → < 0.2 after 1.6 game hours ± 0.05; at −4 °C → still 1.0 after 5 game hours.
14. [A] I5: hatchet 600, 599 uses → 1 left; 50 damage at 30 left → 0, broken.
15. [A] Data with `carry_capacity_kg = 0` or `l_free = 1` is rejected and defaults are used.

**Cross-system & feel**
16. [A] **GIVEN** the MVP kit and the Needs & Weight defaults, **WHEN** a scripted run follows Needs & Weight's N1 typical-day schedule from 13:00 on day 1 and eats a pemmican whenever fullness ≤ 60, **THEN** fullness first stays at 0 for ≥ 3 consecutive game hours on day 3, not before (the brief's hunger beat).
17. [A] **GIVEN** a hauling load, **WHEN** the survivor walks for 1 game hour, **THEN** Needs burns +200 kcal and Body adds +0.6 °C/h activity heat (heavy work) instead of walking values.
18. [P] **GIVEN** the owner hauls a full pack of logs back to camp, **THEN** they describe it as heavy, and choose between one heavy trip or two light ones at least once.
19. [P] **GIVEN** a screenshot of a wet and a dry tinder stack in the backpack screen, **THEN** a tester can tell them apart in greyscale.

**Performance:** ≤ 0.1 ms per pick-up/drop; drying update ≤ 0.05 ms per tick for up to 50 stacks.

*QA gaps found and resolved: partial pick-up (2), wetness merge (3), loss vs consumption (5), pile join radius (7), unknown ids (8), haul threshold boundary (11). Feel lines moved to playtest criteria 18–19.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Activate the sleeping bag's +0.5 insulation in the MVP? It would soften night-1 deaths in sleep, but Body Temperature (approved) fixes MVP insulation at 1.0 — needs a small Body revision. | owner | before the MVP build | if yes, set `sleep_bonus_active = true` and revise Body Temperature AC1 and Rule 1 |
| Hatchet lasts ≈ 5 hard days of chopping. Too fragile for a season? | economy-designer + owner | MVP / VS playtest | tune `durability_max` (data) |
| `fuel_value` (stick 6, log 60) and `tinder_quality` are placeholders. | Fire GDD | next Fire GDD | Fire confirms or renames |
| Should logs be carried in the arms (no pack, can't act while carrying) instead of the backpack? More physical, more complex. | game-designer | Character Controller GDD | — |
| Do world piles get wet in snowfall without the tarp over them? | systems-designer | Weather GDD (VS) | add a cover flag to piles |
