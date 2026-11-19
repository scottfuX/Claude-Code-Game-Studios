# Playtest Report: First Playable Night

## Session Info

- **Date:** 2026-11-19; observations approximately 07:23–08:07 UTC.
- **Build:** main b8268dd, production build in [src/](../../../src/), PR #15.
- **Tester:** Devin agent; keyboard through a GUI tool; returning tester following screen prompts, not blind.
- **Platform / input:** Linux VM, OpenGL3; keyboard and mouse.
- **Launch:** `DISPLAY=:0 godot --path . --rendering-driver opengl3`; default pacing, no user args.
- **Duration / method:** three runs, not a measured average session. Run 1 stopped before ignition; learned Run 2 reached dawn; Run 3 separately checked burnout with Z wait. Runs 1–2 used no Z wait. Pause-assisted ignition/note-taking, tool latency, brief diagnostic F3 and code inspection in Run 2 invalidate claims of blind/unassisted success or precise unpaused duration.
- **Evidence:** raw notes at `/home/ubuntu/notes/playtest-notes.md`; pacing digest at `/home/ubuntu/notes/vs-digest.md`. Session-local capture directory: `/home/ubuntu/screencasts/rec-5d406e98-ce4d-444f-a715-fb6009146f3c/`; `default-night-highlights.mp4` (3m35s condensed, not session duration), `rec-5d406e98-ce4d-444f-a715-fb6009146f3c-edited.mp4` (8m08s edited capture). These local artifacts are not committed.

## Test Focus

Test the [first-night milestone](../../milestones/first-playable-night.md): move, gather, light/feed fire, read cold/stamina, and reach dawn; separately observe an unfed fire burn out. Test loneliness, cold and relief against the [brief](../../../design/game-brief.md). No sleep/food scope.

## First Impressions (First 5 minutes)

- **Goal:** understood “Make a fire before dark.”
- **Controls:** dense hint disappeared before the first meaningful action, approximately 24 seconds after launch including setup/tool overhead. Exact human discovery time is unmeasured.
- **Response:** strong cold-blue scene, clear survivor/resource silhouettes and urgency as night darkened. Controls and tiny HUD symbols were not absorbed before help vanished.
- **Blocker:** after clearing, the fire site offered no next step or missing-material explanation. Prior material intuition, not the screen, suggested collecting more sticks.

## Gameplay Flow

### What worked well

- Gather/chop/strip prompts and progress rings worked; backpack supplies increased.
- Learned Run 2 eventually produced “Blow embers — done,” yellow flame and warm light: strong relief after retries.
- Feeding visibly spent sticks (“plenty” → “a few”) and later exhausted logs; light expanded. Away from the fire the band receded; returning close restored warmward trend.
- Backpack left open for 60 seconds showed continuing sky/light changes; pause/resume worked. Dusk/night/dawn and “You saw the dawn” were observed.
- Run 3, unfed and using Z wait, visibly shrank to embers then a dark ring; coldward trend continued. Exact zero heat was not instrumented.

### Pain points

- Smolder offered only a tiny glow and “Blow embers,” without urgency/deadline feedback. Multiple attempts went dark. Tool round trips contributed; timing failures without captured cause remain uncertain, not engine bugs.
- An explicit “Blow embers — failed: cold hands” and a failed chop named causes. Their mechanical consequences were clearer than how to prevent them.
- Stamina drain was not distinguishable on the ordinary HUD. Diagnostic energy changed, but a dedicated visible warning was not established.
- The non-pausing backpack looks like pause (dark overlay, Resume/Restart). Cold safety is easy to misread.
- A log buffer reduced mid-night play to short errands and stationary watching. Large survivor shadows obscured the ring; flame remained visible.

### Confusion points

- Required recipe was undisclosed: four sticks plus two bark or three grass. More sticks restored Lay; insufficient materials had silently removed it.
- Controls cannot be reopened after the initial hint. Resource exhaustion also removes verbs while the trunk remains; “Make fire here” appeared just outside reach of an existing ring.
- Light radius exceeded intuitively safe warmth distance; standing closer made recovery clearer. This is perception feedback, not proof the two radii should match.

### Moments of delight

- First successful flame felt like rescue; warm light became a safe anchor.
- Returning warmward trend and dawn light gave relief. Loneliness as a sustained core emotion was not independently established.

## Bugs Encountered

| ID | Defect / expected behavior | Severity | Reproducibility / evidence |
|---|---|---|---|
| B1 | Cleared fire site silently loses all prompts when materials are insufficient; E gives no refusal. Expected named missing tinder/kindling, not an invisible dead end. | High onboarding impact; recoverable, not a hard softlock | Observed Run 1 after one stick gather/chop/strip/clear; more sticks restored Lay. Code confirms reachable gating: FireController.can_act rejects arrange_tinder without four sticks and valid tinder; RunCoordinator._update_target filters it out, _prompt returns empty for a fire with no verbs, _try_action silently returns for an empty verb index. Evidence: ss_6b8492e4.png → ss_ae4b81dc.png. |

**Classification:** B1 is an implementation omission, not merely a design gap: [Fire edge cases and acceptance criterion 2](../../../design/gdd/fire.md#edge-cases) explicitly require refusal naming missing tinder/kindling. [HUD Core Rules 1 and 8](../../../design/gdd/hud.md#core-rules) describe available-action prompts/refusal feedback, but do not override that Fire requirement. Diagnosis inspected [fire_controller.gd](../../../src/features/fire_controller.gd) and [run_coordinator.gd](../../../src/run/run_coordinator.gd). No confirmed crashes, engine ignition defect, input defect or clock stall. Earlier uncaptured blow failures remain unclassified.

## Feature-Specific Feedback

- **Fire:** intended struggle-to-relief payoff landed after assisted retries. [Fire Rules 2 / Edge Cases / Game Feel](../../../design/gdd/fire.md) specify a three-game-minute blow window and readable missing materials. The window follows tuning but lacks readable urgency; changing its length is balance/design work, not a proven timing bug.
- **HUD / stamina:** [HUD H4](../../../design/gdd/hud.md#formulas) and [Needs stages / UI](../../../design/gdd/needs-and-weight.md) intentionally hide energy until Tired (<25) / Exhausted (<10). Run 2 diagnostics were 85.59 then 80.57, above warnings: this does **not** prove a missing warning implementation. It does leave the milestone's readable stamina drain unproven; review warning-only intent rather than assume a continuous numeric gauge.
- **Hint / backpack:** [HUD Rule 1](../../../design/gdd/hud.md#core-rules) permits the ten-game-minute cutoff (~15 real seconds initially). The cutoff is implemented intent, but no persistent/reopenable controls and pause-like pack styling are UX gaps. Preserve time-running backpack behavior.
- **Pacing:** the [brief's tension/relief question](../../../design/game-brief.md) and Fire's active tending intent merit a fresh-player check after the buffer flattens pressure. Do not infer difficulty or tuning from GUI-tool wall-clock delay. Full Needs/Weight scope is deferred; no sleep/food expansion proposed.

## Quantitative Data (if available)

- **Runs / testers:** 3 / 1 returning agent; 0 naive humans. One learned dawn completion; one interrupted attempt; one separate burnout check. No recorded death.
- **Calculated normal slice:** 963 game minutes, 1,007.5 real seconds (~16m48s); skill target 3–5 minutes, not an observed elapsed-session measurement.
- **Smolder:** 3 game-minute ticks, nominal 4.5 s in Dusk/Day/Dawn or 3 s at Night; tick alignment can shorten this. Blow itself takes 1.5 s / 1 s initially and must finish before expiry.
- **Other windows:** Embers nominal 90 game minutes (135 s daytime / 90 s night); hint 10 game minutes (~15 s initially). Values from the digest and [SliceTuning](../../../src/data/slice_tuning.gd).
- **Discovered:** gather, chop, strip, place/clear, lay, strike, blow, feed, pack, pause, dawn. Precise item counts, burn extension and zero post-Out heat unmeasured.

## Overall Assessment

Would play again: not formally asked. Difficulty: unresolved because of prior knowledge and pause/tool assistance. Pacing: stationary middle after fuel buffer; validate independently. Preferred session length: not formally asked. The cold/relief contrast is promising evidence from one agent, not novice validation.

## Top 3 Priorities from this session

1. Fire onboarding: say which materials are missing, and the 3-4.5 s smolder→blow window is unreadable and tight.
2. Stamina isn't readable on the HUD; the controls hint hides after about 15 s with no way to reopen it; the backpack looks like pause.
3. Pacing: a 17-minute night (target 3-5 min of slice play) with a long stationary mid-night once a log buffer is in; survivor shadows hide the fire ring.

Pacing/window numbers are calculated above and in the local digest; timing usability is confounded by tool latency, not established for unaided humans.

## Phase 3: Action Routing

- **Design changes needed:** explain short ignition opportunity; clarify non-pausing backpack and recoverable help; reconcile warning-only stamina with readable milestone feedback. Run `/propagate-design-change [path]` on the affected design document to find downstream impacts before making changes. Affected: `design/gdd/fire.md`, `design/gdd/hud.md`, `design/gdd/needs-and-weight.md`.
- **Balance adjustments:** assess smolder/blow timing and stationary fuel-buffer mid-night against the 3–5-minute slice target, with independent player evidence before tuning. Run `/balance-check [system]` to verify the full balance picture before tuning values. Systems: Fire; Time & Day Cycle; energy-only Needs.
- **Bug reports:** B1 missing-material refusal. Use `/bug-report` to formally track these.
- **Polish items:** reduce ring-obscuring survivor shadows; improve tiny icon/help legibility, depleted-resource feedback and warmth-distance communication. Add to the polish backlog in `production/` when the team reaches that phase.

## Creative Director Review and Next Step

CD-PLAYTEST skipped — Lean mode.

Analyze-mode report COMPLETE; actions above are routing recommendations, not executed fixes or a production approval. Next: the silent fresh-player run specified in the [vertical-slice report](../../../prototypes/first-night-vertical-slice/REPORT.md#if-not-assessed).
