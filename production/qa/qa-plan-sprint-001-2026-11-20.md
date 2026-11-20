# QA Plan: Sprint 001 — Three-Day Survival Foundations

**Date**: 2026-11-20

**Scope**: 7 Logic/Integration stories; Godot 4.7.2, gdUnit4, Standard QA.

**Sprint File**: [Sprint 001](../sprints/sprint-001.md). This is a test plan, not evidence of passed tests.

## Test Summary

| Story | Type | Automated file | Manual evidence |
|---|---|---|---|
| CLK-001 | Logic | `tests/unit/clock/chapter_day_boundaries_test.gd` | None |
| CLK-002 | Logic | `tests/unit/clock/interruptible_rates_test.gd` | None |
| NEED-001 | Logic | `tests/unit/needs/hydration_energy_test.gd` | None |
| NEED-002 | Logic | `tests/unit/needs/fullness_weight_test.gd` | None |
| NEED-003 | Logic | `tests/unit/needs/sleep_state_test.gd` | None |
| BODY-001 | Integration | `tests/integration/run/body_cold_wake_test.gd` | First-night smoke |
| RUN-001 | Integration | `tests/integration/run/chapter_outcomes_test.gd` | First-night smoke |

## Automated Tests Required

- **CLK-001:** Start each profile and assert distinct starts. Step across three midnights and sunrises; compare day and phase events to Time T1/T2 and require exactly one event per boundary.
- **CLK-002:** Owe at least 121 ticks in a frame and verify the cap and retained debt without loss/duplication; repeat across midnight and sunrise. Request skip and normal in the same minute and verify next-interval rate/budget. Contrast explicit pause with inventory-only routing.
- **NEED-001:** Validate N3 at 1.4/0.7/2.1 hydration loss per hour (awake idle/asleep/heavy), clamps and N6 hysteresis. Start with a positive-to-zero crossing, then check no candidate at 359, exactly one at 360 and no repeat. Compare accepted reset at 359 against refusal; check Parched + Exhausted composition and energy penalty.
- **NEED-002:** Verify 1,200 → 1,090 kcal after an idle hour, max-not-sum effort, 3,530 kcal empty burn losing 0.458 ± 0.002 kg, 40 kg floor and N5 caps. Compare 1,439/1,440 empty minutes and immediate reset on accepted intake.
- **NEED-003:** Check day/night thresholds including equality; compare warm/full to chilled/empty recovery under the cap. Verify natural wake, an external normal-mode interruption and coalescing with forced wake. Collapse at zero, wake once and check the energy floor.
- **BODY-001:** Compare three fixtures: Fire Out while warm (no wake), subsequent qualifying cold (one wake before the next owed minute) and collapse while already Cold (one wake, floor 5). Track one Thermal/Body/Needs step per minute and no Fire-issued mode request.
- **RUN-001:** Assert no chapter win at the first two sunrises, one win at the third. Exercise separate causes and the simultaneous hypothermia/dehydration/survival/action boundary, then attempt extra updates after termination. Compare seeded replay results across frame partitions, verify the first-night win at day 2 sunrise and verify state reset on a fresh run.

## Manual QA Checklist and Smoke Test Scope

Before QA handoff, run `/smoke-check sprint` and retain the gdUnit4 result and a brief smoke note. Launch the existing main scene with no flags. Use the first-night path to check movement, gathering, ignition and fueling, then observe the dawn result. In a second run, verify cold loss before dawn. The gameplay owner verifies no new clock, action or outcome regression; the first-night profile remains the default.

## Playtest Requirements

No new three-day playtest for this fixture sprint. Run the full [chapter milestone exit checks](../milestones/three-day-survival.md#success-criteria) after content and the HUD are integrated.

## Definition of Done — This Sprint

- [ ] Expected outcomes and boundary assertions above pass in CI on Godot 4.7.2.
- [ ] First-night smoke passes; retain its note and report any failure with a reproduction.
- [ ] QA approves the evidence and each story's reviewed implementation is closed with `/story-done`.
