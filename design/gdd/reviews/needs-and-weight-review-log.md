# Review Log — Needs & Weight

## Review — 2026-11-16 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: none (lean)
Blocking items: 0 | Recommended: 3
Summary: All six formulas verified at boundaries; 20 testable ACs; AC17 reproduces Morale F4's own worked example verbatim (H = 52). The `is_asleep` ownership implements the two-channel wake (wake_request OR rate_mode_changed) that Time and Body were designed against — the pivotal contract lands correctly. Three-clock pacing (thirst/energy/weight) honors the brief's beats.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] N4: `e_rest` "resting by a burning fire" lacks a declared input source — name Fire's `is_burning`/`warm_radius` or Interaction's rest-at-fire action as the reporter
- [RECOMMENDED] Core Rules §10 / Interactions: `move_speed_mult` collides with Body Temperature's identically-named output — rename to `needs_move_speed_mult`
- [RECOMMENDED] Registry: append needs-and-weight.md to `game_minute_tick` referenced_by; align `burn_kcal_per_hour` expression's `asleep` with canonical `is_asleep`
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4f1252d3d0658bc27e6c910506fbb88a5ea3325b
Reviewed-Content-Hash: design/registry/entities.yaml 865e2d770a7135273cb0db1b28c59e3edf2d0f3f
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/time-and-day-cycle.md 1532944c4c8849a8c5821554f96eb83245869cac
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/thermal-environment.md e562d08a3055b49147f7716aed69e0363452e11d
Reviewed-Content-Hash: design/gdd/systems-index.md 17b2477a7964f16fa68bf870681b635379b4f36f
Reviewed-Content-Hash: design/game-brief.md 65cbcbc13a4f7a1c2dc2b60b35688cdfb6e7dbba
