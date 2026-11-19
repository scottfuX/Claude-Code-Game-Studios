# ADR-0004: Authored map, Jolt terrain/snow grid and persistent trail representation

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — checked against engine references and GDD contracts; no terrain spike or measurements performed.

## Decision Makers
Scott (owner) and Devin (authoring agent, also performing inline godot-specialist review). Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Lonefire needs deterministic surface queries, finite seeded resource placement and trails that survive a whole run without an addon dependency. Propose an authored heightmap/Jolt collision adapter, packed authoritative snow cells and persistent footprint records feeding a dirty-region trail renderer, with WorldMap solely owning node yields.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf; GDScript; Jolt; Forward+ desktop |
| **Domain** | Physics / Rendering |
| **Layer** | Core |
| **Knowledge Risk** | HIGH — VERSION.md identifies 4.7 as post-May-2025 cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/physics.md`, `modules/rendering.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | Jolt default since 4.6 does not change an existing project's selection; 4.7 packed-array element edits require explicit dirty tracking. No new 4.7 rendering feature required. |
| **Verification Required** | HeightMapShape3D/mesh alignment and scaling on Jolt; collision masks/ray samples; snow displacement/trail upload adapters and exact signatures; memory/query/render/collision spike on nominated hardware |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 and ADR-0003, both Accepted; must be Accepted before implementation |
| **Enables** | ADR-0005, ADR-0006, ADR-0007, ADR-0010, ADR-0011, ADR-0013, ADR-0015 |
| **Blocks** | Map/Terrain implementation until Accepted; no production story files exist |
| **Ordering Note** | Terrain format and Map content are co-designed here, not mutually dependent ADRs. Consumer ports do not depend on future consumer ADR acceptance to define this data boundary. |

## Context

### Problem Statement
The map's visible landform, collision, snow response and resource history must agree. Terrain must not move the survivor or roll ice breaks, and Gathering must not own a duplicate remaining-yield counter.

### Constraints
- Registry constraints retained: run-owned mutable state, detached snapshots, one authoritative RNG stream, no foreign writes or signal-order simulation. Sources remain Proposed, not Accepted.
- No new terrain addon; cost/license approval is Scott's call. A spike is a verification obligation, not measured evidence or approval to reduce scope.
- QQ-01 budgets/hardware remain PROPOSED; no shrinking the 240 m map, changing cell resolution, discarding footprints or buying tools to fit an unmeasured budget.

### Requirements
- Backlog coverage / unblocks (verbatim): All Terrain and Map TRs. Terrain spike measures grid memory, query/mesh/collision costs, lifetime tracks, safe spawn/bounds and node depletion ownership. No new terrain addon approved without owner cost/license review.
- Preserve the 240 × 240 m map, 241 × 241 one-metre height samples and default 0.5 m surface cells; TS1–TS7 and MR1–MR4 remain normative.
- Surface queries must be deterministic; same point/state/grade must return identical values; footprints persist until approved future snowfall fills them.

## Decision

WorldMap owns immutable authored height/zone/bounds data and mutable node identities/remaining yields. TerrainSurface owns the runtime surface grid, compaction/cooldown state, broken ice and footprint records. Construct a built-in heightmap mesh with flat per-face normals and a HeightMapShape3D Jolt collision adapter; static ground height is unchanged at runtime. Snow sink is a visual/body offset, not runtime digging or moving the collision surface. Exact engine adapter compatibility remains subject to the spike.

Use packed structure-of-arrays storage for the 480 × 480 surface cells: type, depth, compaction, ice thickness/broken state and per-cell pass time. Derive effective depth, sink, type/depth/slope multipliers and wading rather than duplicating cached truth. A preliminary layout of one byte type, four float32 fields and one byte broken flag would be 18 bytes/cell (4,147,200 payload bytes); this is an estimate only, excludes runtime overhead/height/marks/renderer buffers, and is not a measured ≤8 MB result. Spike must report each category separately and the complete surface allocation. Float precision and time storage must preserve cooldown semantics over the intended run.

Preserve `surface_at(p)` with a default grade argument for directional TS4 queries; grade along travel, not merely slope magnitude, blocks >35° uphill while contour travel remains possible. Sample normal/height from the same authored triangles as collision. TS1 depth×(1−compaction), TS2 min(depth,sink cap)×type sink, TS3/4 floors and TS5 product stay unchanged. Character alone applies final movement modifiers/floor and sends activity; moving at effective depth ≥0.25 m is wading, standing still is not.

For an accepted foot contact, sample pre-stamp surface/sink once, collect every covered cell within the foot radius (~0.15 m), update eligible compaction with TS7 at most once/cell per 5 real seconds, and append a unique mark storing original position/foot/sink/time. Publish the contact sample to Audio/Mishaps and mark modified render regions explicitly. Duplicate run/sequence contacts and stationary shuffling must not restamp. Subsequent queries see new compaction; repeated read-only queries never mutate it. Crawling uses drag marks through the same boundary. Terrain reports thin ice; only a validated Mishaps command breaks a cell, after which it reports open water. Nearest shore escape comes from Map/Character, not Terrain movement code.

Keep authoritative marks for the whole run; render them through chunked dirty-region world-space trail textures/mesh updates with near-camera snow displacement as the proposed adapter. Distant chunks may change rendering LOD/cull draw work but must never evict gameplay grid/mark history; re-entering restores the same marks. No decal-per-mark node population is authoritative. Precision, geometry, upload strategy and camera readability must be established by the spike before this adapter is treated as production-proven.

WorldMap resolves overlapping zones using lake > drift field > lee > forest > open snow > scoured ridge; cells use their centre's zone. Seeded scatter uses the injected run RNG in fixed ring/kind/node/retry order, MR1 count variation and MR2 at most 30 placement retries. Force the drop-facing 20–30 m deadfall and second near-ring deadfall first; guarantee three authored safe lee camp sites. Stable node IDs distinguish saved remaining yields from rerolled placement. Empty nodes remain visible but non-actionable; no MVP regrowth. Gathering commits an idempotent successful depletion request to WorldMap; failures never deplete. No nodes/sites on ice, >0.6 m drift or >20° slope. Authoring validation must report impossible guaranteed placement rather than silently start a run missing required safety content.

### Architecture Diagram
`WorldMap authored height/zones → TerrainSurface → Character/Camera/Mishaps queries`; `Character contact → Terrain stamp → dirty trail renderer + Audio/Mishaps sample`; `Gathering success → WorldMap.deplete_node → node snapshot`.

### Key Interfaces
- `surface_at(p: Vector3, grade_deg: float = 0.0) -> SurfaceSample`: retains GDD fields type/snow_depth_m/compaction/effective_depth_m/sink_m/slope_deg/normal/terrain_speed_mult/is_wading/ice_thickness_cm/footstep_sound; moving/activity context is supplied by the Character adapter, never guessed from read-only query side effects.
- `stamp_footfall(event: FootfallEvent) -> void`, `break_ice(cell_id) -> void`: validated run-tagged commands; snapshots remain detached values. `zone_at(p)`, `node_snapshot(id)`, `deplete_node(id, attempted_units)` preserve architecture names.
- Map query ports expose playable bounds, drop/facing, safe sites and nearest safe shore edge; Terrain exposes height/normal for engine adapters. These are application contracts, not claims of native Godot methods.

### Implementation Guidelines
- Terrain must never move Character, mutate static height, or roll an ice break. WorldMap alone must mutate remaining yield; each accepted depletion token must commit once.
- Packed-array mutation must explicitly dirty changed cells/chunks. Marks must never be silently expired to meet a memory target.
- Scatter must use stable ordering and finite retries, never its own gameplay RNG. Invalid authoring must fail closed or follow the GDD's named fallback, not fabricate guaranteed success.
- Outside-grid query must return rock/speed1 with warning and heightmap-derived slope; zero-depth snow must have no sink/mark and use rock sound. Approved terrain bad-data defaults remain mandatory.

## Alternatives Considered

### Alternative 1: Terrain GDExtension/addon
- **Description**: Delegate terrain/grid/rendering to an external package.
- **Pros**: May supply editing and LOD infrastructure.
- **Cons**: Unknown cost/license, engine compatibility and data/save ownership constraints.
- **Rejection Reason**: Not authorized; no addon is chosen or purchased. Revisit only with owner approval and spike evidence.

### Alternative 2: Decal-only transient footprints
- **Description**: Spawn capped/fading decals and infer trails visually.
- **Pros**: Simple small demonstration.
- **Cons**: Decal lifetime is not authoritative compaction/history; capped marks disappear and do not restore exactly.
- **Rejection Reason**: Violates whole-run trail persistence and deterministic surface queries.

## Consequences

### Positive
- One grid is authoritative for movement and history; authored content and runtime depletion have distinct owners.
- Rendering can optimize chunks without deleting the survivor's history.

### Negative
- Built-in terrain/snow adapters require a measured spike; persistent marks add growing state and restore cost.
- A failed budget/quality spike requires escalation or a new proposal, not a silent map reduction/addon purchase.

## Risks
- Inline godot-specialist review: Node/Resource adapters, typed queries and physics ray APIs fit the reference; no deprecated API required. HeightMapShape3D scaling, mesh/collision normals and displacement APIs are not proven by the library and require the pinned-engine spike. Verify Jolt explicitly; do not transplant a 4.6 WorldBoundaryShape3D plane without checking its flipped sign. TD-ADR skipped — Lean mode; this is author self-review, not runtime validation.
- Memory/trail quality is unmeasured; profile grid, cooldowns, marks, mesh/collision and GPU uploads separately. QQ-01 cannot be called satisfied without nominated hardware.
- GDD sync: checked Terrain and Map (2 GDDs), no renamed signal/API/type. Map already notes drift/scoured zone additions for Thermal's next revision; preserve authored values, do not edit GDDs here.
- Autonomous calls: assumptions Proceed (problem/alternatives, Foundation dependencies, full Terrain/Map ranges, Proposed); separate design tabs chose built-in heightmap, packed grid, persistent mark-backed chunks, stable bounded scatter and sole Map depletion; write ADR only; append registry candidates; continue requested C2. All are proposals, not owner approval.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [terrain-and-snow-surface.md](../../design/gdd/terrain-and-snow-surface.md) | Full provisional TR-terrain-and-snow-surface-001 … TR-terrain-and-snow-surface-031; all rules, TS1–TS7, edge/dependency contracts and AC/performance | Deterministic authoritative surface, directional grade, capped sink, cooldown compaction, persistent marks, ice ownership, outside-grid/default behavior and required spike evidence. |
| [map-and-resource-distribution.md](../../design/gdd/map-and-resource-distribution.md) | Full provisional TR-map-and-resource-distribution-001 … TR-map-and-resource-distribution-025; all authored content, MR1–MR4, edge/dependency contracts and AC/performance | Fixed map/zone formats, safe seeded scatter/IDs, finite owner-held yields, visible depletion, camp/drop/bounds guarantees and later restore boundary without new save scope. |

## Performance Implications
- **CPU**: GDD obligations: surface_at ≤0.02 ms/query; node queries ≤0.05 ms; scatter ≤200 ms. Spike query, stamp/upload, collision and mesh costs, not merely averages.
- **Memory**: Grid ≤8 MB is an unverified GDD target; whole-run mark growth and renderer/collision allocations must be reported separately. No unmeasured min-spec claim.
- **Load Time**: Validate authoring, build collision and bounded scatter before activation; report full-run trail restore cost in later save work.
- **Network**: None.

## Migration Plan
No production terrain/map is replaced. After acceptance, spike the proposed built-in adapters and storage using approved dimensions, then implement pure query/scatter tests and run wiring; leave prototypes/config/GDDs unchanged. Save/Load stays deferred; retain explicit grid/mark/yield DTO ownership.

## Validation Criteria
- Terrain AC1–19 remain required: fresh cell effective0.35/sink0.315±0.005; 40° uphill blocked but contour allowed; 8 cm ice reports without breaking; standing60 s no stamps; 10-day mark persistence; outside-grid rock/speed1/warn; repeated queries identical.
- TS tests: passes2 compaction0.4375, passes3 trail; drift1 m sink0.45; ice sink0.015; fresh depth speed0.65/trail0.853; grade0/15/30/34/downhill→1/0.75/0.5/0.5/1; fresh15°0.4875, drift15°0.3375; wade threshold0.25 versus0.249; passes1/2/3/6/20→0.25/0.4375/0.578/0.822/0.85; c_max≥1/depth_floor≤0 reject/default.
- Map AC1–16: 100 seeded runs verify bounds/exclusions, 20–30 m facing deadfall plus ≥2 near, 3 safe lee sites, unchanged ice thickness, no regrowth over30 days, visible empty nodes, identical restored positions/yields; mid deadfalls8–12 mean10±0.5, spacing/retry logging, MR3 travel110±1 s fresh100 m, MR4 base fuel counts and lee wind-chill integration.
- Empty optional node collections must query safely; impossible mandatory spawn/sites must log validation failure; saturated scatter must terminate after30 retries; stale/duplicate depletion/contact must not mutate state. Reload must restore cells/marks, not regenerate marks by replay. Later Save/Load integration is an obligation, not new MVP implementation.
- Capture terrain day/dusk ≥4/5 landmark recognition, deep-snow owner feel and day3 visible trails; Map landmark/pattern-learning/day3-distance evidence remains required. Measure grid/query/render/collision and ≤16.6 ms target on owner-nominated min-spec; no visual/performance verification performed here.

## Related
- [Master architecture](architecture.md), C1 and ADR Audit; [ADR-0001](adr-0001-run-scene-composition-and-service-lifecycle.md), [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md).
- QQ-01 hardware/budgets and any addon spend/license remain owner-only; all other QQ recommendations remain PROPOSED. `/architecture-decision accept ADR-0004` is the acceptance route; authoring unblocks no story.
