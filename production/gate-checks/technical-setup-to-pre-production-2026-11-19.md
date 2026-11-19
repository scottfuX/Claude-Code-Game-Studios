# Gate Check: Technical Setup → Pre-Production

**Date**: 2026-11-19
**Checked by**: gate-check skill, artifact/quality assessment
**Config**: review Lean; workflow Standard; qa.level Standard; team Individual; automation Autonomous. Testing strictness defaults to blocking for Logic/Integration; performance.enforce is warn. No system overrides.
**Stage written**: none. Acceptance of ADRs is not acceptance of this gate's risks or authorization to advance with required checks unassessed. `project.stage` and `production/stage.txt` remain unchanged.

## Scope and owner decision

Scott explicitly answered **“Accept all 16”** on 2026-11-19. ADR-0001–ADR-0016 now record Accepted status in dependency order, retaining their original Date, Last Verified and decision content. This clears the former Proposed-only architecture prerequisite, not the validation obligations or QQ defaults. No stories exist under `production/epics/`; no story status was changed.

This is the Technical Setup gate, not the later Production gate. A playable vertical slice, production stories/sprints, full implementation coverage and finished runtime/visual benchmarks are not manufactured as prerequisites here. The older architecture review remains a historical full-mode CONCERNS report; its hashes and review-time counts were not restamped as if a new review had run.

## Required Artifacts: 9/9 present

| Required at Standard | Evidence | Result |
|---|---|---|
| Engine chosen | `project.yaml`, `docs/engine-reference/godot/VERSION.md`: Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt | Present |
| Populated config/preferences | `project.yaml` naming/engine; `.claude/docs/technical-preferences.md` fallback budgets 60 fps / 16.6 ms | Present; final allocations/hardware remain QQ-01 |
| Critical Foundation ADRs | ADR-0001–0003 Accepted, scene lifecycle, input/pause, ordered Clock/events/RNG; Save/Load explicitly deferred | Present |
| Engine reference | `docs/engine-reference/godot/` version, deprecations, best practices and module references | Present |
| Initialized test roots | `tests/unit/`, `tests/integration/`, gdUnit4 addon | Present; integration root contains no test cases yet |
| CI test workflow | `.github/workflows/tests.yml` | Present |
| Functional example test | `tests/unit/project_settings_test.gd`: 1 test executed, 0 failures/errors | Present and passing |
| Master architecture | `docs/architecture/architecture.md`: 18-system ownership/layer/API/data-flow design and Accepted ADR inventory | Present |
| Full-mode architecture review | `docs/architecture/architecture-review-2026-11-18.md`: `Mode: full`, historical CONCERNS; dated status update records acceptance | Present; not a fresh runtime audit |

`artifact-check.sh --phase technical-setup`: 7 steps, all PRESENT, NO_CHECK 0. Catalog observations were reduced using the gate's Standard checklist, not treated as a verdict.

### Recommended / conditional artifacts

- Art bible: `design/art/art-bible.md` has substantive sections 1–4 and later sections. No visual-asset stories exist, so its Standard conditional requirement does not trigger; the document is present anyway.
- Traceability index: present, 521 registered rows; **519 Accepted-covered, 2 Partial, 0 gaps, 0 Proposed-covered**. All 57 Input/Time rows have Accepted Foundation coverage. The two Partial rows are `TR-body-temperature-029` and `TR-thermal-environment-029` (O4 profiling).
- Accessibility requirements and interaction-pattern library: present. **Subsequent owner update, 2026-11-19:** Scott confirmed and committed Standard (A1 resolved); A2–A6 and UX fixture/delivery-scope decisions remain open. This annotation does not rerun the historical gate or imply runtime compliance.
- Screen UX specs: subsequently added in merged PR #13 at `design/ux/hud.md`, `inventory.md`, `pause-menu.md`, `main-menu.md` and `death-screen.md`; the pattern library is not a substitute. Recommended at Standard; future title/result lifecycle inputs and runtime validation remain open.
- Regenerated control manifest: Accepted ADRs 0001–0016, version/Last Updated 2026-11-19; TD-MANIFEST skipped — Lean mode. Foundation 47/6/9, Core 87/12/18, Feature 33/6/9, Presentation 45/8/12 (required/forbidden/guardrails). Global: 7 naming conventions, 20 scoped API/pattern prohibitions, 0 approved libraries. No ADR omitted.

## Quality and engine checks

| Check | Result / evidence |
|---|---|
| Core architecture decisions cover input/state/rendering | Pass: Foundation/Core/Presentation ADRs and 18-system architecture inventory |
| ADR sections and engine version | Pass: all 16 have Engine Compatibility and GDD Requirements Addressed; same 4.7.2/Jolt pin; post-cutoff risks and verification obligations recorded |
| Foundation coverage | Pass: no uncovered Foundation rows; prerequisites now Accepted |
| Circular dependencies | Pass: `adr-dep-graph.sh` ADRS 16, acyclic ORDER covers all 16; no CYCLE, NO_DEPS_SECTION or UNFILLED_DEPS findings |
| Registry integrity | Pass: 53 entity entries, 521 TR entries, 35 architecture entries; duplicate/tr_unknown/path_missing/status/layout all 0 |
| GDD structure | Pass at Standard: all 18 system GDDs have Overview, Detailed Rules, Formulas, Edge Cases, Dependencies, Acceptance Criteria; only optional Player Fantasy/Tuning Knobs absent |
| High-risk engine domains addressed | Pass for planning: architecture and ADRs explicitly flag physics/animation/rendering/input/UI/audio risks and pin-validation work |
| Deprecated API positive-use audit | Existing full-mode engine audit found none; negative mentions are prohibitions. Decision sections are unchanged by acceptance. PR #9 already reconciled Camera/Thermal names. This is not proof that unimplemented adapters compile |
| Import / automated suite | Pass: headless Godot import exit 0 with no ERROR/SCRIPT ERROR lines; gdUnit4 runs 1 test, 0 failures, 0 errors, exit 0. The runner's documented remote-debug port-0 diagnostics are expected. No simulation or integration coverage is implied |
| Final performance compliance | Unmeasured, advisory: defaults are targets, not evidence. O4 directs profiling inclusive Body ≤0.02 ms and tightening Thermal's query allocation afterward; no new number approved |
| Accessibility/UX commitment | Concern: Standard accessibility is still a proposed target; A1–A6 and UX combined-state fixtures require owner review, not inferred approval from ADR acceptance |

## Director Panel — required checks NOT ASSESSED

At Lean/Standard, **TD-PHASE-GATE (technical-director)** and **PR-PHASE-GATE (producer)** are required. This session has no Agent/run_subagent/session-dispatch tool exposed, so neither independent director assessment could be run. No inline self-review is represented as an independent director verdict. Creative and Art directors are deliberately outside the Standard panel, not missing required reviews.

Run the two required directors with the Standard gate scope, architecture/ADR/reference paths and current artifact evidence. This omission blocks a stage write even if the concerns below are accepted (gate-check Section 6).

## Blockers / unassessed work

- **Required director panel unavailable:** TD-PHASE-GATE and PR-PHASE-GATE are NOT ASSESSED. No critical artifact failure or automated-test failure was found in the checks that ran. The gate is not a completed phase approval.

## Concerns and recommendations

1. **Accessibility target not committed; screen specs not started.** Review A1–A6 and UX-01/02 with Scott, then `/ux-design` the core HUD/backpack/pause surfaces and `/ux-review` them. Do not treat acceptance of ADR-0016 as approval of extra settings or a changed UI scope.
2. **Two Partial O4 rows; no measured performance evidence.** Nominate hardware/final budgets under QQ-01; profile inclusive Body and exclusive Thermal costs before approving a tightened query allocation. `performance.enforce: warn`; this is not a newly invented hard benchmark gate.
3. **Runtime/visual/platform obligations remain.** Terrain persistence, Jolt/IK, native input/focus/disconnect, camera occlusion, rendering/colour, audio and HUD readability need real adapter fixtures and evidence during Pre-Production. Current tests exercise project identification only; no screenshots or user-facing change was rendered in this documentation task.
4. **Review freshness.** The full 2026-11-18 report is retained with historical receipts, not silently re-certified. Run `/architecture-review full` on the updated sources for a fresh review record. O1–O4 and ADR acceptance are already decided, not reopened by that work.

QQ-01–07, QQ-09 and QQ-10 retain their recommended defaults. QQ-08 remains decided: backpack/inventory does not pause time/actions; explicit pause menu does. HUD remains minimal and non-numeric. O1–O4 are decided and are not unresolved design blockers; O4's profiling is follow-up work.

## Verdict: CONCERNS

Known advisory gaps make CONCERNS outrank NOT ASSESSED under gate-check Section 5. **The required director panel remains NOT ASSESSED within this verdict**, so the phase cannot advance even by accepting only the listed concerns. No stage files were changed, no risks accepted on Scott's behalf, and no missing artifact was authored just to manufacture a PASS.

## Chain-of-Verification

1. **Could Proposed-only Foundation coverage still block this gate? [TOOL ACTION]** Re-read the updated ADR status/metadata and index: all 16 Accepted; 57 Input/Time rows Accepted-covered. Former blocker cleared.
2. **Did the accessibility wording become a commitment by accident? [TOOL ACTION]** Re-read accessibility Tier Target/Own Call A1 and the interaction-pattern introduction: Standard still awaits Scott. Kept as a concern, not marked owner-approved.
3. **Did a passing test imply implementation validation?** No: the suite has one project-settings test and an empty integration root; the report explicitly limits the claim.
4. **Could missing formal directors be hidden by the CONCERNS verdict?** No: both named NOT ASSESSED above; Section 6 stage write is prohibited and was not performed.
5. **Are performance/visual prototypes hard prerequisites from a later gate?** No: at this gate high-risk domains must be addressed/flagged; they are. O4 profiling and warn-only final budgets remain concerns, not fabricated critical failures.

Chain-of-Verification: 5 questions checked — verdict unchanged; 2 file-based tool actions. Next: obtain the required panel, review the listed UX/accessibility concerns, then deliberately re-run/complete the gate before advancing. After approval, validate a vertical slice before committing to production epics.
