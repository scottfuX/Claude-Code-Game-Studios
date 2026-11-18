# Accessibility Requirements

> **Status**: In Design — provisional target, not owner-approved or audited
> **Author**: Devin (ux-designer), for Scott's review
> **Last Updated**: 2026-11-18
> **Accessibility Tier Target**: Standard — Own Call A1, pending Scott's confirmation
> **Platforms**: PC — macOS and Windows (Steam); keyboard/mouse primary, partial gamepad; no touch
> **External Standards Targeted**: WCAG 2.1 AA principles for UI, not whole-game conformance; Game Accessibility Guidelines; XAG as reference only. No console certification or mobile standard claimed. CVAA applicability requires review if communication features are added.
> **Accessibility Consultant**: None engaged
> **Linked Documents**: [Systems index](gdd/systems-index.md), [interaction patterns](ux/interaction-patterns.md), [architecture review](../docs/architecture/architecture-review-2026-11-18.md)
> **Template**: Accessibility Requirements

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core commitment |
|---|---|
| Basic | Readable critical text, no color-only information, separate music/SFX/voice volume, photosensitivity safety. |
| Standard | Basic plus full remapping, adjustable text, colorblind support, speaker-identified subtitles, and extendable or toggle alternatives to timed input. |
| Comprehensive | Standard plus menu screen reader support, mono, difficulty assists, HUD repositioning, reduced motion and visual equivalents for critical audio. |
| Exemplary | Comprehensive plus full subtitle customization, high contrast, cognitive assists, tactile alternatives and external audit. |

### This Project's Commitment

**Target Tier: Standard, provisional Own Call A1 pending Scott.** Lonefire's cold, low-contrast snow, small contextual prompts and deliberate repeated work create visual and motor barriers even without twitch combat. Basic would leave remapping, readable scaling and time-dependent confirmation insufficiently addressed. Standard is the most defensible planning baseline for the PC survival loop without promising unbudgeted narration, a screen reader or difficulty redesign. No audience research or specialist audit has been performed; this recommendation does not claim their endorsement.

This is a requirements draft, not a committed tier for the Technical Setup → Pre-Production gate. Scott must confirm the tier. Its implementation schedule must retain the existing MVP/Alpha split: MVP scale remains 100%, remapping UI and settings remain Alpha/dependent on QQ-09; unmet release-target features stay visible as gaps, not silently waived.

**Beyond-baseline proposals (A2)**: reduced motion/static urgent icons, mono output and qualitative captions for critical sound, because posture, breath and directional foley carry survival information. Pending scope confirmation under QQ-09/QQ-10; none is an MVP addition authorized here.

**Not promised**: blind world navigation, full menu narration, HUD repositioning, difficulty/simulation assists, or a numeric/explicit-readout HUD. Limitations below document impact. Only the explicit pause menu pauses player-requested play; backpack never pauses or cancels actions. Disconnect safety follows InputRouter, not a new menu pause rule.

## Visual Accessibility

| Feature | Tier / scope | Status | Requirement and implementation note |
|---|---|---|---|
| Text size | Standard; all UI | Designed floor; untested | Preserve HUD GDD ≥18 px at 720p (27 px proportional at 1080p). Proposed menu floor 24 px and caption floor 32 px at 1080p (A3); do not shrink critical HUD below its stronger GDD floor. Localized strings wrap without clipping. |
| Text resizing | Standard; release menus/captions | Pending QQ-09 | Target 100–200% text with reflow (A3). HUD's separate authored 80–140% Alpha scale cannot make critical text smaller than its floor; MVP remains 100%. A general UI scale does not substitute for text resizing. |
| Contrast | Basic/Standard; UI | Not tested | Target 4.5:1 ordinary text, 3:1 large text/meaningful control edges; captions target 7:1 on opaque backing (A3). Measure composited paper/ink over snow, night and fire, including 35% calm alpha. |
| Colorblind support | Standard; band and state cues | Design present; not validated | Snowflake/flame, tick marks and fill direction duplicate blue/orange. Validate protanopia/deuteranopia/tritanopia and grayscale. A color-safe ink preset is proposed for Alpha (A3), retaining warm-fire hue protection; no global palette shift that turns safety cold. |
| High contrast | Above baseline; Alpha HUD GDD | Pending QQ-09 | High-contrast ink/background treatment; keep bands qualitative. Do not bypass calm/hide rules without Scott's decision. |
| Motion/flash reduction | A2 above baseline | Proposed | Replace urgent 1 Hz/10% scale pulse with static bold icon; remove shake/breathing camera and transition movement where possible. Keep necessary movement/posture cues. No new flashes; test fire, damage and grading transitions for >3 flashes/s risks. Warning text alone is not mitigation. |
| Brightness calibration | Basic; release | Pending settings scope | Propose reference snow/ink/night image before graphics adjustment. No arbitrary gamma values or visibility guarantee until QQ-04 camera/readability testing. |
| Subtitles/captions | Standard plus A2 | Proposed | Captions on at first launch (A4), with speaker identity for future speech and distinct environmental cue labels. No invented dialogue system; current foley needs a caption plan rather than a fictitious voiced-content claim. |

### Color-as-Only-Indicator Audit

| Location | Signal | Non-color backup | Status |
|---|---|---|---|
| Body band | Cold blue / warm orange | Snowflake/flame endpoints, fill position, ticks | Specified; screenshot tests pending |
| Needs | Normal / urgent ink | Distinct energy/water/food shapes and boldness; static urgent form under reduced motion | Specified; recognition test pending |
| Day/night | Dawn/dusk tint | Sun/moon identity and arc position | Specified; contrast test pending |
| Fire/world grade | Warm safety / desaturated cold | Flame/smoke/breath/posture and existing prompts; caption proposal for critical sounds | Pending combined color/audio-off tests |
| Inventory/control states | Wetness, load, focus, refusal | Localized qualitative labels and persistent focus outline; no rarity-color invention | Proposed; stale/empty tests required |

The HUD remains minimal and non-numeric: no morale/Resolve, temperature numbers, hunger/weight/day/time/count labels, thermometer, minimap, markers or damage numbers. Debug information is development-only. An explicit numerical accessibility readout is **not decided**; see S2.

## Motor Accessibility

| Feature | Requirement | Status / boundary |
|---|---|---|
| Remapping | Every supported action remappable, collision validation per context, reset with confirmation, glyphs reflect actual binding. Preserve a reachable cancel/pause path. | Data contract exists; remap screen Alpha, pending QQ-09. |
| Keyboard/mouse and gamepad | No hover/drag-only action; focus navigation, select then use/drop alternative; adjustable analog deadzone target using IN1. | Partial PC gamepad scope; test supported menus, do not claim complete controller certification. |
| Work | Tap starts timed work; no sustained hold. Each repeat-action tap is one attempt; no auto-chop/auto-strike or new result queue. | GDD contract; QQ-07 remains open. |
| Hold-to-confirm | VS radio remains deliberate 1.5 real-second hold, release cancels. Propose accessible two-step confirmation alternative (A5), no timeout; never a single accidental tap-out. | Pending Scott/input owner; no binding or simulation change authorized. |
| Timing | No menu response timeout; captions/readouts persist long enough to read. Propose configurable hold threshold and hurry toggle, preserving cancel and context rearming (A5). | Settings/VS scope pending; no extension to world survival time or automatic backpack pause. |
| Simultaneous inputs | Menus require no chords; stick move and tap interactions need one input at a time except optional hurry. | Test one-hand menu traversal; full one-hand gameplay not guaranteed. |

## Cognitive Accessibility

Use one localized verb per affordance, current-device glyphs and a stable back action. Keep the body band dominant; at most three warning need icons; no permanent tutorial or new meters. First-fire hint disappears on Kindling or after ten game minutes and never returns this run, as authored; a replayable help page would require QQ-09 approval rather than resetting that latch.

Feedback states say what happened and the available next action without blaming the player: e.g. “Too heavy — leave some here.” Preserve qualitative uncertainty instead of exposing hidden probabilities or morale. Menus have labeled empty states, refusal explanations and safe cancel focus for destructive actions. Pause provides reading time explicitly; the backpack carries a concise “Time continues” label (Own Call A6) so players do not infer safety from an overlay.

No timed menu decisions, automatic destructive default or automatic selection on hover. Localization expansion, line wrapping and icon-plus-word labels are required; the missing player journey is an evidence gap, not a synthesized research finding.

## Auditory Accessibility

| Feature | Requirement | Status |
|---|---|---|
| Volume | Independent Master/Music/Ambience/Foley/UI per audio GDD and proposed ADR-0015; future voice separately controlled where content exists. Muting must not hide actionable UI state. | Settings deferred; audio implementation untested |
| Critical cues | Identify cold breath, ice danger, failed work, tool loss and fire-state changes with existing visible cues; propose qualitative captions where those cues are insufficient (A2/A4). No extra fire meter or numeric warning. | Cue-equivalence audit required |
| Mono | Optional mono mix, no information lost by channel collapse; caption direction only for a genuinely directional critical sound. | A2 proposal, pending scope |
| Speech/subtitles | Future diary/dialogue speech gets speaker labels and readable background, text size controls, no music-only indication. | Deferred content; no current voice implementation claimed |
| Rumble | Supplement only, never the sole alternative; no new rumble commitment. | QQ-10 open |

## Platform Accessibility API Integration

Godot 4.7 Control nodes should expose semantic name, role, state and logical focus order where supported. Verify actual engine/platform support for focus and live announcements before selecting API calls; application ports in ADR-0002/0016 are not native Godot APIs. Do not promise screen reader compatibility from node labels alone.

| Platform | Integration / evidence required | Status |
|---|---|---|
| macOS | VoiceOver menu spike, keyboard focus, scale/contrast and reconnect checks on exported build | Not tested; narration beyond provisional Standard |
| Windows | Narrator/NVDA menu spike, keyboard focus, scale/contrast and reconnect checks on exported build | Not tested; narration beyond provisional Standard |
| Console/mobile | No certification, touch or platform API work committed | Out of current targets |

## Per-Feature Accessibility Matrix

This matrix covers all 18 designed MVP systems and explicitly records the remaining 15 planned systems below. “Specified” means a document requirement, never implemented or passed.

| System / GDD | Visual / auditory alternative | Motor / cognitive requirement | Status / pattern |
|---|---|---|---|
| Input & Action Map | Current binding glyph + text; visible reconnect | Context clearing, remapping, safe hold alternative pending | Specified; Context Action Prompt, Reconnect Recovery |
| Time & Day Cycle | Sun/moon arc, no clock/day numerals | Backpack real-time; explicit pause only | Specified; Qualitative Survival HUD, Pause Stack |
| Terrain & Snow Surface | Surface depth/trail shape, not color alone | Readable walkability without extra map | World-readability audit pending |
| Item Database & Inventory | Identity, wetness/load words; no numbers | Select/use/drop, live revisions | Specified; Real-time Backpack, Inventory Slot |
| Map & Resource Distribution | World landmarks, no minimap/markers | No undisclosed route assist | World-readability audit pending QQ-04 |
| Character Controller & Animation | Posture/gait supports strain cues | Named actions, tap work, optional hurry alternative pending | World/input test pending |
| Camera | Survivor visible, no shake-only signal | Turn/zoom actions, reduced motion proposal | QQ-04; read camera GDD, no reframing decision |
| Interaction & Timed Actions | Up to two verbs and qualitative refusal | Tap work/cancel, no mandatory progress HUD | Context Action Prompt, Action Refusal; O1/QQ-07 open |
| Thermal Environment | No thermometer; body/world cues | No extra simulation controls | World-readability audit pending O3/O4 |
| Body Temperature | Band/ticks/trend plus breath/posture | Critical whitelist stays owner-defined | Qualitative Survival HUD; O1 open |
| Mishaps & Failure | Visible cause, animation; captions proposal | No reaction-time escape added | Feedback audit; QQ-05/QQ-07 open |
| Gathering | Interaction verbs, backpack state | No result-count overlay; no auto-repeat | Real-time Backpack; O2 open |
| Fire | Flame/smoke/light + prompts; captions proposal | Existing timed/repeat verbs only | No fire meter; O3 open |
| Needs & Weight | Three need icons maximum, no mass/hunger numerals | Qualitative load and allowed-action explanations | Qualitative Survival HUD; O1 open |
| Morale & Mental State | Posture/gait/world, never a Resolve meter | Do not expose hidden morale or change relief | QQ-05/QQ-07/QQ-10 open |
| Emotional Feedback | Warm hue preserved, redundant bodily cues | Reduced motion proposal, no gameplay changes | ADR-0014 proposed; QQ-10 open |
| Ambient & Foley Audio | Visual cues/captions proposal | No HUD chatter/sound added during play | Sound Standards; cue audit pending |
| HUD | Floors/safe area/qualitative hierarchy | Noninteractive nodes ignore focus/input | Qualitative Survival HUD; QQ-09 open |

### Deferred-System Coverage

These rows record barriers to assess when each GDD is authored, not new feature commitments or approvals.

| Planned system | Visual / auditory concern to assess | Motor / cognitive concern to assess | Status |
|---|---|---|---|
| Injury & Pain | Injury cause/condition readable without sound alone | Pain effects and treatment input readability | VS; GDD absent, QQ-10 |
| Shelter | Construction stages visible by shape, not hue alone | Stage selection/cancel and material refusal | VS; GDD absent |
| Water | Boiling/water state discernible without sound alone | Safe action prompts and repeat work | VS; GDD absent |
| Wildlife Behavior | Silhouette/movement and critical audio equivalence | Tracking demand without adding markers | VS; GDD absent, QQ-10 |
| Food | Readable preparation/failure state | Traps/fishing/cooking inputs and timing | VS; GDD absent |
| Weather & Cold Snaps | Reduced effects must not erase weather information | Forecast/response complexity without new meter | VS; GDD absent |
| Medical Check-ins | Readable weigh-in/result text outside HUD | Clear forced-exit consequence and navigation | VS; GDD absent |
| Rival Simulation & Ranking | Readable rankings outside HUD | Explain result/remaining-rivals information | VS; GDD absent |
| Kit Selection | Item identity/selection independent of hue | Keyboard/gamepad selection; no drag-only picking | VS; GDD absent |
| Self-Filmed Diary | Speaker-identified subtitles/mood-word legibility | Advance at own pace, no timed reading | VS; GDD absent |
| Tap-out & Run Results | Visible hold confirmation/results, no audio-only outcome | Safe irreversible confirmation, A5 pending | VS; GDD absent |
| Meta Rewards | Readable reward information outside HUD | Understandable consequence/choice, no fabricated economy | Alpha; GDD absent |
| Save/Load & Settings | Text scaling, contrast, all audio buses | Remapping conflicts, safe recovery, persistence errors | Alpha; GDD absent, QQ-09 |
| Screens & Menus | Focus/contrast/readable paper-and-ink | Real-time backpack vs pause and nested back behavior | VS full screens; MVP facade only |
| Localization, Accessibility & Onboarding | Long Chinese/English text, captions and glyph fallback | Configurable timings and discoverability | Full Vision index entry; tier delivery schedule S1 remains open |

Interaction's optional thin progress arc is an Alpha accessibility hook, not a default work bar or numeric countdown. Camera's Alpha zoom/45°–90° turn-step controls, Emotional Feedback's reduce-camera-motion/reduce-screen-effects, HUD off/high-contrast/80–140% scale, and per-action keyboard/gamepad remap columns all require their deferred screen specs under QQ-09. Morale diary mood words and Needs weigh-in/body-weight information belong to VS screens, never a morale/weight HUD.

## Accessibility Test Plan

| Test | Procedure / acceptance | Owner / timing |
|---|---|---|
| Legibility | 720p, 1080p, 4K and ultrawide; snow/night/fire backgrounds; 5% safe area within centered 16:9 on ultrawide; long locale; actual survivor clearance ≥40 px. Verify floors and reflow at supported scale endpoints. | UI + accessibility specialist before screen acceptance; no evidence yet |
| Color/contrast | Measure composited contrast, grayscale and three CVD simulations; identify band direction, urgent needs and fire safety without hue. Include calm alpha and warm-safe grading. | Art + accessibility specialist; no evidence yet |
| Motor/focus | Traverse each scoped menu with keyboard only/gamepad only; test cancel, destroyed row, remap conflicts, release/rearm, disconnect during action. No double dispatch. | UI/input owner before implementation acceptance |
| Timing/overlay | Open backpack mid-chop and across minute tick: work, Fire, Needs and Morale continue. Pause over backpack freezes Clock/action; resume returns to backpack UI, no leaked movement/use; second pause token still holds. | Gameplay/UI owner; QQ-08 regression |
| Empty/error | Empty backpack shows safe non-actionable message; stale/deleted stack refuses and reloads; missing glyph/key or invalid snapshot never becomes an actionable stale command. | UI owner before screen acceptance |
| Audio/motion | Audio off and mono tests; determine each critical cue remains perceivable without additional meters. Reduced-motion urgent state is static but distinct; measure photosensitivity risk, do not infer from nominal animation rate alone. | Audio/art/accessibility specialist; scope pending |
| Assistive tech | macOS VoiceOver and Windows Narrator/NVDA exploratory exported-build menu spike; report actual support and gaps rather than certify by inspection. | UI programmer; before promising narration |
| Player testing | Recruit disabled players for first-fire prompt, warmth/trend recognition and safe overlay use; include motor, low-vision, CVD, deaf/hard-of-hearing participants. Agree consent/budget before recruitment. | Producer/Scott; no participants or results yet |

## Known Intentional Limitations

| Feature | Tier | Why not committed now | Impact / mitigation |
|---|---|---|---|
| Menu screen reader / blind world navigation | Comprehensive / beyond | No tested engine integration or navigation design | Blind completion not promised; API spike before scope decision, no claim captions solve it |
| Difficulty assists / time slowdown / auto-repeat | Comprehensive | Would change survival rules and QQ-05/QQ-07 | Motor/cognitive barriers remain; preserve tap work and explicit pause, ask Scott before simulation changes |
| HUD repositioning | Comprehensive | Minimal authored hierarchy, no implementation scope approval | Low-vision flexibility limited; test authored safe zones/scaling first |
| Full subtitle style suite / external audit | Exemplary | No budget or specialist engaged | Review release resourcing; baseline contrast/size still required |
| Real-time backpack | All | Owner's resolved QQ-08, not an accessibility omission to auto-fix | World danger persists while reading; disclose it and retain explicit pause |
| Numeric/explicit-readout accessibility HUD | Owner-only | Would contradict non-numeric rule; S2 open | Some players may struggle with qualitative cues; test labels outside HUD only after approval |
| Release-target settings absent in MVP | Standard | Existing GDD phases, not a tier waiver | Cannot call MVP Standard-compliant; QQ-09 schedule/implementation review required |

## Audit History

| Date | Auditor | Type | Scope | Findings / status |
|---|---|---|---|---|
| 2026-11-18 | Devin, author | Document cross-reference only | 18 MVP UI requirement sections, proposed ADR-0002/0014/0016, architecture review | Draft requirements; tier/scope pending; no runtime, visual, assistive-tech or independent audit |

## External Resources

| Resource | URL | Relevance |
|---|---|---|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | Contrast, resizing, input principles; not a game certification |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Game-specific barriers and test checklist |
| Xbox Accessibility Guidelines | https://learn.microsoft.com/en-us/gaming/accessibility/guidelines | Reference criteria, not PC certification claim |
| AbleGamers | https://ablegamers.org | Specialist/user-testing planning |
| Coblis | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Screenshot CVD checks, supplemented by player tests |
| CVAA | https://www.fcc.gov/consumers/guides/21st-century-communications-and-video-accessibility-act-cvaa | Review if communication features enter scope |

## Open Questions

### Own Calls and Scott-only decisions

All values below are proposals, not owner approval or authorization to expand MVP.

| ID | Question / recommended default | Owner / deadline | Resolution |
|---|---|---|---|
| A1 | Confirm Standard tier? Recommend Standard with clearly recorded release gaps, not Basic or an unbudgeted Comprehensive promise. | Scott; before tier gate | Provisional Own Call |
| A2 | Add reduced motion, mono and qualitative critical-audio captions beyond baseline? Recommend release targets after scoped estimate, not extra MVP screens. | Scott; QQ-09/QQ-10 scope review | Provisional Own Call |
| A3 | Approve proposed text/reflow/contrast and color-safe ink targets? Recommend the Visual Accessibility values, preserve stronger HUD floor and authored scale phases. | Scott + art/UI; before UI implementation | Provisional Own Call |
| A4 | Default captions on? Recommend on with a clearly available toggle; future speech uses speaker identification. | Scott; before onboarding/settings spec | Provisional Own Call |
| A5 | Permit configurable hold/hurry alternatives, especially two-step VS tap-out? Recommend safe two-step confirmation, never immediate tap-out or auto-repeat. | Scott; before affected input/settings scope | Provisional Own Call |
| A6 | Explain backpack risk? Recommend concise localized “Time continues” label within backpack, no added HUD warning. | Scott; backpack screen review | Provisional Own Call |
| S1 | When do release accessibility targets become deliverable under QQ-09? Recommend keep MVP/Alpha boundaries and separately estimate missing targets. | Scott; before production planning | Open |
| S2 | Is any explicit/numeric accessibility readout acceptable? Recommend no numeric HUD; first test qualitative contrast/shape/labels, bring evidence before any exception. | Scott; before any exception | Open, no decision taken |
| S3 | Player journey absent: author from `.claude/docs/templates/player-journey.md`? Recommend before per-screen UX, no invented journey evidence. | Scott/UX; before screen review | Open |

### Architecture decisions explicitly preserved

All 16 ADRs remain **Proposed**. This document neither accepts them nor resolves the following [architecture-review owner register](../docs/architecture/architecture-review-2026-11-18.md#owner-decision-register--recommendations-not-decisions). Recommendations below are inherited, not new decisions.

| ID | Dependency / recommended default for Scott | Status |
|---|---|---|
| QQ-01 | Hardware/performance budgets; retain proposed targets only, nominate test hardware and inclusive policy. | Open |
| QQ-02 | Animation/readability; evaluate legally usable clips on existing survivor, no spend/cap approval. | Open |
| QQ-03 | Audio resources; evaluate existing legal audio/sparse stems, no purchase commitment. | Open |
| QQ-04 | Camera/readability; compare 22 m vs 32 m with owner, retain proposed 22 m/FOV30/pitch50/45° steps until decision. | Open |
| QQ-05 | Survival/emotional feel; keep authored values and gather day/night/Breaking-recovery evidence before tuning. | Open |
| QQ-06 | MVP pacing; keep proposed first-day/night plus day-3 hunger validation, rates/map/sink-only food pending owner. | Open |
| QQ-07 | Do not add sleeping-bag bonus, snow cooling, hunger heat, arm logs, auto-chop, mandatory ring, giving-up or late relief without revision. | Open |
| QQ-08 | Backpack real-time; pause menu pauses all. | Decided by owner; not reopened |
| QQ-09 | Minimal backpack, calm fade, 100% MVP scale/hooks vs extra screens/settings; retain proposal pending usability decision. | Open |
| QQ-10 | Deferred content/music/rumble/keepsakes etc.; no new MVP additions/spend. | Open |
| O1 | Snow in Critical: recommend preserve Body/Interaction whitelist; Hypothermic snow allowed, no invented cooling cost. UI must not decide availability itself. | Open GDD conflict |
| O2 | Failed bush bonus: recommend floor each output independently, one grass → zero on failure, reserve unchanged. Do not print a predicted reward. | Open GDD conflict |
| O3 | Fire threshold: recommend exact authoritative heat/radius each minute, >0.1 threshold cosmetic only. No UI-owned heat inference. | Open GDD conflict |
| O4 | Inclusive Body/Thermal cost: recommend profile and tighten query sub-budget before any budget increase; no compliance claim. | Open GDD conflict |

**Handoff**: Run `/ux-review` before implementation; independent audit and Scott's tier/scope confirmations remain outstanding. At standard workflow, review of key screen specs is recommended before `/gate-check production`; this project-wide draft is not a substitute for those specs.
