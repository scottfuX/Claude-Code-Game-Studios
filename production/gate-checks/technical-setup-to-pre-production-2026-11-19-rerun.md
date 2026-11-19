# Gate Check: Technical Setup → Pre-Production (rerun)

- **Date**: 2026-11-19
- **Checked by**: gate-check skill and independent Technical Director and Producer reviews
- **Baseline**: [`1949a4f`](https://github.com/scottfuX/Claude-Code-Game-Studios/commit/1949a4fa408fc002d6bf56300805d4a6a71ecfd4), after [ADR acceptance](https://github.com/scottfuX/Claude-Code-Game-Studios/pull/11). The [previous run](technical-setup-to-pre-production-2026-11-19.md) is preserved as history.
- **Resolved config**: Lean review, Standard workflow and QA, individual team, strict Logic/Integration defaults, performance `warn`, no system overrides.
- **Stage written at the rerun**: none. See the [subsequent owner decision](#accepted-risks) authorizing Pre-Production.

## Required Artifacts: 9/9 present

| Standard requirement | Evidence |
|---|---|
| Engine chosen | [Project config](../../project.yaml) selects Godot 4.7 / GDScript / Jolt / Forward+; installed pin is 4.7.2. |
| Config and technical preferences populated | Project naming is configured; [legacy preferences](../../.claude/docs/technical-preferences.md#performance-budgets) provide provisional 60 fps / 16.6 ms targets. |
| Critical Foundation ADRs | ADR-0001–0003 are Accepted (run composition/lifecycle, input/pause, ordered clock/events/RNG). ADR-0001 defines the snapshot boundary; Save/Load is Alpha scope. |
| Engine reference docs | [Godot version and risk reference](../../docs/engine-reference/godot/VERSION.md), module references and deprecated API inventory. |
| Initialized test roots | `tests/unit` and `tests/integration` exist; gdUnit4 is installed. No integration cases yet. |
| CI test workflow | [Automated Tests](../../.github/workflows/tests.yml) runs on PRs and main. |
| Functional example test | [Project settings test](../../tests/unit/project_settings_test.gd) ran and passed. |
| Master architecture | [Architecture](../../docs/architecture/architecture.md) maps ownership, data flow and the ADRs for all 18 MVP systems. |
| Full-mode architecture review | [November 18 report](../../docs/architecture/architecture-review-2026-11-18.md) has `Mode: full`. Its original CONCERNS and engine-audit results are historical; the dated acceptance addendum is not a new audit. |

`artifact-check.sh --phase technical-setup` reported seven PRESENT, no NO_CHECK steps. The table applies the gate's Standard reductions rather than treating the catalog output as a verdict.

**Recommended or conditional:** The [art bible](../../design/art/art-bible.md) has substantive sections 1–4; no visual-asset stories trigger its conditional requirement. The [traceability index](../../docs/architecture/requirements-traceability.md) and Accepted-ADR [control manifest](../../docs/architecture/control-manifest.md) exist. The [accessibility requirements](../../design/accessibility-requirements.md) and [interaction patterns](../../design/ux/interaction-patterns.md) are substantive drafts, not owner approval; no dedicated screen UX spec was on the reviewed baseline. Parallel screen-spec work is not counted as delivered.

## Quality and Engine Checks

| Check | Result |
|---|---|
| Rendering, input and state ownership | Covered by the architecture and Accepted ADRs; [sleep/wake GDD mismatch](#blockers) remains a contract cleanup before integration. |
| ADR metadata and dependency graph | All 16 Accepted, with Engine Compatibility, the 4.7.2 pin, knowledge-risk tags and GDD links. All 16 appear in the graph's acyclic order; no missing or unfilled dependency sections. |
| Foundation traceability | All 57 Foundation rows Accepted-covered, zero gaps. Overall: 519 Accepted-covered, two Partial pending O4 profiling and zero gaps. The two Partial rows' stale `Proposed` suffixes do not describe current ADR status. Registry validation found no integrity findings. |
| High-risk engine domains and deprecated APIs | Physics/Jolt, animation/IK, rendering and native input are addressed or flagged for verification. The newest eligible full-mode audit found no positive deprecated-API decisions. This rerun did not reissue that audit or validate unimplemented adapters. |
| Headless import and configured suite | Godot 4.7.2 import succeeded; gdUnit4 ran one case, with zero errors or failures. The configured loopback port-0 debugger messages are expected. This is test-harness evidence, not a launch, UI, or gameplay test. |
| Measured performance and runtime behavior | Not yet assessed on an integrated playable; documented budgets are planning inputs, not measurements. No mandatory benchmark or playable slice is required for this transition at Standard. |

## Director Panel Assessment

The two required roles ran in parallel in separate read-only Devin sessions against the same baseline.

| Director | Verdict | Assessment |
|---|---|---|
| [Technical Director (TD-PHASE-GATE)](https://app.devin.ai/sessions/99d3a286fe0545f2a0bfe5355dd7a096) | **CONCERNS** | Foundation contracts are ready to build against; fix the direct Fire wake-up references before integrating sleep. Profile Body/Thermal and clock hitch recovery, and validate Jolt terrain/trails, foot IK and native input on the first playable. |
| [Producer (PR-PHASE-GATE)](https://app.devin.ai/sessions/4ca7d867cfef47cabb4035bd73d9894d) | **CONCERNS** | The dependency order supports Foundation-first work. The [brief](../../design/game-brief.md#build-order), [systems index](../../design/gdd/systems-index.md#priority-tiers) and [project plan](../../docs/PLAN.md#7-阶段与过关标准) give scope and sequencing, but the thin first-night playable needs one explicit scope and exit criteria so it doesn't inherit the whole 18-system MVP. Verify risk-heavy work early and keep UX/accessibility visible. |

The Producer found zero blocked stories (no tracked stories) and no sprint plan or capacity figure, which are not expected before the Production gate. There is no committed release date to assess. The rig spike proves basic import/layering, not final clips or IK; the separate feel prototype is not integrated first-playable evidence.

Panel: **2 of 4**, as required by Standard. Creative and Art were not consulted. Raise `modes.rigor` to `full` (or explicitly set `modes.workflow: full`) to include both; changing the review mode alone does not widen the panel.

## Blockers

- **Formal phase advancement:** no hard entry blocker or required panel check remains unassessed. CONCERNS does not advance the recorded stage unless Scott explicitly accepts the risks and confirms the stage write.
- **Before sleep integration:** [Time](../../design/gdd/time-and-day-cycle.md) still permits Fire to request `normal` in its dependency/interface table and AC17; [Needs](../../design/gdd/needs-and-weight.md) still names optional `low_fire` wake. These conflict with [Fire Rule 10](../../design/gdd/fire.md#core-rules) and [Accepted ADR-0011](../../docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md#decision). Align the handoff and tests to Fire Out updating Thermal, Body cold requesting wake, and Needs clearing sleep and requesting normal. Fire Out alone must not wake a sleeping survivor. This is not a new design decision or a hard blocker to starting other Pre-Production work.

## Concerns and Recommendations

1. **Accessibility and screen UX — subsequent update, 2026-11-19:** Scott confirmed and committed Standard (A1 resolved). Five screen specs landed in merged PR #13; review against the committed tier and validate combined-state fixtures. A2–A6, delivery scope, future title/result lifecycle inputs and runtime evidence remain open; this annotation does not rerun the historical gate or infer compliance from ADR acceptance.
2. **First-playable scope:** Give “survive the first night” a single written scope and observable exit criteria before it expands into the full MVP or sprint planning. This is a sequencing recommendation, not a request to cut approved systems.
3. **Body/Thermal and performance:** On nominated hardware (QQ-01), profile Body's inclusive ≤0.02 ms budget and Thermal's separate cost before tightening Thermal's allocation. Those are the two Partial traceability rows. Test clock catch-up against the 16.6 ms frame target: 120 ticks at the 0.5 ms subscriber ceiling would consume 60 ms before other frame costs; that is a budget calculation, not a measured breach.
4. **Runtime, visual and platform validation:** Use the integrated first playable for lifecycle and minute-order tests, terrain/trail persistence, Jolt/IK, input/focus/disconnect, camera occlusion, rendering/colour, audio and HUD readability. The rig and feel prototypes do not close these obligations. Refresh the full architecture review on current sources; do not restamp the historical receipts.

## Verdict: CONCERNS

Both required directors returned CONCERNS; neither returned NOT READY or NOT ASSESSED. Required artifacts and the configured test passed their checks. The scope, UX, documentation and validation findings remain; neither the stage nor owner decisions changed.

### Accepted Risks

On **2026-11-19**, Scott chose **“Accept and move on”** for the remaining Technical Setup concerns, authorizing the stage change to **Pre-Production**. The rerun verdict remains **CONCERNS**; this is an acceptance of the remaining risks, not a new assessment or a PASS.

| Rerun finding | Disposition at advancement |
|---|---|
| Fire wake contract before sleep integration | The [Time and Needs documentation now matches ADR-0011](https://github.com/scottfuX/Claude-Code-Game-Studios/pull/14): Body cold triggers wake; Fire does not. Sleep integration and its runtime verification are deferred beyond the first night. |
| First-playable scope | Resolved in the [first playable night milestone](../milestones/first-playable-night.md). The [integrated first-night build](https://github.com/scottfuX/Claude-Code-Game-Studios/pull/15) is available for validation; it is not sign-off on the broader MVP or Vertical Slice. |
| Accessibility and screen UX | Scott separately confirmed **Standard**. The [core screen specs landed](https://github.com/scottfuX/Claude-Code-Game-Studios/pull/13); Scott accepted advancing before UX review and combined-state validation are complete. Re-run UX review against the recorded tier. |
| Body/Thermal and performance | Scott accepted advancing before measurements. Still profile Body and Thermal separately on nominated hardware, close the two Partial traceability rows with evidence, and measure clock catch-up against the frame budget. |
| Runtime, visual and platform validation | Scott accepted advancing before this evidence is complete. Carry forward lifecycle/minute ordering, terrain and trails, Jolt/IK, input/focus/disconnect, camera occlusion, rendering/colour, audio, HUD readability, and a refreshed full architecture review. |

## Chain-of-Verification

1. **Are the Foundation decisions really complete? [TOOL ACTION]** Re-ran ADR status and graph checks and counted Foundation rows in the traceability index. All three Foundation ADRs are Accepted and no Foundation row is uncovered.
2. **Is the Fire wake concern just wording? [TOOL ACTION]** Re-read Time AC17 and the Needs wake interface against Fire Rule 10 and ADR-0011. AC17 would assert the wrong event source, so the reconciliation must precede sleep integration.
3. **Could a missing screen spec or sprint plan force FAIL?** Screen UX is recommended at Standard here; sprint planning belongs to the Production gate. Neither is a missing required artifact.
4. **Did the test or existing prototypes demonstrate first-playable readiness?** No; only a settings test ran. No launch, runtime behavior, profiling or visual sign-off is claimed.
5. **Did both expected roles assess this baseline?** Yes; both reports are linked, and the two omitted perspectives are intentionally outside the Standard panel.

Chain-of-Verification: five questions checked — verdict unchanged.
