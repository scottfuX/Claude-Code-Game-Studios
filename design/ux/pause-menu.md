# UX Spec: Pause Menu

> **Status**: In Review — document draft, not implementation approval
> **Author**: Devin (ux-designer), non-interactive authoring requested by owner
> **Last Updated**: 2026-11-19
> **Journey Phase(s)**: Inferred from game brief; no player journey map exists
> **Platform Target**: PC macOS / Windows; keyboard/mouse primary, partial gamepad; no touch
> **Accessibility Tier**: Standard, provisional pending owner confirmation (A1)
> **Template**: UX Spec
> **Related GDDs**: [Input contexts](../gdd/input-and-action-map.md), [Time Rule 8](../gdd/time-and-day-cycle.md), [HUD](../gdd/hud.md)
> **Related ADRs**: Accepted ADR-0002, ADR-0016; [control manifest](../../docs/architecture/control-manifest.md)
> **Related UX Specs**: [HUD](hud.md), [Backpack](inventory.md), [Title](main-menu.md)

All controls use [interaction patterns](interaction-patterns.md): Button, Focus Management, Escape / Cancel, Screen Push / Pop / Replace, Loading State / Empty State / Error State and Reconnect Recovery. Paper-and-ink UI follows [art bible §4/§7](../art/art-bible.md). [Accessibility requirements](../accessibility-requirements.md) govern provisional targets; no runtime, contrast, assistive-tech or visual verification is claimed.

## 1. Purpose & Player Need

“I need a genuine break, without losing my place or accidentally ending my run.” Resume is the only required MVP command. This is the only player-requested pause surface. Disconnect/loading safety gates remain separate authorities. Trace TR-input-and-action-map-001…028 (ADR-0002), Time Rule 8 / AC21, HUD pause semantics (ADR-0016).

## 2. Player Context on Arrival

The player may be under pressure, mid-work or browsing the live backpack. They want relief from simultaneous survival demands, and fear that closing one overlay could restart the world unexpectedly. The visual target is a quiet, unambiguous “Paused”, retaining the previous view without demanding attention.

## 3. Navigation Position

Gameplay or [backpack](inventory.md) → pause overlay → exact previous context. No automatic return to Gameplay while backpack remains open. Main-menu/settings navigation is deferred, not an invisible executable feature. Terminal state, if already committed before pause admission, wins and uses [death screen](death-screen.md).

## 4. Entry & Exit Points

| Trigger | Route | Focus / ownership |
|---|---|---|
| `pause_menu` from gameplay/backpack | Push pause | Resume; request own UI source and F2 pause token |
| Resume / B / Esc / Start | Pop pause | Release only own pause token + UI source, restore invoker |
| Disconnect while paused | Router recovery over pause | Retain explicit pause token; deliberate recovery returns here |
| Teardown / terminal | Remove run-owned layer | Release own token exactly once, invalidate callbacks |

Closing pause does not override loading/disconnect tokens. Held inputs must be released and re-pressed before delivery.

## 5. Layout Specification

```text
world / retained backpack, visually subdued
          [ Paused ]
          [ Resume ]
```

| Component | Zone / size | Pattern |
|---|---|---|
| Title | Centre safe rectangle, upper centre | Static heading |
| Resume | Below heading; width 320 px at 1080p, grows for text | Primary Button |
| Background | Existing world/backpack snapshot | Pause Stack; noninteractive, no focus |
| Recovery overlay | Above pause when router requests | Reconnect Recovery, not this menu's token |

Inset 5% of centred 16:9 rectangle; no arbitrary survival metrics, settings list, save/load, “tap out” or quit-to-title button. MVP absence of quit-to-title avoids promising run persistence or implementing destructive navigation without its GDD.

## 6. States & Variants

| State | Trigger | Behavior |
|---|---|---|
| Opening / loading | Request pending | “Pausing”; Resume disabled until owner acknowledges gate |
| Paused | Gate acknowledged | “Paused”; Resume enabled |
| Empty / missing world | No valid retained run | “Run unavailable”; Resume disabled; host navigation required, no fabricated run |
| Error | Gate request rejected / invalid token | “Could not pause”; do not display false Paused state; safe Back dismisses failed layer without releasing others' tokens |
| Closing / pending | Resume accepted | Suppress duplicate releases; restore previous source/focus |
| Recovery | Pad disconnect | Explicit instructions, no timeout; router owns safety gate |

No timer auto-resumes. On error that persists with no valid run, host/application close remains possible; a future title recovery command needs the lifecycle contract rather than a UI-only reset.

## 7. Interaction Map

| Input | Action | Response |
|---|---|---|
| Tab / arrows / D-pad | Focus Resume only | Persistent outline; no focus on world |
| Enter/Space/A / click Resume | Request Resume once | Press feedback and optional quiet confirm cue |
| B / Esc / Start | Same safe Resume/back intent | One routed action, not two token releases |
| Right-click / wheel | No-op | No world cancel/zoom |

## 8. Data Requirements

| Data | Owner / format | Update trigger | Null handling |
|---|---|---|---|
| Pause acknowledgement / owned token | Coordinator F2 / opaque token | Acquire/release result | Pausing/error, never claim freeze from UI context alone |
| Return context and validity | Coordinator / source + run ID | Push/pop/teardown | Disable Resume if no valid run |
| Focus identity | Retained screen / stable row identifier | Return | Missing row falls back to nearest surviving predecessor, first valid row, then Close; gameplay has no focus |
| Glyphs / recovery | InputRouter / binding + gate state | Device/recovery event | Text action fallback |

## 9. Events Fired

| Player action | Request / payload | Receiver | Notes |
|---|---|---|---|
| Open | `request_ui_context(pause,true)`, `request_pause(pause)`; source/run ID | Coordinator | Retain returned token |
| Resume / Back | `release_pause(token)`, `request_ui_context(pause,false)` | Coordinator | Only owned token, once |
| Focus navigation | None | Presentation | No simulation mutation |
| Recovery acknowledgement | Existing router recovery intent / gate identity | InputRouter/Coordinator | Cannot release explicit pause token |

- [ ] Pause mid-work: game minutes, physiology, Fire, Morale and action duration freeze until all relevant tokens release.
- [ ] Resume over backpack restores UI and current selection, not Gameplay; closing pause during disconnect leaves safety pause intact.
- [ ] A failed pause acknowledgement displays “Could not pause”, not “Paused”.

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
- [x] Tab / Shift-Tab cycle Resume only; arrow keys traverse lists or button stacks.
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

Provisional Standard only; project A1/A3 and QQ-09 remain owner decisions. Proposed menu floor 24 px at 1080p; at 720p use at least 18 px. Plan 100–200% release text reflow, not an MVP settings addition. Do not claim Standard compliance while remapping/resizing/settings remain deferred. The template's generic Standard narration assumption differs from the project tier table: accessible names and announcement strings below are implementation hooks; comprehensive menu narration remains unapproved scope.

| Text / control | Background | Required contrast | Measured |
|---|---|---|---|
| All labels, disabled reasons, status | Paper backing over snow/night/fire | 4.5:1 ordinary text | Not measured |
| Large title / meaningful outlines | Paper/ink panel | 3:1 | Not measured |

No color-only states: focus uses outline, pending/error uses words, wetness uses shape plus label. Do not depend on an audio cue to understand an action. Focus order: Resume only; cycle in both directions, omit disabled command stops only if their reasons are still readable in the selected-row description. Modal Cancel is the initial focus; closing restores invoker or safe first control. Focus never enters the passive world/HUD.

Accessible name includes visible label; selected rows include qualitative condition and action availability. Proposed announcement on arrival: “Paused.”; pending changes announce “Working”, rejection announces localized owner reason once, and focus restoration announces destination name. No periodic numeric reading or interruption by repeated live snapshots. Menu narration and reduced motion remain proposals, not delivered features. Keep at most four conceptual streams (title, content, selection/actions, status), below the 7±2 heuristic; this is not user-research evidence.

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
| A1 | Standard tier is provisional, not committed | Scott; before tier gate | Cannot receive APPROVED accessibility review until confirmed |
| J1 | Player journey map not yet created | Design; before implementation planning | Author from `.claude/docs/templates/player-journey.md`; arrival context here is inferred |
| U1 | Menu fade timings, layout sizes, target sizes and text budgets above | Scott + UI/art; before implementation | Reasonable author defaults, not measured outcomes |
| P1 | Resume-only MVP scaffold | Scott; before implementation | No settings/save/quit lifecycle invented; future menu expansion needs Screens & Menus GDD |
| P2 | Missing-run recovery belongs to host lifecycle | Technical design; before production handoff | Not an implemented restart route; error text must not imply recovery succeeded |


Cross-reference audit: named patterns reused, no new reusable pattern required; linked navigation matches sibling specs. Session-state and session-log writes are intentionally excluded by this task. No TR registry changes: these specs refine existing requirements rather than allocate new architecture TRs.
