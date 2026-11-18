# ADR-0005: Survivor locomotion, humanoid retargeting and animation/IK layers

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — document/reference review; existing rig-spike evidence read, no new engine run or playtest.

## Decision Makers
Scott (owner) and Devin (authoring agent, inline godot-specialist review). No acceptance or independent approval claimed.

## Summary
Propose CharacterBody3D locomotion over C1's static collision, a retargetable humanoid rig, AnimationTree layers and SkeletonModifier3D foot IK. SurvivorController owns movement/pose only: ActionRunner owns action completion, Terrain owns compaction, and Body/Needs own activity consequences.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Physics / Animation |
| **Layer** | Core |
| **Knowledge Risk** | HIGH — physics/animation post-May-2025 cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/physics.md`, `modules/animation.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`; `prototypes/rig-spike/README.md` |
| **Post-Cutoff APIs Used** | 4.6+ SkeletonModifier3D/TwoBoneIK architecture; AnimationTree via AnimationMixer.active; skeleton_updated rather than deprecated bone_pose_updated. Exact IK class/properties require pinned-engine verification. |
| **Verification Required** | Jolt step/floor/slide behavior; TwoBoneIK modifier ordering, targets and masks; import/retarget profiles and loop method-track cadence; no engine run performed here |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0003, ADR-0004 (all Proposed) |
| **Enables** | ADR-0007 action pose adapter, backlog P1 camera and P2/P3 feedback/audio |
| **Blocks** | SurvivorController production implementation until acceptance; no story files to unblock |
| **Ordering Note** | Body/Needs/Inventory are consumer snapshot ports, not duplicated owners. Later C4/C5/C6 ratify transactions/integration without making animation the completion authority. |

## Context

### Problem Statement
The survivor must visibly struggle yet respond within one input frame; snow speed, grade, activity and foot contact history must agree without animation deciding survival results.

### Constraints
- Retain registry's sole raw InputRouter, ordered run dispatch and Terrain ownership. Character never draws mishap RNG or writes Body/Needs state.
- Completed prototype proves a 23-bone, 3,222-triangle rig imported with five clips, AnimationTree layering, method-track footfalls and BoneAttachment3D attachment. Its procedural keys are placeholder quality, not production Tier A acceptance or tested TwoBoneIK.
- QQ-02 clip source/license/tool spend and final triangle cap remain owner-only. The current 3,222 mesh is evidence; ≤4,500 is a pending proposed cap, not an approval.

### Requirements
- Backlog coverage / unblocks (verbatim): All Character TRs. Leverage completed rig spike; verify C1 multiplier floor/grade, CharacterBody3D choice, footfall ordering, effort loops and TwoBoneIK. Final clip sourcing/cap remains owner question.
- Preserve Character rules1–14, states, C1–C8 and every acceptance criterion, including Tier A verbs and tiny-camera readability.

## Decision

Use CharacterBody3D in `_physics_process` with explicit velocity, gravity and move_and_slide; propose a downward-floor probe and bounded preflight step-up adapter for the 0.3 m step requirement (not a claimed native automatic stair property). Capsule is radius0.3 m/height1.75 m. No jumping. Collision root remains on static ground; visual rig alone applies smoothed −sink_m (C6, 0.15 s).

Compute travel grade C2 from horizontal intended direction and Terrain normal; near-vertical normals are impassable. Query leading-foot cell for speed and block uphill >35° while projecting motion along contour; collision displacement onto an unwalkable slope slides down safely without damage. Target is base_walk1.4 × max(0.15, terrain×Body×Needs×carry×hurry). In Critical use base_crawl0.35 and omit Body0.40, not both penalties. Apply C3 acceleration/turning; starting movement is never delayed beyond one input frame. Hurry1.3 only Cold-or-better, not Exhausted, not hauling; disallowed hurry changes neither speed nor activity.

Each physics frame supplies one movement activity per C4: idle below0.1 m/s; heavy when moving/hurrying or hauling; otherwise wade when effective depth≥0.25 m, else walk. ActionRunner supplies work separately; Body/Needs select their own maximum at the Clock barrier. Sample load/Body/Needs once for the frame. No physics movement/footfalls during sleep skip, explicit pause or run end. Backpack UI removes gameplay input but simulation/action timers continue per Scott's QQ-08; it is not a pause request.

Retarget legally approved clips to SkeletonProfileHumanoid on one ≤30-bone skeleton and one LOD. Use priority full-body overrides (terminal beats collapse/sleep/crawl), action layer, locomotion, additive overlays; posture precedence Body→Needs→Morale. AnimationTree/AnimationMixer and explicit bone masks implement layers; BoneAttachment3D attaches held tools. SkeletonModifier3D/TwoBoneIK foot placement runs after base pose with contacts against the compacted snow surface, avoiding double sink. Exact modifier/API/mask setup is a spike gate, not assumed from model memory. Input cancels failure beats ≤1.2 s; Critical enters crawl within0.8 s; leaving crawl/collapse gates control behind ≥0.8 s get-up.

Foot contacts originate in animation method tracks at C5 cadence, alternating left/right, but pass a single authoritative adapter per run/sequence/contact. Capture the actual foot's surface and pre-stamp sink; Terrain stamps once, and Audio/Mishaps consume that same sample (ADR-0004). No separate physics timer duplicates a method-track step. Crawling sends drag marks; tiny motion/idle/sleep cannot emit stamps. Cosmetic pose callbacks are never commands to grant a result or consume a tool. Missing Tier B clips fall back to nearest Tier A with warning; missing required Tier A is a content validation failure, not a hidden scope cut.

`play_action(action_id, duration_s)` maps ActionRunner's real-time duration to C7 whole effort loops, with playback clamped0.85–1.15. Intro/outro and actual effort remainder must fit the authoritative deadline: C7's rounded/clamped loop estimate is a pose schedule, not permission to extend the action. Safely trim/blend effort at the deadline when exact fit is impossible; reject malformed zero/negative segments and use a logged fallback pose. Result animation waits for C4 arbitration; move-cancel uses the GDD2× outro. Full-body/terminal override invalidates pending cosmetic callbacks.

### Architecture Diagram
`InputSnapshot + Terrain + Body/Needs/Inventory snapshots → SurvivorController physics → activity + foot contacts`; `ActionRunner → pose token → AnimationTree → SkeletonModifier3D → visual rig`; `Camera ← position/velocity/facing`.

### Key Interfaces
- Preserve `surface_at(p, grade_deg)`, `footfall{position, foot, sink_m}`, movement activity, `play_action(id, duration_s)` and `is_idle`/action callbacks from GDD; typed run/sequence metadata is internal.
- `CharacterSnapshot` exposes position, velocity, facing and animation state, never writable physics state. Action callbacks carry the action token and are presentation acknowledgments only.
- `cancel_action_pose(token)` stops only that pose; the ActionRunner transaction must already be cancelled before a success callback can be considered.

### Implementation Guidelines
- Character must apply the speed floor once after multiplying, and exclude Body's Critical penalty on crawl. Grade must be directional, never absolute slope alone.
- Exactly one accepted contact must stamp one event; layer blends must not double method callbacks. Activity must reflect actual motion, not animation names.
- No root-motion gameplay authority, clip-triggered inventory effects, AnimationTree.playback_active or deprecated bone_pose_updated. Gameplay duration must not be inferred from clip end.

## Alternatives Considered

### Alternative 1: Custom Jolt kinematic body from scratch
- **Description**: Own capsule sweep/contact solver and animation motion.
- **Pros**: Total control over steps and slopes.
- **Cons**: Extra solver/physics maintenance before character feel is known.
- **Rejection Reason**: CharacterBody3D is the proposed baseline; failed step/grade spike would require a revised ADR, not silently switching implementation.

### Alternative 2: Root-motion and globally stretched action clips
- **Description**: Derive motion/results from clips and slow whole playback for cold work.
- **Pros**: Simple contact sync in a small demo.
- **Cons**: Violates authoritative real timing, speed floor and0.85–1.15 effort-speed guard; callbacks can double effects.
- **Rejection Reason**: C1–C7 require model-driven movement/activity and repeated effort, not slow motion.

## Consequences

### Positive
- Completed rig spike informs a bounded production adapter; deterministic movement and contact truth remain outside clip assets.
- Retargeting/layers permit replacing placeholder clips without changing survival math.

### Negative
- Step-up and foot-IK adapters need pinned-engine/visual tests; effort blending and duplicate-track guards add complexity.
- Tier A readability and approved legal clip sourcing remain release obligations.

## Risks
- Inline godot-specialist review: CharacterBody3D, AnimationTree, Skeleton3D and BoneAttachment3D fit references; use AnimationMixer.active and skeleton_updated. 4.6+ IK specifics and Jolt stair/floor behavior remain unverified. Prototype validates only its documented import/layer/track subset. TD-ADR skipped — Lean mode; no independent approval.
- GDD sync checked Character, Terrain, Body, Needs, Inventory, Interaction and Time (7). Character and Needs both publish the distinct `needs_move_speed_mult` name; keep it separate from Body's `move_speed_mult` (no rename needed). The C5 audit corrected this author's initial mismatch note. Known Time Rule8 full-screen pause conflict remains pending QQ-08 correction; no GDD edited.
- C7's rounded loops plus playback clamp need deadline blending for arbitrary durations/intro+outro overflow; do not reinterpret the formula as authority over action timing.
- Autonomous calls: Proceed with problem/three technical choices and Foundation/C1 dependencies; separate design tabs chose CharacterBody3D, model-driven C1–C6 and retargeted AnimationTree/IK with C7 loops; ADR-only write; append registry; continue requested C3. QQ-02 cap/source and QQ-01/04 performance/framing remain undecided.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [character-controller-and-animation.md](../../design/gdd/character-controller-and-animation.md) | Full provisional TR-character-controller-and-animation-001 … TR-character-controller-and-animation-035; rules1–14, C1–C8, all states/edges/dependency ports and AC1–19/performance | Sole physics/pose owner; floor/grade/crawl/hurry; activity/contact ordering; rig/layer/IK/effort adapters; complete content/readability and exception verification without deciding QQ-02. |

## Performance Implications
- **CPU**: GDD controller≤0.1 ms/physics frame; one skeleton/three layers/foot IK≤0.5 ms/frame on owner-nominated min-spec. Existing prototype is not this measurement.
- **Memory**: One rig/LOD, shared immutable clips and bounded cosmetic tokens; no per-step accumulating scene nodes.
- **Load Time**: Validate skeleton mappings, clip segments/events/masks and fallbacks before run activation.
- **Network**: None.

## Migration Plan
No prototype modified or promoted here. After acceptance, build isolated physics/IK/effort adapter spikes, port rig mappings only after content validation, then wire owner snapshots/tokens. Final clip procurement/cap needs QQ-02 decision. Save/Load remains deferred; restore pose/position and set sink immediately, never replay old footfalls.

## Validation Criteria
- AC1–9: fresh walk0.91±0.01; worst stack0.21±0.01; Critical0.35×max(0.15,0.65×needs×carry); forbidden hurry unchanged/heavy haul; legal hurry×1.3/heavy;40° uphill blocked/contour allowed;10 s hard-ground18–19 alternating footfalls; collapse cancels chop; get-up≥0.8 s.
- AC10–15: C2 uphill20°/across0°/diagonal14.4° and n_y0.1 impassable; C3 fresh half pack0.70 s/259°s versus hard empty0.35 s/360°s; activity idle0.05/heavy loaded wade/wade/walk; cadence1.87 versus1.61; sink reaches−0.45 within0.02 after0.45 s; C7 5.6 s→4 loops1× and8.2 s→6 loops0.97±0.01, speed never outside clamp.
- AC16–19: one game-hour fresh travel reports wade and three-pass trail; every Tier A verb ≥4/5 testers at ~30 px, C8 default≥20 px; distinguish three posture silhouettes and owner first-afternoon feel. These visual checks were not performed.
- Empty input/zero-speed/sleep produces no contacts; mixed trail edge uses leading foot for speed and each contacting cell for marks; two blended tracks yield one stamp; stale pose/action callbacks cannot grant effects; missing Tier B warns/falls back, missing Tier A or zero segment duration fails validation; legal move-cancel has2× outro; water restricts shore-directed escape; restore sets sink immediately.
- Measure step0.3 m/capsule/floor stability on pinned Jolt; enforce one-frame motion onset,0.35–0.9 s acceleration, Critical override≤0.8 s and CPU targets with three layers+IK. Backpack routes UI while action timers continue; pause menu freezes; sleep skip never advances physics. QQ-01 hardware and QQ-04 framing stay pending.

## Related
- [Master architecture](architecture.md), C2/layer map; [rig spike](../../prototypes/rig-spike/README.md); [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md); [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md).
- All dependencies remain Proposed; acceptance via `/architecture-decision accept ADR-0005` is separate and authoring unblocks no story. QQ-02 sourcing/license/spend/cap is explicitly owner-only.
