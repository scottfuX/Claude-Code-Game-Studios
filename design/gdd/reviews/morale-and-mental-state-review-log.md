# Review Log — Morale & Mental State

Append-only history of /design-review passes on `design/gdd/morale-and-mental-state.md`.
Each entry ends with a `Reviewed-Content-Hash` receipt block: a byte-identical
re-review of the same inputs may reuse the prior verdict.

## Review — 2026-11-16 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean)
Blocking items: 3 | Recommended: 8
Summary: Strong GDD — guarded formulas, hysteresis, event ordering, honest open
questions, registry values all consistent. Three precise spec holes an
implementer would hit: a self-contradicting tap-out offer rule, undefined
streak-reset semantics, and an unowned is_asleep input. All three were resolved
in-session from the document's own edge cases and the systems index
(autonomous mode; see production/session-logs/decision-log.md).
Prior verdict resolved: First review
Findings:
- [BLOCKING] Core Rules §9: "the first nightfall" reads as a once-per-run latch, making the consecutive-Breaking `plea` unreachable; the consecutive-count reset rule was undefined
- [BLOCKING] Formulas F2: `streak` reset semantics undefined — whether a same-`action_type` success (incl. trivial) resets it, cross-type interruption, 2 h window basis
- [BLOCKING] Interactions/Dependencies: `is_asleep` required by F1 `m_time` and §3 sleep multipliers had no providing system
- [RECOMMENDED] Core Rules §5: `comfort` magnitudes scattered across F1/F3 prose; wildlife's G amount unstated
- [RECOMMENDED] Formulas F3: `homesick_milestone` had no named emitter
- [RECOMMENDED] Formulas F1: L effectively monotonic in the MVP — intent unstated
- [RECOMMENDED] States: one-step-per-tick stated only for drops, not recovery
- [RECOMMENDED] Formulas F2: output range ignored the keepsake floor (+2.8 true min)
- [RECOMMENDED] Core Rules §5: "in the order received" contradicted the Edge Cases fixed order
- [RECOMMENDED] Registry: `morale_resolve` variables omitted strain weights
- [RECOMMENDED] Formulas F6: "one more failure from Breaking" held only for a major failure
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md d9aef6caa55e1f5077eadbc7a664b08e919a4380
Reviewed-Content-Hash: design/registry/entities.yaml 714c0a96eb00d34001133ccc2c4072757786f7c2
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/game-concept.md 947bfd5a053eed5c276acf53373853ad5dc5c3ee
Reviewed-Content-Hash: design/gdd/systems-index.md 0e235a4e75c236a5d3606c2c72c27fd25d48b317

## Review — 2026-11-17 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean)
Blocking items: 0 | Recommended: 1
Summary: Re-review. All three prior blockers resolved in the text — §9 now
specifies the consecutive-Breaking count and its reset, F2 defines streak scope
(same action_type, sliding 2 h window, any success resets), and is_asleep is
owned by Needs & Weight, verified. All eight prior recommendeds are addressed.
Every upstream contract verified live: Time publishes sunrise_window and
back-references the dawn-tick milestone; Needs declares is_asleep ownership;
Interaction publishes is_idle and consumes action_duration_mult; Mishaps emits
the exact action_outcome fields and the 0.90 clamp. Registry entries match
(morale_resolve now carries strain_weights). One remaining nit: Dependencies
and Cross-References still label approved upstreams "not yet written —
provisional" and claim Interaction doesn't list Morale (its Rule 9 does).
Prior verdict resolved: Yes
Findings:
- [RECOMMENDED] Dependencies/Cross-References: stale "not yet written — provisional" labels; bidirectional note says Interaction lacks Morale, now false
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/registry/entities.yaml ed8c65618047175905363bd10475fd3e57e38167
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/mishaps-and-failure.md aa38bc94c4768f844c46e7cfeb905818e41b8b72
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4f1252d3d0658bc27e6c910506fbb88a5ea3325b
Reviewed-Content-Hash: design/gdd/time-and-day-cycle.md 1532944c4c8849a8c5821554f96eb83245869cac
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md 009b062413117c5874e212ae8b761cffad6a1d06
Reviewed-Content-Hash: design/gdd/systems-index.md af938e55d6883165c55eaa6f3b9a83d41478cf2e
