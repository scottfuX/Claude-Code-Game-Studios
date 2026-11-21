# Map & Resource Distribution

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / level-designer / world-builder lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 越活越懂 · 冷是真的 · 苦中有美

## Summary

Map & Resource Distribution is the place: one hand-made patch of northern wilderness — a clearing where the survivor is dropped, a frozen lake, a low hill, belts of pine and birch, rock outcrops — and the rules for where the useful things in it lie: fallen trees, dead bushes, birch bark, dry grass, stones. The land is authored; the resources are scattered fresh each run within authored zones from a seed, so a returning player learns *patterns* (deadfall gathers at forest edges, birch grows near the lake) rather than memorising spots. Nothing regrows in the MVP: every day the wood is further away.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Terrain & Snow Surface`

## Overview

The map is content in three layers, all authored once and loaded at run start: **landform** (the heightmap and its features), **zones** (polygons that give Thermal Environment its offsets and wind exposure, and Terrain its surface types, snow depths and ice thickness), and **resource fields** (zone-weighted densities from which each run scatters resource nodes using the run's seed — Formulas MR1–MR2). It also defines the drop point, the playable bounds the Camera clamps to, and a few "good camp" sites in the lee of rocks that teach the player what shelter from the wind is worth.

The MVP map is deliberately small — 240 × 240 m playable — because walking is slow: 100 m of fresh snow costs about 1.2 game hours (MR3), so the lake and the far forest are already a real decision. Resources are arranged in rings of distance from the drop clearing: a little near camp, more further out, most at the edges. Because nodes are finite and nearest wood goes first, the walk for wood lengthens day by day — the slow pressure the brief asks for ("之后寒潮和大风让柴耗得更快、外出更危险"), built from distance rather than a timer. Animals, water holes and other VS content have reserved places here but are defined by their own GDDs.

## Detailed Design

### Core Rules

1. **One authored map.** The MVP has one map, authored by hand (concept: "地图手工制作"). Its playable area is 240 × 240 m inside a soft natural boundary (steep ridges > 35°, dense young forest, open ice beyond the lake's far shore) wider than the Camera's view so the edge is never visible as a wall.
2. **Landform** (heightmap at 1 m resolution, 241 × 241 samples; Terrain's format):

   | Feature | Where | Shape | Purpose |
   |---|---|---|---|
   | Drop clearing | west-centre | flat (≤ 4°), ~40 m across, fresh snow | the start; open, exposed, beautiful — the art bible's "空地留大片空白雪地" |
   | Low hill | north | rises 12–15 m over ~60 m (≈ 12–15°) with a rock outcrop on its south face | a climb that costs time; the outcrop's lee is the best camp site |
   | Lake | east | ~90 × 55 m flat basin, frozen, 0.05 m snow on ice | fastest walking, coldest place, thin ice near the inlet |
   | Inlet stream bed | north-east, into the lake | a shallow frozen channel | where the ice is thinnest |
   | Pine belts | ring around the clearing at 40–120 m, broken by gaps | groups of trees with open snow between (art bible §6 "树木成团出现，团与团之间留空") | wood, wind break |
   | Birch stand | south-east, near the lake shore | 10–16 birches | bark (best tinder) |
   | Hollow with drifts | south | a shallow dip; drifts 0.8–1.2 m on its east side | a trap of deep snow on the short way to the birches |
3. **Prevailing wind** blows from the north-west (world fact for authoring): drifts lie on the south-east (lee) side of trees, rocks and the hill; the lee of the outcrop and of the pine belts has the lowest wind exposure. Thermal Environment's wind *speed* is direction-free; this rule only shapes where Map paints drifts and lee zones.
4. **Zones** (polygons authored on the map; Thermal and Terrain read them):

   | Zone | Thermal (offset, exposure) | Terrain type / depth | Where |
   |---|---|---|---|
   | open snow | 0, 0.8 | fresh snow 0.35 m | clearing, gaps between belts |
   | forest | +1, 0.4 | forest snow 0.20 m | inside pine belts and the birch stand |
   | lake surface | −3, 1.0 | lake ice, 0.05 m snow; ice 25 cm, inlet 5–8 cm, reed edges 10 cm | the lake |
   | lee | 0, 0.3 | fresh snow 0.30 m, rock where scoured | the outcrop's south side; the inside of pine belts' south-east edges |
   | drift field | 0, 0.6 | drift 0.8–1.2 m | the hollow's east side; lee faces of the hill |
   | scoured ridge | 0, 1.0 | rock 0.0 m | the hill crest |

   Zone edges blend over Thermal's 5 m band; Terrain cells take the zone under their centre.
5. **Resource nodes.** A node is an interactable placed in the world with a kind, a finite yield and an availability (Interaction's actions are defined per kind):

   | Node kind | Action (Interaction) | Yield per node (seeded range) | Zones allowed |
   |---|---|---|---|
   | dead bush 枯灌木 | gather_sticks | 3–8 dry sticks + 0–2 dry grass | open snow edges, forest, lee |
   | deadfall 倒木 | gather_sticks, chop_log | 3–5 sticks; 4–8 logs | forest, forest edges, lee |
   | birch 白桦 | strip_bark | 4–8 birch bark (once) | birch stand, lake shore forest |
   | dry grass tuft 枯草丛 | gather_grass | 2–4 dry grass | lee, lake shore, under trees |
   | stone pile 石堆 | gather_stones | 6–10 stones | outcrop, stream bed, lake shore |

   Yields are finite; an emptied node stays visible as emptied (a cut stump, a stripped trunk — the art bible's "无文字叙事").
6. **Rings.** Resource counts are set per distance ring from the drop point and scattered inside allowed zones (MR1–MR2):

   | Ring (distance from drop) | Dead bushes | Deadfalls | Birches | Grass tufts | Stone piles |
   |---|---|---|---|---|---|
   | Near (0–40 m) | 8 | 3 | 0 | 4 | 1 (outcrop foot) |
   | Mid (40–100 m) | 20 | 10 | 6 | 10 | 3 |
   | Far (100–170 m) | 30 | 20 | 8 | 12 | 4 |

   Each run varies every count by ±20 % (seeded) and places nodes anew; the *pattern* (deadfall at forest edges, birch near water, stones at rock and stream) never changes.
7. **No regrowth in the MVP.** Nothing respawns. (VS: storms knock down 1–2 new deadfalls in the far ring per storm — Weather.)
8. **The drop.** The run starts at the drop point in the clearing, facing the nearest deadfall placed 20–30 m away (seeded within that band), so the brief's first minute holds: "玩家走向枯树捡枯枝".
9. **Good camp sites.** Fire can be built on any flat (≤ 8°), non-ice, non-drift spot (Fire GDD), but Map marks 3 authored "good" sites in lee zones (exposure ≤ 0.3) within 60 m of the drop — the outcrop's lee is one. They are not labelled; they read as sheltered nooks (rocks, low trees) — the first lesson of 越活越懂.
10. **Bounds and spawn safety.** Map publishes the playable polygon (Camera clamps; Character cannot leave). No node or good site is placed on ice, in drifts deeper than 0.6 m, or on slopes > 20°.
11. **Reserved VS content** (positions authored now, systems later): hare and grouse ranges (forest edges, birch stand), fish spots and ice-hole sites (lake centre, ice ≥ 20 cm), a water hole site at the inlet (open water in thaw, VS), shelter-friendly sites (lee, near poles of young trees).
    The [Food chapter proposal](food.md#core-rules) uses one of these forest-edge hare ranges; Map validates the approach and stance but does not produce the catch.

### States and Transitions

| Entity | States | Transitions |
|---|---|---|
| Resource node | full · partly used · emptied | each completed gather/chop/strip/pick-up reduces yield (resolved by Gathering); 0 → emptied (stays visible) |
| Map content | loaded · running | loaded at run start with the seed → nodes scattered → running; nothing re-scatters during a run |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Terrain & Snow Surface (approved) | out | heightmap, cell types, depths, ice thickness per cell | Map (content) / Terrain (format) |
| Thermal Environment (approved) | out | zone polygons with `zone_offset_c`, `wind_exposure` | Map (content) / Thermal (table) |
| Camera (approved) | out | playable bounds | Map |
| Character Controller & Animation (approved) | out | drop position and facing; bounds | Map |
| Gathering | out | resource nodes with kind and remaining yield | Map (placement) / Gathering (yield use) |
| Interaction & Timed Actions (approved) | out | nodes register as interactables with their actions | Map / Interaction |
| Fire | out | good camp sites (unlabelled), flat-ground rule inputs; proposed Chapter 2 reservation input below | Map / Fire |
| Mishaps & Failure (approved) | — | via Terrain's ice thickness | Terrain |
| Wildlife, Water, Food, Shelter (VS) | out | reserved ranges and sites | Map |
| Time & Day Cycle (approved) | — | none (map is time-independent) | — |
| Save/Load (Alpha) | out | seed and per-node remaining yield | Map |

Implementation note → becomes an ADR: authoring format (Godot scene with zone polygons as `Path3D`/`Polygon` data vs. external JSON) and scatter at load vs. baked per seed.

## Formulas

**MR1 — Node count per ring.** The `ring_count` formula is defined as:

`ring_count = round(base_count[ring, kind] × (1 + var × u))`, `u` uniform in [−1, 1] from the run seed

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_count | int | 0–60 | data file (Rule 6 table) | |
| var | float | 0–0.5 | data file | default 0.2 |
| u | float | −1–1 | calculated (seeded) | one draw per ring and kind |

**Output Range:** 0.8–1.2 × base. **Example:** mid-ring deadfalls 10 → **8 to 12**.

**MR2 — Placement.** The `node_placement` rule is defined as:

place each node at a random point (seeded) inside the ring ∩ allowed zones, rejecting points closer than `min_spacing_m[kind]` to another node of any kind, on slopes > 20°, on ice, or on drift deeper than 0.6 m; retry up to 30 times, then skip the node and log it

**Variables:** `min_spacing_m` (data file: bush 4, deadfall 8, birch 3, grass 3, stones 10). **Output:** node positions. **Example:** a 10-deadfall mid ring places along forest edges with ≥ 8 m between them.

**MR3 — Travel cost (derived check, for layout).** The `travel_cost` formula is defined as:

`real_s = distance_m / (base_walk × terrain_speed_mult)`, `game_hours = real_s / (60 × s_day)`

**Variables:** `base_walk` 1.4 m/s (Character), `terrain_speed_mult` (Terrain TS5), `s_day` 1.5 (Time T3). **Output Range:** — **Examples:** 30 m fresh snow → 33 s = **0.37 game h**; 100 m fresh snow → 110 s = **1.22 game h**; 100 m on a trail (0.853) → 84 s = **0.93 h**; 100 m on lake ice (0.855) → **0.93 h**; crossing the drift hollow (40 m, 0.45) → 63 s = **0.71 h** for 40 m.

**MR4 — Wood within reach (derived check).** The `fuel_by_ring` estimate is defined as:

`logs[ring] = Σ deadfalls × mean(4–8) = deadfalls × 6`; `sticks[ring] = bushes × 5.5 + deadfalls × 4`

**Output (base counts):** near **18 logs, 56 sticks**; mid **60 logs, 150 sticks**; far **120 logs, 245 sticks**. The near ring alone covers about the first night; by day 3 the player is working the mid ring (1–1.5 game h round trip) — checked against Fire's burn rates when Fire is designed.

*systems-designer + level-designer lenses applied (Section D, high-risk in Lean mode): counts at min (0.8×) and max (1.2×), zero-count kinds, and placement failure. Findings folded in: tight zones failing placement — retry cap and logging (a missing node is acceptable, a hang is not); a seed placing no deadfall near the drop — the drop-facing deadfall (Rule 8) is guaranteed; resources on thin ice luring players — excluded by MR2; total fuel unbounded — finite by design, no regrowth (MVP). Faucet/sink check: wood faucet = nodes (finite), sink = Fire; the depletion loop (closest first → longer trips → more cold and calories) is intended pressure, bounded by the far ring and Fire's burn rates.*

## Edge Cases

- **If a seed would place fewer than 2 deadfalls within 40 m**: the guaranteed drop-facing deadfall plus one forced near-ring deadfall are placed first, then the rest scatter.
- **If placement fails 30 times for a node**: skip it and log; the run continues with one fewer node.
- **If a node is emptied**: it stays as an emptied prop; Interaction no longer offers its action.
- **If the player stands at the bounds**: Character slides along the edge; Camera clamps; no invisible wall is shown (natural boundary).
- **If the drop point is in shadow at 13:00** (authoring error): validation fails at load in dev builds — the clearing must be sunlit on day 1 (beauty first).
- **If two zones overlap**: priority lake > drift field > lee > forest > open snow > scoured ridge.
- **If a save is loaded**: the seed rebuilds node positions; per-node remaining yields are restored from the save (nodes do not reroll).
- **If Weather (VS) adds new deadfalls**: they appear only in the far ring, out of the camera's view at the moment of spawn.
- **If the player chops near the drop for days**: nothing regrows — trips lengthen by design.

## Dependencies

**Upstream — hard:** Terrain & Snow Surface (approved — the format the landform and cells are authored in).

**Upstream — soft:** Thermal Environment (approved — zone table), Time (none), Weather (VS, storm deadfalls).

**Downstream:** Terrain (content), Thermal (zones), Camera (bounds), Character (drop, bounds), Gathering (hard: nodes), Interaction (interactables), Fire (camp sites), Wildlife / Water / Food / Shelter (VS sites), Save/Load.

**Bidirectional check:** the systems index lists Map → Terrain (matches) and Gathering, Water, Wildlife as dependents (matches). Terrain lists Map as the author of heightmap, types, depths and ice (matches; ice thin spots 5–10 cm here sit within Terrain's 5–10). Thermal lists Map as the zone source with the four zones open/forest/lake/lee (matches; this GDD adds drift field and scoured ridge using values inside Thermal's ranges — Thermal's table should list them at its next revision). Camera lists Map for bounds (matches). Character expects drop and bounds (matches). Index gap: Thermal, Camera, Character and Fire rows do not list Map — soft; add when convenient.

**Chapter 2 forward link:** After the [Shelter architecture gate](shelter.md#cross-references), Map supplies the authored plot and exposes a read-only footprint intersection query (XZ, including edge contact) for [FireController's new-site check](fire.md#interactions-with-other-systems). The reservation exists before framing and never covers the separate apron. Map supplies the spatial input, not the Fire verdict; the first-night profile is unchanged.

## Visual/Audio Requirements

*art-director + level-designer lenses applied, against `design/art/art-bible.md` §1, §3, §6.*
- **Composition from the gameplay camera:** the clearing leaves large empty snow (§6 孤独感); trees in groups with gaps; the lake reads as a flat, slightly bluer plane (§4 lake colder); the hill and outcrop give the one strong vertical shape; the day-1 sun makes long blue shadows across the clearing.
- **Readable resources at ~69 px figure scale:** deadfall as a dark diagonal log against snow (≥ 8 px wide at default framing — §1's 8 px rule), dead bushes as bare grey-brown tangles, birch trunks white with dark bands, stone piles as blunt grey shapes (§3 shape language).
- **Emptied nodes stay** as stumps, stripped trunks, bare ground patches — the map records the run.
- **Thin ice** darker blue patches around the inlet, visible from the gameplay camera.
- **Audio:** each zone has an ambience bed (open — wind; forest — creaks and softer wind; lake — ice tension sounds; hill crest — strongest wind).

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:map-and-resource-distribution` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Game Feel

- **Every trip is a choice.** The lake is fast but cold; the hollow is short but deep; the forest edge is sheltered but further. A player should argue with themselves about which way to go.
- **The land teaches.** By the second run a player should look for deadfall at forest edges and birch by the water without being told.
- **Your camp changes the map.** Stumps, trails and the woodpile make the clearing *yours* over days (亲手做).

## UI Requirements

- **No minimap, no markers** in play. Orientation comes from landmarks (hill, lake, outcrop) and the player's trails.
- **Debug overlay (dev only):** zones, rings, nodes with remaining yields, seed, good camp sites, bounds.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rules 2, 4 | Terrain & Snow Surface (`design/gdd/terrain-and-snow-surface.md`) | heightmap format, types, depths, ice thickness | approved — matches |
| Rule 4 | Thermal Environment (`design/gdd/thermal-environment.md`) | zone offsets and exposure; adds drift field and scoured ridge within Thermal's ranges | approved — flag for Thermal's table |
| Rule 10 | Camera (`design/gdd/camera.md`) | bounds | approved — matches |
| Rule 8 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | drop, base walk 1.4 m/s (MR3) | approved — matches |
| Rule 5 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | node actions | approved — matches |
| Rule 5 | Item Database & Inventory (`design/gdd/item-database-and-inventory.md`) | sticks, logs, bark, grass, stones | approved — matches |
| Rules 5–7, MR4 | Gathering, Fire | yields used; burn-rate check | not yet written — provisional |
| Rules 1, 8 | `design/game-brief.md`, `design/gdd/game-concept.md` | hand-made map; first minute; one map | exists |
| Visual | `design/art/art-bible.md` §1, §3, §4, §6 | composition, shapes, lake colder, density, storytelling | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** any seed, **THEN** the playable area is 240 × 240 m and every node, good site and the drop lie inside it.
2. [A] **GIVEN** any seed, **THEN** a deadfall lies 20–30 m from the drop in the facing direction, and at least 2 deadfalls lie within 40 m.
3. [A] **GIVEN** 100 seeds, **THEN** no node is placed on ice, on drift > 0.6 m, or on a slope > 20°.
4. [A] **GIVEN** any seed, **THEN** 3 good camp sites exist in lee zones (exposure ≤ 0.3) within 60 m of the drop.
5. [A] **GIVEN** a node emptied by Gathering, **THEN** it remains as an emptied prop and offers no action.
6. [A] **GIVEN** 30 game days with no Weather, **THEN** the node count never increases (no regrowth).
7. [A] **GIVEN** the lake, **THEN** ice is 25 cm except the inlet (5–8 cm) and reed edges (10 cm); Terrain reports those values.

**States**
8. [A] **GIVEN** a save and load, **THEN** node positions are identical (same seed) and remaining yields match the save.

**Formulas**
9. [A] MR1: 100 seeds for mid-ring deadfalls give counts only in 8–12, mean 10 ± 0.5.
10. [A] MR2: nodes of the same kind are never closer than their `min_spacing_m`; placement failures are logged, never hang.
11. [A] MR3: 100 m fresh snow → 110 ± 1 s / 1.22 ± 0.01 game h; 100 m trail → 0.93 ± 0.02 h.
12. [A] MR4: base counts give near 18 logs / 56 sticks, mid 60 / 150, far 120 / 245 (expected values).

**Cross-system & feel**
13. [A] **GIVEN** the zone map, **WHEN** Thermal is queried in the outcrop's lee, **THEN** exposure 0.3 and wind chill 1.08 °C at 3 m/s (integration).
14. [P] **GIVEN** a day-1 screenshot from the default camera at the drop, **THEN** testers can point out the hill, the lake and a deadfall without labels.
15. [P] **GIVEN** the owner's second run, **THEN** they head for forest edges for wood and birches near the lake for tinder without searching the whole map (pattern learning).
16. [P] **GIVEN** day 3 of the MVP, **THEN** the owner reports that wood is "further away now".

**Performance:** scatter at load ≤ 200 ms for all nodes; node queries ≤ 0.05 ms.

*QA gaps found and resolved: guaranteed first deadfall (2), placement exclusions (3), good sites (4), no regrowth (6), save/seed determinism (8). Feel lines moved to playtest criteria 14–16.*

## Open Questions

**Shelter/food integration (owner-approved):** the eastern 90 × 55 m lake occupies x=25–115 m, z=−10–45 m. It is shifted 25 m south of the Phase B draft so the authored hare trail, stance and approach remain on snow with at least a 4 m shoreline margin. Hare locations are unchanged. Shore resource bands, Thermal zones and the 0.5 m ice grid follow the relocated lake; thin ice remains on its northern inlet and western shore.

The large ground reuses the existing SnowSurface and its shelter clear-snow port at the full world extent. A lake-bounds cutout and 2 m shore blend keep snow off the ice; lake movement does not inherit fresh-snow resistance. The west-bank stone band extends north and widens inland to retain near-ring placement after the shore moves. First-night lake cutouts remain disabled.

**Phase B own call (owner-approved reversible default):** only the three-night profile uses the 240 × 240 m map and seeded rings. Collision remains flat at y=0; the hill, heightfield and slope costs are deferred to the ADR-0004 terrain/Jolt spike. The central clearing is ~40 m across (rather than the original west-centre drop); zones are authored rectangles, with flat frozen lake visuals. The first-night map/demo retains its original layout. Lake break-through and thin-ice cells follow in Phase C; drifts/ridge are thermal zone data, not changes to snow rendering or animation. Far-ring placement is clipped to the square playfield. Counts can fall short only after the GDD's logged 30-retry limit.

**Phase C own calls (owner-approved reversible defaults):** `LakeSurface.surface_at` / `break_ice` own a temporary 0.5 m lake grid for the three-night profile. Normal ice is 25 cm; seeded 5–10 cm bands on the northern inlet and western shore cover approximately 15% of cells, shown in muted grey-blue. Broken cells are open water and block subsequent walking, without another roll. Footfalls are sampled every 0.7 m of horizontal travel independently of presentation trails. Inventory has no carried-load model yet, so M4 receives load fraction zero. Escape locks gameplay input, struggles for 4 real seconds, then moves at 1.2 m/s to the nearest shore or intact thick-ice cell. Immersion preserves target-owned chop progress; other current actions discard it. No Morale owner exists yet, so the major helplessness notification is deferred. These ports do not implement the terrain heightfield or change footprint/trail ownership.

| Question | Owner | Resolve by | How |
|---|---|---|---|
| Is 240 × 240 m right? 100 m costs ~1.2 game hours; the far ring is a half-day expedition. | owner + level-designer | MVP playtest | resize rings (data) before resizing the map |
| Are ring counts enough for the VS run length (up to 60 days)? MVP covers ~3 days. | economy-designer | Fire GDD + VS planning | add storm deadfalls (Weather) or a larger VS map |
| Should resource positions be fixed per map (pure memory) instead of seeded per run? Seeded supports pattern learning; fixed supports route mastery. | owner | MVP playtest | data toggle |
| VS: unlockable places (concept) — one new small map per unlock or new regions of this one? | game-designer | Meta Rewards GDD | — |
| Thermal's zone table should list drift field and scoured ridge. | systems-designer | Thermal's next revision | — |
