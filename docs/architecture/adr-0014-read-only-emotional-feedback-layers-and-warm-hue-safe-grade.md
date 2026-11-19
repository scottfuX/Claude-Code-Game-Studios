# ADR-0014: Read-only emotional feedback layers and warm-hue-safe grade

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/engine-reference/registry audit only; Compositor/visuals/audio not exercised.

## Decision Makers
Scott (owner), Devin (author/inline godot-specialist reviewer); Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
Emotional feedback must communicate survival and mental state without changing gameplay or washing warmth out of the fire. Propose a read-only EmotionPresenter with layered pose/beat arbitration, breakable camera requests, a warm-hue-masked Compositor resource pass and sparse score/mix targets.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Forward+ / Jolt |
| **Domain** | Rendering / Animation / Audio |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH post-cutoff rendering/animation; MEDIUM audio |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/rendering.md`, `modules/animation.md`, `modules/audio.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | Compositor and CompositorEffect are Resources assigned to WorldEnvironment/Camera3D, never scene nodes; 4.6 glow-before-tonemap/AgX changes affect verification |
| **Verification Required** | Exact render callback/buffer/RID lifecycle on pin, shader colour-space/warm mask, FX scaling, pose/mix adapters and actual screenshots/listening |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0005, ADR-0007, ADR-0008, ADR-0011, ADR-0012, ADR-0013 (all Accepted; acceptance required) |
| **Enables** | ADR-0015, ADR-0016 (mix/presentation consumers) |
| **Blocks** | EmotionPresenter/grade implementation; no story files exist |
| **Ordering Note** | Sends abstract mix requests to future Audio adapter without depending on its concrete implementation. No gameplay write-back or new state authority. |

## Context
### Problem Statement
Cold, hunger and despair overlap; one unprioritized animation or global saturation filter would obscure their distinct meanings and physical failure causes.
### Constraints
- Registry: Character owns pose playback, Camera owns tokens, C4 sequences cause-before-result, Morale owns strain/state. Feedback must not write any model.
- Accessibility hooks do not authorize settings UI (QQ-09); music sourcing/spend QQ-03 and emotional tuning QQ-05 remain owner-only. No new emotional controls or score density decision.
### Requirements
- Backlog coverage (verbatim): All Emotional Feedback TRs; posture/beat priorities, cooldowns, Compositor resource pipeline, reduced-effects hooks and sparse score mix
- Preserve EF1–EF6, every state/edge/accessibility port and AC1–16/performance.

## Decision
EmotionPresenter reads complete snapshots/events only. Each unpaused real second choose EF4 Body→Needs→Morale-if-Strained+→steady posture; blend0.8s. Body Critical/crawl and sleep/death remain Character full-body overrides; Body shiver remains additive whenever is_shivering, never inferred from mood. Needs exhausted/tired/hunger precede Morale L/F/G/H/P postures; grief idle requires10real seconds. State improvement posture lifts over≥3s independently of beat cooldown.

EF3 one beat at a time,≤1.2s, same-ID20unpaused-real-second cooldown: death>loss>failure>second_wind>relief>fire_lit>tap_out_offer. Higher interrupts, lower drops (no backlog). Input cancels in the same frame. Unknown beat logs/ignores, stale sequence inert. During active work hold at most one highest eligible overlay tagged to that action's end; replace/drop by priority, discard on cancel/stale token/input, never interrupt effort or mutate action duration. C4's physical cause cue MUST precede frustration beat; outcome receipt alone is not permission to display it before the cause. Sleep suppresses beats, holds grade and fades music to silence.

Maintain owned Camera tokens: ritual_wide for eligible ritual/sunrise, lonely_hold only L-dominant Strained+ idle outdoors, relief_ease on qualifying relief; release promptly when conditions end. Needs sleep/terminal are authoritative state sources: route sleep_wide/end_rise through one shared per-source token adapter, not duplicate requests from both direct source and Feedback. Death stops beats, music silent and snow-white fade8s with Camera end-rise; explicit pause freezes presentation, terminal survival freeze alone does not block this end animation. Reduced camera motion suppresses ritual/lonely/relief only; end shots remain.

Attach an owned `Compositor` Resource containing one `CompositorEffect` to the run's WorldEnvironment or Camera3D (one attachment, never both). Presenter publishes detached double-buffered parameter values; render callback reads the latest complete buffer, never SceneTree/gameplay objects or mutable main-thread records. Allocate/recreate resolution-dependent buffers and free render RIDs on the appropriate rendering adapter lifecycle; exact API/callback stages require a pinned-engine spike. No manual viewport shader chain, no Compositor child node, no global Resource mutation across runs.

EF1 saturation offset=−(0.05×state_index+(Grief and index≥1?0.05:0))×fx_scale, max magnitude0.20. Classify hue in an explicitly tested colour-space conversion; warm band15°–55° must retain saturation/fire/tarp/collar/skin warmth, including boundaries. Grade only cold hue saturation, never apply a whole-screen saturation slider. EF2 edge vignette toward trunk_navy: Body Warm/Chilled/Cold0,Hypothermic0.25,Critical0.5, eased1.5s; mental Breaking never adds vignette. Keep vignette desaturation warm-masked too, cap edge strength and do not hide centre/survivor. Grade blends≥3s; reduced screen effects fx_scale0.5 scales BOTH grade/vignette; posture still carries meaning. End-white is a separate terminal overlay, not a new strain grade. Restore starts weights at targets, no neutral fade-in.

EF5 targets warm/pad/thin: Steady-fire0.6/0/0,Steady-else0.25/0/0,Strained0.15/0.3/0,Fraying0/0.4/0.2,Breaking0/0.3/0.35, ease4s. These are gains when sparse score cues are active, not permission for continuous music; approved cue assets/schedule must leave mostly silence and remain sourcing/tuning obligations. Ritual sets all targets0 and foregrounds crackle, never starts music. EF6 sends additive wind+2dB/state (max+6) and other-ambience duck−6dB only L-dominant Strained+; Audio owns physical base wind and final buses. No gameplay danger stinger, no grade-driven gameplay/RNG, deferred Diary receives localization word pools only.

### Architecture Diagram
`read-only Body/Needs/Morale/Fire + ordered cause events → EmotionPresenter → Character posture/beat requests + Camera tokens + Compositor parameter buffer + Audio mix targets`.
### Key Interfaces
- Preserve posture/beat, `request_framing/release_framing`, `strain_spike`, state/ritual/second-wind/offer consumers; `set_mix(request)` is an abstract Audio port.
- `render_parameters() -> GradeSnapshot`, `set_accessibility(flags)` and `on_cause_presented(sequence)` are proposed value/ack adapters, not asserted native methods. A presentation ack never blocks/commits simulation.
### Implementation Guidelines
- Presenter must remain read-only to gameplay; never mutate source snapshots or award relief itself.
- Compositor/Effect must be Resources; warm hues must retain saturation; beat priority/cooldown/input cancel and cause-first ordering must hold independently of frame rate.

## Alternatives Considered
### Alternative 1: Global saturation and per-event Tweens
- **Pros**: Short effect setup. **Cons**: Desaturates fire, stacks effects/beat spam and allows contradictory layers.
- **Rejection Reason**: Violates warm band and priority/cooldown design.
### Alternative 2: Manual viewport chain or Compositor node
- **Pros**: Familiar legacy tutorials. **Cons**: Wrong resource lifecycle, extra render surfaces and unbounded shared state.
- **Rejection Reason**: Engine reference explicitly specifies Resource pipeline.

## Consequences
### Positive
- Distinct physical/mental signals, accessible reduced effects and no simulation feedback loop.
### Negative
- Warm-hue/colour-space/render-thread correctness and sparse score require visual/listening evidence; typed state alone is insufficient.

## Risks
- Inline godot-specialist review: reference confirms Resource assignment and AnimationMixer.active (not playback_active); exact Compositor callback/buffer/shader APIs remain spike obligations, not invented validated code.4.6 glow/AgX and4.7 unclamped LinearToSRGB need warm-band tests. TD-ADR skipped — Lean mode; no independent/runtime approval.
- GDD sync checked Feedback/Morale/Body/Needs/Character/Camera/Audio/Fire (8): no interface rename; shared sleep/end token adapter prevents double requests; lower beats drop despite bounded action-end deferral. Updated Time Rule8 checked consistent with QQ-08; no GDD edit.
- Autonomous calls: Proceed assumptions/range/dependencies; separate tabs read-only priority layers, warm-masked Resource pass, reduced-effects hooks and abstract sparse mix; ADR-only write, append registry, continue P3. No paid music/settings/tuning choice settled.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [emotional-feedback.md](../../design/gdd/emotional-feedback.md) | Full provisional TR-emotional-feedback-001 … TR-emotional-feedback-027; EF1–EF6/all rules/states/edges/dependencies and AC1–16/performance | Read-only posture/beat hierarchy, cause-first/cooldowns, camera tokens, safe Resource render pipeline, warm colours, accessibility/sparse mix and restore/end handling. |

## Performance Implications
- **CPU/GPU**: GDD logic≤0.05ms/frame; combined grade/vignette pass≤0.5ms/frame on nominated min-spec, unmeasured.
- **Memory**: One effect instance/buffer set per run and one beat candidate; no accumulating Tweens/events.
- **Load Time**: Validate grade tables/beat IDs/shader backend; compilation/resource failure logs and disables cosmetic pass without simulation failure, but release visual acceptance remains unmet.
- **Network**: None.

## Migration Plan
After acceptance test pure EF selectors/gates, then pinned-engine shader/resource spike and cause-first pose/mix scene. Reserve Alpha settings/VS Diary ports without UI/content implementation. No GDD/config/prototype changes now.

## Validation Criteria
- AC1–7:Cold beats Tired/Morale;Warm FrayingL horizon/Steady steady;five failures6s one beat/20s next;loss interrupts failure;move cancels same frame;ritual camera+music0/reduced-motion no camera;sleep no beats/sleep token;death end-rise+silence/white8s.
- AC8–13: Fraying grade−0.10≥3s and mix0/0.4/0.2 at4s;Grief Breaking−0.20/reduced Breaking−0.075/fire unchanged;vignette0.25/0.5/reduced0.25/mental-only0;all music rows4±0.2s;Fraying wind+4/L others−6;wind cause sparks precede frustration beat.
- Empty events/default snapshots neutral;unknown beat/stale event warns/ignores;lower beat dropped;action-end deferred candidate cannot outlive cancelled token;sleep/terminal discards pending beats;duplicate source tokens do not fight;warm hue15/55 boundaries and gradients preserve saturation;resize/render teardown no leaks/races;missing shader safe cosmetic fallback;restore target weights immediate.
- AC14–16 unperformed:≥4/5 state-direction recognition,no-HUD;Breaking night fire warmest/brightest;30min music not constant/beats not repetitive. Benchmark CPU/GPU and test reduced flags/posture-only comprehension; visually/audibly/runtime unverified.

## Related
- [Architecture](architecture.md), P2; [ADR-0005](adr-0005-survivor-locomotion-humanoid-retargeting-and-animation-ik-layers.md), [ADR-0012](adr-0012-morale-event-ordering-strain-integration-and-relief-limits.md), [ADR-0013](adr-0013-camera-framing-arbitration-collision-and-projection-ports.md).
- QQ-01/03/05/09 hardware/music sourcing/tuning/settings scope remain owner-only. `/architecture-decision accept ADR-0014` separate; no story unblocked.
