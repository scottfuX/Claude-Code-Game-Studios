# UX Spec: Main Menu / Title Shell

> **Status**: In Review — document draft, not implementation approval
> **Author**: Devin (ux-designer), non-interactive authoring requested by owner
> **Last Updated**: 2026-11-19
> **Journey Phase(s)**: Inferred from game brief; no player journey map exists
> **Platform Target**: PC macOS / Windows; keyboard/mouse primary, partial gamepad; no touch
> **Accessibility Tier**: Standard — confirmed and committed by Scott (owner), 2026-11-19 (A1 resolved)
> **Template**: UX Spec
> **Related GDDs**: [Systems index: Screens & Menus](../gdd/systems-index.md), [Game concept](../gdd/game-concept.md), [Input](../gdd/input-and-action-map.md)
> **Related ADRs**: Accepted ADR-0002, ADR-0016; [control manifest](../../docs/architecture/control-manifest.md)
> **Related UX Specs**: [HUD](hud.md), [Death](death-screen.md)

All controls use [interaction patterns](interaction-patterns.md): Button, Focus Management, Escape / Cancel, Screen Push / Pop / Replace, Loading State / Empty State / Error State and Reconnect Recovery. Paper-and-ink UI follows [art bible §4/§7](../art/art-bible.md). [Accessibility requirements](../accessibility-requirements.md) govern the committed Standard tier and separately identified proposals; no runtime, contrast, assistive-tech or visual verification is claimed.

## 1. Purpose & Player Need

“I want to begin a run deliberately and know what happens next.” Provide a future title-screen planning contract, NOT permission to add an MVP full menu. Screens & Menus is VS and its dedicated GDD is Not Started. No new TR IDs are allocated; ADR-0001 lifecycle and ADR-0002 input constrain future implementation but do not supply a start/quit API.

## 2. Player Context on Arrival

First launch, or a future return after terminal presentation; player is curious or disappointed and has no active survival task. They want a clear start, not an apparent Continue that discards progress. Arrival assumptions come from the brief, not a journey study. Emotional target: quiet anticipation.

## 3. Navigation Position

Application host → title → loading/Locked → new-run [HUD](hud.md). Future terminal → title is conditional on an approved teardown/navigation contract. No Continue, Load, rewards, kit-selection, Settings or diary route is activated here.

## 4. Entry & Exit Points

| Trigger | Route | Focus |
|---|---|---|
| Host shows title (future) | Title | New Run |
| New Run | Host validates then Locked loading → HUD | Remove title focus only after accepted transition |
| Quit button | Confirmation substate → host close | Initial focus Cancel, return to Quit if cancelled |
| Esc / B | No-op on title root; Cancel in confirmation | Never instantly quits |
| Host rejection | Remain title with reason | Restore invoking button |

## 5. Layout Specification

```text
           LONEFIRE
          [ New Run ]
          [ Quit    ]
          [ status  ]
```

| Component | Zone | Pattern |
|---|---|---|
| Wordmark/title | Upper centre of centred 16:9 safe rectangle | Localized live text, not baked logo text |
| New Run, Quit | Centre vertical stack, 320 px wide at 1080p, ≥44 px high | Primary / Destructive Button |
| Status | Below stack | Readable loading/error message |
| Quit confirmation | Modal over title | “Quit game?” Cancel / Quit; no timeout |

All content inset 5%; use the art bible paper/ink, not a new warm full-screen color grade or numeric survival summary.

## 6. States & Variants

| State | Trigger | Behavior |
|---|---|---|
| Loading | Host startup pending | “Loading”; no fabricated save data |
| Ready | Host capable of starting | New Run and Quit reachable |
| Empty | No save/profile | Same ready state; no Continue placeholder |
| Starting / pending | New Run accepted | “Starting”; disable repeat Start, context Locked; pause remains routed by owner |
| Error | Host cannot create run | “Could not start run”; restore New Run focus, allow retry/Quit, no UI-created world |
| Quit confirmation | Quit selected | Focus Cancel; Enter never leaks from invoking press |

## 7. Interaction Map

| Input | Action | Response |
|---|---|---|
| Tab/Shift-Tab, arrows/D-pad | New Run → Quit, loop | Outline + label |
| Enter/Space/A / click New Run | Start intent | Pending; owner validates lifecycle |
| Enter/Space/A / click Quit | Open confirmation | Cancel focused |
| Confirmation navigation | Cancel → Quit | Keyboard/D-pad and mouse equivalent |
| B/Esc in confirmation / Cancel | Dismiss | Return focus Quit |
| Confirm Quit | Host close intent | Disable duplicates until owner result |
| B/Esc at root | No-op | No accidental quit |

## 8. Data Requirements

| Data | Owner / format | Update trigger | Null handling |
|---|---|---|---|
| Start capability / run bootstrap result | Host lifecycle / availability + result | Startup / start response | Disable Start with reason |
| Localized title/actions | Localization / keys | Locale change | Dev key; release empty + log, never substitute invented game state |
| Device glyphs | InputRouter / bindings | Device change | Action names |
| Host close result | Application host / accepted or failure | Quit response | Keep confirmation with error and Cancel |

## 9. Events Fired

Proposed semantic intents only; concrete ports need architecture allocation before implementation.
| Player action | Intent / payload | Receiver | Contract |
|---|---|---|---|
| New Run | New-run request / unique request ID | Host lifecycle | Validate once; no existing run silently discarded |
| Quit button | None | Presentation | Local confirmation only |
| Cancel | None | Presentation | Restore focus |
| Confirm Quit | Close-application request / request ID | Host | Owner performs shutdown; no UI direct tree close |

- [ ] Esc at title root never closes application; confirmation always starts on Cancel.
- [ ] One held confirm across New Run cannot activate a gameplay action after load.
- [ ] Failed bootstrap returns usable New Run/Quit controls and shows reason without spawning a second run.

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
- [x] Tab / Shift-Tab cycle New Run → Quit; confirmation Cancel → Quit; arrow keys traverse lists or button stacks.
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

No color-only states: focus uses outline, pending/error uses words, wetness uses shape plus label. Do not depend on an audio cue to understand an action. Focus order: New Run → Quit; confirmation Cancel → Quit; cycle in both directions, omit disabled command stops only if their reasons are still readable in the selected-row description. Modal Cancel is the initial focus; closing restores invoker or safe first control. Focus never enters the passive world/HUD.

Accessible name includes visible label; selected rows include qualitative condition and action availability. Proposed announcement on arrival: “Lonefire. New Run.”; pending changes announce “Working”, rejection announces localized owner reason once, and focus restoration announces destination name. No periodic numeric reading or interruption by repeated live snapshots. Menu narration and reduced motion remain proposals, not delivered features. Keep at most four conceptual streams (title, content, selection/actions, status), below the 7±2 heuristic; this is not user-research evidence.

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
| M1 | Future title uses New Run and confirmed Quit only | Scott + Screens & Menus design; before VS | Planning default; not additional MVP scope |
| M2 | No Screens & Menus GDD or approved start/quit navigation ports | Design/architecture; before implementation | GDD alignment NOT ASSESSED for these commands; cannot honestly pass review |


Cross-reference audit: named patterns reused, no new reusable pattern required; linked navigation matches sibling specs. Session-state and session-log writes are intentionally excluded by this task. No TR registry changes: these specs refine existing requirements rather than allocate new architecture TRs.
