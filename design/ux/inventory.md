# UX Spec: Backpack / Inventory

> **Status**: Approved — scoped MVP design review; implementation and visual verification pending
> **Author**: Devin (ux-designer), non-interactive authoring requested by owner
> **Last Updated**: 2026-11-19
> **Journey Phase(s)**: Inferred from game brief; no player journey map exists
> **Platform Target**: PC macOS / Windows; keyboard/mouse primary, partial gamepad; no touch
> **Accessibility Tier**: Standard — confirmed and committed by Scott (owner), 2026-11-19 (A1 resolved)
> **Template**: UX Spec
> **Related GDDs**: [Inventory §UI Requirements](../gdd/item-database-and-inventory.md#ui-requirements), [HUD](../gdd/hud.md), [Input](../gdd/input-and-action-map.md), [Time Rule 8](../gdd/time-and-day-cycle.md)
> **Related ADRs**: Accepted ADR-0002, ADR-0016; [control manifest](../../docs/architecture/control-manifest.md)
> **Related UX Specs**: [HUD](hud.md), [Pause](pause-menu.md), [Death](death-screen.md)

All controls use [interaction patterns](interaction-patterns.md): Button, Focus Management, Escape / Cancel, Screen Push / Pop / Replace, Loading State / Empty State / Error State and Reconnect Recovery. Paper-and-ink UI follows [art bible §4/§7](../art/art-bible.md). [Accessibility requirements](../accessibility-requirements.md) govern the committed Standard tier and separately identified proposals; no runtime, contrast, assistive-tech or visual verification is claimed.

## 1. Purpose & Player Need

“I need to find and use what I carry without losing track of the cold.” The player goal is a deliberate item command or a safe return to play. The game communicates a **live backpack**, not a time-out. Minimal list MVP only; no grid, crafting, sort/filter tabs, equipment editor or exact counts. Accepted ADR-0016 overrides the older Inventory UI request for counts/load gauge with qualitative identity, wetness and load bands. Trace: TR-item-database-and-inventory-001…030 via ADR-0009; TR-hud-001…024 via ADR-0016, restricted to their presentation portions.

## 2. Player Context on Arrival

The player may be mid-chop, cold, thirsty or trying to eat while a fire declines. Load is high: survival and carried items compete. They know the world still exists but may wrongly expect a pause. Arrival text says “Time continues. Open pause menu to stop.” Existing work continues; new movement/world verbs are blocked. Target feeling: hurried but informed, never tricked into thinking browsing is safe.

## 3. Navigation Position

Gameplay [HUD](hud.md) → backpack UI overlay → [pause](pause-menu.md) over retained backpack → backpack → gameplay. Owner terminal transition replaces the stack with [death](death-screen.md); it is never Back. Backpack requests UI context ONLY, no pause token and no cancellation of active work.

## 4. Entry & Exit Points

| Trigger | Entry / exit | Focus / consequence |
|---|---|---|
| `backpack` (Tab, Y/Triangle defaults) in Gameplay | Open live list | First row, or Close if empty |
| `backpack` while list is top | Close to Gameplay | Release UI request; rearm held inputs only after release |
| Close button / `ui_cancel` | Close to Gameplay | Same |
| `pause_menu` (Esc, Start/Options) | Push pause | Resume focused; list/selection retained |
| Pause Resume / Back | Return to backpack | Restore stable selected row, else nearest surviving predecessor, else first valid row, else Close |
| Terminal snapshot | Replace, disable all commands immediately | Terminal screen handles new focus |

Esc opens pause rather than silently closing the live backpack; it is not also delivered as `ui_cancel`.

## 5. Layout Specification

```text
+ [Backpack]                  +       world remains visible
| Time continues. Pause to stop. |
| Load: [qualitative band label] |
| [sketch] Item — wetness        |
| [sketch] Item — wetness        |
| [Use / Eat] [Drop]             |
| [owner refusal / Working]     |
| [Close]                       |
+-------------------------------+
```

| Zone / component | Placement at 1920×1080 | Content / pattern |
|---|---|---|
| List panel | Left 36% of centred 16:9 safe rectangle, inset 5%; full safe height | Real-time Backpack; nonnumeric sketches/labels |
| Rows | Scrollable middle; selected row visible | List Item / Inventory Slot, stable stack ID |
| Actions | Below rows | Button; contextual Use/Eat and Drop only when owner exposes them |
| Status | Between actions and Close | Action Refusal, always-readable disabled reason |
| Close | Bottom of panel | Secondary Button |
| World cues | Remaining view; band not obscured | HUD may shift within bottom-left safe zone to avoid panel |

Load is a qualitative label from owner band, not a new numeric gauge. No stack multiplier “×N”, durability percent, mass or food stats. Wetness uses droplet + darker sketch + word, readable in grayscale.

## 6. States & Variants

| State | Trigger | Behavior |
|---|---|---|
| Loading | No current run snapshot | “Loading backpack”; commands disabled, Close/Pause work; no auto-pause |
| Ready | Valid snapshot | Show current rows and owner-available commands |
| Empty | No stacks | “Backpack empty”; no phantom selected row, Close focused |
| Pending | Command accepted for processing | “Working”; disable repeat dispatch, still Close/Pause; world keeps running |
| Busy / Critical | Owner refuses admission | Readable localized reason; do not bypass work/hand/tool whitelist |
| Stale / error | Missing stack, mismatched revision or invalid snapshot | Clear actionable stale row, request refresh; “Items changed” / “Backpack unavailable”; Close/Pause remain |
| Lost/broken/consumed row | Owner revision changes | Remove row, focus nearest surviving predecessor, then first valid row, then Close; never dispatch another item's command from the same event |
| Disconnect | Active controller lost | Router-owned safety gate, deliberate resume required |
| Terminal | C4 commits terminal | Disable facade at once; no late command callback affects next screen/run |

No auto-dismiss timeout on reading/error states. Owner refusal feedback uses newest-only 1.5 real seconds; disabled reason persists while unavailable.

## 7. Interaction Map

| Input | Focus / action | Response |
|---|---|---|
| Arrow keys / D-pad | Row zone → available Use/Eat → Drop → Close | Left/right traverses zones, up/down selects bounded rows or buttons; no list wrap; outline focus |
| Tab / Y / Triangle | Close via backpack action | Reserved for backpack-close, never also traverses focus |
| Left-click row, Enter/A on row | Select only | Selected identity and conditions shown; no implicit consume |
| Enter/Space/A or click action | Use/Eat or Drop selected stable ID | Owner request once, pending text; quiet paper cue optional |
| Wheel / keyboard arrows | List | Scroll and keep focus visible; no world zoom |
| Close / B / `backpack` | Close | §4 |
| Esc / Start | Pause | §4 |

No drag/drop, split quantity or drop-all affordance. Owner-resolved unit/action semantics apply, never a UI-invented quantity. Unavailable actions show the admission reason, not hover-only tooltips. Tab is not focus traversal on this screen: the authored backpack binding takes precedence. Shift-Tab has no second focus meaning here either; arrows reach every control without changing bindings. This is an explicit template Tab-navigation exception to retain the GDD default and one-event/one-meaning rule, not a second dispatch route.

## 8. Data Requirements

| Data | Owner / format | Update trigger | Null handling |
|---|---|---|---|
| Rows: stable ID/revision, identity key, wetness band, allowed verbs | Inventory C6 detached snapshot | Inventory revision: consume, transfer, loss, wetness band change | Clear stale command targets, show unavailable/empty as appropriate |
| Load qualitative band | Inventory / enum | Owner load-band revision | “Load unavailable”, no fabricated value |
| Busy/admission reason | C4 / localized reason key | Command result/action state change | Disable command, retain Close/Pause |
| Device glyphs | InputRouter / bindings | Meaningful device/binding change | Localized action name |
| Live / terminal context | Coordinator / run ID and end snapshot | Owner context/end dispatch | Disable commands until valid |

## 9. Events Fired

Proposed typed application requests, not newly approved engine APIs or analytics.
| Player action | Request / payload | Receiver | Contract |
|---|---|---|---|
| Open / close | `request_ui_context(source, open)`, run/source identity | Coordinator / InputRouter | Idempotent; backpack never a pause source |
| Select / scroll | None | Local presentation | No gameplay effect |
| Use / Eat / Drop | Existing C4/C6 action/transfer request; run ID, stable stack ID, expected revision, owner verb | Action resolver / Inventory | Validate current stack, hands, tools and terminal state; owner commits or refuses |
| Pause | Pause navigation request; return source/focus | Coordinator | Pause spec owns token |
| Refresh after stale row | Snapshot refresh request; run/revision | Inventory facade | Read only |

- [ ] With a timed action running, open backpack: clock, action completion, physiology, Fire and Morale continue; W/E send no world action.
- [ ] Pause over backpack freezes timers; Resume returns to the same list and work resumes; closing list with E held fires nothing.
- [ ] Delete/consume a selected stack while list is open: no stale command commits and focus lands on valid row or Close.

## 10. Transitions & Animations

| Transition | Trigger | Type | Duration | Easing | Interruptible | Reduced-motion proposal |
|---|---|---|---|---|---|---|
| Enter | Owner accepts navigation | Opacity only | 150 ms | Linear | Yes, terminal wins | Instant |
| Exit | Accepted close/navigation | Opacity only | 100 ms | Linear | Yes | Instant |
| Pending / error / refresh | Owner response | Static label replacement | Immediate | None | Yes | Identical |

These are author defaults, not new player settings. Input context changes immediately, not after a fade. Transition cosmetic failure must not strand focus or keep a token alive. Terminal presentation's authored end shot takes precedence over these menu timings.

## 11. Input Method Completeness Checklist

Checked boxes describe specification coverage, NOT executed tests.
**Keyboard**
- [x] Arrow keys reach rows → Use/Eat → Drop → Close, with bounded list traversal; Tab closes instead of traversing, as explicitly required by the authored backpack binding.
- [x] Enter / Space through `ui_accept` activates focused control once; Esc through `pause_menu` follows §7.
- [x] Every mouse action has a keyboard path; focus outline remains visible; modal focus cannot escape.
**Gamepad**
- [x] D-pad or left stick follows the same order; A/Cross = `ui_accept`, B/Circle = `ui_cancel`; Start/Options = `pause_menu`.
- [x] No analog precision, trigger/bumper shortcut, drag, hold or chord required.
- [x] Active-pad disconnect uses InputRouter safety overlay. Reconnection alone does not resume; deliberate resume and release/re-press are required. Keyboard recovery remains reachable.
**Mouse**
- [x] All buttons/rows have readable default, hover, focus, pressed, disabled and pending states per Button/List patterns; hover never steals keyboard/gamepad focus.
- [x] Targets at least 44×44 reference pixels; left-click selects/activates once on release; release outside cancels.
- [x] Right-click is no-op; wheel scrolls only the list under pointer, otherwise no-op.
Touch: not supported. Menu `ui_*` mappings are semantic InputRouter bindings, not permission for per-control raw event listeners.

## 12. Accessibility

Standard is confirmed and committed by Scott (owner), 2026-11-19; A1 is resolved. Detailed A2–A6 proposals and QQ-09 delivery scope remain open. Proposed menu floor 24 px at 1080p; at 720p use at least 18 px. Require adjustable text with reflow for Standard release delivery; the proposed range is 100–200%, not a new MVP settings addition. Remapping, text adjustment, colorblind support and applicable speaker-identified subtitles remain Standard release requirements even while their shared settings implementation is deferred. This is a screen design requirement, not a claim that an implemented build meets Standard. The template's generic Standard narration assumption differs from the project tier table: accessible names and announcement strings below are implementation hooks; comprehensive menu narration remains unapproved scope.

| Text / control | Background | Required contrast | Measured |
|---|---|---|---|
| All labels, disabled reasons, status | Paper backing over snow/night/fire | 4.5:1 ordinary text | Not measured |
| Large title / meaningful outlines | Paper/ink panel | 3:1 | Not measured |

No color-only states: focus uses outline, pending/error uses words, wetness uses shape plus label. Do not depend on an audio cue to understand an action. Focus order: rows → Use/Eat → Drop → Close; cycle in both directions, omit disabled command stops only if their reasons are still readable in the selected-row description. Modal Cancel is the initial focus; closing restores invoker or safe first control. Focus never enters the passive world/HUD.

Accessible name includes visible label; selected rows include qualitative condition and action availability. Proposed announcement on arrival: “Backpack. Time continues.”; pending changes announce “Working”, rejection announces localized owner reason once, and focus restoration announces destination name. No periodic numeric reading or interruption by repeated live snapshots. Menu narration and reduced motion remain proposals, not delivered features. Keep at most four conceptual streams (title, content, selection/actions, status), below the 7±2 heuristic; this is not user-research evidence.

## 13. Localization Considerations

All strings use localization keys, never text baked into sketches. Minimum 40% expansion; character budgets are test fixtures, not permission to truncate meaning. No ellipsis for actions or failure reasons: wrap and grow/scroll panel. CJK uses font fallback and stable spacing; never shrink below font floor. RTL mirrors panel alignment, reading/focus order and text, not device glyph artwork or world projection.

| Text role | English fixture limit | Expansion fixture | Overflow |
|---|---|---|---|
| Title | 24 characters | 34 | Wrap |
| Action label | 24 | 34 | Grow button, then wrap |
| Row identity / condition | 48 | 68 | Wrap row |
| Status / confirmation / error | 96 | 135 | Grow status region, scroll if needed |

Layout-critical: actions and status must survive the expansion fixture, 200% planned text and RTL. No numeric gameplay values are introduced by localization.

## 14. Acceptance Criteria

Implementation targets below remain unexecuted.
- [ ] First panel frame appears within 200 ms and usable local data within 500 ms on nominated minimum hardware; maintain 60 fps ±5 during navigation (hardware nomination QQ-01 pending).
- [ ] At 1280×720 and 3840×2160, 4:3/16:9/16:10/21:9, safe content does not overlap, clip or escape the inset; expanded strings and planned 200% text reflow without hiding actions.
- [ ] Every §7 action works with keyboard alone, D-pad/face buttons alone and mouse alone; no double command from one input and no held action on return.
- [ ] Every §6 loading/empty/error case has its stated safe escape; stale response from an old run cannot navigate or change a row.
- [ ] Every §9 request goes to its owner once with listed identity; no UI mutation of gameplay state or direct SceneTree pause.
- [ ] All ordinary text measures at least 4.5:1, large text/control boundaries 3:1 over snow, fire and night; grayscale preserves all meaning and focus.
- [ ] Enter and exit obey §10; proposed reduced-motion mode uses instant menu transitions if that setting is approved.
- [ ] All localized action/status fixture lengths in §13 wrap without clipping; focus remains visible when scrolled.

## 15. Open questions / own calls

| ID | Decision / gap | Owner / deadline | Disposition |
|---|---|---|---|
| A1 | Standard tier confirmed and committed | Scott (owner); resolved 2026-11-19 | Tier criterion available for UX review; implementation compliance and A2–A6 not approved by this decision |
| J1 | Player journey map not yet created | Design; before implementation planning | Author from `.claude/docs/templates/player-journey.md`; arrival context here is inferred |
| U1 | Menu fade timings, layout sizes, target sizes and text budgets above | Scott + UI/art; before implementation | Reasonable author defaults, not measured outcomes |
| I1 | Qualitative list replaces older count/gauge request | Accepted ADR-0016 | No numbers; full inventory remains VS |
| I2 | Esc opens pause, B/Close/Tab closes list; arrows navigate all controls | UI/Input; before implementation | Author mapping within ADR-0002 UI context; template Tab traversal waived here to preserve authored backpack binding |
| I3 | No UI quantity selector or new consumption semantics | C4/C6 owners; before implementation | Expose only existing resolver verbs; do not implement an invented bulk drop |


Cross-reference audit: named patterns reused, no new reusable pattern required; linked navigation matches sibling specs. Session-state and session-log writes are intentionally excluded by this task. No TR registry changes: these specs refine existing requirements rather than allocate new architecture TRs.
