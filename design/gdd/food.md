# Food — Three-Day Survival

> **Status**: In Design — chapter proposal; owner approval required before implementation
> **Author**: Scott (chapter scope), Devin (system design)
> **Last Updated**: 2026-11-20
> **Last Verified**: 2026-11-20 (design only)
> **Implements Pillar**: 越活越懂 · 冷是真的 · 饥饿感

## Summary

One learnable food trip for the three-day chapter: read tracks at one authored forest-edge site, set and later check a snare, cook the one available hare at a Burning fire, and eat the portions through the existing timed nutrition transaction. The run's cold and hunger still matter even when the trip pays off.

> **Quick reference** — Category: `Gameplay` · Layer: `Feature` · Priority: `Vertical Slice` · Chapter deps: `Map, Clock, Interaction, Item DB / Inventory, Fire, Needs / Body`. Broader Wildlife/Fishing design stays deferred.

## Overview

Food gives the survivor a reason to leave the fire and a reason to come back. In the [three-day chapter](../../production/milestones/three-day-survival.md), the minimum playable source is one authored hare trail: notice the tracks, set a snare, return after a night window, then bring the catch back to a fire for two small meals. A premature visit can be empty; reading the sign and giving the site time works without rolling for the chapter's only food. Calories buy time, not a cure for the cold or a new way to die.

This is the chapter slice of the [Food system](systems-index.md#systems-enumeration), not the full Vertical Slice. The wider snares/ice-fishing/cooking design and Wildlife Behavior (fish, hare and grouse wandering/fleeing) remain deferred. There is no combat, live animal simulation, fishing, general trapping system, recipes UI, spoilage, new map, or change to Sprint 001 or the first playable night.

## Detailed Design

### Core Rules

1. **Read the place.** Author one stable hare-trail interactable in an existing reserved forest-edge range, on the clearing side of a pine belt. Use Map's authored placement and approach validation rather than a runtime spawn/scatter. The player can reach a valid interaction stance from the current drop and return without crossing ice, deep drifts (>0.6 m) or slopes >20°. The site itself obeys the same limits, is separate from fire/build/resource targets, and shows hare tracks before the player commits. The chapter layout places it 40–60 m from the drop; Map supplies position and safe ground, not catches.
2. **Set it and leave.** The chapter profile equips one existing `snare_wire` at its catalog durability (50; 0.2 kg); Food requests one normal tool use on authorized set completion. The wire stays an Inventory-owned tool, not an extra recoverable world item. A set remains armed even if that use breaks the tool or the tool is later dropped. No starting chapter ration is introduced: the current playable baseline has no carried food; the broader approved MVP pemmican kit and the first-night profile are unchanged. The 400 kcal backlog ration remains a test fixture.
3. **Come back after the night crossing.** The hare is represented by an authored trail and a non-graphic catch prop, not an actor or RNG roll. There are two crossing windows, 20:00–22:00 on days 1 and 2. The snare must already be armed at or before a window's opening minute and remain set through its close. A valid full window makes one catch claimable at and after its closing minute; no second catch accrues. Setting after the first opening costs a later return; if the last opening has passed, setting is refused. Checking before a qualifying window closes gives “Nothing yet” without resetting the snare, consuming a catch, or earning relief. The catch persists into day 3 if not collected; an unset site after the last opening yields nothing.
4. **Check and carry.** A completed check of a ready site runs one prepared transaction: mark the site spent and create one raw hare unit via Inventory's add-or-pile policy. Fit goes to the backpack; otherwise the raw unit becomes an identifiable pickup at the survivor's feet. Never grant calories at the trap. A second check cannot pay out again. The catch prop clears only after that commit, including if the result went to a pile.
5. **Cook one batch.** The raw hare's backpack row can request cooking, using its stack ID and revision and the normal focus/range rule restricted to Fire targets (ADR-0007; within 1.5 m and ±50°, including stable ties). The valid target must be the same reachable **Burning** campfire at start and commit, never a small Kindling flame, Smoldering, Embers or Out. Loss of reach/target or of Burning during the action cancels it; a relight does not resume it. Do not replace the fire's normal action priorities or add a binding. The prepared completion removes one raw unit and adds two cooked portions in one Inventory plan, calculating fit *after* the raw unit's planned removal and placing any remainder at the survivor's feet. No pot, special fuel debit, persistent recipe progress or additional Fire state; the existing fire continues to burn fuel normally during work.
6. **Eat when useful.** Use the existing backpack `eat` command. One cooked portion adds its catalog calories at the eligible completion only; if preflight/commit would exceed the Needs-owned stomach cap, refuse and keep it. Eating cannot restore lost weight, add hydration/heat or override Body/Needs action gates. Existing calorie burn, staged warnings, sleep quality and starvation pressure still apply. No hunger death, direct morale relief, or change to third-sunrise and same-minute death arbitration.

| Action | Target / required input | Base game min | Activity | Successful completion |
|---|---|---:|---|---|
| `set_hare_snare` | unset trail; usable `snare_wire`; a future or current opening minute | 3 | light | arm at latest processed game minute; charge one Inventory tool use |
| `check_hare_snare` | armed trail | 2 | light | show “Nothing yet” or commit the finite catch |
| `cook_hare` | selected raw stack in backpack; eligible Burning campfire | 10 | light | replace one raw unit with one batch of cooked portions |
| `eat` (existing) | selected cooked stack in backpack; Needs admission | 5 (item data) | none | consume one unit and deliver nutrition once |

All four are timed, cancellable, discard partial progress, do not count as idle and are **not** Critical-allowed. These chapter entries have no Mishaps profile, so they draw no RNG and produce no `action_outcome` event. An early empty check is time/world feedback, not a failed skill roll. Durations and effort follow ActionRunner's existing snapshot/multiplier rules; elapsed time and effort are not refunded. Exhaustion's heavy-work veto does not ban light work, but collapse still cancels all four. Opening the backpack does not pause or cancel; the explicit pause menu does freeze progress.

| Catalog ID | Category | Mass/unit | Stack max | Nutrition | Other |
|---|---|---:|---:|---|---|
| `hare_raw` | misc | 0.4 kg | 1 | none (not edible) | nonwettable; “Raw hare” / “生野兔肉” |
| `hare_cooked` | food | 0.15 kg | 2 | 350 kcal per unit; no hydration | nonwettable; 5 game min to eat; “Cooked hare” / “熟野兔肉” |

Both rows have no other gameplay values; dressing is abstracted into the cooking action. Uncooked and cooked pickups obey ordinary camp/backpack transfer rules. There is no expiry in this chapter.

### States and Transitions

| Stored site state | Entry / exit | Read-only view |
|---|---|---|
| Unset | Run start → Armed only on accepted set commit | Tracks; “Set snare” while a qualifying window can still begin. Afterward, tracks stay but the site is inactive. |
| Armed | Accepted set → Spent only on a successful ready check | Waiting before the derived ready minute, catch prop from the ready minute onward. Both permit “Check snare”. |
| Spent | Catch transfer committed → remains Spent to run end | Empty, tripped marker; no further Food action. |

The Food provider owns only the site's state, stable ID/revision and arming minute. Waiting/ready are projections of the latest processed game minute, not separate mutations that stale a healthy check token. At exactly 20:00 a set committed after that minute still qualifies; at exactly 22:00 an eligible check can claim the catch. A check starting just before and completing on or after the close uses the close-minute state. Midnight, sleep and wait never grant food, change the site's revision, or count twice; the schedule runs on ordered Clock minutes, not real time.

### Interactions with Other Systems

- **Coordinator / Clock:** Feature is run-owned and enabled only by the chapter profile. Use the latest settled simulation minute; no Timer callbacks or gameplay writes from presentation or public tick handlers. Clear state and stale tokens on run teardown. At an eligible checkpoint use existing terminal/cancellation precedence before set, check, cook or eat.
- **Map / Terrain:** Resolve the authored anchor and validate stance/routes with Map/Terrain queries. Queries are read-only, do not produce items or register heat. Food, not Map or Wildlife, owns whether the site has paid out.
- **ActionRunner / Inventory:** Register validated action/data rows before activation. On eligible completion revalidate token, target and stack/tool revisions, reach, allowed actions and fire eligibility as applicable. Prepare all owner effects and overflow placement before any write. Commit once, synchronously without callbacks/yields, then publish outcomes; stale/duplicate/invalid input changes nothing. The Food resolver uses the accepted plan pattern, not a call into Gathering's recipes or direct mutation of foreign owners.
- **Fire / Body / Needs:** Fire supplies read-only stage/identity; Food neither spends Fire fuel directly nor emits heat/wake. Body retains the Critical whitelist, shiver and cold wake. Only the existing Inventory/Needs transaction for eating changes the stomach and resets the continuous-empty timer; normal Needs/Body minute steps continue.
- **Presentation:** Feed existing prompts, effort animation and localized inventory/result views from committed, detached snapshots. No commands from animation/audio callbacks or direct writes to Morale; the existing hunger inputs can reflect a meal.

## Formulas

**FO1 — Availability.** Use integer game minutes from midnight of day 1. Let `open(d) = (d − 1) × 1440 + 1200` and `close(d) = open(d) + 120`, for `d ∈ {1, 2}`. A valid unset site can arm if some `open(d) ≥ now_min` at start and again at commit. For an armed site, `ready_min = min(close(d) where armed_min ≤ open(d))`. If there is no qualifying window there is no catch. Readiness is `state == Armed AND now_min ≥ ready_min`.

| Variable | Type / range | Source and meaning |
|---|---|---|
| `d` | int, 1–2 | chapter data; daylight and sunrise remain Clock-owned |
| `now_min`, `armed_min` | int, 780 to day 4 sunrise at the chapter default | last fully processed Clock minute and same value recorded once at set commit |
| opening, window length | int, 1200 min since midnight, 120 game min | chapter defaults, fixed in both windows; author only a nonempty within-day window in supported run days |
| ready | bool | derived; never grants produce by itself |

Example: set day 1 at 20:00 → ready day 1 at 22:00; set at 20:01 → ready day 2 at 22:00. At day 2 20:01 no further set can complete. Same result if a sleep skip crosses 22:00.

**FO2 — Finite yield.** `chapter_kcal = raw_claims × cooked_units_per_raw × kcal_per_portion` is the maximum food delivered by this source if all crafted portions are eventually eaten, not a direct award.

| Variable | Type / range | Source and meaning |
|---|---|---|
| `raw_claims` | int, 0–1 | the site's once-only claim |
| `cooked_units_per_raw` | int, 2 (fixed chapter batch) | cooking recipe |
| `kcal_per_portion` | finite float, default 350 kcal; proposed tuning 250–450 kcal | validated catalog value; keep the finite batch at ≤900 kcal in this chapter |

Output: 0 or 700 kcal of potential food at defaults (0–900 over tuning). One accepted portion at an empty stomach initially buys about 2 game hours of ordinary walking (Needs N1: 110+60 kcal/h), not an extra day; 1,150 + 350 = 1,500 kcal is allowed, 1,151 + 350 is refused. The 3/2/10 game-minute Food base actions use IA1 exactly, including the cap of 2; the 5-minute eating duration is catalog-owned. Amounts and durations are playtest starting values, not real-world nutrition or handling instructions.

## Edge Cases

- **Too soon / too late:** Early check changes no state or entitlement and may be tried again after the closing minute. Set past the last opening refuses even if the tap occurred before it. No visit, empty check, skipped minute or repeated action replenishes the site.
- **Inventory pressure:** Produce fits or goes to a validated pile. If no legal pile can be prepared for overflow, refuse without consuming the catch or raw input; let the player free space or retry at a valid campfire. A stale row, missing raw item, missing/unusable tool or invalid item/action/placement definition never produces a default yield. Invalid required chapter data blocks chapter activation with diagnostics; first-night activation is independent.
- **Same-checkpoint interruptions:** Cancel beats any due action when movement/cancel, collapse, immersion, forbidden Critical entry, invalidated target/stack/tool or terminal intervenes. Any cook reaching completion on the minute Fire leaves Burning is rejected. Keep existing tool/ingredient/output/stomach state; already elapsed time, normal fuel burn and exposed body/needs costs stand. No refund of a legitimately committed earlier action.
- **Last tool use:** If authorized set commits and the wear breaks the wire, keep the set and send only the existing tool-loss event. Losing the wire externally before commit cancels without wear or set.
- **Past run:** Old IDs and callbacks cannot claim from or start work in a new run. End at the chapter's existing terminal gate, even if a catch became ready or an action otherwise completed on that minute. A fresh chapter begins Unset.

## Dependencies

**Hard:** [Map & Resource Distribution](map-and-resource-distribution.md) (reserved hare range and safe authored stance), [Terrain & Snow Surface](terrain-and-snow-surface.md) (via Map validation), [Time & Day Cycle](time-and-day-cycle.md) (processed minutes), [Interaction & Timed Actions](interaction-and-timed-actions.md) (targets/transactions), [Item Database & Inventory](item-database-and-inventory.md) (catalog, tools, piles and consumption), [Fire](fire.md) (read-only stage), [Needs & Weight](needs-and-weight.md) (nutrition and activity), [Body Temperature](body-temperature.md) (via ActionRunner admission/cancellation).

**Indirect / presentation:** [Mishaps & Failure](mishaps-and-failure.md) still owns normal world hazards during travel and the C4 profile rules; there is no new food roll. [HUD](hud.md), [Input](input-and-action-map.md), [Character](character-controller-and-animation.md), [Audio](ambient-and-foley-audio.md) and [Emotional Feedback](emotional-feedback.md) reuse their existing ports. Fire, Item DB, Map and Needs already name the deferred Food contracts; this chapter gives those ports content without changing their canonical rules. Wildlife Behavior is a dependency of the broader design, **not** of this chapter; no Wildlife, Water or Shelter port is required by Food itself. [RUN-002](../../production/epics/run-coordinator/story-002-wire-three-day-chapter.md) still requires Shelter independently.

## Visual/Audio Requirements

- Use one readable angled track cluster at the forest edge and a tied/untied/spent silhouette at the anchor. The catch reads as a small, still bundle from the existing high camera; no live animation, struggle, gore or cutaway. Do not rely on colour to distinguish states.
- Reuse crouched light-work staging and existing hand/foley cues; short quiet rustle on check, existing fire crackle and a simple tending pose on cook. Feedback can be muted without hiding whether a catch or meal was obtained. Keep the snow palette and warm hues tied to the fire.

## Game Feel

The valuable choice is whether to spend daylight on a trip now or keep the fire safe and return later. A premature check shows a slack snare and a clear “nothing yet,” not an arbitrary punishment. The payoff is a small quiet meal by the fire; repeatable chores, guaranteed calories at the drop and offscreen rolls deciding the only catch would undermine that contrast.

## UI Requirements

Use existing context verbs and device glyphs for Set/Check, the raw row's Cook command, and the cooked row's existing Eat command. Localize item and prompt keys for Chinese and English; suggested lines: “野兔踪迹” / “Hare tracks”; “还没收获” / “Nothing yet”; “火不够旺” / “The fire isn't strong enough”; “吃不下” / “Too full”. After setting and on an early check, use the eligible window's day to hint “明早再来” / “Check tomorrow morning” or, if the qualifying window is tomorrow, “后天早上再来” / “Check the morning after next.” The hint is safe guidance, not a restriction on a check at night. After the last opening an unset trail says the tracks have gone cold rather than offering Set. An overflow result says the pickup is at the survivor's feet. Use the existing refusal/progress channel and qualitative need cues; no numeric food, time, odds or track HUD, new screen or pause path.

## Cross-References

| Constraint | Source | Food handoff |
|---|---|---|
| Run lifecycle, ordered clock, stable world placement | [Control Manifest, Foundation and Core](../../docs/architecture/control-manifest.md#foundation-layer-rules) (ADR-0001–0004) | Validate chapter anchors/catalog before activation. Use typed detached snapshots and the existing interaction context. No node-level timer, RNG or spawn on query. |
| Activity/thermal ownership, cancellation and C4/C5/C6 | [Control Manifest, Core](../../docs/architecture/control-manifest.md#core-layer-rules) (ADR-0005–0009) | Stand at an existing target; prove death/collapse wins ties; Inventory and Needs commit together without direct foreign state writes. |
| Finite yield, Fire and Morale | [Control Manifest, Feature](../../docs/architecture/control-manifest.md#feature-layer-rules) (ADR-0010–0012) | Preserve the prepared overflow pattern; no new fuel/heat/morale side channel. |
| Read-only cues, glyphs and list commands | [Control Manifest, Presentation](../../docs/architecture/control-manifest.md#presentation-layer-rules) (ADR-0013–0016) | Use existing camera/HUD/foley conventions; UI never pauses from backpack or mutates a stack. |
| Food source / availability | [WORLD-001](../../production/epics/world-map/story-001-place-content.md) and [chapter milestone](../../production/milestones/three-day-survival.md#content-and-presentation-handoffs) | After owner sign-off, author and validate the stable hare-site placement, then supply the Feature provider. This spec does not implement the provider or change story status. |
| Timed nutrition | [ITEM-001](../../production/epics/item-catalog-inventory/story-001-nutrition-transaction.md) → [ACT-002](../../production/epics/action-runner/story-002-eat-action.md) | Reuse authoritative food transactions. Keep the 400 kcal fixture separate from the real cooked-hare row. |
| Default chapter integration | [RUN-002](../../production/epics/run-coordinator/story-002-wire-three-day-chapter.md) | Requires approved content and the independent Shelter/HUD handoffs. Enable Food only in the chapter profile; no Sprint 001 work or milestone exit claim here. |

Engine feasibility: the proposal uses the accepted Godot 4.7.2/Jolt authored placement, catalog rows, ActionRunner and owner ports. It needs no navigation, creature physics, new shader/API or runtime timing claim; verify map reachability and projection in the pinned build.

## Acceptance Criteria

| ID | Given | When | Then |
|---|---|---|---|
| FD-01 | The default chapter and existing map | A player walks from the drop via the validated approach and targets the signed trail | The site is discoverable within the authored distance band without ice/deep-drift/steep-slope traversal; queries spawn nothing. First-night and a fresh chapter retain their separate profiles. |
| FD-02 | The site is armed by day 1 20:00 | A check completes before 22:00, then another at 22:00 or later | The early check shows “Nothing yet”; the later one grants exactly one raw unit and marks spent. A duplicate/concurrent stale check and a day-3 return grant nothing extra. |
| FD-03 | Set completes at day 1 20:01 | Clock crosses the first close normally and the second while sleeping or waiting | No catch at the first close; one is ready after the second with no auto-claim. A set attempt completing at day 2 20:01 refuses without tool cost. |
| FD-04 | The wire has one use left, or is removed just before completion | Set resolves | Authorized last use arms once and breaks the wire once; external loss cancels without arming. No Food RNG draw in either case. |
| FD-05 | Backpack is full before check or cook | Check completes with a legal pile and then in a fixture without one; cook completes in a separate full-pack fixture | Check piles the whole raw unit once and marks spent, or refuses and leaves the catch retriable. Cook frees the raw unit's 0.4 kg before fitting the 0.3 kg batch, so both cooked portions fit with neither dropped nor lost. |
| FD-06 | One raw unit and an eligible Burning fire | Cook completes, or the fire falls below Burning on the same checkpoint | Valid completion consumes one raw and yields two cooked; invalid cancels and keeps the raw. Raw has no Eat action. Fire follows its normal burn either way. |
| FD-07 | One cooked portion in a current stack; at revalidation the stomach has 1,150 or 1,151 kcal | Eat completes | At 1,150 the portion is consumed and 350 kcal enters Needs once; at 1,151 it is kept with a refusal. A stale stack or duplicate commit grants nothing. |
| FD-08 | Each Food action has an eligible completion due | Movement/cancel, forbidden Critical, collapse, immersion or terminal arrives before commit | No interrupted reward, nutrition, depletion, tool wear or RNG; ordinary elapsed simulation is retained. A same-minute death beats eating or catching. |
| FD-09 | A localized Chinese/English chapter build on the default camera, including audio muted | A player checks early, collects, cooks and eats using existing inputs | State and refusals are distinguishable without colour or sound; no new HUD numbers. Backpack commands do not pause. |
| FD-10 | Paired chapter runs replay equivalent travel/work, warmth and sleep with and without consuming the two portions | QA compares Needs snapshots through third sunrise | On the fed path, consumption increases fullness and delays reserve burn; neither path gains weight. The stocked path can still get hungry after the finite batch is spent. No new terminal outcome. |

FD-07 reuses the ITEM-001/ACT-002 boundaries with the real item; FD-01, FD-09 and FD-10 are implementation/playtest requirements, not evidence that a build passed.

## Open Questions

| Owner sign-off before implementation | Recommended answer |
|---|---|
| Chapter food source, availability and initial carried food | Use the single signed hare site and two deterministic night windows with one catch total. Equip the existing wire for this chapter; no starting food or full Wildlife dependency. Keep random catches as a later design, not a gate on the only source. |
| Chapter cooking effort and nutrition | Cook at a Burning fire for 10 base game minutes, yielding two 350 kcal portions. Keep set/check at 3/2 game minutes and eating at the existing 5; tune after the first chapter playtest, not by changing Needs or Body. |

Merging this design for review does not authorize implementation or unblock chapter content by itself.
