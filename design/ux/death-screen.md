# UX Spec: Death / Terminal Shell

> **Status**: In Review — document draft, not implementation approval
> **Author**: Devin (ux-designer), non-interactive authoring requested by owner
> **Last Updated**: 2026-11-19
> **Journey Phase(s)**: Inferred from game brief; no player journey map exists
> **Platform Target**: PC macOS / Windows; keyboard/mouse primary, partial gamepad; no touch
> **Accessibility Tier**: Standard — confirmed and committed by Scott (owner), 2026-11-19 (A1 resolved)
> **Template**: UX Spec
> **Related GDDs**: [Emotional Feedback death edge / AC7](../gdd/emotional-feedback.md), [Input Locked rule](../gdd/input-and-action-map.md), [Time UI Requirements](../gdd/time-and-day-cycle.md), [Systems index](../gdd/systems-index.md)
> **Related ADRs**: Accepted ADR-0002, ADR-0016; [control manifest](../../docs/architecture/control-manifest.md)
> **Related UX Specs**: [HUD](hud.md), [Backpack](inventory.md), [Title](main-menu.md)

All controls use [interaction patterns](interaction-patterns.md): Button, Focus Management, Escape / Cancel, Screen Push / Pop / Replace, Loading State / Empty State / Error State and Reconnect Recovery. Paper-and-ink UI follows [art bible §4/§7](../art/art-bible.md). [Accessibility requirements](../accessibility-requirements.md) govern the committed Standard tier and separately identified proposals; no runtime, contrast, assistive-tech or visual verification is claimed.

## 1. Purpose & Player Need

“I need to understand that this run ended and leave the moment without accidentally starting over.” Preserve the authored death end shot, then provide a future minimal terminal navigation shell. No rewards, penalty arithmetic, ranking, day count or invented diagnosis. Screens & Menus / Tap-out & Run Results GDDs are not authored; shell navigation is a planning default, not new MVP implementation scope. ADR-0007/C4 terminal arbitration owns the outcome; presentation never decides death.

## 2. Player Context on Arrival

The survivor may die during sleep, work or a live backpack visit. The player is disappointed and may still be holding an input. Their need is certainty without blame or an accidental replay. Target quiet closure; no new mishap toast or numeric postmortem. Mishaps' UI requirement remains “None in play”.

## 3. Navigation Position

Owner commits one terminal snapshot → close/disable backpack and hide gameplay HUD → end shot → terminal shell. Future Return to Title replaces run stack after host teardown. No Back to living gameplay. This is death, not radio extraction or a generic “survived” victory.

## 4. Entry & Exit Points

| Trigger | Route | Timing / focus |
|---|---|---|
| C4 terminal commit | Invalidate command facade, request owner terminal context | Immediate; no UI-generated outcome |
| Death end shot begins | `end_rise`, silence, snow-white grade | Emotional Feedback owns 8 real-second fade |
| First 1.0 s | Locked | Only pause_menu routed, all other presses dropped |
| After end presentation | Show terminal title / future Return to Title | Initial focus Return to Title, release/re-press required |
| Return to Title | Future host teardown → [title](main-menu.md) | Only after owner accepts |
| Esc/B at terminal root | No-op | No gameplay restoration |

Pause during the terminal shot is routed to Coordinator; it cannot resume a dead run or bypass terminal precedence. Exact end-shot pause-clock policy is a deferred architecture question, not decided by this UI.

## 5. Layout Specification

```text
         snow-white end frame
           Run ended
        [ Return to Title ]
             [status]
```

| Component | Zone | Pattern |
|---|---|---|
| End frame | Full view, no HUD | Existing Emotional Feedback / Camera output |
| Terminal heading | Centre after presentation | Static localized words |
| Return to Title | Below heading, ≥44 px hit height, 320 px reference width | Secondary Button, future shell only |
| Status | Below action | Loading/error, no cause guessed from numeric body values |

Inset 5% of centred 16:9 rectangle. Title is neutral until Results GDD defines copy/causes. No cause-specific icon/color added without owner data contract.

## 6. States & Variants

| State | Trigger | Behavior |
|---|---|---|
| End shot / loading | Terminal owner accepted | Hide all gameplay HUD; 8 s authored grade; no interactive shell yet |
| Ready | Presentation completes and terminal snapshot valid | “Run ended”; future Return to Title |
| Empty | Terminal snapshot lacks optional cause/results | Same neutral heading; never synthesize cause/day/rewards |
| Invalid/error | No valid end snapshot | “Run status unavailable”; no fabricated death or restart; host recovery required |
| Returning / pending | Host accepts title intent | “Returning”; suppress duplicates |
| Navigation error | Teardown/title load fails | “Could not return to title”; allow retry on same run-bound terminal intent |
| Disconnect | Active pad lost | Router recovery gate; never returns to living gameplay |

Input lock minimum is 1 s; the 8 s shot is not replaced by a one-second instant menu. No auto-restart or auto-navigation timeout. Proposed reduced-motion menu transitions do not waive the authored end shot, which Emotional Feedback explicitly retains.

## 7. Interaction Map

| Input | Action | Response |
|---|---|---|
| Tab/arrows/D-pad after shot | Return to Title only | Persistent outline |
| Enter/Space/A / click | Future title intent | Pending then host navigation |
| B/Esc root | No-op navigation; pause_menu remains owner-routed | No resurrection, teardown or automatic replay |
| Held input from before terminal | Ignore until released/re-pressed | No accidental confirmation |
| Wheel / right-click | No-op | No world interaction |

## 8. Data Requirements

| Data | Owner / format | Update trigger | Null handling |
|---|---|---|---|
| Single terminal identity/outcome | C4 / detached run-bound snapshot | Once after terminal arbitration | Neutral unavailable state; never infer from temperature |
| Shot completion | Emotional Feedback / Camera presentation signal | End presentation completion | Await valid completion; adapter failure routes host error, not death re-evaluation |
| Title navigation availability/result | Host lifecycle / capability and response | Host acknowledgement | Disable unsupported navigation with reason |
| Glyphs | InputRouter / current binding | Device event | Text fallback |

## 9. Events Fired

| Player action | Intent / payload | Receiver | Contract |
|---|---|---|---|
| Return to Title | Proposed terminal-navigation intent / run ID, terminal ID, request ID | Host lifecycle | Idempotent teardown; port not yet allocated |
| Pause key | Existing pause intent / terminal source | Coordinator | No change to terminal outcome |
| Focus / no-op Back | None | Presentation | No mutation |
| End shot completion | Presentation-complete notice / terminal ID | Coordinator | Cosmetic completion, not a gameplay death event |

- [ ] Death behind a live backpack invalidates commands immediately; late Inventory callbacks cannot reopen it.
- [ ] First second drops all non-pause input, death shot fades to snow white over 8 s and every gameplay HUD element is hidden.
- [ ] Missing optional cause produces only neutral words; no numeric day, reward, hidden Resolve or inferred diagnosis appears.

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
- [x] Tab / Shift-Tab cycle Return to Title only; arrow keys traverse lists or button stacks.
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

No color-only states: focus uses outline, pending/error uses words, wetness uses shape plus label. Do not depend on an audio cue to understand an action. Focus order: Return to Title only; cycle in both directions, omit disabled command stops only if their reasons are still readable in the selected-row description. Modal Cancel is the initial focus; closing restores invoker or safe first control. Focus never enters the passive world/HUD.

Accessible name includes visible label; selected rows include qualitative condition and action availability. Proposed announcement on arrival: “Run ended.”; pending changes announce “Working”, rejection announces localized owner reason once, and focus restoration announces destination name. No periodic numeric reading or interruption by repeated live snapshots. Menu narration and reduced motion remain proposals, not delivered features. Keep at most four conceptual streams (title, content, selection/actions, status), below the 7±2 heuristic; this is not user-research evidence.

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
- [ ] After the authored 8 s death presentation completes, first terminal panel frame appears within 200 ms and usable local data within 500 ms on nominated minimum hardware; maintain 60 fps ±5 during navigation (hardware nomination QQ-01 pending).
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
| D1 | Neutral Run ended copy; no numerical results | Scott + Results design; before VS | Avoid inventing cause, penalty or survival scoring |
| D2 | Return to Title shell proposed, not approved host API | Design/architecture; before implementation | GDD alignment for result navigation NOT ASSESSED |
| D3 | Pause timing during end shot needs owner-clock policy | Technical design; before terminal UI handoff | No assumption that pause key resurrects run or skips shot |
| D4 | No dawn/survived screen | Existing sunrise ritual and Time/Emotional Feedback contracts | Dawn is in-world, not terminal; add only with Results/Screens GDD |


Cross-reference audit: named patterns reused, no new reusable pattern required; linked navigation matches sibling specs. Session-state and session-log writes are intentionally excluded by this task. No TR registry changes: these specs refine existing requirements rather than allocate new architecture TRs.
