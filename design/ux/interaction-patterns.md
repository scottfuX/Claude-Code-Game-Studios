# Interaction Pattern Library

> **Status**: In Design — draft, no implementation approval
> **Author**: Devin (ux-designer), for Scott's review
> **Last Updated**: 2026-11-18
> **Version**: 0.1
> **Engine / UI**: Godot 4.7 / Control nodes, Theme, CanvasLayer
> **Template**: Interaction Pattern Library
> **Related**: [Accessibility requirements](../accessibility-requirements.md), [art bible](../art/art-bible.md), [HUD GDD](../gdd/hud.md), [input GDD](../gdd/input-and-action-map.md), [architecture review](../../docs/architecture/architecture-review-2026-11-18.md)

## Overview

Reusable paper-and-ink behaviors for Lonefire's small survival interface. No per-screen UX specs exist yet; this initial catalog is derived from GDD requirements, not an audit of implemented components. Player journey is absent; expected context is cold, pressured work, inferred from the concept rather than user research. The backpack is a **real-time overlay**: time and active work continue. Only the explicit pause menu requests player-initiated pause; disconnect safety is a separate InputRouter-owned recovery gate.

All patterns use named InputMap actions, localization keys and current-device glyphs. Keyboard/mouse is primary; gamepad is partial on macOS/Windows PC. No touch or console behavior is promised. Noninteractive HUD controls ignore focus/input. Keyboard/gamepad focus and mouse hover are independent; raw event handling never dispatches an owner command twice.

The provisional accessibility target is **Standard**, not yet confirmed by Scott; see Own Calls A1–A6 in the accessibility document. All 16 ADRs stay **Proposed**; ADR-0002/0014/0016 supply proposed implementation contracts, not accepted architecture. QQ-08 is owner-decided; QQ-01–QQ-07, QQ-09 and QQ-10 remain open. O1–O4 were resolved by Scott on 2026-11-19; O4 profiling remains pending.

## Pattern Catalog

| Pattern | Category | Used in / role | Scope |
|---|---|---|---|
| Button (Primary / Secondary / Destructive) | Standard control | Menus, backpack, confirmations | MVP scaffold; full menus deferred |
| Toggle / Slider / Dropdown | Standard control | Accessibility/audio/camera/settings | Alpha; QQ-09 |
| List Item / Grid Item / Scroll Container | Standard control | Backpack list, later full inventory | List MVP; grid deferred |
| Modal / Confirmation Dialog | Standard control | Pause-owned dialogs, future destructive choices | No implicit pause |
| Toast / Tooltip / Progress Bar / Input Field / Tab Bar | Standard control | Future non-gameplay screens | Conditional; no new MVP surface |
| Inventory Slot | Game-specific | Qualitative item selection | Minimal list facade |
| Qualitative Survival HUD | Data display | Body band, need icons, sun/moon arc | MVP, no numeric meters |
| Context Action Prompt | Game-specific | World verbs and first-fire hint | MVP |
| Action Refusal | Feedback | Unavailable action or stale request | MVP |
| Real-time Backpack | Overlay | Live inventory commands | MVP |
| Pause Stack | Navigation | Explicit pause over gameplay/backpack | MVP contract |
| Reconnect Recovery | Overlay | Active controller disconnect | MVP safety contract |
| Screen Push / Pop / Replace | Navigation | Nested screens | Scaffold; screen specs still needed |
| Focus Management | Navigation | Every interactive screen | Required |
| Escape / Cancel | Navigation | Back vs work cancellation | Required |
| Loading State / Empty State / Error State | Feedback | Data and async screens | Required where applicable |
| Hold-to-confirm | Input | VS radio/tap-out | Deferred; A5 alternative pending |

## Patterns

### Standard Control Patterns

All entries are Draft. Use the shared state model below; screen-specific commands remain with their owners. Reference wireframe: `[sketch] Item name — damp   [Use] [Drop]    [Close]`. This is a semantic example, not an approved visual layout.

#### Button (Primary / Secondary / Destructive)

**Category**: Input. **Used In**: backpack commands, pause and later menus.
**Description / when to use**: one labeled primary action, lower-weight Back/Cancel, or an irreversible action that opens confirmation. Do not use a button to display a passive HUD state.

| State | Visual / feedback | Input / behavior |
|---|---|---|
| Default | Paper/ink, primary filled vs secondary outline | Visible label matches semantic name |
| Hover | Ink emphasis, no selection change | Mouse hover only; does not steal keyboard focus |
| Focus | Persistent high-contrast outline, proposed 2 px at 1080p (P1) | Named UI navigation; keyboard/gamepad always see focus |
| Press | Subtle ink depression; optional menu confirm sound | Click or `ui_accept` activates once on release; release outside cancels |
| Disabled | Muted but readable label + reason | No command; reason available in adjacent text, not hover only |
| Pending | “Working…” text, no spinner dependency | Suppress duplicate command until result; owner snapshot determines enabled state |

Destructive buttons open **Confirmation Dialog** and never commit directly. Focus safe Cancel by default (P1), not the dangerous choice. Ordinary Drop follows Inventory's existing owner transaction, not an invented delete-item confirmation. Use native Button signals for menu input; no parallel gameplay polling.

#### Toggle / Slider / Dropdown

**Category**: Input. **Used In**: Alpha settings only, pending QQ-09.
**Description**: binary state, bounded continuous value or discrete choice respectively. Not for hidden survival values or HUD meters.

| Pattern | States / input | Feedback / accessibility |
|---|---|---|
| Toggle | Off/on, hover, focus, disabled; click/`ui_accept` switches once | Printed On/Off and switch position, never hue alone; semantic state separate from label |
| Slider | Default/focused/dragging/disabled; mouse drag or left/right steps, endpoints clamp | Visible setting value, named range/unit, no drag-only control; no survival values. Numeric settings values are not numeric HUD readouts. |
| Dropdown | Closed/open, focused option, selected, disabled; up/down browse, accept commits, cancel restores | Keep selected option visible, scroll into view; empty options → disabled with reason |

Ranges derive from GDD/settings ownership, not generic template defaults. Proposed text range and motion options refer to A2/A3/A5; this library does not approve them. Invalid setting leaves last valid value and clear recovery; persistence failure must not falsely report Saved. Menu adjustment sounds are supplementary and settings-bus owned.

#### List Item / Grid Item / Scroll Container

**Category**: Layout/Input. **Used In**: MVP backpack list; future inventory grid deferred.
**Description**: select a stable item row, then a labeled owner command; do not require double-click or drag. Rows distinguish default/hover/focus/selected/disabled; selection and focus may differ, with an outline for focus and a separate selection mark. Up/down navigates bounded rows, accept selects, explicit Use/Drop activates. Mouse click does the same, never acts on hover.

Keep focused content visible inside ScrollContainer; mouse wheel, keyboard and gamepad all scroll. Empty list uses **Empty State**. Removed focused row chooses nearest surviving predecessor, then first enabled row, then Close. Never fall back to a different item's command during the same event. Grid Item remains a future variant: directional cell navigation, named empty cells, select/action parity and non-drag transfer alternative required before use; no MVP grid, counts or crafting tree added.

Accessibility: localized identity/qualitative condition, readable rows, semantic selected/disabled states. Stable IDs and revisions bind selection; visual row index never identifies an owner transaction.

#### Modal / Confirmation Dialog

**Category**: Modal. **Used In**: explicit pause menu's nested choices, future reset/quit screens.
**Description / when to use**: block background UI while a decision is necessary, not to show routine refusals or pickups. A modal by itself **does not pause simulation**. Only the explicit pause menu owns its pause token; a dialog inside it inherits that context and never releases the parent's token.

States: opening → active → confirming/pending or cancelled → closed; failure returns to active with error text. Give title, consequence, Cancel and explicit action label. Focus Cancel, trap traversal to visible dialog children, restore trigger on close or safe surviving fallback. Escape/`ui_cancel` cancels; Enter/`ui_accept` activates the focused choice, never a hidden destructive default. A blocking system error offers recovery or quit, not an inescapable blank modal. Optional audio and transitions must not delay focus readiness or become the sole feedback.

#### Toast / Notification

**Category**: Feedback. **Used In**: future non-gameplay menus only.
**Description**: non-blocking informational outcome; never a mandatory acknowledgment, danger cue or in-play reward counter. Proposed single visible toast with a bounded two-entry newest queue, no achievements/rewards surface invented (P2). Do not queue in-play refusals: **Action Refusal** replaces them. No focus theft; if narration is later scoped, test polite announcement support. Important information must remain available in its originating screen; no toast-only error recovery.

#### Tooltip

**Category**: Feedback. **Used In**: later settings/details.
**Description**: supplementary explanation, not the only source of an action or refusal. Appear after proposed 400 ms hover or 300 ms keyboard/gamepad focus (P2), wrap/clamp to safe area, close on blur/cancel without closing parent. Do not obscure focused control. Empty/missing description creates no blank tooltip; semantic description remains attached to control where supported.

#### Progress Bar

**Category**: Data Display. **Used In**: real loading work or future radio hold ring, not routine survival work.
**Description**: determinate progress only when authoritative completion is known; otherwise label “Loading…” without fabricated percentage. No health/resource numeric bars, mandatory work ring or completion countdown added to the HUD (QQ-07). Interrupted radio hold resets with no action. Loading progress may be described textually for assistive tech if verified; no announcement on every frame.

#### Input Field / Tab Bar

**Category**: Input/Navigation. **Used In**: future settings only if a screen spec establishes need.
Input Field supports focused/editing/invalid/disabled states, labeled constraints, keyboard editing/paste and visible inline error; commit validates, cancel restores prior valid text. No invented naming/search feature.
Tab Bar separates a small set of peer panels: selected and focused are distinct, left/right browse and accept activates (P1); preserve each panel's focus, expose selected state. No empty tabs, hover activation or MVP settings categories authorized.

### Game-Specific UI Patterns

#### Inventory Slot

**Category**: Game-specific. **Used In**: MVP backpack row, later full inventory.
**Description / when to use**: localized item sketch/name with qualitative wetness/load, selected via **List Item**. Damp uses droplet + darker sketch + word, never darkness alone. Empty row has no commands; no locked/DLC/cooldown/rarity variants are invented. Do not apply generic template counts to MVP: ADR-0016 proposes no count labels. Inventory GDD's future counts/load gauge are a QQ-09 screen-scope dependency, not permission to add numbers to this facade.

Input routes Use/Eat/Drop to existing action/transaction owners with stable stack ID and revision. A stale selection fails harmlessly and refreshes; never mutate a model from UI. Selection remains visible without hover, associated command labels remain keyboard/gamepad accessible. No mandatory drag, split-stack quantity dialog or nested crafting.

#### Qualitative Survival HUD

**Category**: Data display. **Used In**: gameplay.
**Description**: body band first, trend second, up to three need sketches and sun/moon arc. Reference: `❄ |----ink----| flame   ◀   [arm] [cup] [bowl]    sun arc` (semantic only, exact layout goes into HUD spec).

| State / element | Specification |
|---|---|
| Body | H1 clamps fill between 30–37°C internally; no printed values. Snowflake/flame, stage ticks and fill direction back up hue. |
| Trend | H2 single at absolute rate ≥0.1, double ≥1.0; candidate persists two unpaused real seconds; steady hides. These are internal thresholds, not labels. |
| Calm | Warm, no trend/warning/prompt for eight real seconds → alpha 0.35 over 1.5 s. Warning/trend/stage/prompt → full alpha within 0.5 s. |
| Needs | First warning normal ink; urgent bold with authored 1 Hz/10% pulse, at most three. A2 proposes static bold alternative; no extra hunger/energy bars. |
| Day/night | Sun/moon along H5 arc, no hour/day numbers. |
| Ritual/sleep/end | Ritual/sleep hides all except band 0.35; end hides all. Critical versus ritual/sleep combined visibility is a proposed ADR-0016 precedence, not accepted owner clarification; record fixture gap below. |

Paper/ink, no low-poly widgets/glow/gradients. Text ≥18 px at 720p, 5% safe inset; ultrawide centered 16:9 safe rectangle then inset. No morale/Resolve, thermometer, minimap/markers, numeric temperature/hunger/mass/day/time/counts or damage numbers. Empty optional warnings hide; invalid band/arc snapshot logs and holds last valid state (never NaN). No UI audio in play. Read-only detached snapshots, no gameplay queries during drawing.

**When NOT to use**: debug telemetry, progress meters or accessibility numeric readouts; A/S2 remains Scott-only. Alpha scale/off/high-contrast must await QQ-09; no new MVP toggles.

#### Context Action Prompt

**Category**: Game-specific/Input. **Used In**: world target and first-fire hint.
**Description**: show at most two localized verbs from current Interaction snapshot, paired with actual binding glyphs. Reference: `[current interact glyph] Gather sticks   [secondary glyph] …`. Tap starts timed work; repeat mode remains one tap/attempt. Never imply a sustained hold for ordinary work or add a mandatory work ring.

Project final camera world point into UI once, reject behind-camera/invisible points, stay ≥40 px clear of actual survivor silhouette and inside safe area. Hide immediately when target/verb disappears; do not leave fading stale actionable prompts or offscreen markers. Changed device/rebind updates glyph and text; no hard-coded E/F. Missing glyph falls back to localized action/binding text (P3), not a wrong controller icon. Missing localization follows HUD GDD: key in dev, empty+log in release; log a release-blocking critical text defect rather than inventing translation.

First-fire hint starts in the first minute and latches gone on first Kindling flame or ten game minutes. Refusals use **Action Refusal**. No extra sound or animated rise through the survivor. Empty target = no prompt; controller disconnect uses recovery overlay. Critical verbs come from owner admission; O1 was resolved by Scott (2026-11-19): snow allowed in Hypothermic, refused in Critical; UI cannot override it.

#### Action Refusal

**Category**: Feedback. **Used In**: failed action admission/backpack commands.
**Description**: short localized diegetic reason above survivor for 1.5 real seconds; newest replaces previous, never queues or blocks input. Missing tool, fatigue, cold or load reason comes from owner; no invented probability, timer or reward count. The corresponding backpack row may show its current disabled reason without extending the in-play refusal timer.

No target or reason means hidden, not “Unknown” indefinitely. Stale stack refreshes without applying a different selection's action. Missing-key behavior follows **Context Action Prompt**. No harsh buzzer; in-play HUD remains silent. A persistent help/refusal-history feature is a scope gap, not approved compensation.

#### Real-time Backpack

**Category**: Overlay. **Used In**: backpack.
**Description**: inventory is a live, qualitative command facade, not a safe planning pause. Reference: `Backpack — Time continues | item — damp | Use | Drop | Close`. Label is A6 provisional, not an approved layout.

| Event | Behavior |
|---|---|
| Open via backpack action | Request UI context only; no pause token, no Clock stop, no action cancel. Clear/rearm input per router. Focus valid selected row or first row/Close. |
| While open | Time, work, Fire, physiology and Morale continue. Refresh owner snapshots continuously; action may complete behind list. Movement/world action inputs are gated, not simulation. |
| Use/eat/drop | Request through C4/C6 admission with stable ID/revision, respect existing work/critical/tool constraints; facade never bypasses one-action-at-a-time. |
| No items | Icon + “Backpack is empty” + “Gather supplies nearby”; Close remains available. |
| Item disappears | Disable its pending affordances, clear stale selection, refresh, restore safe focus. Never retarget a command by row index. |
| Pause over backpack | Open explicit pause menu/token above UI; simulation freezes. Close pause returns to backpack UI, still no Gameplay until backpack closes. |
| Close via backpack/back | Release only its UI request; held inputs must be released before gameplay re-arms. Closing never cancels running work or releases someone else's pause. |
| Death/end | Close/disable command facade and use single terminal snapshot; no commands from stale rows. |

**When NOT to use**: full inventory grid/crafting/kit selection/settings. Follow **Focus Management** and text/contrast targets. There is no numeric load/count/durability label in MVP; qualitative state may wrap.

#### Pause Stack

**Category**: Navigation/Modal. **Used In**: explicit pause menu over gameplay or backpack.
**Description**: `Gameplay → Backpack(UI, running) → Pause(UI, paused) → Backpack(UI, running) → Gameplay`. Direct Gameplay → Pause → Gameplay is also valid.

Pause menu acquires InputRouter-owned token; Clock and action timers freeze until all pause tokens release. Resume/close releases only its own token; second safety/pause token keeps pause. Nested confirmation keeps parent pause. No direct SceneTree pause manipulation, duplicate clock or accidental “all screens pause” helper. Escape in Gameplay opens pause, never silently cancels timed work. Opening pause during an input hold clears it; resume requires release, not ghostconfirm.

Accessibility: focus Resume/safe return on initial pause (P1), retain return focus to backpack row if it still exists. Missing row uses safe fallback. Back/cancel from pause returns to exact prior context. Future settings are not implied by naming this pattern.

#### Reconnect Recovery

**Category**: Overlay. **Used In**: active-gamepad disconnect path.
**Description**: InputRouter owns safety pause/gate and reconnect instructions; HUD presents localized “Reconnect controller or use keyboard” and correct device glyphs. This is the explicit safety exception, not backpack-triggered pause.

Do not allow the reconnecting button to activate the row behind overlay. Keyboard recovery switches device/glyphs on meaningful input; restore prior UI context and focus, release/rearm before gameplay. Preserve other pause tokens, including explicit pause above a backpack. Test actual router behavior when disconnect happens while backpack UI is open; do not create another automatic-pause authority if safety scope differs. No supported device/glyph = accessible text recovery, not a blank modal.

#### Hold-to-confirm

**Category**: Input. **Used In**: VS radio/tap-out only; dormant in MVP.
**Description**: named radio action stays reachable in UI and Critical as authored; hold 1.5 real seconds fills qualitative ring, early release cancels with no effect. Completion dispatches once through owner, not UI result mutation. Context change/disconnect clears holds/buffers. No numeric countdown or new mandatory work-progress ring.

A5 proposes configurable timing/two-step accessible confirmation, pending Scott and VS input design. Do not implement it as immediate tap-out or settle QQ-07 “mandatory ring.” A future screen spec must define safe confirm/cancel and recovery before activation.

#### Non-applicable template patterns

Ability / Skill Icon, generic numeric Health / Resource Bar, Damage Number and Dialogue Box are not current gameplay patterns. Do not copy template combat meters, cooldown counts, numeric accessibility values or dialogue typewriter into Lonefire. Body band uses **Qualitative Survival HUD** instead. Future diary dialogue requires its own screen/voice scope under QQ-10; this is a gap, not a removed GDD requirement.

### Navigation Patterns

#### Screen Push / Pop / Replace

**Category**: Navigation. **Used In**: nested menus and overlays.
**Description**: push retains previous UI/focus record; pop removes only top screen and restores that record; replace discards current screen and places focus at the new screen's safe first control. Use replace for loading/terminal transition, not Back. No application-wide singleton or new architectural service is selected here; compose existing run UI/context ports.

Never infer pause from stack depth. Opening backpack requests UI only; opening explicit pause requests its token. Focus readiness/context gating is immediate even while a decorative fade runs. Interrupted transition releases only resources owned by removed screen; terminal replaces/disables all actionable gameplay UI. Long text reflows inside safe area; transitions never move essential content offscreen while actionable.

#### Focus Management

**Category**: Navigation. **Used In**: every interactive screen; not passive HUD.

| Event | Rule |
|---|---|
| Open | Last valid control, otherwise first meaningful enabled control; pause Resume, destructive dialog Cancel. Empty list → Close. |
| Tab / Shift+Tab | Forward/reverse visible logical order; never tab into passive band/arc/sketch. |
| D-pad/stick | Spatial nearest control inside current region, bounded lists, no wrap to unrelated panel. |
| Mouse hover | Independent highlight, never erases keyboard/gamepad focus or triggers selection. |
| Modal | Trap to dialog until cancelled/resolved; no background activation. |
| Disabled/destroyed focus | Next enabled sibling if disabled; nearest predecessor if destroyed, then first enabled, then Close/Back. |
| Pop | Restore trigger by stable ID if still valid, otherwise preceding/first enabled, then Close. |
| No controls | Keep a routed back/recovery path; no invisible fake focus. |

Focus is always visibly outlined at supported scale and contrast. Use Control focus neighbors/semantic names and test actual Godot 4.7 separate mouse versus keyboard focus behavior. A screen reader guarantee requires exported-build API verification; labels alone are not a pass.

#### Escape / Cancel

**Category**: Navigation. **Used In**: every screen and Gameplay.

| Context | Named action / representative binding | Result |
|---|---|---|
| Gameplay | `pause_menu` / Esc or Start/Options | Open explicit pause; do not cancel work |
| Gameplay work | `cancel_action` / C, right mouse, B/Circle | Owner cancels if allowed; not a menu-back alias |
| Backpack | `ui_cancel` / B/Circle or Back control; `backpack` / Tab,Y | Close backpack only; simulation already running |
| Backpack | `pause_menu` / Esc,Start | Open pause above backpack, not a simultaneous close |
| Pause root | `pause_menu` or `ui_cancel`, Resume | Release own token, restore previous context |
| Nested dialog/menu | `ui_cancel` / routed Esc,B/Circle | Pop top UI, safe cancel, retain parent pause |
| Root main menu (future) | `ui_cancel` | Quit confirmation, not immediate quit (P1) |
| Locked/terminal intro | Router's existing gate | No new gameplay command; pause routing only as supported by owner |

The generic template's “Escape always Back” is adapted to the named `pause_menu` contract. Overlapping physical defaults must be resolved once by InputRouter/topmost UI; no raw Esc handler also firing `ui_cancel`. Backpack key closes only backpack, not pause/dialog plus backpack in the same event. Actual per-screen routing and rebound cancel reachability require tests; no InputMap change is made here.

### Feedback and Loading Patterns

#### Loading State

**Category**: Feedback. **Used In**: real async loads/screens.
**Description**: full-screen load supplies title and “Loading…” with determinate fill only from authoritative progress; inline load preserves component size and disables duplicate action. Unknown progress uses static label, not fake percentage/loop required for comprehension. Full loads use existing Locked context, not a modal-induced clock pause. Completion restores defined destination/focus; empty result uses Empty State; failure uses persistent Error State. Future narration needs tested loading/loaded announcements.

#### Empty State

**Category**: Feedback. **Used In**: data-dependent UI.

| Location | Empty behavior |
|---|---|
| Backpack | Bag sketch, “Backpack is empty”, “Gather supplies nearby”; Close enabled, Use/Drop absent |
| Row/details after removal | Clear stale selection, bag sketch + “Item is no longer here”, “Choose another item”; safe focus fallback |
| Settings choices | Neutral sketch + “No choices available”, explanation/Back; disabled selector, not an empty popup |
| World target / optional warning | Hide prompt/icon entirely; do not add a distracting “Nothing here” message to play |
| Loading result | Distinguish legitimate empty collection from load failure; icon/message/recovery action for failure |

No blank selectable phantom row. Passive HUD absence intentionally differs from explanatory screen empty state.

#### Error State

**Category**: Feedback. **Used In**: owner refusal, validation, operation/system failure.

| Type | Treatment / recovery |
|---|---|
| Action unavailable | Action Refusal, diegetic 1.5 s newest-only; no predicted reward or probability |
| Stale inventory request | No mutation, refresh snapshot, safe selection fallback, localized reason; no automatic retry on another stack |
| Invalid setting/binding | Inline icon+specific explanation; retain last valid setting and conflict description, allow edit/cancel |
| Save/load failure (future) | Persistent clear failure and valid Retry/Back route; never “Saved” before actual success, no nonexistent “load last save” feature |
| Missing locale/glyph | Locale follows dev-key/release-empty+log contract; glyph fallback P3; critical missing text blocks release acceptance |
| Invalid presentation snapshot | Log and hold last valid band/arc; clear absent target/verbs; no NaN or actionable stale target |
| Unrecoverable system state | Clear explanation plus known-safe quit/restart route only if supported; no hidden auto-delete/reset |

Use calm, actionable language; icon/outline/text, not red alone. Critical failure persists until acknowledged or recovered; no toast-only recovery. Error presentation never becomes another gameplay authority.

## Animation Standards

Own Call **P2** proposes restrained fades/ink emphasis rather than generic slide/scale-heavy menus. Values below are starting points for usability tests, not a style approval or performance claim. All durations are real time; decorative tweens may not delay input gating or repeat commands.

| Animation | Duration / easing | Reduced motion |
|---|---|---|
| Hover/focus enter / exit | 80 / 60 ms ease-out / ease-in | Static outline, immediate |
| Button down / release | 60 / 80 ms ease-in / ease-out; ink emphasis, no required scale | Immediate state |
| Screen push / pop / replace | 200 ms ease-in-out fade; no required slide | 100 ms fade or immediate |
| Modal open / close | 200 / 150 ms ease-out / ease-in fade | 100 / 75 ms fade |
| Tab change / scroll to focus | 150 ms ease-in-out | Immediate, keep focus visible |
| Tooltip show / hide | 120 / 80 ms fade; hover delay 400 ms, focus delay 300 ms | Same delay, immediate state |
| Future menu toast | 200 ms in/out; minimum 5 s display, pointer/focus pauses expiry | 100 ms fade, no slide |
| Actual loading fill | Up to 300 ms ease-out, never ahead of actual progress | Direct fill; static “Loading…” for indeterminate |
| HUD calm / reactivate | Authored 1.5 s down / 0.5 s up after 8 s calm | Preserve visibility rules pending QQ-09 |
| Urgent need | Authored 1 Hz/10% pulse | A2 proposed static bold indicator |
| World grade / vignette | EF authored ≥3 s grade, 1.5 s vignette, warm hues protected | Existing Alpha reduce-effects factor 0.5; no new simulation modifier |

No damage flash, floating numbers, dialogue typewriter or looping control scale copied from template. Motion options remain Alpha/QQ-09 dependencies; camera reduced-motion disables cinematic framings except end shots per camera GDD, not all movement. Combined Critical/sleep visibility needs owner-reviewed fixtures; do not silently choose a contradictory priority.

## Sound Standards

Use [Ambient & Foley](../gdd/ambient-and-foley-audio.md) and [Emotional Feedback](../gdd/emotional-feedback.md) as current audio sources. No separate sound bible exists. **No UI sound in play**: ordinary HUD changes, prompts, backpack/refusal feedback do not add a layer of clicks/chimes over survival. Template examples of level-up, achievement and damage-number sounds do not authorize those systems.

| Event | Sound category / boundary | Non-audio feedback |
|---|---|---|
| Future menu hover/focus | Optional UI Hover, quiet, rate-limited; no repeated hover chatter | Visible focus/hover |
| Future menu accept/back | UI Confirm / UI Cancel, distinct, supplementary | Button/navigation state |
| Pause-owned destructive confirmation | UI Warning then UI Confirm — Destructive if later scoped | Explicit consequence, safe Cancel |
| Alpha toggle/slider/dropdown/tab | UI Toggle / UI Adjust / UI Select; no per-frame slider spam | State/value and focus |
| In-play HUD/backpack/refusal | None | Band/shape/text; existing owner world sound may still play |
| Work success/failure/item loss/fire | Existing world foley/emotional audio, not new UI reward chime | Cause animation, world changes, qualitative caption proposal A2 |
| Disconnect | Optional safety cue only if audio owner scopes it | Persistent reconnect text |

Actual assets, licensing, sparse music stems and rumble remain QQ-03/QQ-10 open. Alpha bus controls must include Master/Music/Ambience/Foley/UI per audio GDD; any future voice channel needs independent control rather than merging speech into effects. Mono/captions proposal requires cue audit, not new morale/fire meters.

## Gaps & Patterns Needed

- No existing per-screen component inventory/navigation map to reconcile. Write core HUD, backpack, main menu and pause specs at standard workflow, then use this catalog by name; no screen layout is approved by this library.
- Player journey absent: author `design/player-journey.md` from `.claude/docs/templates/player-journey.md` before claiming researched emotional arrival states.
- Full inventory grid/counts/load gauge, settings/remapping, save/load, kit selection, diary, radio/results and captions need screen specs in their actual milestones. QQ-09/QQ-10 gate expansion.
- Preserve Interaction's optional thin progress arc as an Alpha accessibility hook, never a mandatory MVP work bar. Deferred settings also include camera default zoom/45°–90° turn-step, reduce camera motion/effects, HUD scale/off/high-contrast, and per-action keyboard/gamepad remap columns/conflict warnings. Diary mood words and weigh-in/body-weight information are VS screen requirements, not extra HUD elements.
- Critical × sleep/ritual/end visibility and disconnect while backpack UI is active need explicit owner-reviewed fixtures against proposed ADR-0016/0002; not resolved here.
- A1–A6 accessibility targets need Scott confirmation; Standard requirements not implemented in MVP are gaps, not a compliance claim. Screen reader/live announcement support needs platform spike.
- Ability icons, damage numbers, generic numeric health/resource bars and dialogue UI are deliberately not applicable, not missing MVP features.

### Cross-Reference Check

| Check | Result / remaining gap |
|---|---|
| GDD UI requirements | Scanned 18/18 system GDD UI sections, no unmatched systems. All have a requirement destination in accessibility matrix: prompts, band/needs/arc, backpack, world-only cues or deferred settings. This is design coverage, not 18 systems implemented or all future screens specced. |
| Patterns | Every named interaction above appears in this catalog or is an explicit deferred/non-applicable entry. Accessibility doc uses the same names. |
| Navigation | No other UX specs exist to compare. Proposed backpack/pause stack follows owner QQ-08; per-screen and runtime routing remain unverified. |
| Accessibility | Provisional Standard mapped; A1–A6 and settings/caption/hold alternatives remain pending. No numeric HUD workaround. |
| Empty/error states | Backpack, selection, dropdown, loading, target, warnings and invalid snapshots defined; future screens must add their own cases. |
| Architecture conflicts | O1–O4 resolved by Scott (2026-11-19), with O4 profiling pending; QQ-01–QQ-07/09/10 preserved open. Inventory GDD's future counts versus minimal facade explicitly deferred to QQ-09. No ADR accepted. |

## Open Questions

| ID | Question / recommendation | Owner / deadline | Resolution |
|---|---|---|---|
| P1 | Confirm safe focus, visible 2 px reference outline, bounded navigation and explicit tab activation? Recommend these defaults, test at actual scales; screen layouts remain undecided. | Scott/UX; screen review | Provisional Own Call |
| P2 | Confirm restrained timing/notification defaults? Recommend table above, one visible future menu toast + two queued, 5 s minimum; no in-play toast queue. | Scott/art/UX; first UI playtest | Provisional Own Call |
| P3 | Missing glyph fallback? Recommend localized current binding/action text instead of wrong icon; missing localization still follows GDD release-empty+log. | Scott/input/UI; prompt implementation | Provisional Own Call |
| A1–A6 / S1–S3 | See accessibility document's Own Call/open-question tables; recommend defaults there, including Standard provisional tier and no numeric HUD. | Scott; before affected gates/scope | Open |
| QQ-01–QQ-07, QQ-09, QQ-10 | [Inherited owner decisions and recommended defaults](../accessibility-requirements.md#architecture-decisions-explicitly-preserved); no new authority to tune, spend or expand. | Scott; architecture review deadlines | Open |
| O1 | Snow: retain Body whitelist; allowed Hypothermic, refused Critical. UI displays owner-offered verbs only. | Scott; affected action acceptance | Resolved by Scott 2026-11-19 |
| O2 | Failed bush bonus: floor half per output; one grass becomes zero, reserve unchanged. No UI predicted reward count. | Scott; gathering acceptance | Resolved by Scott 2026-11-19 |
| O3 | Fire threshold: exact Thermal/Body publication every minute; >0.1 visual-only. | Scott; heat contract acceptance | Resolved by Scott 2026-11-19 |
| O4 | Body/Thermal: keep Body ≤0.02 ms; profile full path then tighten query budget, number pending. | Scott/technical director; performance acceptance | Resolved by Scott 2026-11-19; profiling pending |
| UX-01 | Full inventory counts/load gauge versus proposed qualitative facade? Recommend minimal MVP, separate full-screen decision in QQ-09. | Scott; inventory screen scope | Open |
| UX-02 | Combined Critical/sleep/ritual visibility and backpack disconnect? Recommend fixture-led review of proposed ADR precedence/router safety, no independent UI exception. | Scott/input/UI; first HUD acceptance | Open |

**Handoff**: Documents are drafted, not approved or visually validated. Run `/ux-review` before implementation; at standard workflow this is recommended for key screens before `/gate-check production`. Stop after requested authoring/commit/push; no implementation, gate pass, ADR acceptance or PR creation is implied.
