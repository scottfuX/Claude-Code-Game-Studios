# Cross-GDD Review Report — Lonefire（孤火）

Date: 2026-11-17
GDDs Reviewed: 18 of 18 present (all MVP-tier system GDDs + game-concept.md + systems-index.md + entities.yaml + art-bible.md)
Not read: none (all GDDs readable, none empty)
Focus: full
Systems Covered: Input & Action Map · Time & Day Cycle · Terrain & Snow Surface · Map & Resource Distribution · Character Controller & Animation · Camera · Thermal Environment · Interaction & Timed Actions · Mishaps & Failure · Gathering · Fire · Body Temperature · Needs & Weight · Morale & Mental State · Item Database & Inventory · Emotional Feedback · Ambient & Foley Audio · HUD
Pillars: 冷是真的 · 越活越懂 · 退赛是赌注 · 苦中有美 · 亲手做 — Anti-pillars: no stat-bar chore loop, no power growth/skill trees, no fail-safe easiness, no combat/dangerous beasts (v1), no photorealism/permanent housing.
Entity registry: populated (11 items, 17 formulas, 20 constants) and used as the conflict baseline.

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)

None found. Every cross-system contract verified (Mishaps penalties summed & clamped ≤ 0.90; `warm_radius` = Fire's registered `radius_m`; `is_asleep` owned by Needs; movement multipliers composed by Character with a floor; action duration capped by Interaction at 2.0) is consistent between the defining and consuming documents.

#### Warnings (should resolve, but won't block)

⚠️ **Critical-stage action whitelist is double-owned and disagrees** — `body-temperature.md` Rule 7 publishes `allowed_actions` in Critical as "only crawl, tend/add fuel to a fire within reach, and call extraction"; `interaction-and-timed-actions.md` Rule 4 marks `critical_allowed = yes` on `add_fuel`, `blow_embers`, `sit_warm`, **and** `drop` (its bidirectional check asserts this set is resolved). Two documents enumerate the same whitelist with different membership and no declared owner. Recommend: Interaction's `critical_allowed` column is the runtime gate (make it authoritative); Body's stage table should describe intent, not enumerate actions. Also decide whether `sit_warm`/`drop` in Critical is intended — drop could enable an inventory-dump exploit while crawling; sit_warm in Critical is arguably desirable (crawl to the fire and sit).

⚠️ **Character C8 readability formula still omits cos(pitch)** — `character-controller-and-animation.md` C8: `figure_height_px = screen_h × 1.75 / (2 × cam_dist × tan(fov/2))` overestimates figure height ≈1.6× at pitch 50°; `camera.md` CA3 is the corrected formula and its own Cross-References row already flags C8 "for its next revision". Character C8's ≥20 px QA check will pass figures that actually render ~13 px. Cosmetic for design (QA rule, not runtime) but should be corrected so C8 and CA3 agree.

⚠️ **Character tags In-water as VS, but Mishaps' ice-break is MVP** — `character-controller-and-animation.md` States table ("In water (VS: after ice break)") and Edge Cases ("If the survivor falls through ice (VS)") mark the state Vertical Slice, while `mishaps-and-failure.md` M4 is an MVP system that emits `fell_in_water` and explicitly relies on "Character enters In-water and climbs out at the nearest edge". The state and behaviour are fully defined, so this is a mislabel, not a missing design — but implementers reading "VS" may defer it. Remove the VS tags.

⚠️ **Character expects stumble/slip events from Mishaps that Mishaps never emits** — `character-controller-and-animation.md` Interactions table lists "in: stumble / slip / fall-through events" from Mishaps & Failure; `mishaps-and-failure.md` emits only the In-water trigger and cause beats to Character (stumble is driven by Body's Hypothermic stage per Character Rule 10/overlay). Stale table row; either Mishaps defines a slip-on-ice event (it doesn't today) or Character's row should read "in: In-water trigger, cause beats".

⚠️ **Needs still publishes `move_speed_mult`; Character and registry consume `needs_move_speed_mult`** — `needs-and-weight.md` N6 table and Downstream list use `move_speed_mult`; `character-controller-and-animation.md` C1 and the registry's `target_speed` formula use `needs_move_speed_mult` (the rename its review recommended). Apply the rename in Needs.

⚠️ **`feather_stick` item missing from Item DB (and registry items)** — `fire.md` build step 3 produces a feather stick (tinder, quality 0.8, fuel 3, mass 0.2, wetness = source stick × 0.5) and explicitly flags it for Inventory's table; `item-database-and-inventory.md` Rule 12 has no `feather_stick` row; `entities.yaml` `fire_max_fuel` notes "feather stick 3 (confirmed for Item DB)" but no item entry exists. Add the row + registry item.

⚠️ **`gather_grass` / `gather_stones` not adopted downstream** — `gathering.md` Rule 1 introduces both ids (and renames Map's `pick_up` on stone piles); `interaction-and-timed-actions.md`'s Rule 4 catalogue contains neither (grass tufts and stone piles have no action at all); `map-and-resource-distribution.md` Rule 5 still lists stone pile → `pick_up`. Both target GDDs flag the change in their own Cross-References/Open Questions. As written, grass tufts are unreachable and stones use an instant pick-up that contradicts Gathering's "timed heavy action" decision.

⚠️ **Map adds zones Thermal's table doesn't list** — `map-and-resource-distribution.md` Rule 4 defines `drift field` (0 offset, 0.6 exposure) and `scoured ridge` (0, 1.0) on top of `thermal-environment.md` Rule 4's four zones. Values are inside Thermal's declared ranges and Thermal's zone table is data-driven (Map supplies the zone; the table should just list them), so no runtime conflict — flag for Thermal's next revision per its own Open Question.

⚠️ **Ambient AF2 lake example uses wind_eff 3.6 — should be 3.0** — `ambient-and-foley-audio.md` AF2 example "lake (3.6) → −10.4 dB" (and acceptance criterion echoing the example set) conflates the lake's wind *chill* (3.6 °C, Thermal TH3) with `wind_eff` (= wind_speed × exposure = 3 × 1.0 = **3.0 m/s**). Its other examples (open 2.4, forest 1.2, lee 0.9) are correct wind_eff values. Correct result at 3.0: −12 dB exactly (20·log10(3.0/3.0)=0 → −12). One-line fix, but the acceptance test value must change too.

⚠️ **Systems-index soft-dependency gaps (self-reported by the GDDs)** — Camera→Input (turn/zoom, cinematic break), Mishaps→Terrain (ice) and →Thermal (wind), and Thermal/Camera/Character/Fire→Map are all used in the GDDs' Interactions tables but absent from `systems-index.md` Depends On column. Each GDD's bidirectional check already notes "add when convenient". Soft deps only — no ordering impact — but the index should be updated so `/create-architecture` sees the real edges.

---

### Game Design Issues

#### Blocking

None. No competing progression loops (one dominant loop: survive the night with the fire), no anti-pillar violations (no XP, no skill trees, no stat-bar chores — needs are felt through the body, not managed on bars; HUD shows icons only at warning stages), no dominant strategy detected (driest kindling bushes give no logs; logs are damp; best tinder needs the knife and is finite; the depletion loop makes nearest-first gathering self-correcting).

#### Warnings

⚠️ **Food is a sink-only resource in the MVP — hunger is guaranteed, not a choice** — Item DB analysis: 8 pemmican (4,000 kcal) + 1,200 stomach vs ~3,500 kcal/working day and no food faucet (Food is VS). From ~day 3 the stomach stays empty, Hunger distress rises monotonically, and sleep quality (q_food) degrades. This is intentional (brief: "第 3 天起饱腹不够", MVP covers days 1–3) but note the consequence: the MVP cannot be played "well" past day ~4 — there is no player action that restores food. Acceptable for the MVP playtest scope; must be answered by the Food GDD before Vertical Slice, and the playtest should treat "hunger beat lands day 3" (Needs AC 19) as the check, not survivability.

⚠️ **Attention budget at ~4 concurrent active systems — at the comfortable ceiling** — During a typical excursion the player actively manages: movement/terrain (route choice, sink, ice risk), body temperature (activity vs cooling trade-off), load/inventory (what to carry, two-trip decisions), and timed actions (work, cancel, retry failures). Needs (three clocks) runs passive until warning stages; camera is mostly passive. That's ~4 active — within the 3–4 guideline but with no headroom; any added active system in the VS (injury tending, trap checking, water) should displace or automate something rather than stack on top.

⚠️ **Fail→frustration→more-fails feedback loop is bounded but the floor is thin** — Mishaps' own loop analysis: morale penalty (≤0.10) + cold hands (≤0.20) + fatigue (≤0.15) can push a struggling player's strike chance to the 0.90 cap, and the named cause is always physical so the loop is legible. The dampers (fire-tending allowed in Critical, fumble guard, ±cap) exist, but the spiral "cold → clumsy → failed fire → colder" is the game's core tension and deserves a playtest check on whether Breaking-state players can recover at all (Morale's ritual relief requires reaching a burning fire — exactly the thing they can't light). Not a numbers error; a flow-channel edge to validate.

#### Info

ℹ️ **Ember window vs. worst-case duration multiplier is tight** — Fire's `ember_window` is 3 game min; `blow_embers` takes 1 game min × dur_mult (cap 2.0) = up to 2 game min, leaving ~1 game min after the last successful strike to start blowing. By day (1.5 s/game min) that's ~1.5 real s of slack — a confused first-time player will often miss the window and lose their tinder. Consider whether the window should pause during the strike→blow transition or start on the *successful* strike rather than being marginal; at minimum verify in playtest that players learn the rhythm within 1–2 attempts.

ℹ️ **Simultaneous-death precedence partially specified** — Needs defines hypothermia-beats-dehydration when both fire in one tick, but collapse (energy 0) + `body_died` same tick and `fell_in_water` while an action is running are unspecified. Trivial ordering rules suffice (death events win; `fell_in_water` force-cancels actions the way Critical entry does).

ℹ️ **Time GDD over-lists its consumers** — `thermal-environment.md` notes Time lists `phase`, `sun_progress`, `daylight_hours` as Thermal inputs that Thermal doesn't read (harmless over-listing; flag for Time's next revision).

---

### Cross-System Scenario Issues

Scenarios walked: 5
1. Lighting the first fire (Gather → Interaction → Mishaps → Fire → Thermal → Body → Morale/Emotional Feedback → Camera ritual_wide)
2. Sleeping through a dying fire (Needs → Time sleep → Fire burn → Fire Out → Body cooling → wake_request → Needs clears is_asleep → Time normal)
3. Falling through lake ice (Character footfall → Mishaps M4 → Terrain broken cell → Body wetness 1.0 → Inventory soak + possible tool loss → Character In-water → Morale major failure)
4. Exhaustion collapse in deep cold (Needs energy 0 → is_asleep + Character collapsed → Body continues ticking → Cold stage → wake_request → forced wake, energy floor 5 → crawl to fire)
5. Critical-stage survival at the fire (Body Critical → Character crawl → Interaction critical_allowed → add_fuel/blow_embers → fire saved → rewarm)

#### Blockers

None. Scenarios 2, 4 and 5 walk end-to-end with every handoff defined in both directions (Fire deliberately does not wake — Body does; collapse floors energy at 5 after forced wake; crawling can still tend the fire).

#### Warnings

⚠️ **Scenario 3 — Falling through ice** (Character + Mishaps + Body + Inventory): the chain is fully specified except the Character side labels its In-water state "(VS)" while the trigger (M4) ships in the MVP — same issue as the consistency warning above; also `fell_in_water` arriving mid-action has no defined cancel rule (Interaction's forced-cancel list covers Critical entry, collapse, target loss, tool break — not immersion). Recommendation: add fell_in_water to Interaction's forced-cancel list and de-tag In-water.

⚠️ **Scenario 1 — First fire** (Fire + Interaction + Mishaps): see Info note on the ember window — a WARNING-level player-experience risk for first-time players (losing laid tinder to a timer they haven't learned), kept at Info/Warning boundary because the numbers nominally fit.

#### Info

ℹ️ **Scenario 5 — Critical crawl to fire**: coherent; the one open question is whether `sit_warm`/`drop` should be `critical_allowed` (the double-owned whitelist above). Whatever is decided, both documents must say the same thing or a Critical player may find a listed verb refused — contradictory messaging at the most dramatic moment in the game.

ℹ️ **Scenario 2 — Dying fire night**: coherent and deliberately so (`fire_died_unattended` while asleep feeds Morale's grief — intended design, good scenario coverage in the GDDs).

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| body-temperature.md | Critical whitelist disagrees with Interaction's `critical_allowed` (needs to defer or match) | Consistency | Warning |
| interaction-and-timed-actions.md | Whitelist conflict (other side); add `gather_grass`, `gather_stones` to catalogue; add `fell_in_water` to forced-cancel list | Consistency | Warning |
| character-controller-and-animation.md | C8 missing cos(pitch); In-water tagged VS (trigger is MVP); stale "stumble/slip from Mishaps" row | Consistency | Warning |
| needs-and-weight.md | Rename `move_speed_mult` → `needs_move_speed_mult` | Consistency | Warning |
| item-database-and-inventory.md | Add `feather_stick` item row (+ registry item) | Consistency | Warning |
| map-and-resource-distribution.md | Stone pile action `pick_up` → `gather_stones` | Consistency | Warning |
| thermal-environment.md | Zone table should list drift field + scoured ridge | Consistency | Warning |
| ambient-and-foley-audio.md | AF2 lake example/acceptance value wind_eff 3.6 → 3.0 (−12 dB) | Consistency | Warning |
| mishaps-and-failure.md | (Optional) define slip/stumble events, or accept Character's table fix removing them | Consistency | Info |
| systems-index.md | Add soft-dependency edges (Camera→Input; Mishaps→Terrain, Thermal; Thermal/Camera/Character/Fire→Map); mark flagged GDDs "Needs Revision" — **listed here per instructions; index NOT edited** | Consistency | Warning |

---

### Verdict: CONCERNS

Warnings present that should be resolved before architecture locks the interaction tables and item data, but nothing blocking: every runtime contract cross-checked between defining and consuming GDDs agrees, and all flagged issues are single-line data/table fixes or stale labels, not design contradictions. No GDD needs structural redesign.

Recommended order: fix the Critical whitelist ownership first (it gates a dramatic moment), then the catalogue/item additions (feather_stick, gather_grass, gather_stones — the only gaps where a designed action is unreachable), then the label fixes (C8, In-water VS tags, Needs rename, Thermal zones, AF2 value, index edges).
