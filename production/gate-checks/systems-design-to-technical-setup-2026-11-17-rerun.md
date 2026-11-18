# Gate Check: Systems Design → Technical Setup (re-run)

- **Date:** 2026-11-17
- **Config:** workflow `standard` · review `lean` · qa.level `standard` · team `individual` (resolved via `resolve_config`; `modes.rigor: standard` is the source for all four)
- **Stage written:** none — stage update deferred to the user-facing session; `project.stage` is currently unset
- **Prior run:** `systems-design-to-technical-setup-2026-11-17.md` = FAIL (blocker: morale + input GDDs not yet re-reviewed). Both re-reviewed since → APPROVED. Blocker cleared.
- **Panel note (deviation):** director subagents could not be spawned from this session (no `run_subagent` tool available to the gate runner); the TD-PHASE-GATE and PR-PHASE-GATE protocols from `.claude/docs/director-gates/` were executed in-line instead, with each gate's stated context passed. Re-run the panel with real subagents if a formal panel record is wanted.

## Required Artifacts: 3/3 present

- [x] `design/gdd/systems-index.md` exists with MVP systems enumerated — 33 systems, 18 MVP, all Status: Approved (`artifact-check.sh --phase systems-design`; NO_CHECK item verified manually: 18 `| MVP | Approved |` rows)
- [x] All MVP-tier GDDs exist in `design/gdd/` and individually pass `/design-review` — 18/18 files; all 19 review logs in `design/gdd/reviews/` end at `Verdict: APPROVED` (input-and-action-map and morale-and-mental-state each passed re-review on 2026-11-17); zero `MAJOR REVISION NEEDED`
- [x] Cross-GDD review report — `design/gdd/gdd-cross-review-2026-11-17.md` present (recommended at `standard`; `artifact-check` PRESENT count=1)

## Quality Checks

- [x] MVP GDDs pass design review at the standard tier — `gdd-structure-check.sh`: all 18 PRESENT Overview, Detailed Rules, Formulas, Edge Cases, Dependencies, Acceptance Criteria (the 5 standard sections + conditional Formulas); only optional Player Fantasy / Tuning Knobs absent; no PLACEHOLDER sections reported; spot-reads confirm substantive content (0 placeholder markers)
- [x] `/review-all-gdds` verdict is not FAIL — verdict **CONCERNS**, `Focus: full` (both passes + 5 scenario walkthroughs ran; 0 blocking issues found)
- [!] All cross-GDD consistency issues resolved or explicitly accepted — **9 of 10 warnings resolved in-session** (verified below); `fell_in_water` mid-action forced-cancel remains undefined in `interaction-and-timed-actions.md` Rule 7 → open, needs owner fix-or-accept
- [x] Dependencies mapped and bidirectionally consistent — cross-review verified every runtime contract both directions (penalty sums ≤ 0.90, `warm_radius` = `radius_m`, `is_asleep` owned by Needs, movement-multiplier composition, action-duration cap); soft-dep edges added to the index this run (Camera→Input; Mishaps→Terrain, Thermal; Thermal/Camera/Character/Fire→Map)
- [x] MVP priority tier defined — Priority column in systems-index (18 MVP / 15 VS)
- [x] No stale GDD references flagged — all flagged stale refs fixed (see fix verification); residual cosmetic staleness noted under Concerns

## Cross-review fix verification (each flagged warning re-checked on disk)

| Cross-review warning | Status |
|---|---|
| Critical whitelist double-owned, disagrees | RESOLVED — Body owns `allowed_actions`; Rule 7 table lists crawl, add_fuel, blow_embers, sit_warm, drop, tap-out; Interaction's `critical_allowed` now states it implements Body's whitelist |
| Character C8 omits `cos(pitch)` | RESOLVED — formula now `screen_h × 1.75 × cos(pitch) / (2 × cam_dist × tan(fov/2))`, credits Camera CA3 |
| In-water tagged VS while M4 is MVP | RESOLVED — States row + edge case now "(MVP: thin ice, Mishaps M4)" |
| Stale "stumble/slip from Mishaps" row | RESOLVED — Mishaps row reads fall-through (`fell_in_water`) only; stumbles = Body overlay, slips not rolled in MVP |
| Needs `move_speed_mult` rename | RESOLVED — `needs_move_speed_mult` in all 4 Needs-output spots; 0 bare `move_speed_mult` remain |
| `feather_stick` missing | RESOLVED — Item DB Rule 12 row + `entities.yaml` entry; `registry.sh validate` = 0 issues |
| `gather_grass`/`gather_stones` not adopted | RESOLVED — Interaction Rule 4 catalogue + Map Rule 5 node table updated |
| Thermal zone table missing drift field / scoured ridge | RESOLVED — both zones added with Map's values |
| AF2 lake example wind_eff 3.6 | RESOLVED — lake (3.0) → −12 dB (verified: 20·log10(3.0/3.0)=0 → −12); AC 2 does not cite the lake example, unchanged |
| Index soft-dep gaps | RESOLVED — Depends On column + mirrored prose updated |

| Remaining flagged item | Status |
|---|---|
| `fell_in_water` in Interaction's forced-cancel list (Scenario 3 + revision table) | **OPEN** — Rule 7 cancel list unchanged (covers collapse, Critical entry, target loss, tool break — not immersion) |
| Mishaps define slip/stumble events (optional alternative) | RESOLVED by the alternative — Character's table fix removed them |
| Time GDD over-lists consumers (Info) | OPEN — harmless over-listing, flag for Time's next revision |

## Director Panel Assessment

Panel: 2 of 4 (`workflow: standard`). Creative and Art perspectives not consulted. Raise `modes.rigor` to `full` (or set `modes.workflow: full`) for the complete panel.

| Director | Verdict | Feedback |
|---|---|---|
| Technical Director | CONCERNS | Groundwork is sound enough to architect from: contracts consistent both directions, per-GDD "Implementation notes → become ADRs" seeds present, engine pinned (Godot 4.7.2, verified), risks table sequences rig + terrain spikes first. Concerns: `fell_in_water` forced-cancel still unspecified; `project.yaml` performance budgets cited by the index do not exist yet (set during Technical Setup; enforce=`warn`); cosmetic stale notes (camera.md CA3 line now false; "provisional" cross-ref labels). |
| Producer | READY | Scope realistic for the team: all 18 MVP GDDs approved, VS systems deferred, consistent contracts mean no design re-litigation during architecture; dependency graph orders execution; rig spike is the named schedule risk, correctly sequenced first with documented fallbacks and owner help offered. Sprint plan not expected before Production (not a finding); 0 blocked stories. Note: first sprint plan should cover Technical Setup outputs when epics are created. |

## Blockers

None.

## Concerns (require explicit owner acceptance to advance)

1. **`fell_in_water` forced-cancel rule still undefined** — `interaction-and-timed-actions.md` Rule 7 cancels on collapse, Critical entry, target loss, tool break — not immersion mid-action (cross-review Scenario 3 warning). One-line fix (add `fell_in_water` to the forced-cancel list) or explicit acceptance as a Technical-Setup work item.
2. **Forward design warnings carried from the cross-review** (inherent to the approved design, not doc defects): food is sink-only past ~day 3 by design (must be answered by the VS Food GDD); attention budget already at ~4 active systems (VS additions should displace, not stack); fail→frustration→more-fails floor is thin at Breaking state (playtest check); `ember_window` vs worst-case duration is tight for first-time players (playtest check); simultaneous-death precedence partially specified (death-events-win ordering suffices — fold into an ADR).
3. **Cosmetic staleness** — `camera.md` CA3 note still says "Character Controller's C8 omits the `cos(pitch)` term" (now false); ~29 "not yet written — provisional" status labels remain in GDD cross-reference tables (morale review already flagged); Time GDD's consumer over-listing (Info). Non-blocking doc hygiene.
4. **`project.yaml` has no `performance.*` budgets** though the systems-index risk table cites them — set during Technical Setup (`performance.enforce: warn`, so non-blocking).
5. **Panel width** — 2 of 4 directors at `standard`; creative-director and art-director perspectives not consulted this gate.

## Recommendations

- Apply the one-line `fell_in_water` cancel-rule fix (or record acceptance) before `/create-architecture`.
- Set `performance.target_framerate` / `frame_budget_ms` / `draw_call_limit` / `memory_ceiling_mb` early in Technical Setup (Terrain spike measures against them).
- Sweep stale "provisional" cross-ref labels + the camera.md CA3 note when convenient.
- Next step per workflow: `/create-architecture` (rig spike is the first technical task), then `/create-epics`.

## Verdict: CONCERNS

All required artifacts present, all blocking issues from the prior FAIL run cleared, cross-review verdict is CONCERNS (not FAIL) with 9/10 consistency warnings resolved. Advance only on explicit owner acceptance of the concerns above — primarily the open `fell_in_water` cancel rule (fix or accept).

Chain-of-Verification: 5 questions checked — verdict unchanged (2 tool actions: re-grepped all 19 review-log verdict lines + `fell_in_water` cancel-rule absence; re-scanned for placeholder markers and MANUAL CHECK items — none found).
