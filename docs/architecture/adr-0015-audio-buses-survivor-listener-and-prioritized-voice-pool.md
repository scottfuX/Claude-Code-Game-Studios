# ADR-0015: Audio buses, survivor listener and prioritized voice pool

## Status
Proposed

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/registry/engine-reference audit; no playback/listening or profiling.

## Decision Makers
Scott (owner), Devin (author/inline godot-specialist reviewer); no acceptance or independent approval.

## Summary
Lonefire needs readable snow, work and failure causes even with a far camera and a strict voice cap. Propose a survivor-head listener, explicit bus topology and one prioritized pool covering all concurrent audio, with cause-before-result sequencing and real-time cosmetic scheduling independent of survival skips.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | Audio |
| **Layer** | Presentation |
| **Knowledge Risk** | MEDIUM audio; HIGH global engine pin post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/audio.md`, `modules/rendering.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | 4.7 AudioStreamPlayer3D.area_mask defaults0: explicitly set intended masks; no removed AudioEffectSpectrumAnalyzer.tap_back_pos |
| **Verification Required** | AudioListener3D transform/current selection, bus routing/masks, active voice accounting, spatial attenuation and actual cause pre-roll on pin |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0011, ADR-0013, ADR-0014 (all Proposed; acceptance required) |
| **Enables** | ADR-0016 (menu paper/ink and context integration) |
| **Blocks** | SurvivalAudio implementation; no story files exist |
| **Ordering Note** | Audio consumes physical snapshots/ordered cues and Feedback mix; cosmetic randomness never uses F3 gameplay RNG. |

## Context
### Problem Statement
The camera cannot be the listener, cause cues cannot be stolen by ambience, and sleep catch-up must not play hours of one-shots in a burst.
### Constraints
- Registry: pre-stamp footfall sample, C4 cause-first events, Thermal zone weights, Fire source truth, read-only Feedback requests. No audio-driven simulation/wake/danger alert.
- QQ-03 asset sourcing/license/spend, QQ-01 hardware/voice performance and QQ-05 mix tuning remain owner-only; no paid library or final clip approval.
### Requirements
- Backlog coverage (verbatim): All Ambient/Foley TRs; <=24 voices, cause pre-roll, AF1–AF5, explicit area masks
- Preserve all surfaces/beds/cause/work/body/fire rules and AC1–11/performance.

## Decision
SurvivalAudio owns buses/players/scheduling only. Route Ambience/Foley/Music/UI into Master; bus sends point TO Master, despite shorthand tree notation. Use wind and other-ambience sub-buses so Feedback's loneliness−6dB ducks birds/creaks without ducking wind; keep physical base wind, emotional additive emphasis, pause and user volume as separate parameters (never accumulate dB each frame). UI menu paper/ink remains audible when world branches duck−12dB on explicit pause; do not duck Master/UI and then compensate double. Backpack alone is not pause and causes no pause duck.

One AudioListener3D sits at survivor head position with final Camera orientation; disable competing current listeners. Foley gain AF5 depends on Camera effective distance, not listener displacement. Spatial fire players stay at Fire positions. Explicitly set area_mask=0 if no intended area overrides, or the documented audio-area layer mask where used (including layer1 when that is the authored convention); never rely on the changed4.7 default. Audio area effects cannot decide gameplay shelter/thermal state.

Preallocate pooled 2D/3D players and count EVERY simultaneous active playback, including bed crossfades, wind, fire loops, body,3 score layers and menu UI, against≤24. No hidden polyphony on a stream/player bypasses the count. Priority cause>footsteps>work>fire>body>ambience details; score/bed continuous voices reserve within the same ceiling, not an extra pool. On pressure stop/drop lowest-priority non-cause with short cosmetic fade; do not steal a playing cause. Cause requests carry ordered event IDs, admitted before ordinary effects and held for sequenced playback if all playing slots are protected, not silently dropped. Real production throughput bound must be demonstrated from C4's admitted actions/contacts; excess arbitrary all-cause test traffic must retain pending sequence without exceeding active cap, never block simulation. Missing licensed clip logs/silence and fails audible acceptance rather than crash or invent an alert.

One accepted footfall plays exactly one sample using the C1/C2 pre-stamp surface/sink, with fresh/forest/drift/trail/ice/rock variants (3/type, cosmetic ±5% pitch); crawling drag instead. Effort-loop beats trigger work sounds, not success effects. Cause hiss/gust/clatter/exhale/fizzle/miss/ice crack→plunge starts before the corresponding outcome/frustration presentation; send a presentation-only cue-start ack to P2 when needed, never stall gameplay commit. Deduplicate source event IDs, discard stale callbacks on restart.

Preserve AF1 step_base fresh−14/forest−16/drift−12/trail−18/ice−15/rock−13 +6×sink/0.45, clamp≤0dB. AF2 physical wind=clamp(−12+20log10(max(0.3,wind_eff)/3),−36,0)+EF emphasis0…6; lake3→−12, not open2.4→−13.9. Cosmetic gusts±3dB over2–6real seconds use isolated non-authoritative randomness, no gameplay draws. AF3 Fire Out silent/Embers−34/otherwise−30+24s, spatial attenuation on top; wet pops/hiss from w_burn, smother burst separate. AF4 breath12+8×work_level(0/0.5/1)+6 if Tired+, chatter only Chilled/Cold, never Hypothermic/Critical. Hungry growl about once/game hour is still real-time throttled during skips. AF5 clamp(−0.15×(d_eff−22),−3,+3).

Blend zone beds using Thermal's SAME weights and current phase, zone transition5s, phase across Dawn/Dusk; drift uses the authored appropriate snow bed fallback rather than new content approval, scoured strongest wind. Absent VS owl/wildlife stays absent. Sleep: no step/work, slow breathing, ambience/fire continue at real playback rate. Catch-up advances latest world/mix state but never replays a minute per audio detail; coalesce cosmetic environmental updates and schedule details on real time. Explicit pause ducks world−12dB, UI plays; release restores underlying mix targets without drift. Death fades Foley3s, wind alone then with8s end image; active cause/end ordering cannot send owner commands. Teardown stops all players/listener and clears pending cues/pooled callbacks.

### Architecture Diagram
`Character/Terrain contacts + work/cause + Fire/Body/Needs/Thermal snapshots → SurvivalAudio pool/scheduler → Foley/Ambience/Music/UI → Master`; `Camera orientation → survivor-head listener`; `P2 mix targets → independent bus modifiers`.
### Key Interfaces
- Preserve `on_footfall(event,surface)`, `on_cause(event)`, `set_mix(request)` from architecture; typed requests carry run/event sequence and validated asset IDs.
- `request_voice(cue)`, `cause_started(sequence)` and final bus/listener snapshots are application adapters, not asserted Godot methods; no audio result controls gameplay.
### Implementation Guidelines
- All active streams must count toward24; cause must precede outcome and never be silently stolen/dropped. No per-event node creation or gameplay RNG draws.
- Listener must stay at survivor head; wind formula/base versus emotional modifiers must remain separate; explicit area masks and no Hypothermic chatter.

## Alternatives Considered
### Alternative 1: Camera listener and ad-hoc players
- **Pros**: Simple positional wiring. **Cons**: Far camera mutes survivor, pooled cap bypassed and allocations spike.
- **Rejection Reason**: Violates survivor listener and total voice budget.
### Alternative 2: Catch-up replay or danger stingers
- **Pros**: Every minute gets a sound, obvious warnings. **Cons**: Bursts/clutter and explicit alert design change.
- **Rejection Reason**: GDD requires real-time sparse details and no danger alerts.

## Consequences
### Positive
- Physical causes survive mix pressure; spatial sound remains intimate at far framing without affecting simulation.
### Negative
- Voice accounting includes loops/crossfades; sourcing/readability and all-cause backlog bound need real evidence.

## Risks
- Inline godot-specialist review: reference confirms pooled AudioStreamPlayer/3D and AudioServer buses; set area_mask explicitly, avoid removed tap_back_pos. Exact Listener/current/attenuation/pool adapter behavior and audible pre-roll unverified. TD-ADR skipped — Lean mode, author self-review only.
- GDD sync checked Audio/Thermal/Terrain/Character/Fire/Feedback/Mishaps (7): AF2 lake3mps matches−12, no rename. Updated Time Rule8 checked consistent with inherited QQ-08. Source licenses/clip availability and reserve sizes not assumed; no GDD edit.
- Autonomous calls: Proceed assumptions/dependencies/range; separate tabs head listener, bus modifiers, total voice pool and real-time cosmetic scheduler; ADR-only write, registry append, continue P4. QQ-03 procurement not decided.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [ambient-and-foley-audio.md](../../design/gdd/ambient-and-foley-audio.md) | Full provisional TR-ambient-and-foley-audio-001 … TR-ambient-and-foley-audio-024; all rules/AF1–AF5/states/edges/dependencies and AC1–11/performance | Explicit buses/masks/listener, complete cues/surface/body/fire rules, cause priority/pre-roll,24-voice total, real-time skip behavior, mix/pause/end and asset validation. |

## Performance Implications
- **CPU**: GDD audio thread≤1ms/frame with24voices; measure actual mixing/stream formats and main-thread scheduling separately.
- **Memory**: Preloaded approved short cues, streamed beds/score where validated; pool allocations bounded. No unapproved asset tooling or measured-memory claim.
- **Load Time**: Validate buses/clip routing, masks/listener and license manifest before activation; missing cosmetics log/silence, never block survival.
- **Network**: None.

## Migration Plan
After acceptance implement pure AF/pool tests, pin-engine routing/listener/mask scene and cause-pre-roll listening evidence; source clips only after QQ-03 review. No bus config/assets/runtime/GDD edits now.

## Validation Criteria
- AC1–5: fresh sink0.315−9.8±0.2/trail0.13−16.3/drift−6;wind2.4−13.9/1.2−20/zero−32/15→0 plusEF4 additive;F120−9.2±0.1/Embers−34/Outsilence;Tired heavy26breaths/min,noHypothermicchatter;d14/40/56→+1.2/−2.7/−3.
- AC6–9:zone beds5±0.5s;30mixed requests≤24active/no cause drop;damp hiss before outcome;10h sleep no detail burst. Test >24 all-cause synthetic requests sequence pending without active-cap overflow or gameplay blocking; demonstrate bounded legitimate throughput before implementation acceptance.
- Empty/missing cue logs/silence;unknown surface fresh+warn;duplicate/stale contact no extra sound;all crossfades/music/UI count;listener translates with head/orients with Camera at all zooms;mask0 versus explicitarea layer tests;pause world−12/UI audible/backpack unchanged;death Foley3s/wind image fade;teardown no phantom loops;cosmetic pitch/gust RNG leaves gameplay draw count unchanged.
- AC10–11 unperformed listening evidence:≥4/5 eyes-closed lake/forest/open identification;owner snow-depth/walking texture. Profile≤1ms on nominated min-spec and audible pre-roll; visually/audibly/runtime unverified.

## Related
- [Architecture](architecture.md), P3; [ADR-0006](adr-0006-thermal-spatial-queries-and-source-registration.md), [ADR-0013](adr-0013-camera-framing-arbitration-collision-and-projection-ports.md), [ADR-0014](adr-0014-read-only-emotional-feedback-layers-and-warm-hue-safe-grade.md).
- QQ-01/03/05 hardware, legal clip sourcing/spend and mix tuning remain owner-only; `/architecture-decision accept ADR-0015` separate, no story unblocked.
