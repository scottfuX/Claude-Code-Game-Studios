# UX Spec: Main Menu / Title Shell

> **Status**: Ready for implementation pending Scott review
> **Author**: Scott (direction) + Devin (autonomous drafting)
> **Last Updated**: 2026-11-20
> **Journey Phase(s)**: Inferred from game concept; no journey study
> **Screen / Flow Name**: TitleShell
> **Platform Target**: PC macOS / Windows; keyboard/mouse and gamepad; no touch
> **Accessibility Tier**: Standard (owner committed); no implementation compliance claimed
> **Template**: UX Spec
> **Related GDDs**: [Screens & Menus](../gdd/screens-and-menus.md), [Save/Load](../gdd/save-load.md)
> **Related ADRs**: Accepted ADR-0001/0002; [ADR-0018 Proposed](../../docs/architecture/adr-0018-shell-navigation-end-shot-and-run-checkpoint.md)
> **Related UX Specs**: [Title](main-menu.md), [Terminal](death-screen.md), [Pause](pause-menu.md), [HUD](hud.md)
> **Decision label**: Default (reversible, pending Scott review). Applies individually to every rule, size, copy fixture, table row and acceptance target below. Ready means design contracts supplied, not ADR acceptance or implementation approval.

Use [interaction patterns](interaction-patterns.md) for Buttons, Focus Management, Escape/Cancel, Push/Pop/Replace, Loading/Empty/Error and Reconnect Recovery. Follow paper/ink [art bible](../art/art-bible.md) and [accessibility requirements](../accessibility-requirements.md).

## 1. Purpose & Player Need
I want to choose a fresh or saved run deliberately without losing progress.
Player goal: make one intentional navigation choice. Game goal: acknowledge the owner result before removing focus or world.

## 2. Player Context on Arrival
BOOT validation or deliberate return from a run/results; quiet anticipation.
Retain understandable identity and focus; no fabricated save, cause, rewards or measured-user-research claim.

## 3. Navigation Position
BOOT → TITLE → Locked start/restore → RUN; confirmed Quit → application close.
Title is a root screen, confirmations modal.
No world input may leak through a visible menu.

## 4. Entry & Exit Points
| Trigger | Entry / exit | Focus / owner result |
|---|---|---|
| Host BOOT/title | Title | Continue or New Run |
| Activate action | Request owner, pending state | Remove focus only on accepted transition |
| Cancel confirmation | Return to invoker | No mutation; restore invoking button |
| Owner failure | Remain safe title/paused/terminal error | Restore invoker, readable reason and Retry |
| Teardown | Invalidate run callbacks | Release only own token/source once |

Continue is absent unless SaveStore validated the slot; first focus Continue when present, otherwise New Run. New Run starts first_night; chapter starts three_night. Both select fresh seeds. Starting over a checkpoint asks “Discard saved run?” with Cancel initially focused; cancel preserves slot, accepted replacement only follows successful mount. Quit confirmation asks “Quit game?”; title quit never saves. --three-day / --demo bypass title as specified by the GDD.

## 5. Layout Specification

### 5.1 ASCII Wireframe
```text
          LONEFIRE
        [ Continue ]  (valid only)
        [ New Run ]
        [ Three-Night Chapter ]
        [ Quit ]
       [ localized status ]
```

### 5.2 Layout Zones
Centred 16:9 safe rectangle, inset 5%; title/outcome above 320px reference-width vertical action stack at 1080p. Grow width/height for localized labels. Status below stack; scroll overflow without hiding focus.

### 5.3 Component Inventory
Live localized heading, Buttons, readable status/error label, modal confirmation with Cancel/Confirm and retained invoking identity. Retained world is noninteractive and subdued. Buttons ≥44×44 reference pixels. Reuse HUD fallback font/paper-ink style rather than inventing a theme.

### 5.4 Information Hierarchy
Outcome/title first, available next actions second, pending/error reason third. No numeric survival HUD, rewards list or unrelated Settings.

## 6. States & Variants
| State | Display | Behavior |
|---|---|---|
| Loading | Loading / Starting / Saving | Owner pending; block duplicates, do not claim success |
| Ready | Continue (valid save only), New Run, Three-Night Chapter, Quit. | Routed activation once |
| Empty | No Continue; other actions available | New Run remains usable |
| Confirmation | Quit game? / Discard saved run? | Cancel initial focus; opening accept never confirms |
| Error | Could not start / save / continue | Retain safe owner state, reason and Retry/Cancel |
| Disconnect | Recovery overlay | Keep own pause, deliberate recovery; no auto-resume |

Manual save failure stays paused; autosave failures warn without trapping play. Terminal checkpoint deletion failure blocks results navigation/close behind Retry; OS force-close cannot be guaranteed safe. Missing save is not an error; corrupt save hides Continue and reports quarantine warning.

## 7. Interaction Map
| Input | Action |
|---|---|
| Tab/Shift-Tab; arrows/D-pad/left stick | Cycle visible enabled actions in displayed order, both directions |
| Enter/Space / A-Cross / left click release | ui_accept activates once; release outside cancels |
| Esc / B-Circle | Cancel modal; title root no-op |
| Start/Options | pause_menu routed to coordinator; never duplicate accept/back |
| Confirm/interact during shot | Only terminal coordinator may admit eligible skip |
| Right click / wheel | No world cancel/zoom; wheel scrolls overflowing panel only |
Hover never steals pad/keyboard focus; modal cannot leak focus.

## 8. Data Requirements
| Data | Owner / format | Refresh / null behavior |
|---|---|---|
| Start/close/save capability and result | Shell/SaveStore; accepted/reason | Startup/response; disable unavailable action with reason |
| Run/profile/terminal identity and clock | Coordinator detached values | Run-bound response; reject stale, neutral fallback |
| Checkpoint validity | SaveStore validated envelope | BOOT/save/delete/load; hide Continue on invalid/absent |
| Shot elapsed/completion | Coordinator real-time gate | Presentation notice only; UI never decides death |
| Glyphs/context/recovery | InputRouter semantic actions | Device change; action-name fallback |
| Labels/status | CSV localization keys | Locale change; dev missing key, release empty + log |

## 9. Events Fired
| Intent | Receiver / payload | Ownership |
|---|---|---|
| Start / retry | Shell start_run(profile, fresh seed, null) | New subtree; no UI-created world |
| Continue | Shell start_run(validated profile/seed/DTO) | Fresh staged restore, Locked one-second loading fade |
| Save/title | Shell return_to_title(), live run identity | Coordinator quiesces; SaveStore success precedes stop_run |
| Confirm Quit | Shell close intent | Save if live; no save if terminal/title |
| Pause / resume | Coordinator UI source + request_pause/release_pause token | Run-tagged token, once, retain others |
| Eligible skip | Coordinator run/terminal identity | No direct terminal mutation |
Callbacks from stopped runs are ignored. Restoration uses a loading pause gate with pause menu closed, then releases it after one-second fade; other gates still win.

## 10. Transitions & Animations
Menu opacity enter 150ms / exit 100ms defaults, instant if reduced-motion support is approved. Context changes immediately, not after cosmetic fade. Terminal shot lasts eight unpaused seconds unless optional eligible skip; run-owned pause freezes it. Terminal wins over menu transitions; no fade may retain a stale token. Save/restore loading remains until owner completion, never a fabricated fixed-duration load.

## 11. Input Method Completeness Checklist
Specification targets, not executed evidence:
- [ ] Keyboard-only navigation/accept/cancel reaches every action and restores focus after modal/error.
- [ ] Pad-only D-pad/stick/A/B/Start reaches same actions; disconnect requires deliberate recovery.
- [ ] Mouse buttons and scroll have keyboard/pad equivalents; no raw per-control listeners.
- [ ] Held input requires release/repress across every context transition; one event has one meaning.

## 12. Accessibility
Standard tier remains committed. All text ≥20px at target resolutions; wrap/reflow, no shrinking below floor, 40% expansion and planned adjustable text up to 200%. Visible outline and label identify focus, pending/error uses words rather than color/audio alone. Text contrast ≥4.5:1; large text/control boundaries ≥3:1, measured over snow/night/fire before sign-off. No required time-limited input; skip is optional, all next actions wait indefinitely. Accessible names match visible labels; announce arrival/result/rejection once, not repeated snapshots. Remapping, text adjustment and applicable subtitles remain project Standard requirements; full narration/reduced-motion implementation remains unapproved scope.

## 13. Localization Considerations
All headings, ordinal-word survival copy, action labels, status, confirmations and error reasons use CSV keys (existing assets/localization/hud.csv pipeline or dedicated registered CSV). Never bake text into art, concatenate English ordinals or show raw filesystem errors. English fixture labels ≤32 characters, status ≤135; budgets test expansion, not permission to truncate meaning. CJK font fallback; RTL mirrors layout/focus reading order, not glyph artwork. Grow/wrap then scroll; never ellipsize actions/reasons.

## 14. Acceptance Criteria
- [ ] All entry/exit paths above tested with normal/empty/invalid/error owner results and duplicate/stale intents.
- [ ] Continue presence and fresh profiles correct; CLI bypass retained; discard/quit Cancel preserves save.
- [ ] Confirmations never accept invoking press; keyboard/pad/mouse parity, focus visible and trapped.
- [ ] 720p through 4K, 4:3/16:9/16:10/21:9 safe area, 40% expansion, 200% planned text and contrast checked with retained screenshots.
- [ ] No gameplay mutation/direct SceneTree pause; no stale callback or token leakage; terminal precedence preserved.
- [ ] No runtime/visual compliance claimed until implementation and evidence exist.

## 15. Open Questions / Own Calls
| ID | Decision / gap | Disposition |
|---|---|---|
| M2 | Resolved design contract | [Screens GDD](../gdd/screens-and-menus.md), [Save GDD](../gdd/save-load.md), ADR-0018 supply start/quit ports; Ready for implementation pending Scott review/ADR acceptance |
| A1 | Standard tier | Committed; implementation compliance unverified |
| J1 | No player journey map | Arrival inferred; does not claim user research |
| U1 | Layout/copy/timings | Default (reversible, pending Scott review) |
| C1 | Architecture/GDD exceptions | ADR-0018 Proposed: early skip/Locked exception, narrowed Terrain save and pulled-forward scope await Scott; existing Accepted records not silently superseded |

Contract blockers are resolved at design level by linked docs; wider Tap-out/Results, Settings, kit and diary remain out of scope. No code, translations, TR test evidence or runtime behavior changed by this spec.
