# ADR-0013: Camera framing arbitration, collision and projection ports

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/reference/registry review only; camera/occlusion/visuals not rendered.

## Decision Makers
Scott (owner), Devin (author/inline godot-specialist reviewer); Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Camera framing must remain breakable and stable for movement while keeping the survivor visible through scenery. Propose one SurvivalCamera rig with priority tokens, early-phase yaw snapshots, bounded physics-query occlusion/clearance and read-only HUD projection ports.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt / Forward+ |
| **Domain** | Rendering / Physics / Input |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH post-cutoff rendering/physics |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/rendering.md`, `modules/physics.md`, `modules/input.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None required; Camera3D projection, PhysicsDirectSpaceState3D shape/ray adapters; verify signatures and collision masks on pin |
| **Verification Required** | Capsule queries/masks, per-instance dither material overrides, viewport projection/stretch, terrain clearance and CA3 screenshots |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0004, ADR-0005, ADR-0007 (all Accepted; acceptance required) |
| **Enables** | ADR-0014, ADR-0015, ADR-0016 |
| **Blocks** | SurvivalCamera implementation; no story files exist |
| **Ordering Note** | Framing callers use abstract tokens; Camera never imports concrete Feedback/Morale. Character reads an early immutable yaw snapshot, not a late camera transform. |

## Context
### Problem Statement
Competing mood/sleep/end shots must not snap, lock gameplay or shrink/occlude the survivor; projection must match the final render camera.
### Constraints
- Registry: sole InputRouter, run-scoped ownership, Character alone moves the survivor, Terrain supplies height, C4 chooses one terminal. No camera control of simulation.
- QQ-04 framing/distance acceptance and QQ-01 budgets remain owner-only; default22m/50°/30°FOV is PROPOSED pending owner acceptance, not a newly settled art choice.
### Requirements
- Backlog coverage (verbatim): All Camera TRs; breakable tokens, stable yaw, occlusion/clearance, end-rise
- Preserve CA1–CA5, all framing table rows/states/edges and AC1–16/performance.

## Decision
SurvivalCamera owns pivot, chosen d_user/yaw, eased turn/zoom, request token registry, occluder fade state and projection snapshot. CA1 perspective Camera3D at pivot+R_y(yaw)×(0,sin(pitch_eff)d_eff,cos(pitch_eff)d_eff), looking at pivot; no orthographic substitution or free mouse-look. Named routed turns45°/0.4s repeat0.4s; zoom3m/step clamp14–40 eased0.25s. Handle turn/zoom input in an early phase, publish a yaw value fixed for each Character physics step; follow final Character ground position afterward. Character never reads a transform being edited halfway through its step. Visual sink does not feed ground pivot.

CA2 lookahead=dir×min(2,speed×0.8), exponential XZ lag0.35s/Y0.8s. Clamp pivot to Map playable bounds, permit survivor off-centre near edge. CA4 token priority highest wins/newest stable sequence tie; losing requests stay registered, release falls back to previous. Blend from CURRENT effective distance/pitch, not defaults. Scale chosen distance, not a global base; pitch clamp25–80°. Unknown IDs warn/ignore; stale/duplicate run token release no-op. Input move/action breaks cinematic tokens, blend-out≤1s; turn/zoom breaks first then applies; noncinematic sleep retains multiplier while user zooms.

Keep standard framing values: ritual1.4/−10°/4in1out/p2/cinematic; lonely1.15/−5°/6in3out/p1; relief0.95/0°/1.5in2out/p1; sleep1.3/−5°/3in1out/p3; end2.5/+15°/8s/p5; extraction4/+20°/10s/p5 reserved VS. Camera ignores its own turn/zoom in End but never locks InputRouter globally or moves Character. C4 final terminal starts end_rise once; it runs on unpaused presentation real seconds after survival freezes, explicit pause still freezes rig/blends. Other menus freeze only when they actually hold a pause token; backpack alone does not.

CA5 query a radius1m capsule camera→survivor chest, exclude survivor/gameplay triggers, at most12 scenery candidates nearest line first with stable-ID ties. Dither each occluder's visual opacity to0.3 over0.25s, restore over0.5s after leaving; no collision removal, no shared material mutation, never fade survivor. Track/restoration ownership through request changes/teardown so a freed run cannot leave trees faded. Terrain ridges use a bounded height/line-of-sight clearance solver, not transparent terrain: raise pivot where needed for visibility and lift camera along fixed pitch line until≥3m above terrain; do not rotate pitch or move survivor. Validate authored map admits a solution; bounded failure logs and uses last valid shot rather than endless ray loops.

CA3 is QA screen_h×1.75×cos(pitch_eff)/(2d_eff tan(fov/2)), not a runtime autozoom override. Default/user max and ritual at max must≥20px at720p; owner framing acceptance remains QQ-04. Projection API uses the FINAL camera transform/viewport snapshot after clearance, with explicit visible/behind-camera flag and viewport-local coordinates. HUD converts through CanvasLayer stretch/safe area; Audio takes orientation, not elevated camera position for hearing. No gameplay targeting or world movement is decided by projection. Settings/save deferred: chosen distance/yaw restorable; token state is run-owned and teardown invalidates it.

### Architecture Diagram
`InputSnapshot → early yaw/zoom → Character yaw snapshot → final Character/Terrain → Camera follow/framing/clearance → render/projection/orientation`; `Feedback/Needs/terminal → token requests`.
### Key Interfaces
- Preserve `request_framing(id,distance_mult,pitch_offset_deg,blend_in_s,blend_out_s,priority,cinematic)` / `release_framing(id)` via owner/run-tagged token adapter.
- `yaw_snapshot()`, `project_world(p) -> ProjectionResult{visible,viewport_point}`, `orientation_snapshot()` are read-only application ports; exact Camera3D calls belong to pinned-engine adapter tests.
### Implementation Guidelines
- Camera must never move survivor/lock gameplay/cut away; cinematic requests must release on input and transition from current shot.
- Occluders must fade visually only and restore on teardown; projection must correspond to final clearance-adjusted camera, not desired pre-collision position.

## Alternatives Considered
### Alternative 1: Per-caller camera Tweens
- **Pros**: Easy local shots. **Cons**: Competing tweens snap/overwrite chosen zoom and leave stale state.
- **Rejection Reason**: One token arbiter is required for priority/breakability.
### Alternative 2: Pull camera close or move survivor around blockers
- **Pros**: Avoids dither shader work. **Cons**: Changes composition/control and may obscure terrain lessons.
- **Rejection Reason**: GDD requires scenery fade, fixed-pitch clearance and no survivor control.

## Consequences
### Positive
- Stable input-relative movement and one final projection surface; shots remain reversible/readable.
### Negative
- Physics/material/clearance adapters and tiny-scale readability require visual verification, not just formulas.

## Risks
- Inline godot-specialist review: Camera3D plus explicit space queries and isolated material parameters fits references. Jolt masks/query signatures and dither/shadow artifacts unverified; avoid assuming4.6 WorldBoundary plane signs. TD-ADR skipped — Lean mode; no independent/runtime approval.
- GDD sync checked Camera/Character/Input/Terrain/Map/Feedback/HUD (7): C8 already includes cosine, historical missing-term complaint is stale. Camera's “ice VS” label is stale; MVP thin ice follows normally. Updated Time Rule8 checked consistent with QQ-08. No rename/GDD edit.
- Autonomous calls: Proceed assumptions/dependencies/range; separate tabs token arbiter, early yaw, bounded query/fade and final projection ports; ADR-only write, registry append, continue P2. QQ-04 choice not accepted on owner's behalf.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [camera.md](../../design/gdd/camera.md) | Full provisional TR-camera-001 … TR-camera-029; rules/CA1–CA5/states/edges/dependencies/AC1–16/performance | Token arbitration, stable yaw, exact framing/follow, bounded fade/clearance, final projection, pause/end and owner readability validation. |

## Performance Implications
- **CPU**: GDD update≤0.05ms/frame; occlusion≤0.1ms/frame/≤12 candidates; profile clearance too, not just hit count.
- **Memory**: Bounded fade candidates plus live requester tokens; release all on run teardown.
- **Load Time**: Validate framing table/FOV/pitch and isolated shader/material adapters.
- **Network**: None.

## Migration Plan
After acceptance implement pure arbiter/CA math fixtures, pin-engine query/material adapter, then one visual scene covering requested framings/occlusion. No prototype/settings/GDD changes now; QA must supply screenshots before visual acceptance.

## Validation Criteria
- AC1–8: default50°/22m/30° gives16.85±0.05m height; turn45°0.4±0.05s/hold1s135°;10zooms clamp40/14; ritual broken by W returns≤1s; priority release fallback no frame jump>0.5m;tree0.3 in0.25s/no survivor fade;clearance2→3m pitch unchanged;pivot bounded.
- AC9–14:terminal end-rise8s ignores Camera turn/zoom;speed1.19 lookahead0.95/3mps cap2;720p figure69/108/38px and ritual-max32±1;ritual22→30.8m/40° after4s;bad FOV/pitch clamp/log;Morale ritual request integrates4s.
- Empty requests→Follow; equal priority newest/release older; stale tokens inert; invalid ID warns;>12 blockers stable cap/restore; freed scenery/teardown leaves no fade; pause mid-blend freezes/resumes; backpack does not invent pause; noncinematic zoom retains factor; terrain no-solution terminates/logs; final projection rejects behind-camera positions and matches stretched viewport.
- AC15–16 unperformed visual/owner evidence: survivor found≤2s, “far, quiet, wide,”10min turning never loses survivor/disorients; QQ-04 framing still pending. Profile specified ceilings and verify masks/dither/ridge clearance on pin. No visual/runtime/performance claim.

## Related
- [Architecture](architecture.md), P1; [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md), [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md), [ADR-0005](adr-0005-survivor-locomotion-humanoid-retargeting-and-animation-ik-layers.md).
- QQ-01/04 hardware/budgets and framing remain owner-only; `/architecture-decision accept ADR-0013` separate, no story unblocked.
