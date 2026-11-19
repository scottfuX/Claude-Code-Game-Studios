# HUD Design: Lonefire

> **Status**: In Review — no implementation or visual approval
> **Author**: Devin (ux-designer), owner-requested non-interactive draft
> **Last Updated**: 2026-11-19
> **Template**: HUD Design
> **Platform Target**: PC macOS / Windows; keyboard/mouse primary, partial gamepad; no touch
> **Accessibility Tier**: Standard, provisional pending Scott (A1)
> **Related**: [HUD GDD](../gdd/hud.md), [systems index](../gdd/systems-index.md), [accessibility](../accessibility-requirements.md), [patterns](interaction-patterns.md), [backpack](inventory.md), [pause](pause-menu.md), [death](death-screen.md)
> **Architecture**: Accepted ADR-0002, ADR-0016; ADR-0007 terminal ownership, ADR-0013 projection, ADR-0014 emotional feedback; [control manifest](../../docs/architecture/control-manifest.md)
> **Traceability**: TR-hud-001…024 under ADR-0016, with Input/Body/Needs/Time sources owned by their existing ADRs; no new TR allocation

## 1. HUD Philosophy

“I need to feel how cold and tired I am, and what I can do here, without reading a dashboard.” The world, posture and sound carry the experience; paper-and-ink corners supply only essential qualitative cues. No gameplay numbers, morale/Resolve display, thermometer, minimap, markers, resource counters or work-progress bar. Dawn is an in-world sunrise ritual, not a victory or survived screen. Full Results/diary/day numbers remain VS requirements, not missing MVP HUD widgets.

Player arrival context is inferred from the game brief: pressure to light the first fire, then growing strain through cold nights. No player journey map or user research exists. The emotion is restrained uncertainty, not unreadable UI.

## 2. Information Architecture

### 2.1 Full Information Inventory

Aggregation denominator: 18 system GDDs at `design/gdd/*.md`, all 18 have UI Requirements. Excluded non-system files: game-concept, systems-index, gdd-cross-review. The table accounts for every system, including explicit absence/deferred UI; developer overlays are never release HUD scope.

| GDD system | Information / UI requirement | Category and disposition |
|---|---|---|
| Body Temperature | Core stage/band/trend; cold warning | Must Show band, Contextual trend; posture carries cold too |
| Needs & Weight | Energy/water/food warnings; no numeric needs/weight; eat/sleep/work refusals | Contextual, at most three icons; refusals share Interaction line; diary/Medical weight readout VS |
| Time & Day Cycle | Arc, no digital clock; diary/results day count | Must Show faint arc; day count deferred to VS screens |
| HUD | Band, needs, arc, prompts, refusal, hint, reconnect, backpack, VS hold ring; Alpha scale/off/high-contrast | Elements below; backpack on demand; hold ring/settings deferred |
| Input & Action Map | Active glyphs, radio ring, reconnect, Alpha remap | Contextual glyphs/recovery; VS radio / Alpha remap dormant |
| Interaction & Timed Actions | Available E/F verbs, refusal; optional Alpha progress | Contextual prompts/refusal; progress not MVP |
| Item Database & Inventory | Sketches, counts/load/wetness; pickup refusal | On Demand [list](inventory.md); ADR-0016 replaces older numeric counts with qualitative facade; refusal here |
| Gathering | Interaction prompts and inventory only | Contextual verbs; no yield counter |
| Fire | World flame/smoke/sound, Interaction verbs | Hidden world state; contextual verbs, first Kindling ends hint |
| Thermal Environment | No thermometer; body/world cues | Hidden |
| Character Controller & Animation | Body is interface | Hidden world posture |
| Terrain & Snow Surface | World tracks/ice/snow cues, no HUD | Hidden |
| Map & Resource Distribution | No minimap/markers | Hidden landmarks/trails |
| Mishaps & Failure | None in play; future diary words | Hidden world outcome; no probability/cause popup |
| Morale & Mental State | No meter; body/audio, VS diary/tap-out offer | Hidden; no Resolve even in Critical |
| Emotional Feedback | No mood indicators; Alpha motion/effect settings | Hidden world presentation; settings deferred |
| Camera | No normal UI; Alpha default zoom/turn-step/reduce-motion settings | No new gameplay control surface; Input owns glyphs; Alpha settings deferred |
| Ambient & Foley Audio | No normal UI; Alpha audio/settings/captions scope | Hidden world audio; release caption gap in accessibility document |

Deferred systems in the systems index (Screens & Menus, diary, kit selection, Results, localization/settings, wildlife, etc.) have no authored system GDD UI checklist yet. Their absence is an explicit scope gap, not a claim those future screens are unnecessary.

### 2.2 Categorization

Must Show means ordinary gameplay, subject to end/sleep/ritual precedence. Contextual means only the owner condition, never a permanent warning. On Demand is backpack UI, not automatic pause. Hidden means no release text/meter; debug remains development-only. Patterns reused: Qualitative Survival HUD, Context Action Prompt, Action Refusal, Real-time Backpack, Pause Stack, Reconnect Recovery; no new reusable pattern is introduced.

## 3. Layout Zones

### 3.1 Zone Diagram

```text
+---------------------------------------------------+
|                    first-fire hint      sun/moon   |
|                                                   |
|             WORLD / survivor                     |
|            contextual verb(s)                      |
|            refusal (when needed)                   |
| need need need                                    |
| body band →                                       |
+---------------------------------------------------+
```

### 3.2 Zone Specification Table

Reference 1920×1080; use centred 16:9 safe rectangle then 5% inset on ultrawide, 5% viewport inset otherwise. Do not stretch drawings or move world-space prompts twice through stretch transforms.

| Zone | Reference allocation | Constraints |
|---|---|---|
| Bottom-left | 320×110 px | Band/trend below need row; reposition within safe zone to avoid open backpack panel |
| Top-right | 160×90 px | Faint sun/moon arc |
| Top-centre | Up to 560×72 px | First-fire hint only |
| Target/survivor | Up to 480×100 px each prompt/refusal group | Use final Camera projection; at least 40 px from projected survivor silhouette; clamp safe bounds |
| Centre overlay | Recovery only | Explicit blocking visibility rule; hides interaction prompts, never a persistent aim marker |

Hide a prompt if behind camera, no target, invisible projection or no safe placement avoiding survivor. Never replace it with an offscreen marker. Scale allocations proportionally; text wraps and can grow vertically without covering survivor. If constrained, remove low-priority hint before essential band/need cues.

## 4. HUD Element Specifications

Each source is a detached end-of-update snapshot, not a live mutable model. UI never owns survival state or queries gameplay from draw callbacks. Every element ignores pointer input and keyboard/gamepad focus. Device switching changes glyphs, not commands.

| Element | Content / zone | Trigger / update source | Priority / timing |
|---|---|---|---|
| Body band | Largest/most prominent survival element; snowflake to flame, blue-to-orange ink, faint stage ticks; bottom-left | Body snapshot core/stage change; fill clamp((core−30)/7,0,1), no labels | MUST KEEP in ordinary play; opacity below |
| Trend | Single/double directional arrow at band end | Body rate: ±0.1 single, ±1.0 double; candidate persists 2 unpaused real seconds | MUST KEEP when applicable; steady hides |
| Need row | Energy axe-arm, water cup, food bowl | Needs stage revision: Tired/Thirsty/Hungry normal; Exhausted/Parched/Empty/Starving urgent | MUST KEEP when warning; urgent bold + 1 Hz / 10% scale pulse; max three |
| Sun/moon arc | Half arc with sun/day or moon/night identity | Time phase/progress on owner time update; 180°×phase progress | SHOULD KEEP; no numbers |
| Verb prompt | Current device glyph + one/two available verbs | Interaction target/availability change and Input device/binding change; Camera final projection each rendered frame | SHOULD KEEP; never stale verb/target |
| Refusal | Localized owner reason near survivor | Latest Interaction refusal including cannot carry, cannot eat, not tired, heavy-work restriction | SHOULD KEEP; newest replaces for 1.5 real seconds |
| First-fire hint | Localized “天黑前要有火”, top-centre | Run start; gone on first Kindling flame OR 10 game minutes | CAN HIDE; one-way latch until new run |
| Reconnect | Localized reconnect/use-keyboard instructions + deliberate Resume | InputRouter active-pad disconnect/recovery event | MUST KEEP safety overlay; no auto-resume on reconnection |

Data absence: invalid mandatory Body/Time value logs and retains last valid band/arc, never NaN or invented safe state; if none has ever arrived, hide absent drawing and expose host loading/unavailable state, not a fake full band. Missing optional needs hide that icon; no target clears prompt immediately. Missing glyph uses localized action name. Missing localization key shows key in development; release empty + log, flagged as acceptance failure. A missing source does not authorize UI to pause or mutate simulation.

Backpack rows/load/wetness and item commands are specified in [inventory.md](inventory.md), not double-rendered as HUD counters. Radio ring is VS only: future 1.5 real-second hold, early release cancels, owner validates once; no new extraction behavior or mandatory progress ring is activated here.

## 5. HUD States by Gameplay Context

Visibility precedence is end > sleep/ritual > ordinary Critical > calm/active. Router recovery overlays this and suppresses actionable prompts. Pause freezes current gameplay presentation timers; recovery UI stays usable. Backpack alone freezes nothing.

| Context | Visible / behavior |
|---|---|
| Exploration calm | Warm, steady, no warning/prompt: after 8 real seconds, band+arc to 35% over 1.5 s |
| Active / warning | Trend, stage change, need warning or prompt raises band+arc to 100% over 0.5 s |
| Ordinary Critical | Band 100%, applicable needs and owner-approved verbs only; no numeric emergency display |
| Backpack | Live snapshots, unobscured band/needs; gameplay input suppressed, work/clock continue |
| Paused | Retained view under [pause](pause-menu.md); Clock/actions stop via owned pause token, not HUD |
| Sleep / ritual / sunrise | Everything hidden except body band 35%; on ritual exit restore over 0.5 s |
| Death / end shot | All gameplay HUD hidden, facade disabled; [terminal shell](death-screen.md) owns future navigation |
| Loading / no data | No stale previous-run prompts, hint or band; host loading surface, Locked per owner |
| Combat | N/A — no combat system; no copied boss/health/ammo UI |
| Dialogue / cutscene | Dialogue N/A; authored framings use ritual/end rules, no invented subtitles/skip controls |
| Disconnect | Router safety gate, text recovery; no stale interaction; preserve all other pause sources |

On scene/run teardown unsubscribe and clear snapshot identities/refusal/hint state. Repeated frame callbacks cannot reopen the hint or commands after terminal arbitration.

## 6. Information Hierarchy

Band/trend/needs are MUST KEEP during ordinary play; body/posture remain world backup. Arc/prompts/refusal SHOULD KEEP; world lighting/landmarks and verbs in context carry secondary meaning. Hint CAN HIDE first when space conflicts; it is onboarding, not a quest marker. Reconnect MUST KEEP until deliberate recovery. Morale, numeric values, map, developer diagnostics and deferred radio ring are ALWAYS HIDE in MVP. Sleep/ritual/end rules explicitly override normal priority, not silent exceptions.

## 7. Visual Budget

Author planning target: at most nine gameplay groups (band+trend counted as one, three need icons, arc, two verb lines, refusal, hint), ≤12% occupied screen area in exploration; no combat budget as combat is absent. Count actual occupied union including text backing, not just ink pixels. Recovery is a separate blocking overlay, not a tenth gameplay group; hide prompts/hint during recovery. Open backpack is an on-demand screen outside this exploration HUD budget.

Centre 40% reserved for world/survivor; transient prompts/refusal may enter only while relevant and remain 40 px clear of silhouette. Hint stays top-centre outside central play area; if text reflow violates clearance/budget, hide hint then suppress unplaceable prompts, never shrink critical text. Band/need warnings cannot be dropped to satisfy an arbitrary budget; escalate layout conflict instead. Budget values are proposed, not measured.

## 8. Feedback & Notification Systems

| Type | Source / position | Duration / max | Priority / queue |
|---|---|---|---|
| Refusal | Interaction near survivor | 1.5 real s / one | Latest replaces; no backlog, pickup “背不动了” uses same channel |
| Hint | Run/Fire top-centre | First Kindling or 10 game min / one | Low, hide on collision; never queue or repeat this run |
| Need urgency | Needs bottom-left | Until stage changes / three | Immediate state, not queued; repeated same stage does not restart pulse |
| Reconnect | InputRouter centre | Until deliberate recovery / one | Safety override, deduplicate; no auto-expiry |

No pickup toast, loot counter, damage text, achievement or mishap probability message is added. Under explicit pause retain/refreeze refusal timer; backpack does not pause it. Under sleep/ritual hidden refusal expires rather than becoming a delayed stale notification. Terminal clears transients, no old-run queue. UI audio uses optional quiet paper focus/confirm/refusal cues per patterns; audio failure cannot affect commands.

## 9. Platform Adaptation

macOS and Windows PC share zones and semantic InputMap actions. Text ≥18 px at 1280×720 (27 px proportional at 1080p); MVP scale 100%. Test 1280×720 through 3840×2160 at 4:3/16:9/16:10/21:9, including actual Godot 4.7 stretch mapping and thin-line rendering. No console 10% safe-zone, touch targets or mobile portrait layout is promised. Partial PC gamepad still requires glyph, backpack, pause and recovery parity; hover cannot move focus. Release/re-press after each context change prevents phantom movement/use.

## 10. Accessibility

Follow [project accessibility requirements](../accessibility-requirements.md), A1/A2/A3 and QQ-09; Standard remains provisional. All text targets 4.5:1 ordinary / 3:1 large text and meaningful edges over snow, night and fire, including composited 35% calm state. Ratios have NOT been measured. Paper backing/ink contrast must meet target without raising authored calm opacity or adding numerical readings. No color-only information: endpoints+fill/ticks, directional arrows, distinct needs/boldness, sun/moon shapes, words plus droplet for inventory. Validate grayscale and protanopia/deuteranopia/tritanopia; no global hue shift that makes warm fire cold.

### 10.1 Colorblind Modes
Alpha color-safe/high-contrast ink proposal pending A3/QQ-09; MVP fixed redundant shape cues. Test default cues, not just a hypothetical filter.

### 10.2 Text Scaling
Plan release 100–200% text with wrapping; preserve ≥18 px floor at 720p even at later HUD 80% scale. Text overflow must not enter survivor clearance area. No new MVP settings panel.

### 10.3 Motion Sensitivity
MVP authored pulse/fades; proposed reduced-motion path replaces urgent pulse with static bold icon and UI fades with instant changes. A2 scope approval pending. Emotional Feedback's separate camera/effect settings are Alpha, and its retained end shot must not be silently removed by this HUD spec.

### 10.4 Subtitles Specification
No current dialogue or voiced subtitle stream. Environmental/critical-audio captions and future speaker-identified subtitles are documented release gaps, not invented text producers. Proposed captions use readable backing/7:1 target per accessibility requirements, with final layout requiring their own scoped design.

### 10.5 HUD Opacity and Visibility Controls
MVP no adjustable opacity/visibility. HUD-off is an existing Alpha HUD GDD requirement, not removed here; its warning/recovery visibility interaction needs an Alpha settings spec before activation. No screen reader focus on passive HUD; accessible qualitative descriptions may be exposed by owner-approved accessibility ports later, never numeric temperature/Resolve. Menu narration is not a currently promised project Standard feature despite generic template tier wording. Reconnect has readable text and explicit recovery focus handled by router bridge.

## 11. Tuning Knobs

| Setting / parameter | Default / range | Owner / phase |
|---|---|---|
| HUD scale | MVP 100%; reserved Alpha 80–140% | Settings / QQ-09, not a new widget |
| Calm opacity / delay | 35% / 8 real seconds | Authored data, not player-adjustable |
| Active fade / calm fade | 0.5 / 1.5 real seconds | HUD authored data |
| Trend hysteresis | 2 unpaused real seconds | HUD per ADR-0016 |
| Urgent pulse | 1 Hz, 10% scale | Authored; proposed static alternative A2 |
| High contrast / reduced motion / text scale | No new MVP controls | Alpha/release scope pending A2/A3/QQ-09 |
| HUD off | Existing Alpha requirement; default HUD on | Defer exact off/recovery behavior to Alpha settings spec |

No setting bypasses nonnumeric rules. The existing Alpha HUD-off requirement must be reconciled with essential warning/recovery behavior in its settings spec rather than silently discarded or implemented as an unreviewed global hide.

## 12. Acceptance Criteria

Unexecuted implementation criteria, not evidence that a game UI exists.
- [ ] All elements render first valid owner snapshot on the next rendered frame; HUD draw ≤0.3 ms/frame on nominated hardware (QQ-01 pending), with layout/projection costs profiled separately.
- [ ] At 1280×720 and 3840×2160 across stated aspects, content stays within 5% inset, text ≥18 px at 720p, no overlap/clipping, prompts ≥40 px from silhouette, ultrawide uses centred safe rectangle.
- [ ] H1 endpoints and thresholds render only qualitative band/trend; all needs stages show correct hidden/warn/urgent icon, max three. No visible temperature, count, weight, day/time, morale/Resolve or developer value.
- [ ] Warm steady/no-warning/no-prompt becomes 35% after 8 real seconds, eased 1.5 s; a warning reaches 100% within 0.5 s; transient trend shorter than 2 unpaused real seconds does not replace arrow.
- [ ] Exploration union area is ≤12% and ≤nine groups; missing target removes prompts immediately; behind-camera target has no marker; no survivor overlap on long localized verbs.
- [ ] Ritual/sleep shows only 35% band even in Critical; end shows no gameplay HUD; ordinary Critical shows 100% band and allowed needs/prompts; combat/dialogue produce no invented UI.
- [ ] First Kindling or 10 game minutes removes hint for the rest of the run; simultaneous refusals show only newest for 1.5 real seconds; no stale notification after teardown.
- [ ] Backpack during active work keeps ticks/actions/survival running; pause freezes them; closing pause over backpack keeps UI context; held E never fires on close.
- [ ] Invalid/missing snapshots follow §4 and never render NaN or stale target commands; next valid snapshot recovers without UI model mutation.
- [ ] Contrast meets 4.5:1 text / 3:1 meaningful edges over snow/night/fire including calm alpha; grayscale and three CVD checks retain all meanings. Record actual screenshots before visual signoff.
- [ ] At 40% text expansion, RTL and CJK font fallback, words wrap and glyph artwork remains correct; dev missing key shows key, release logs missing key without displaying fabricated state.
- [ ] Router active-pad disconnect displays recovery; reconnect alone cannot resume; inactive-pad disconnect does nothing; keyboard recovery works and existing pause token survives.

## 13. Open questions / own calls

| ID | Decision / gap | Owner / deadline | Resolution |
|---|---|---|---|
| A1 | Standard is provisional | Scott; before tier gate | Accessibility review NOT ASSESSED until committed, not a documentation pass |
| J1 | No player journey | Design; before UI implementation | Author from `.claude/docs/templates/player-journey.md`; arrival context inferred |
| H1 | Nine groups / 12% budget and proposed zone dimensions | Scott + art/UI; before visual design | Planning default, preserve authored band/needs before budget |
| H2 | No dawn/survived modal | Time and Emotional Feedback existing rules | Sunrise ritual stays in-world; future Results needs its own GDD/spec |
| H3 | Counts versus nonnumeric inventory | Accepted ADR-0016 | Use qualitative facade; older Inventory counts not implemented |
| H4 | Standard release targets exceed current MVP settings scope | Scott; QQ-09/10 | Keep explicit remap/text/caption/motion gaps; no claim of Standard implementation compliance |

Cross-reference audit: 18/18 system UI sections dispositioned above; all sibling overlay links match. The skill requires no index/TR registry update for these screen refinements. Session checkpoint/log writes excluded by task; `.devin/` untouched. Review uses HUD checklist 3B; no runtime, visual or independent audit is implied.
