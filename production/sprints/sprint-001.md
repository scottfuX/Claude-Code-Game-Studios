# Sprint 001 — 2026-11-23 to 2026-12-04 (proposed)

## Sprint Goal

Prove three nights of ordered simulation, including needs and interruptible sleep, with deterministic run fixtures while the default first-night play remains unchanged.

The deliverable is a tested simulation, not a content-complete three-day playthrough. No food source or shelter spec is needed to implement this sprint.

## Goal Prerequisites

| Needed to show the goal | Status |
|---|---|
| Run scene and default launch | Exists: [app shell](../../src/run/app_shell.tscn), [run scene](../../src/run/run.tscn), [main scene configuration](../../project.godot). Used for first-night smoke only. |
| Deterministic simulation and first-night fixture | Exists: [RunSimulation](../../src/run/run_simulation.gd) and [integration suite](../../tests/integration/run/run_simulation_test.gd). Chapter target/outcome fixture is built by RUN-001. |
| Day/rate and Body/Needs fixture inputs | Built by CLK-001/002, NEED-001/002/003 and BODY-001 using the existing model and suite roots. No new scene. |
| Engine and CI | Exists: Godot 4.7.2 and [gdUnit4 workflow](../../.github/workflows/tests.yml). |

## Milestone Context

- Current milestone: [Three-Day Survival](../milestones/three-day-survival.md).
- Milestone deadline and remaining sprint count: not committed; re-plan after content specs.
- QA plan: [Sprint 001 QA scenarios and first-night smoke](../qa/qa-plan-sprint-001-2026-11-20.md).
- PR-SPRINT feasibility review skipped (Lean); schedule is a planning estimate, not measured velocity.

## Capacity

One implementer; proposed 10 working days, with 2 days (20%) reserved for reviews, fixes and overlap with the first-night work. Available and allocated: 8 dev days. No prior sprint velocity or separate risk register.

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. days | Dependencies | Acceptance Criteria |
|---|---|---|---:|---|---|
| CLK-001 | [Advance day and phase through three nights](../epics/game-clock/story-001-day-boundaries.md) | Gameplay programmer | 1 | — | One midnight and sunrise event per boundary; correct day/phase through day 4. |
| CLK-002 | [Arbitrate sleep and wait between minutes](../epics/game-clock/story-002-interruptible-rates.md) | Gameplay programmer | 1 | CLK-001 | Skip processes every minute; normal wins before the next one. |
| NEED-001 | [Integrate hydration and submit dehydration once](../epics/needs-model/story-001-hydration-energy.md) | Gameplay programmer | 1 | — | Hydration/energy rates and penalties; grace 359/360; no duplicate candidate. |
| NEED-002 | [Burn stomach calories before body weight](../epics/needs-model/story-002-fullness-weight.md) | Gameplay programmer | 1 | — | Stomach first, weight/cap floor, Starving threshold and food reset. |
| NEED-003 | [Own sleep, exhaustion collapse and natural wake](../epics/needs-model/story-003-sleep-state.md) | Gameplay programmer | 1.25 | CLK-002, NEED-001, NEED-002 | Sleep eligibility, recovery, coalesced wake and collapse floor. |
| BODY-001 | [Wake sleep from Body cold, not Fire Out](../epics/body-thermoregulation/story-001-cold-wake.md) | Gameplay programmer | 1.25 | NEED-003 | Fire Out alone does not wake; qualifying cold interrupts the skip. |
| RUN-001 | [Resolve third-sunrise outcomes and death precedence](../epics/run-coordinator/story-001-chapter-outcomes.md) | Gameplay programmer | 1.5 | BODY-001 | Deterministic third-sunrise result; terminal ties and first-night regression. |

Start with the two clock stories. Then land the two independent Needs rules, reconcile sleep state, wire Body's cold wake, and finish with coordinator outcomes. Validate each group before taking the next dependency.

### Should Have

None allocated. If scope needs to move, re-plan rather than spending the buffer on content. The [backlog](../epics/index.md) leaves daily cold/insulation, player actions, nutrition commits, content wiring and HUD handoff for follow-on work.

### Nice to Have

None.

## Carryover from Previous Sprint

None. First-night work is baseline and regression coverage, not carried sprint work.

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Catch-up loop applies stale sleep rate after Body wake | Medium | High | Batch-boundary tests compare repeated and differently partitioned frames. |
| Needs and terminal rules change first-night feel | Medium | High | Isolate the chapter profile and retain the first-night outcome and action smoke. |
| Both branches edit run composition | Medium | Medium | Coordinate with flicker work before gameplay PRs; avoid renderer or scene changes in this sprint. |
| Measured tick performance not yet verified | Medium | Medium | Track saturation/debt in tests; profile Thermal/Body separately on nominated hardware before closing prior gate concerns. Tests do not certify frame budgets. |

## Dependencies on External Factors

No owner decision on Shelter or Food blocks this sprint. Recheck available developer time at kickoff; dates are a proposal. Do not advance the project stage as part of this work.

## Definition of Done for this Sprint

- [ ] All Must Have stories verified and closed with `/story-done`; new gdUnit4 suites and existing CI pass.
- [ ] Run `/smoke-check sprint` against the default first-night path and record the QA verdict; no open S1/S2 regressions.
- [ ] Reviewed changes merged; document deviations without changing pending Feature decisions.
