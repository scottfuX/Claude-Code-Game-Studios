# Architecture Review Report — Lonefire

Date: 2026-11-18
Mode: full
Workflow: standard
Engine: Godot 4.7 / 4.7.2.stable.official.ed1daf0bf, GDScript, Jolt, Forward+
GDDs Reviewed: 21 directory documents: 18 system GDDs, game-concept.md, systems-index.md and gdd-cross-review-2026-11-17.md
ADRs Reviewed: 16; all Status: Proposed

Reviewed-Content-Hash: docs/architecture/adr-0001-run-scene-composition-and-service-lifecycle.md eefc23a5daea19f98e46f7fdec2c8ea332364bc1
Reviewed-Content-Hash: docs/architecture/adr-0002-input-routing-contexts-and-ui-pause-requests.md 8db27db77ab80f0d2db19a92f71548848aff616c
Reviewed-Content-Hash: docs/architecture/adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md 69c89d869efcd4b106c043a31148f417988075be
Reviewed-Content-Hash: docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md a1fff416015ce8131ad669ad355a2a34df99c31a
Reviewed-Content-Hash: docs/architecture/adr-0005-survivor-locomotion-humanoid-retargeting-and-animation-ik-layers.md 6a11fda11e820a3700fa5cb8a0936822f9917789
Reviewed-Content-Hash: docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md 91d923154db06842c9be4ba8f7f5100055bffdaf
Reviewed-Content-Hash: docs/architecture/adr-0007-timed-action-transactions-seeded-mishaps-and-simultaneous-death-precedence.md 315a5e944dbe7bae52f4fa37242c9a6597d53b92
Reviewed-Content-Hash: docs/architecture/adr-0008-body-needs-minute-integration-sleep-and-terminal-candidate-ports.md 822a49cfe95046d371c6a87ca6c94bdb001e5f9f
Reviewed-Content-Hash: docs/architecture/adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md 81e9652060793bc7b2db6415819da9d5581fa13f
Reviewed-Content-Hash: docs/architecture/adr-0010-gathering-resolver-depletion-and-overflow-transactions.md 29445215bbb2ece813ae2c66855dcf750363b3e2
Reviewed-Content-Hash: docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md 7c289ae407da4940075351217d8c44fc917a46db
Reviewed-Content-Hash: docs/architecture/adr-0012-morale-event-ordering-strain-integration-and-relief-limits.md 9f4201216cadaeaab3780b94386a621156264b92
Reviewed-Content-Hash: docs/architecture/adr-0013-camera-framing-arbitration-collision-and-projection-ports.md 0714bda898a5baca45ef7fa4ce683011de0e3e15
Reviewed-Content-Hash: docs/architecture/adr-0014-read-only-emotional-feedback-layers-and-warm-hue-safe-grade.md fbc9166f485b09cbc7ded616259dbe1e4d867289
Reviewed-Content-Hash: docs/architecture/adr-0015-audio-buses-survivor-listener-and-prioritized-voice-pool.md 33842ffce72a3bafeb9c0b576d32e3c1051784b9
Reviewed-Content-Hash: docs/architecture/adr-0016-non-numeric-hud-and-mvp-inventory-facade-contracts.md 033e0304a5d99686904201b68b4836cc896e8709
Reviewed-Content-Hash: design/gdd/ambient-and-foley-audio.md b2406529466125e25256b23c929253f8e75c2484
Reviewed-Content-Hash: design/gdd/body-temperature.md 428ae5ba25d8e725a70db93cf30fb8817fd88c79
Reviewed-Content-Hash: design/gdd/camera.md 4d8c35da74b3e9b34b4025ce76d3527504fce04c
Reviewed-Content-Hash: design/gdd/character-controller-and-animation.md ac271791b86d5e230576af3c39ba9cab56491054
Reviewed-Content-Hash: design/gdd/emotional-feedback.md e99c300e51a3f325ea52af39ef4b0237bc91296c
Reviewed-Content-Hash: design/gdd/fire.md 6ed677eabe9f2712941f515045dd7380ae5c3051
Reviewed-Content-Hash: design/gdd/game-concept.md 947bfd5a053eed5c276acf53373853ad5dc5c3ee
Reviewed-Content-Hash: design/gdd/gathering.md 99fa5bfcff190822134be1a6c00fa6eeed928af6
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-17.md 70da3ad97eea4aaeb31d6e86c96dbc057b2db905
Reviewed-Content-Hash: design/gdd/hud.md 7bc65755721bac7ea2cebd9d628e3e7bc5c69513
Reviewed-Content-Hash: design/gdd/input-and-action-map.md e08b34d9b8b590d53a593b6cedd7043fb7549e18
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md bbc3763d8e881ffe49f6127b8698a4b30a6e87c0
Reviewed-Content-Hash: design/gdd/item-database-and-inventory.md 54de45360089eb34fb5e1ed7e241f3ea5d1cf060
Reviewed-Content-Hash: design/gdd/map-and-resource-distribution.md 11ba10e6d7bf4dd1b8dad40b3da1f831dc306d33
Reviewed-Content-Hash: design/gdd/mishaps-and-failure.md aa38bc94c4768f844c46e7cfeb905818e41b8b72
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 786a4a6bb3132f6a51175a7cea90f418f75e5a65
Reviewed-Content-Hash: design/gdd/systems-index.md fdfd5c3856e052bf0757bfc6d9d272cb0e8c640f
Reviewed-Content-Hash: design/gdd/terrain-and-snow-surface.md 180a455f7b9bfec7ff67213c5c2f8b47b71fede3
Reviewed-Content-Hash: design/gdd/thermal-environment.md 02d70468e99048b5708f428102915654ee280fb6
Reviewed-Content-Hash: design/gdd/time-and-day-cycle.md 40972783b42fdcbb8652388091438d2f441b5e57
Reviewed-Content-Hash: docs/architecture/tr-registry.yaml f6993daa35f408e5f9fd2138150154bdbce8ce56
Reviewed-Content-Hash: docs/architecture/architecture.md d6f11e2ce0346c0a943a1a15762b658926d49d81
Reviewed-Content-Hash: docs/engine-reference/godot/VERSION.md ed8aa8d491a41ebee6c98334ec239354e4d2a8c2
Reviewed-Content-Hash: docs/engine-reference/godot/breaking-changes.md c01fad937ab444eeb872a94549355eeb4f4ee216
Reviewed-Content-Hash: docs/engine-reference/godot/current-best-practices.md 180131286f46ff953ba3b3a8341b9ae0f941b20f
Reviewed-Content-Hash: docs/engine-reference/godot/deprecated-apis.md 58e368e085ae8f36373d4568a7e907643b9f8d79
Reviewed-Content-Hash: docs/engine-reference/godot/modules/animation.md ee51f50a46f8c63b771f62fe438947d4d84c59e3
Reviewed-Content-Hash: docs/engine-reference/godot/modules/audio.md c72af247505908a04f84a1dd3e765939efe700bd
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: docs/engine-reference/godot/modules/navigation.md 7ae18ffbd2c3230cb19d610373225bfba187a472
Reviewed-Content-Hash: docs/engine-reference/godot/modules/networking.md 6606880462a2241014f77feb9610c5611e659ec6
Reviewed-Content-Hash: docs/engine-reference/godot/modules/physics.md 3b6ac8947f3f3e8c9ac9e6e0ff6cac06fdb8d805
Reviewed-Content-Hash: docs/engine-reference/godot/modules/rendering.md 37e29e3eb4e0ca5aba4e8f3600800d0d183890f9
Reviewed-Content-Hash: docs/engine-reference/godot/modules/ui.md 30ad166ab8c4e92c15aa37ed3464483b92b7845b
Reviewed-Content-Hash: project.yaml c592ba12b638476923e99dbf4714e8542b7b30e7
Reviewed-Content-Hash: .claude/docs/technical-preferences.md 3310732e386bf1dab0264ba2592974da898eadad
Reviewed-Content-Hash: .claude/skills/architecture-review/SKILL.md 8c1dd9d6f27f396e3b769b939de27d780d7c486a
Reviewed-Content-Hash: .claude/skills/architecture-review/references/1-load.md 9a65759ebdbb2cb1f9744775bfed18cb25e76347
Reviewed-Content-Hash: .claude/skills/architecture-review/references/2-extract-requirements.md d08ea0b0e9ab9760b0d8bfe0cd9115f0bc40f8e2
Reviewed-Content-Hash: .claude/skills/architecture-review/references/3-traceability.md bb7b6b65c5e5e5b8869fa692413aa831615dede7
Reviewed-Content-Hash: .claude/skills/architecture-review/references/4-conflicts.md 0d30f8173b23248a32523a365b606dd1ce9642ab
Reviewed-Content-Hash: .claude/skills/architecture-review/references/5-engine.md 9a0de3ccca214e473e9433450462e0c6e57f9de2
Reviewed-Content-Hash: .claude/skills/architecture-review/references/6-document-coverage.md dcce78482ec2ce60048989b6f9d1f797dd0a9a0e
Reviewed-Content-Hash: .claude/skills/architecture-review/references/7-report.md a43e17378df952791974dab5f10d7a98c16156fe
Reviewed-Content-Hash: .claude/skills/architecture-review/references/8-write.md bf6d8946fc7b9e19eda7f65503a5c8f593a0d2b1
Reviewed-Content-Hash: .claude/skills/architecture-review/references/9-handoff.md ade419da14b200ae3bc8d00ed3f2c04707a6275b
Reviewed-Content-Hash: .claude/skills/architecture-review/references/lens-engine.md d7770f2737d185cf51a338aaf550fa01b773fb07

## Verdict: CONCERNS

The architecture has a proposal for every existing MVP requirement, but **zero
requirements have Accepted coverage**. Eleven baseline rows remain partial because
their contracts or performance obligations need owner reconciliation. No missing
Foundation/Core ADR, dependency cycle, or blocking contradiction between the ADRs'
chosen designs was found. This is not permission to implement unaccepted records.

The four owner issues below **block acceptance of the affected contracts**. They
are not silently resolved by an ADR's proposed default. CONCERNS, rather than FAIL,
follows Phase 7: the proposals agree on their integration approach and explicitly
expose these unresolved design/budget questions; no blocking cross-ADR conflict has
been established. A decision requiring both incompatible behaviors would change
that assessment. Proposed-only coverage alone also caps this review at CONCERNS.

## Scope, freshness and method

- Requested `full` review overrides the standard workflow's reduced reading scope;
  the resolved workflow remains `standard`, not a config change to `full`.
- Denominators: `design/gdd/*.md` = **21**, `docs/architecture/adr-*.md` = **16**.
  Summary sections: **18/21** GDD-directory files and **16/16** ADRs. The three
  non-system files without Summary are not omitted systems. The concept supplies
  platform/pillars/future scope; the index enumerates 33 systems (18 MVP, 15 deferred);
  the historical cross-review is evidence of prior observations, not current truth.
- All 18 system GDDs have Detailed Design, Formulas, Dependencies and Acceptance
  Criteria sections. ADR Status, Decision, Requirements Addressed, Engine
  Compatibility, Dependencies and Performance sections are present in **16/16**.
- Section-oriented review uses those GDD/ADR contracts and the architecture's
  provisional requirements baseline. Preserve its **521 IDs**, including its 18
  aggregate dependencies/acceptance/performance rows. A table/header requirement
  includes the source table, not just its short baseline heading. Counts are at
  this existing granularity, not a claim of 521 independent atomic acceptance tests.
- Registry started empty. All 521 matching provisional IDs become permanent;
  no renames, new intents, deprecations or owner decisions are introduced.
- Freshness: no prior `architecture-review-*.md` report existed. Initial receipt
  check returned `RECEIPT: NONE`; a full review was therefore required.
- No stories under `production/epics/`; Phase 3b is inapplicable. This is the
  architectural traceability index, not evidence of implemented/tested coverage.
- Engine validation is a document/reference audit, not execution. No GUI, compile,
  physics, visual, listening, platform or performance verification was performed.

## Autonomous decision record

Configuration prelude, run before review loading:

```text
automation: autonomous (project.yaml)
workflow: standard (rigor:standard)
```

| Decision point | Options / choice | Reason |
|---|---|---|
| Review scope | Stand on prior / reduced / full → full | No prior receipt; user explicitly requests all phases and all ADRs. |
| Ambiguous owner contracts | Settle a default / preserve open → preserve open | Scott retains these decisions; recommendations below are non-binding. |
| Phase 8 output | A all three / B report only / C no write → A | Write report, complete traceability index and matching registry. |
| Register matching provisional IDs | Register / postpone → register unchanged | Empty registry; stable baseline IDs already cited by ADRs. |
| Phase 9 next action | Test setup / UX setup / stop → stop after handoff | Both setups required, but authoring them exceeds this review's authorized files. |

These choices are logged here instead of modifying the automation helper's usual
`production/session-logs/decision-log.md`, which is outside the user's allowed
Phase 8 output set. No always-ask scope/schema/deletion choice was made. No ADR
acceptance, GDD edit, config edit, purchase or new feature is authorized.

## Traceability summary

| Status | Count | Share |
|---|---:|---:|
| ✅ Covered by Accepted ADR | 0 | 0.00% |
| 🟡 Covered (Proposed) | 510 | 97.89% |
| ⚠️ Partial (also Proposed) | 11 | 2.11% |
| ❌ Gap | 0 | 0.00% |
| ❓ Not assessed | 0 | 0.00% |
| Total | 521 | 100.00% |

The [complete matrix](requirements-traceability.md#full-matrix) contains every
requirement, GDD, system, requirement text, ADR coverage and status. The registry
is the stable ID source. Neither proposed coverage nor a registry `active` status
means architectural acceptance or a passing test.

| GDD system | Rows | Primary ADRs | Proposed | Partial | Decision evidence |
|---|---:|---|---:|---:|---|
| Input & Action Map | 28 | 0001, 0002 | 28 | 0 | Sole router, contexts, IN1–3, real-time holds/buffers, remap and disconnect. |
| Time & Day Cycle | 29 | 0001, 0003 | 29 | 0 | T1–5, 120-tick debt, minute order, run RNG, non-pausing backpack. |
| Terrain & Snow Surface | 31 | 0004 | 31 | 0 | Static height collision, cell state, TS1–7, persistent marks, ice and bounds. |
| Map & Resource Distribution | 25 | 0004 | 25 | 0 | Seeded finite scatter, MR1–2, zone precedence, sole yield owner. |
| Character Controller & Animation | 35 | 0005 | 35 | 0 | CharacterBody adapter, multiplier product, footfalls, overrides, retarget/IK. |
| Camera | 29 | 0013 | 29 | 0 | Early yaw, breakable tokens, clearance/fade, final projection, CA1–5. |
| Thermal Environment | 29 | 0006 | 28 | 1 | Exact TH1–5 after coarse candidate lookup, same-minute source barrier. |
| Interaction & Timed Actions | 30 | 0007 | 30 | 0 | IA1–4, preflight/commit, cancellation before completion, terminal arbiter. |
| Mishaps & Failure | 26 | 0003, 0007 | 26 | 0 | One run stream, one roll, M1–4, physical cause, owner consequences. |
| Gathering | 23 | 0010 | 19 | 4 | G1–4, success-only depletion, partial failure, conserved output/overflow. |
| Fire | 31 | 0011 | 29 | 2 | FI1–6, escrow, deadlines, smother, exact heat, no direct wake. |
| Body Temperature | 29 | 0008 | 28 | 1 | B1–4, pre-step wetness/activity, post-stage outputs, wake/death ports. |
| Needs & Weight | 33 | 0008 | 30 | 3 | N1–6, grace endpoints, sleep authority, atomic eating, Critical ambiguity. |
| Morale & Mental State | 38 | 0012 | 38 | 0 | F1–7, ordered events, independent streaks, relief caps, no forced tap-out. |
| Item Database & Inventory | 30 | 0009 | 30 | 0 | Immutable definitions, unique stacks, wetness, use/loss, atomic plans. |
| Emotional Feedback | 27 | 0014 | 27 | 0 | EF1–6, read-only layers, warm hue mask, cause-first beats, shared tokens. |
| Ambient & Foley Audio | 24 | 0015 | 24 | 0 | AF1–5, head listener, inclusive 24-voice pool, bus/mask/cause ordering. |
| HUD | 24 | 0016 | 24 | 0 | H1–5, non-numeric snapshots, safe projection, current list commands. |

### Partial requirements and owner reconciliation

| Finding | Partial rows | Evidence and impact | Options; recommendation only |
|---|---|---|---|
| O1 — Snow in Critical | TR-needs-and-weight-006, 031, 033 | Needs Drinking rule says available anywhere on snow; its Edge Cases expressly allow Hypothermic “or worse.” Body Rules 7/10 and Interaction's catalogue restrict Critical to crawl/fire tending/sit/drop. ADR-0008 Decision explicitly flags this and retains the whitelist; ADR-0007 validates Body permissions. A Critical snow command cannot satisfy both texts. Blocks affected action/Needs acceptance. | Clarify snow allowed below Critical only; or explicitly revise Body/Interaction to admit it. Recommend preserve Critical whitelist, allow snow in Hypothermic, with no invented cooling cost. |
| O2 — Failed bush bonus grass | TR-gathering-001, 002, 010, 023 | Gathering action table adds one bonus grass; G1 halves failed produce and leaves node yield unchanged. ADR-0010 proposes flooring each line (one grass → zero) and explicitly requests confirmation; ADR-0007 preserves partial-yield profiles. Whether the bonus inherits failure rules is not settled. Blocks bush reward acceptance. | Apply floor-half independently to each output; or author a separate bonus-on-failure rule. Recommend zero bonus grass on failure, retain reserve; it follows G1 without inventing a reward. |
| O3 — Heat threshold | TR-fire-008, 031 | Fire Rule 8 pushes heat/radius each minute, but its Performance paragraph says source update only for changes >0.1. Thermal source contract/ADR-0006 requires current exact values before Body. ADR-0011 proposes exact authoritative publication and cosmetic coalescing only, explicitly pending confirmation. | Clarify threshold is render-only; or revise Thermal's exact-sampling contract with explicit error bounds. Recommend render-only threshold to preserve same-minute physiological correctness. |
| O4 — Inclusive Body cost | TR-body-temperature-029, TR-thermal-environment-029 | Body Performance ≤0.02 ms includes one Thermal query; Thermal permits ≤0.05 ms/query at eight sources/four nearby zones. ADR-0008 flags this against ADR-0006; neither is measured. A query reaching its allowed ceiling would exceed the caller budget before arithmetic. | Allocate a tighter inclusive query target; or owner-approved budget revision after profiling. Recommend profile the inclusive path and tighten its query allocation first; do not silently raise either budget. |

There are no no-ADR gap rows and no new missing-ADR request. These are partial
contracts in existing proposals, not absent designs. O1–O4 remain OPEN for Scott.
Normal, empty/refused, invalid-data and duplicate/cancellation behavior has design
coverage in the ADR decisions/validation criteria; **none is claimed as tested**.

## Cross-ADR consistency

Known conflict-prone areas: no `docs/consistency-failures.md` exists. The historical
cross-GDD report names ownership, clocks, aliases and stale references; this run
uses current source rather than inheriting its old findings. In particular QQ-08
and the C8 cosine correction are not reopened.

All 120 ADR pairs were considered for ownership, integration, patterns, state,
budgets and dependency order. No dual authoritative owner or contradictory chosen
dispatch policy was identified. Significant boundaries:

| Boundary / ADRs | Assessment |
|---|---|
| 0001/0002/0003/0016 | Input context and pause independent; backpack UI does not pause or cancel, explicit pause stops both Clock and ActionRunner. QQ-08 decided, not open. |
| 0003/0006/0011/0008 | Thermal inputs → Fire publication → Inventory → Body → Needs → terminal → Morale. O3 is GDD/proposal reconciliation, not two ADRs choosing different publication. |
| 0004/0007/0009/0010/0011 | Map alone owns yield; Inventory alone owns stacks; preflight both outcome branches then synchronous owner commits. No animation callback/RNG retry authority. O2 remains explicit. |
| 0007/0008 | Body owns Critical gate; Coordinator selects one terminal, hypothermia before dehydration, cancellation before completion. Proposals agree; O1 is their conflict with Needs prose. |
| 0006 vs 0008 — Performance compatibility concern | Query ceiling 0.05 vs inclusive Body ceiling 0.02 (O4). A worst-case target allocation is incompatible, but ceilings are not measured execution times: no actual overrun or mandatory 0.05 cost is established. Owner budget/profile review required. |
| 0003/0007/0012 | One authoritative run stream, separate Mishaps fumble guards versus Morale sliding streaks; category order preserved. |
| 0005/0013/0014/0015/0016 | Early immutable yaw avoids camera/movement frame-order cycle; final projection/audio orientation read-only. Shared per-source camera tokens avoid duplicate sleep/end framing; cause audio precedes feedback without stalling simulation. |

O4 is the cross-ADR budget concern found; O1–O3 are cross-document unresolved
contracts already surfaced by mutually aligned proposals. **No blocking cross-ADR
conflict proven.** No reflexion file is created, per Phase 8.

## ADR dependency order

The deterministic helper reported 16 ADRs, 77 edges and this order (not manually
re-sorted):

```text
ORDER: adr-0001, adr-0002, adr-0003, adr-0004, adr-0005, adr-0006, adr-0007, adr-0008, adr-0013, adr-0009, adr-0010, adr-0011, adr-0012, adr-0014, adr-0015, adr-0016
```

### registry.sh validate

```text
registry	entities	design/registry/entities.yaml	53
registry	tr	docs/architecture/tr-registry.yaml	521
registry	architecture	docs/registry/architecture.yaml	35
checked	production/epics	0
duplicate	0
tr_unknown	0
path_missing	0
status	0
layout	0
```

### Artifact integrity check

```text
ARTIFACT CHECK: 521 stable IDs; 521 matching matrix rows; 510 Proposed / 11 Partial / 0 gaps; 16 ADRs still Proposed; 77 unique retained dependency edges.
```

### Receipt generation

`review-receipts.sh hash` was run after the registry update; its stamp output is
retained verbatim under the report header. It also printed the expected optional
input observation:

```text
review-receipts: not stamped, no such file: docs/consistency-failures.md
```

Navigation/networking reference files are stamped by the skill's prescribed glob
for future freshness checks; no in-scope ADR names them, so they were not loaded
as engine review modules. Hashing is not a claim of substantive module review.

No `CYCLE`, `BLOCKED_BY_CYCLE`, `NO_DEPS_SECTION` or `UNFILLED_DEPS` output. Each
edge points to an existing **Proposed** record, so every one of the 15 dependent
ADRs is blocked from safe implementation until its prerequisites are Accepted.
ADR-0001 has no prerequisite; that does not make it Accepted. Full helper output
is preserved below. Range-parser caution: no bogus missing dependency was emitted
in this run; ranges such as `ADR-0001–0006` must not be treated as a missing ADR.

## Engine audit results

Engine Compatibility sections: **16/16**. Engine version agreement: **16/16**
target 4.7.2, consistent with project.yaml's 4.7 series and VERSION.md's patch pin.
Stale engine-version decisions: none found. Deprecated positive-use decisions:
none found; negative mentions of old APIs are not use. Post-cutoff incompatible
claims between ADRs: none found against the local reference set.

| ADRs | Reference cross-check | Remaining verification |
|---|---|---|
| 0001, 0003, 0006–0012 | current-best-practices / breaking-changes: typed value ports, explicit dirty tracking for packed-array element writes, no per-entity Timer/extra clock, run-owned mutable state. Thermal uses pure exact queries rather than delayed overlap truth. | Pause/lifecycle/snapshot isolation, explicit typed-return overrides, ledger bounds and all benchmark paths remain unexecuted. |
| 0002, 0016 | input.md / ui.md: device type rather than ID zero; SDL3, separate mouse versus keyboard/gamepad focus; typed accessibility and image units, existing stretch settings not assumed retroactive. | Native Control routing, no duplicate events, disconnect/rearm and actual macOS/Windows behavior. |
| 0004, 0005, 0013 | physics.md / animation.md: Jolt and CharacterBody motion fit; restored SkeletonModifier-based IK, AnimationMixer.active and skeleton_updated fit current guidance. No HingeJoint damp/soft-body/world-boundary-sign dependence is introduced. | HeightMapShape3D adapter specifics, exact solver class/properties, contact masks/footfall order, retarget/rig layers and bounded camera shape-query signatures are unverified where local references lack detail. |
| 0011, 0013, 0014 | rendering.md: Compositor and CompositorEffect are Resources, not Nodes; glow-before-tonemap respected; light/particle adapters not invented new AreaLight APIs. Warm-safe colour space, per-instance fade and final-camera projection require proof. | Render callback/buffer/RID lifecycle, shaders, light radius versus visible warm core, occlusion and screenshots. |
| 0015 | audio.md: area_mask default changed to zero; explicit intended masks specified. Removed tap_back_pos appears only as a prohibition. Survivor listener and pooled inclusive voice count avoid lens anti-patterns. | Listener/current selection signatures, asset licenses, pool/cause throughput and audible acceptance. |

### Engine Specialist Findings

The inline Godot specialist lens found no additional established engine-pattern
violation. It does **not** certify those unverified adapter signatures or runtime
behavior. No GDD revision flags from **verified engine contradictions**: none
found. O1–O4 are owner/design/budget flags, not fabricated engine limitations;
therefore no systems-index status is changed to Needs Revision.

## Architecture document coverage

- `architecture.md` exists; all **18/18 MVP systems** appear in M1–M18, the
  layer/ownership map, API boundaries and data flow. All **15 deferred systems**
  are explicitly named as deferred, not missing MVP implementations.
- Lifecycle, movement/footfall/ice, action/inventory/depletion, Fire/Thermal,
  Body/Needs/wake/death, Morale/feedback and camera/audio/HUD paths are represented.
  Deferred Save/Load, Weather, Shelter and extraction ports do not activate scope.
- RunCoordinator/application shell and rendering adapters are infrastructure, not
  orphan gameplay systems. No unsupported new gameplay system found.
- **Stale audit/backlog**: Architecture's ADR Audit still says “GAP: no existing
  ADR” on all 18 system rows and Required ADRs describes the old backlog. Sixteen
  proposals now exist; none is Accepted. Use this report/index as the current
  proposal-coverage view, not the stale zero-ADR snapshot. Architecture itself
  remains untouched under the output restriction.
- **Boundary-name drift**: M6 camera API is simplified relative to ADR-0013's full
  framing contract; M7 `upsert/remove` versus ADR-0006 `register/update/unregister`
  needs an explicit adapter/name reconciliation before code. These are pseudocode
  proposals, not proven runtime interface failures. Do not silently pick an API.
- Budgets/hardware are still proposed (QQ-01); no min-spec, 60 fps, draw, memory or
  mesh-cap compliance is certified. Inclusive C5/C3 budget concern is O4 above.

## Owner decision register — recommendations, not decisions

Every item below remains **OPEN** except QQ-08. None is accepted by writing this
report. QQ recommendations retain architecture.md's existing direction, not a new
design commitment.

| Item | Recommended answer and evidence | Effect / timing |
|---|---|---|
| Snow vs Critical | Preserve the Body/Interaction whitelist; snow allowed Hypothermic but not Critical, no new cooling cost (Body Rules 7/10, ADR-0008). | O1; before affected acceptance/implementation. |
| Failed gathering bonus | Floor each output line independently: bonus grass 1 → 0 on failure, reserve unchanged (G1, ADR-0010). | O2; before bush reward acceptance. |
| Fire threshold | Apply >0.1 only to cosmetics, publish exact authoritative heat/radius each minute (Fire Rule 8, TH source contract, ADR-0006/0011). | O3; before heat contract acceptance. |
| Body/Thermal budget | Profile inclusive Body path and reserve a Thermal sub-budget below 0.02 ms before considering an owner-approved increase (Body Performance, ADR-0006/0008). | O4/QQ-01; no unmeasured compliance claim. |
| QQ-01 | Retain 60 fps/16.6 ms/500 draws/2048 MB as proposed profiling targets only; nominate macOS/Windows hardware/resolution and inclusive measurement policy first (architecture owner table; all ADR performance sections). | Blocks final performance acceptance; affects every layer. |
| QQ-02 | Evaluate existing 3,222-triangle/23-bone survivor with legally usable clips and hand-key gaps; authorize no spend or new triangle cap (ADR-0005). | Before final animation/content/cap approval. |
| QQ-03 | Evaluate legally usable existing audio and sparse stems, no purchase/composer commitment (EF5, ADR-0014/0015). | Before shipping content/licensing approval. |
| QQ-04 | Keep 22 m/FOV30/pitch50 and 45° steps pending owner 22 m versus 32 m readability test, not silent reframing (CA3, ADR-0013). | Visual acceptance remains unverified. |
| QQ-05 | Keep approved survival/emotional values; gather day-1/night-1/day-3 and Breaking-recovery evidence before tuning (ADR-0008/0011/0012). | Owner feel acceptance; no softened tests. |
| QQ-06 | Keep first-day/night MVP plus day-3 hunger validation, 90/60 s game-hour rates, 240 m finite map and sink-only food (Time, Map, Needs; architecture owner table). | Scope/pacing review before VS. |
| QQ-07 | Add none of sleeping-bag bonus, snow cooling, hunger heat, arm logs, auto-chop, mandatory ring, giving-up or late relief (ADR-0008/0009/0010/0011/0012). | Explicit design revision required before any activation. |
| QQ-08 | **DECIDED:** backpack does not pause time/actions or cancel work; pause menu pauses all (updated Time Rule 8, ADR-0002/0003/0016). | Implement the decision; do not reopen. |
| QQ-09 | Retain 35% calm body band, minimal non-numeric backpack and 100% MVP scale/hooks, no extra screen/settings scope (H3, ADR-0016). | Owner usability decision before expanding UI. |
| QQ-10 | No MVP additions/spend for keepsakes, silhouette thinning, wildlife, music/rumble or deferred systems; retain dormant future contracts (ADR-0012/0014/0015, architecture deferred map). | Owner review at corresponding later phase. |

## Required ADRs and handoff

New missing ADRs: **none**. Highest-impact records to revisit, rather than create
duplicates: (1) ADR-0008 with 0006/0007 for O1/O4; (2) ADR-0011 with 0006 for O3;
(3) ADR-0010 for O2. Obtain Scott's decisions, reconcile the affected proposals and
GDD contracts, then use the separate `/architecture-decision accept ADR-NNNN`
workflow only when owner-authorized. Do not bulk-accept as review bookkeeping.

### Pre-gate checklist (filesystem existence)

| Required artifact | Result | Next step |
|---|---|---|
| tests/unit/ | ❌ absent | /test-setup |
| tests/integration/ | ❌ absent | /test-setup |
| .github/workflows/tests.yml | ❌ absent | /test-setup |
| design/accessibility-requirements.md | ❌ absent | /ux-design |
| design/ux/interaction-patterns.md | ❌ absent | /ux-design |

Both setup skills are required before gate-check; **gate-check is not offered as
the next action**. This run stops after review delivery, without changing CI or
test/config files. Re-run `/architecture-review` after each new ADR is written to
verify coverage improves; also rerun after owner reconciliation or acceptance.

## Helper evidence

### Initial freshness check

```text
RECEIPT: NONE
```

### adr-dep-graph.sh

```text
ADRS: 16
EDGES:
  adr-0002 -> adr-0001
  adr-0003 -> adr-0001
  adr-0004 -> adr-0001
  adr-0004 -> adr-0003
  adr-0005 -> adr-0001
  adr-0005 -> adr-0002
  adr-0005 -> adr-0003
  adr-0005 -> adr-0004
  adr-0006 -> adr-0001
  adr-0006 -> adr-0003
  adr-0006 -> adr-0004
  adr-0007 -> adr-0001
  adr-0007 -> adr-0002
  adr-0007 -> adr-0003
  adr-0007 -> adr-0004
  adr-0007 -> adr-0005
  adr-0007 -> adr-0006
  adr-0008 -> adr-0001
  adr-0008 -> adr-0003
  adr-0008 -> adr-0005
  adr-0008 -> adr-0006
  adr-0008 -> adr-0007
  adr-0009 -> adr-0001
  adr-0009 -> adr-0003
  adr-0009 -> adr-0006
  adr-0009 -> adr-0007
  adr-0009 -> adr-0008
  adr-0010 -> adr-0001
  adr-0010 -> adr-0004
  adr-0010 -> adr-0007
  adr-0010 -> adr-0009
  adr-0011 -> adr-0001
  adr-0011 -> adr-0003
  adr-0011 -> adr-0004
  adr-0011 -> adr-0006
  adr-0011 -> adr-0007
  adr-0011 -> adr-0009
  adr-0011 -> adr-0010
  adr-0012 -> adr-0001
  adr-0012 -> adr-0003
  adr-0012 -> adr-0007
  adr-0012 -> adr-0008
  adr-0012 -> adr-0009
  adr-0012 -> adr-0011
  adr-0013 -> adr-0001
  adr-0013 -> adr-0002
  adr-0013 -> adr-0004
  adr-0013 -> adr-0005
  adr-0013 -> adr-0007
  adr-0014 -> adr-0001
  adr-0014 -> adr-0002
  adr-0014 -> adr-0005
  adr-0014 -> adr-0007
  adr-0014 -> adr-0008
  adr-0014 -> adr-0011
  adr-0014 -> adr-0012
  adr-0014 -> adr-0013
  adr-0015 -> adr-0001
  adr-0015 -> adr-0002
  adr-0015 -> adr-0003
  adr-0015 -> adr-0004
  adr-0015 -> adr-0005
  adr-0015 -> adr-0006
  adr-0015 -> adr-0007
  adr-0015 -> adr-0011
  adr-0015 -> adr-0013
  adr-0015 -> adr-0014
  adr-0016 -> adr-0001
  adr-0016 -> adr-0002
  adr-0016 -> adr-0003
  adr-0016 -> adr-0007
  adr-0016 -> adr-0008
  adr-0016 -> adr-0009
  adr-0016 -> adr-0011
  adr-0016 -> adr-0013
  adr-0016 -> adr-0014
  adr-0016 -> adr-0015
ORDER: adr-0001, adr-0002, adr-0003, adr-0004, adr-0005, adr-0006, adr-0007, adr-0008, adr-0013, adr-0009, adr-0010, adr-0011, adr-0012, adr-0014, adr-0015, adr-0016
```
