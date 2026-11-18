# Gathering

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / economy-designer / systems-designer lenses)
> **Last Updated**: 2026-11-19
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 越活越懂 · 亲手做

## Summary

Gathering turns the wilderness into fire: breaking dry sticks off dead bushes, chopping logs from fallen trees with the hatchet, stripping birch bark with the knife, pulling dry grass, digging stones out of the snow. Each node gives a little per piece of work, runs out, and stays emptied; what you take has a dampness that depends on where it came from — standing dead wood is dry, wood that lay in the snow is damp, birch bark burns even wet. Knowing which is which is the first knowledge the player carries from run to run.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Interaction & Timed Actions, Item Database & Inventory, Map & Resource Distribution`

## Overview

Gathering is the resolver for Interaction's gathering actions on Map's resource nodes. When a gather action completes, Gathering takes a fixed amount from the node (Formula G1), halves it if Mishaps reports a failure, gives the produce the dampness of its source (G2) and hands it to Inventory — into the backpack, or onto the ground at the survivor's feet if the pack is full. Map scatters the nodes and keeps them visible when emptied; Interaction times the work (base durations below) and rolls each completion through Mishaps (profiles gather 0.05, strip_bark 0.10, chop_log 0.10); Inventory stores what is gathered with its wetness, mass and stacking.

For the player Gathering is most of the day: the walk to wood, the work at the node, the heavy haul back. It makes the daily rhythm concrete — a night's fire is ~8 logs, which is two loads and most of an afternoon once the near wood is gone (G3–G4) — and it carries the first lessons of 越活越懂: dead bushes give dry kindling, deadfall gives the logs but they are damp until dried at the fire, birch bark is the tinder that never fails you. Gathering owns none of the burning (Fire), carrying limits (Inventory), placement (Map) or failure odds (Mishaps).

## Detailed Design

### Core Rules

1. **Gather actions** (Interaction's catalogue; durations confirmed here):

   | Action | Node | Tool | base_game_min | Intensity | Take per completion | Mishaps profile |
   |---|---|---|---|---|---|---|
   | gather_sticks | dead bush | none | 3 | light | 3 dry sticks (+1 dry grass while the bush still has grass) | gather_sticks (0.05) |
   | gather_sticks | deadfall | none | 3 | light | 2 dry sticks (branches) | gather_sticks (0.05) |
   | chop_log | deadfall | hatchet | 4 | heavy | 1 log | chop_log (0.10) |
   | strip_bark | birch | knife | 4 | light | 2 birch bark | strip_bark (0.10) |
   | gather_grass | grass tuft | none | 2 | light | 2 dry grass | gather_sticks (0.05) |
   | gather_stones | stone pile | none | 1 | heavy | 1 stone | none (cannot fail) |

   `gather_grass` and `gather_stones` are added to Interaction's catalogue (Map listed stones as `pick_up`; digging a frozen stone out of the snow is work, so it becomes a timed heavy action — Interaction and Map should adopt the new id).
2. **Yield.** Each completion takes `take` units (or what is left) from the node's remaining yield (G1). On a Mishaps failure the player gets half of each output separately, rounded down (one bonus grass becomes 0; chop: nothing — a glancing blow). The node's remaining yield falls by what was *attempted*, not what was kept, only on success; a failure leaves the node's yield untouched (the wood is still there; you fumbled it).
3. **Dampness of produce** (G2, data table — the bushcraft lesson):

   | Source | Produce | Wetness at gathering | Why |
   |---|---|---|---|
   | dead bush (standing) | dry sticks | 0.0 | standing dead wood is dry |
   | deadfall branches | dry sticks | 0.3 | lay in the snow |
   | deadfall trunk | logs | 0.3 | outer wood damp; dries at the fire |
   | birch | birch bark | 0.0 | oily bark sheds water |
   | grass tuft (lee, under trees) | dry grass | 0.1 | sheltered |
   | grass tuft (open) | dry grass | 0.4 | snow-blown |
   | bush grass bonus | dry grass | 0.1 | |

   Forest-zone deadfall is 0.2 instead of 0.3 (less snow load under the canopy). Snowfall (VS) raises all world produce wetness.
4. **Where produce goes.** To the backpack through Inventory's pick-up rule; anything that does not fit is dropped as a pile at the survivor's feet (Interaction's overflow rule). Nothing is ever lost.
5. **Without the tool.** Without the hatchet, deadfall gives only sticks; without the knife, birch gives nothing (bark refused: "没有刀"). The fixed MVP kit has both; losing one (ice, Mishaps) is a real setback.
6. **Emptied nodes.** When remaining yield reaches 0 the node becomes emptied (Map keeps it visible: a stripped bush, a cut-up trunk, a bare birch, a dug-out hollow) and offers no action.
7. **Wear.** Each chop completion is one hatchet use; each strip one knife use (Interaction → Inventory); failures add Mishaps' damage (hatchet −10).
8. **Effort.** Intensity is reported by Interaction (light / heavy) to Body Temperature and Needs & Weight; chopping and stone-digging are heavy work (+0.6 °C/h heat, +200 kcal/h, −5 energy/h).
9. **No auto-gathering.** One completion per action; the player chooses each piece of work. (A "keep chopping" convenience — repeat until the pack is full — is an open question for playtest.)

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Node (via Map) | full · partly used · emptied | each successful completion lowers remaining yield (G1); 0 → emptied |
| Bush grass bonus | available · used up | while the bush has grass, each successful stick completion also gives 1 grass; failed completions give 0 bonus grass and leave its reserve unchanged; after its 0–2 grass are taken, sticks only |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Interaction & Timed Actions (approved) | in | completed gather actions with outcome; Gathering is their `resolver` | Interaction |
| Mishaps & Failure (approved) | in | outcome (success / failure) per completion | Mishaps |
| Map & Resource Distribution (approved) | in/out | in: node kind, zone, remaining yield; out: new remaining yield, emptied | Map |
| Item Database & Inventory (approved) | out | produce stacks with count and wetness; pick-up / overflow-to-pile | Inventory |
| Fire | out | (indirect) the fuel and tinder it will burn; wetness matters to strikes and burn | Fire |
| Body Temperature, Needs & Weight (approved) | — | effort via Interaction's intensity | Interaction |
| Weather (VS) | in | snowfall raises world-node produce wetness | Weather |
| Save/Load (Alpha) | — | node yields saved by Map | Map |

## Formulas

**G1 — Yield per completion.** The `gather_yield` formula is defined as:

`attempted = min(take[action, node], remaining)`
`kept = success ? attempted : (action == chop_log ? 0 : floor(attempted / 2))`
`remaining' = success ? remaining − attempted : remaining`

Apply G1 independently to every output, including bonus grass (O2 resolved by Scott, 2026-11-19). A failed bush attempt at 3 sticks + 1 bonus grass keeps 1 stick + 0 grass and leaves both reserves unchanged.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| take | int | 1–5 | data file (Rule 1) | units per completion |
| remaining | int | 0–10 | calculated (Map) | node yield left |
| success | bool | — | calculated (Mishaps) | |

**Output Range:** kept 0–3 per completion. **Examples:** dead bush with 7 sticks: success → **3** kept, 4 left; failure → **1** kept, 7 left; deadfall chop failure → **0** kept, logs unchanged; last 1 stick on a bush → **1**.

**G2 — Produce wetness.** The `produce_wetness` rule is defined as:

`wetness = source_wetness[source, zone] + snowfall_wet (VS, 0 in MVP)`, clamped 0–1; merged into backpack stacks by Inventory's mass-weighted rule

**Variables:** `source_wetness` (data file, Rule 3 table), `snowfall_wet` (Weather, VS). **Output Range:** 0–1. **Example:** 6 logs from an open-snow deadfall at 0.3 merged with 2 dry logs (0.0) → stack **0.225**.

**G3 — Gathering rate (derived check).** The `units_per_game_hour` estimate is defined as:

`rate = 60 / (base_game_min × dur_mult) × (1 − p_fail) × take + (fail share kept)`

**Output (healthy, dur_mult 1):** sticks from dead bushes ≈ **58/h** at the bush; logs ≈ **13.5/h** at the deadfall (15 attempts, 10 % glance); birch bark ≈ **28/h**; stones **60/h**. **Example:** a night's 8 logs at one deadfall = 8 attempts + ~1 glance ≈ **36 game min** of chopping (≈ 54 real s by day) — plus walking.

**G4 — Haul trips (derived check).** The `trips` estimate is defined as:

`trips = ceil(produce_mass / (carry_capacity_kg − current_load_kg))`

**Example:** 8 logs (20 kg) with the 6.9 kg kit and a 25 kg pack → 18.1 kg free → **2 trips**, and the first is a hauling trip (load > 70 % → heavy work, slower: Inventory I2). From a near-ring deadfall (~30 m: 0.37 game h each way, MR3) the night's wood costs ≈ 0.6 h chopping + ≈ 1.5 h walking ≈ **2 game hours ≈ 3 real minutes** — a quarter of day 1's remaining light.

*economy-designer + systems-designer lenses applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: a node at 0 still offered work — emptied state removes it; failure consuming the node would double-punish — failures leave yield untouched; half of 1 = 0 lost silently — `floor` documented (1-unit takes keep 0 on failure, including bonus grass; stones cannot fail and chop has its own zero-output rule); produce lost to a full pack — overflow to ground. Faucet/sink: Gathering is the only fuel/tinder faucet (Map's finite nodes); Fire is the sink. No dominant strategy: dead bushes give the driest kindling but no logs; deadfall gives logs but damp; birch is the best tinder but needs the knife and is finite (6–8 trees within 100 m). The depletion loop (nearest first → longer trips) is intended.*

## Edge Cases

- **If the node empties mid-action** (a second action on the same node is impossible — one action at a time): not possible in the MVP; if it happens (VS), the completion yields what remains.
- **If the pack is full**: produce drops at the feet as a pile; the player sees it.
- **If the hatchet breaks on the completing chop**: the log is kept; the next chop is refused.
- **If the survivor fails five chops in a row**: each failure costs hatchet −10 and time; Mishaps' fumble guard applies only if the cause is a fumble.
- **If a bush has grass left but no sticks** (impossible by data: grass bonus only with sticks): data validation rejects bushes with grass > sticks / 3.
- **If produce is gathered in a forest-zone deadfall**: wetness 0.2 instead of 0.3.
- **If an unknown node kind is targeted**: refuse, log.
- **If the player gathers at night by firelight**: allowed; no darkness penalty in the MVP (VS question).
- **If a save is loaded**: node yields come from Map's save; produce in the pack from Inventory's.

## Dependencies

**Upstream — hard:** Interaction & Timed Actions (approved), Item Database & Inventory (approved), Map & Resource Distribution (approved).

**Upstream — soft:** Mishaps & Failure (approved — outcomes), Weather (VS).

**Downstream:** Fire (hard: the fuel and tinder it burns), Shelter (VS: poles and boughs), Morale (indirect: gather failures via Mishaps outcomes), Inventory (stacks).

**Bidirectional check:** the systems index lists Gathering → Interaction, Item DB, Map (matches) and Fire, Shelter as dependents (matches). Interaction lists Gathering as the resolver of gather_sticks, strip_bark, chop_log (matches; adds gather_grass, gather_stones — flag for Interaction's catalogue). Map lists stones as `pick_up` — changed here to `gather_stones` (flag for Map). Mishaps' profiles (gather 0.05, strip_bark 0.10, chop_log 0.10) are used unchanged. Inventory's produce items (dry_stick, log, birch_bark, dry_grass, stone) are used unchanged.

## Visual/Audio Requirements

*art-director lens applied, against `design/art/art-bible.md` §1, §3, §5, §6.*
- **Work you can read at 69 px:** snapping sticks off a bush with both hands, a two-handed overhead chop with chips flying, peeling a white strip from the birch, kneeling to pull grass, digging a stone out with a heave (Character Tier A clips).
- **Nodes show use** (§6 无文字叙事): a bush thins with each pick, the deadfall gets shorter with cut ends (lighter wood_brown), the birch shows a dark stripped band, a stone pile leaves a dark hollow.
- **Damp is visible**: damp produce is a value step darker in the backpack sketch and on the ground (Inventory).
- **Audio:** dry snaps (dead bush) versus duller cracks (damp deadfall branches) — the player can *hear* dry wood; hatchet thocks; bark tearing; stone scrape.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:gathering` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Work is the day.** An afternoon should feel full of effort — walk, chop, haul — never "动动就干完了".
- **The land has lessons.** Dry snap or dull crack, standing or fallen — the player should start choosing their wood.
- **Every load is a decision.** One heavy haul or two light trips before dark.

## UI Requirements

- **None beyond Interaction's prompts** ("捡枯枝", "劈柴", "剥桦树皮", "拔枯草", "挖石头") and Inventory's backpack.
- **Debug overlay (dev only):** node remaining yields, produce wetness, rates.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 1 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | catalogue rows; adds gather_grass, gather_stones | approved — flag for its catalogue |
| Rules 2, 7 | Mishaps & Failure (`design/gdd/mishaps-and-failure.md`) | profiles and chop damage | approved — matches |
| Rules 1, 6 | Map & Resource Distribution (`design/gdd/map-and-resource-distribution.md`) | node kinds, yields, emptied state; stones action renamed | approved — flag for Map |
| Rules 3–4 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | produce items, wetness merge, overflow | approved — matches |
| G4 | Map MR3, Inventory I2 | travel and haul costs | approved — matches |
| Downstream | Fire (`design/gdd/fire.md`) | consumes fuel/tinder, wetness | not yet written |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** a dead bush with 7 sticks and 2 grass, **WHEN** gather succeeds, **THEN** +3 sticks (wetness 0.0) and +1 grass (0.1); the bush has 4 sticks and 1 grass left.
2. [A] **GIVEN** a deadfall with 6 logs and a hatchet, **WHEN** chop succeeds, **THEN** +1 log at wetness 0.3 (0.2 in forest) and 5 left; **WHEN** chop fails, **THEN** 0 logs, 6 left, hatchet −10 (Mishaps).
3. [A] **GIVEN** no knife, **WHEN** strip bark is pressed, **THEN** refused "没有刀".
4. [A] **GIVEN** a full pack, **WHEN** a log is produced, **THEN** it lies in a pile at the survivor's feet.
5. [A] **GIVEN** a node's last unit is taken, **THEN** the node is emptied and offers no action.
6. [A] **GIVEN** chop and gather_stones running, **THEN** Body/Needs receive heavy; gather_sticks → light.

**States**
7. [A] **GIVEN** a bush whose grass bonus is used up, **THEN** stick completions give sticks only.

**Formulas**
8. [A] G1: 7 sticks, take 3 → success 3 / left 4; failure 1 / left 7; 1 stick left → success 1.
9. [A] G2: 6 logs at 0.3 + 2 at 0.0 → 0.225 ± 0.001.
10. [A] G3 simulation: 1 game hour of chopping one deadfall, healthy → 13.5 ± 1.5 logs (seeded runs average).
11. [A] G4: 8 logs with the MVP kit → 2 trips.

**Cross-system & feel**
12. [A] **GIVEN** gathered deadfall sticks (0.3) used as kindling, **THEN** Mishaps' blow_embers damp term is 0.15 (0.5 × 0.3) (integration).
13. [P] **GIVEN** the owner's first afternoon, **THEN** gathering for the first fire feels like work and takes most of the light.
14. [P] **GIVEN** the owner's second run, **THEN** they prefer dead bushes for kindling and birch for tinder.

**Performance:** resolution ≤ 0.02 ms per completion.

*QA gaps found and resolved: failure leaves the node (2, 8), refusals (3), overflow (4), emptied state (5), grass bonus (7). Feel lines moved to playtest criteria 13–14.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| A "keep chopping until full" convenience — kinder or less physical? | owner | MVP playtest | Interaction repeat option |
| Is 1 log per 4 game min (≈ 6 s by day) too quick to feel heavy? | owner | MVP playtest | raise `base_game_min` (data) |
| Darkness penalty for gathering at night outside firelight (VS)? | game-designer | Weather / VS | — |
| Standing dead trees (VS): a third wood source — dry logs but slow to fell. | game-designer | VS | — |
| Interaction and Map should adopt `gather_grass` and `gather_stones`. | game-designer | their next revisions | — |
