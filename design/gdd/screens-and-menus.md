# Screens & Menus

> **Status**: Designed — pending Scott review
> **Author**: Scott (direction) + Devin (autonomous drafting)
> **Last Updated**: 2026-11-20
> **Last Verified**: 2026-11-20 — document/code survey only; not runtime verified
> **Decision label**: Default (reversible, pending Scott review). This label applies to every rule, table row, formula, copy fixture and acceptance target below; none is ADR acceptance or implementation evidence.
> **Implements Pillar**: Know More Each Run; Hard to Live, Beautiful to Watch

## Summary
Give the player deliberate entry, safe interruption and a legible end to a run. This bounded title/pause/results slice does not introduce kit selection, diary, rewards or scoring.

> **Quick reference** — Layer: Presentation · Priority: Vertical Slice (menu/checkpoint slice pulled forward by owner) · Key deps: Input, Time, terminal arbitration, Save/Load

## Overview
A persistent shell owns navigation and a non-autoload SaveStore. Each start mounts a fresh run; Continue supplies validated owner DTOs rather than reviving old scene nodes. Existing CLI playtest routes remain available.

## Player Fantasy
I can leave deliberately, trust where I return, and understand an ending without a scorecard.

## Detailed Design

### Core Rules
1. **TR-screens-and-menus-001:** Shell states are BOOT → TITLE → RUN(playing/paused) → END_SHOT → RESULTS → TITLE or a new RUN. BOOT validates the checkpoint before advertising Continue. The run subtree survives END_SHOT/RESULTS until navigation.
2. **TR-screens-and-menus-002:** Title order: Continue (only a valid checkpoint), New Run (first-night profile), Three-Night Chapter, Quit. Initial focus is Continue if present, otherwise New Run. No Settings/Load slot browser.
3. **TR-screens-and-menus-003:** Shell `start_run(config)` accepts {profile, seed, restore DTO or null}. Profiles are first_night / three_night. Fresh starts choose a new seed. Validate and initialize per ADR-0001 before enabling time/input; failure returns to TITLE with localized retryable error and no partly mounted run.
4. CLI `--three-day` or `--demo` skips TITLE and mounts directly; three-day takes precedence if both are supplied and demo remains first-night/debug-only. No `--title` flag. A failed direct mount falls back to TITLE with error.
5. **TR-screens-and-menus-004:** Esc pauses through the router/coordinator. Playing pause actions: Resume, Save & Return to Title, Start Three-Night Chapter (or Switch to First Night), Quit. Switching/restarting with a checkpoint requires a discard confirmation, initial focus Cancel; cancellation changes nothing. Accepted fresh start replaces the single checkpoint only after new-run initialization succeeds.
6. Quit always confirms, initial focus Cancel. From a live run, obtain a quiescent checkpoint and save before application close; from TITLE/RESULTS close without creating a checkpoint. Save failure keeps the run paused with Retry/Cancel; no silent loss or implicit unsaved quit.
7. **TR-screens-and-menus-005:** Terminal arbitration wins over pending save/navigation. Hide all gameplay HUD, lock gameplay input, hold the final camera and run an eight-real-second END_SHOT. Run coordinator owns the timer. Esc opens terminal pause (Resume Shot, Quit); its run-owned pause token freezes shot time, never revives simulation. No save/profile switch during terminal pause.
8. First unpaused shot second admits only pause. After it, a fresh routed confirm/interact may skip the remainder; held inputs cannot skip. RESULTS otherwise arrives at eight unpaused seconds. No timed required response. This explicitly proposes a narrow terminal-only Locked input exception to ADR-0002.
9. **TR-screens-and-menus-006:** RESULTS shows neutral outcome and qualitative survival wording; cold/dehydration causes use existing localized cause meaning. Example: “The cold took you”; “You lasted until the second night.” Use localized words, not numeric counters, rewards, ranks or scores. Before a first night use “Your run ended before the first night.” Dawn victory uses “You saw the dawn” / chapter victory line in the same layout.
10. Results buttons: Try Again (same profile, fresh seed) and Return to Title. Title return tears down the run once. A failed retry returns to TITLE with error. Terminal deletes the checkpoint before navigable results; see deletion failures in Save/Load.
11. **TR-screens-and-menus-007:** Standard accessibility, full keyboard/mouse/gamepad equivalence, visible focus, minimum 20px text and CSV localization apply to all screens. Context changes suppress held actions; UI never writes simulation state or directly pauses SceneTree.

### States and Transitions
| From | Intent | Result / refusal |
|---|---|---|
| BOOT | Probe save | TITLE, Continue only after validation; invalid save warning |
| TITLE | Start / Continue | Locked loading → RUN; failure restores invoking focus |
| RUN playing | Esc | RUN paused, own token; backpack retained |
| RUN paused | Save/title or confirmed Quit | Quiesce/save → teardown/title or close; error remains paused |
| RUN | Terminal | Invalidate live navigation, delete save, END_SHOT |
| END_SHOT | Esc / Resume Shot | Freeze / resume shot only; no gameplay |
| END_SHOT | Eligible skip / eight seconds | RESULTS |
| RESULTS | Try Again / Title | Fresh same-profile RUN / teardown → TITLE |

### Interactions with Other Systems
ADR-0007 owns death precedence and single terminal identity; presentation never detects death from temperature. Save/Load owns checkpoint validity; Time advances nights in the same run. Router owns contexts, pause tokens, device recovery and one-event dispatch. No new survival tuning.

## Formulas
Shot elapsed = sum of finite nonnegative real deltas while no router pause gate is held. Skip eligible at elapsed ≥1s; completion at elapsed ≥8s. Survival copy derives from terminal clock phase/day and profile start day, not wall-clock time; daylight after an overnight names the preceding night. Localize ordinal words for the bounded first/second/third-night profiles; unknown values use neutral “Your run ended.”

## Edge Cases
Repeated starts/quits are idempotent pending commands. Old run responses cannot navigate a new run. Disconnect retains safety pause; reconnect alone never resumes shot/gameplay. Empty/invalid terminal snapshot displays “Run status unavailable” and safe title navigation, never invented diagnosis. Missing save hides Continue; disappearing save at activation restores title/error. Fresh-start discard confirmation does not erase the old save until initialization succeeds.

## Dependencies
Accepted ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0008; Proposed [ADR-0018](../../docs/architecture/adr-0018-shell-navigation-end-shot-and-run-checkpoint.md). Wider Screens & Menus depends on Inventory/Kit/Diary/Results; those wider routes remain deferred.

## Tuning Knobs
Shot 8s, earliest skip 1s, restore fade 1s, minimum menu text 20px. All are defaults under the decision label, not settings exposed in this slice.

## Visual/Audio Requirements
Reuse paper/ink art direction and HUD theme/font fallback; no new full-screen warm grade. Hold camera and preserve authored snow-white death fade/silence within the shot, without requiring death treatment on dawn victory. Pause freezes shot presentation. Results appears after completion/skip; no HUD behind it.

## Game Feel
Quiet anticipation at title, reliable interruption, then a restrained ending. No forced automatic replay or reward escalation.

## UI Requirements
Title, pause and results follow the linked UX specs. Confirmations never inherit the opening accept press. Loading, absent-data and error states have readable localized escape/retry paths. Safe content stays inset 5% in centred 16:9; expansion wraps rather than shrinking below 20px.

## Cross-References
[Save/Load](save-load.md); [main menu](../ux/main-menu.md); [death/results](../ux/death-screen.md); [pause](../ux/pause-menu.md); [Input](input-and-action-map.md); [Emotional Feedback](emotional-feedback.md).

## Acceptance Criteria
- [ ] All state edges above tested for normal, empty/invalid and failed owner responses; no duplicate/stale navigation.
- [ ] CLI bypasses title; default launch shows title; correct profile and fresh seed mount.
- [ ] Pause, backpack and disconnect compose without releasing another source's token.
- [ ] Terminal hides HUD, camera holds; pause freezes shot, first-second skip is rejected and fresh later skip succeeds; timeout reaches results.
- [ ] Death/victory copy and same-profile retry work without scores or numeric HUD changes.
- [ ] Every action works keyboard-only, pad-only and mouse-only; focus restored after cancel/error.
- [ ] 720p/1080p/4K, 40% string expansion, minimum 20px and contrast meet Standard requirements; retained evidence required.

## Open Questions
All rules are Default (reversible, pending Scott review). ADR-0018 acceptance remains Scott's decision. This design resolves UX contract gaps, not implementation readiness against Accepted architecture: early skip conflicts with Emotional Feedback's unskippable eight-second reading and Locked-only-pause policy; terrain persistence is narrowed in Save/Load. No existing approved GDD/ADR is silently amended.
