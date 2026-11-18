# ADR-0006: Thermal spatial queries and source registration

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD and engine-reference review only; no engine/query profiling or visual check.

## Decision Makers
Scott (owner) and Devin (authoring agent, inline godot-specialist review). No acceptance or independent approval claimed.

## Summary
ThermalField must answer deterministic felt-temperature queries without a frame-dependent Area3D overlap cache or a concrete Fire dependency. Propose exact polygon/boundary evaluation behind a coarse index, typed owner-registered source records and an explicit same-minute Fire publication barrier before Body samples.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Core / Physics |
| **Layer** | Core |
| **Knowledge Risk** | HIGH global post-cutoff pin; pure arithmetic minimizes API exposure |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/physics.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None required by model; typed records/arrays and geometry adapters, not 4.7 physics callbacks |
| **Verification Required** | Pinned-engine polygon/distance adapters, deterministic boundary ties, packed-array explicit dirty handling if used, same-minute source barrier and query cost |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003, ADR-0004 (all Proposed; acceptance required before implementation) |
| **Enables** | ADR-0008, ADR-0011, ADR-0014, ADR-0015 (Body/Fire and feedback/audio adapters) |
| **Blocks** | ThermalField implementation pending acceptance; no story files exist |
| **Ordering Note** | Map is a value-data provider; Fire publishes source values after Thermal establishes this minute's air/wind inputs. No Core import of Feature FireController. |

## Context

### Problem Statement
Physics-area entry/exit signals can lag skip-time integration. A changed/extinguished fire must influence Body in the same survival minute, and zone seams must never cause temperature jumps.

### Constraints
- Preserve registry run ownership/ordered minute dispatch. No per-point mutable temperatures, duplicated Fire warmth or independent clocks.
- TH1–TH5 and authored Thermal defaults are design, not tuning authority. QQ-01 budgets and QQ-05 harshness/warm-radius changes remain owner-only; Weather/Shelter implementation is deferred scope.

### Requirements
- Backlog coverage / unblocks (verbatim): All Thermal TRs. Decide polygon/coarse-index lookup, deterministic sampling and same-minute Fire source publication; preserve TH1–TH5.
- Retain published `effective_temp_c(p)`, `components(p)`, air/wind values, `wind_eff(p)`, `is_sheltered(p)`; no direct HUD thermometer or Morale-Thermal link.

## Decision

ThermalField owns the thermal table, minute air/wind inputs and source registries, not source heat/radius design. Compile authored Map zone polygons into a coarse uniform XZ index (proposed10 m cells) covering polygon bounds expanded by the5 m blend. At query, obtain candidates then evaluate exact containment and boundary distances; index cells never quantize felt temperature. Stable zone IDs break exact geometry ties, and Map's zone precedence remains authoritative for discrete terrain surfaces.

Represent the zone transition as a shared5 m linear boundary band: a point2.5 m through the specified forest/open blend gets equal weights. For a two-zone band use weights1−t,t; at multi-zone junctions use nonnegative distance-band weights for every participating zone then normalize once in stable ID order. Validate band endpoints/midpoint, corners and continuity against the GDD before production wiring; do not substitute nearest-zone selection or an inverse-distance curve. Export the same weights for audio beds. No-zone fallback is open snow offset0/exposure0.8; preserve all six zone values including drift0/0.6 and ridge0/1.0. Band geometry at junctions is an explicit authoring/adapter verification item, not a claim that the GDD specifies a unique triangulation.

Sources are copied value records keyed by stable owner/run/source ID: position, heat_c, radius_m, enabled plus revision. Proposed coarse source bins cover the source radius AABB; exact Euclidean distance and strict d<radius decide TH4. Process candidate sources in stable ID order for reproducible float accumulation. Reject nonfinite position/heat/radius, radius≤0 and negative heat with error; an invalid update disables that ID until a valid update so bad source data contributes no heat. heat0 disables but retains the record; relight re-enables; unregister removes. Stale-run/revision commands cannot resurrect removed sources; teardown clears all registrations.

Preserve formulas exactly: TH1 max(t_floor,t_start−t_ramp×(day−1)); TH2 daily mean+t_swing×cos(2π×(hour−(solar_noon+peak_lag))/24)+weather_offset, noon=(sunrise+sunset)/2; TH3 min(chill_cap,k_wind×wind_speed×exposure_eff); TH4 source_heat×(1−(d/radius)²)×reflect strictly inside radius; cap sum at heat_cap30; TH5 air+zone−wind_chill+heat+shelter_bonus. components must agree with that same query's total. Registry/model queries are pure, with no RNG, cache warming side effects or per-point history.

At each Coordinator minute: establish Clock-derived TH1/TH2/weather/wind → Fire samples this minute's wind and burns → Fire publishes every changed heat/radius/enabled record synchronously → seal Thermal source revision → Inventory/Body query that minute's updated view. Fire.warm_radius is exactly its registered radius_m; Morale reads Fire's port, not Thermal. A source extinguished this minute contributes0 to this minute's Body step, never yesterday's heat. Normal real-time action changes publish atomically before subsequent readers/completion checkpoints. Sleep executes every minute, not final-time bulk evaluation; restore owners re-register before the first minute.

Reserve typed Weather/Shelter registration ports without implementing deferred features. Inside multiple shelters take minimum exposure override and maximum bonus, never additive stacking; the responsible shelter's reflection applies to eligible inside/opening sources with stable ties, not multiplying all volumes. Weather owns offsets; absent weather uses wind_base3. Unregistering weather transitions wind to base over10 game minutes. Reject an invalid thermal table (including floor>start, negative swing or chill_cap≤0), log and install whole approved defaults before activation. Future volume/reflection adapters must pass the GDD overlap rules before enabling that scope.

### Architecture Diagram
`Clock + Map polygons → Thermal minute inputs/index`; `Thermal wind → Fire owner → source publication barrier → Thermal query → Inventory/Body`; `Fire warm_radius → Morale`.

### Key Interfaces
- Preserve GDD `effective_temp_c(p) -> float`, `components(p) -> ThermalComponents{air,zone,wind_chill,heat,shelter_bonus}`, `wind_eff(p)`, `is_sheltered(p)` and air_temp_c/wind_speed snapshots.
- Proposed `register_heat_source(source) -> Result`, `update_heat_source(source) -> Result`, `unregister_heat_source(id) -> Result` validate ownership/run/revision; supplied DTO includes all GDD fields. These are application ports, not asserted Godot methods.
- `begin_minute(context)` and `seal_sources(minute_sequence)` are Coordinator-only barriers, not a second public minute_tick subscription; optional `zone_weights(p)` exports detached weights.

### Implementation Guidelines
- Query must be pure and exact after coarse candidate lookup; index membership must never decide final distance/zone weight.
- Body must sample after Fire's same-minute publication; no deferred signal callback or Area3D overlap list may be authoritative.
- Source values must remain Fire-owned, table/registry Thermal-owned. Invalid registration must contribute nothing; no NaN may enter Body integration.

## Alternatives Considered

### Alternative 1: Area3D overlap-derived temperature
- **Description**: Temperature follows enter/exit signals and scene overlap order.
- **Pros**: Easy gizmos and prototype triggers.
- **Cons**: Physics-frame lag, boundary jitter and sleep skips can miss updates.
- **Rejection Reason**: Cannot guarantee deterministic same-minute samples; areas may visualize but never own Thermal truth.

### Alternative 2: Quantized temperature grid or full rescans
- **Description**: Bake cell temperatures, or scan all zones/sources every query.
- **Pros**: Simple implementation or predictable fixed-grid lookup.
- **Cons**: Grid seams/stale source caches, or avoidable scaling cost; interpolation can change TH4.
- **Rejection Reason**: Coarse index plus exact evaluation retains formulas without assuming full scans meet the unmeasured query budget.

## Consequences

### Positive
- Stable pure queries work during skip/catch-up; Core depends only on source data, not Feature concrete types.
- Empty registries/default zones remain useful; shared zone weights prevent audio/thermal seam disagreement.

### Negative
- Boundary-band authoring/geometry and index invalidation require tests; publication ordering is a hard integration contract.
- Future shelter/weather semantics need their own scope/ADRs before implementation.

## Risks
- Inline godot-specialist review: typed data and direct synchronous owner calls fit reference practice and avoid Jolt Area timing; no deprecated API required. Exact geometry adapter signatures and performance remain unverified; 4.7 packed-array in-place mutation needs explicit index/dirty invalidation if used. TD-ADR skipped — Lean mode; author self-review only.
- GDD sync checked Thermal, Map, Fire, Body, Time and Audio (6). No API rename introduced. Thermal cross-reference prose still calls existing Map/Fire/Body documents unwritten; Time over-lists Thermal consumers. Those are documented stale/cosmetic references, not authority to change contracts. Known Time Rule8/QQ-08 pause warning persists; no GDD edit.
- Autonomous calls: Proceed on Thermal scope/TH constraints and Foundation/C1 dependencies; separate design tabs chose polygon+coarse index, stable exact sampling and source DTO/barrier; write ADR only, append registry, continue C4. Budgets/thermal harshness and deferred Weather/Shelter scope are not settled.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [thermal-environment.md](../../design/gdd/thermal-environment.md) | Full provisional TR-thermal-environment-001 … TR-thermal-environment-029; TH1–TH5, every source/zone/default/skip/restore edge, dependency and AC1–17/performance | Pure exact indexed queries, complete published components/ports, preserved formulas and deferred source contracts, same-minute source barrier and full error/default validation. |

## Performance Implications
- **CPU**: GDD≤0.05 ms/effective_temp_c query with8 sources/4 nearby zones; profile index lookup+exact weights/distances, not just arithmetic. Proposed10 m bin size is not measured optimal.
- **Memory**: World registries/indices only; no per-point temperature state or saved Thermal caches.
- **Load Time**: Validate table/build polygon index; restore sources from owners before activation.
- **Network**: None.

## Migration Plan
After acceptance, implement/test pure TH formulas and exact zone adapter, then index and source lifecycle, then Coordinator/Fire publication integration. No runtime/GDD/prototype changes now. Save/Load stays deferred; Thermal state regenerates from owner records. Weather/Shelter ports reserve compatibility, not MVP work.

## Validation Criteria
- AC1–7: day1 13:00 open/no fire−4.2±0.1; no-zone0/0.8; blend midpoint offset0.5/exposure0.6; source25→0→25 retains disabled record; radius0 rejected/logged; identical queries identical; shelter minimum exposure/maximum bonus without stacking.
- AC8–13: TH1 days1/11/31/51/60→−5/−9/−17/−25/−25; TH2 day1 13:00−1.30±0.05,02:30−9,day31 14:30−13; TH3 open2.88/forest1.44/lake3.6/storm cap15; TH4 d0/1.5/2.5/3/4→25/18.75/7.64±0.01/0/0 and three sources cap30; TH5−5.1/+13.7/−16/−23.9 examples; invalid floor−2/start−5 defaults.
- AC14–17:600 distinct minute queries over10-hour sleep including02:30 coldest; Fire registered3 m equals warm_radius3; owner first-afternoon cold feel; night image distinguishes~3 m warm core from6 m light. Visual/feel evidence not collected here.
- Empty source list heat0; missing zone defaults; negative/NaN source and invalid update disable/log without poisoning result; exact radius0 heat; source move updates both bins atomically; unregister/stale revision cannot leave ghost heat. Compare indexed versus brute-force reference across seams/corners/multi-zone junctions and overlapping sources in multiple insertion orders.
- Integration: fire goes Out this minute→same-minute Body heat0, including120-tick catch-up; weather removal10-minute wind recovery; forest wind also changes Fire's wind input; restore registration precedes first tick. Benchmark stated query load on nominated hardware; no measurement is claimed.

## Related
- [Master architecture](architecture.md), C3 and layer map; [ADR-0003](adr-0003-ordered-clock-dispatch-typed-events-and-run-randomness.md); [ADR-0004](adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md).
- QQ-01/05 budgets and survival tuning, deferred scope/cost remain owner-only; `/architecture-decision accept ADR-0006` is separate. Authoring unblocks no story.
