# Review Log — Camera

## Review — 2026-11-17 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 0 | Recommended: 2
Summary: The show's camera designed like the show — a patient operator on a far hill, ritual pull-backs earned only when the player stops, any input back within a second. All five formulas verified; all three prototype defaults (pitch 50°, dist 22 m, fov 30°) confirmed in main.gd; Input action names and art-bible quotes verbatim. The C8 cos(pitch) flag on Character is correct (1.6× over-estimate).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] CA1: `d_eff` variable range says 13–160 m; CA4 output and math give 11.2–160 m (14 × 0.8) — stale table value
- [RECOMMENDED] Rule 10/CA3: "never smaller than 20 px" conflicts with the doc's own end framings (end_rise ≈10 px, extraction_aerial ≈5 px — intentional dissolve); scope the floor to gameplay framings
Reviewed-Content-Hash: design/gdd/camera.md 91b96489e1303dd346fc100d73b994284dfe7034
Reviewed-Content-Hash: design/registry/entities.yaml 0291ada0f0dc0ea71b93c6a8daf0b961a7b5509b
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/character-controller-and-animation.md e1326d9c24a02c4b668f098509ddc02630c9ca1f
Reviewed-Content-Hash: design/gdd/terrain-and-snow-surface.md 180a455f7b9bfec7ff67213c5c2f8b47b71fede3
Reviewed-Content-Hash: design/gdd/input-and-action-map.md d2410e4ef94ce6e844c89afc21af5e9bdccb53b1
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4f1252d3d0658bc27e6c910506fbb88a5ea3325b
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/art/art-bible.md 0adebfba9d9843c6b3f34624771833e7d4bf7db1
Reviewed-Content-Hash: design/gdd/game-concept.md 947bfd5a053eed5c276acf53373853ad5dc5c3ee
Reviewed-Content-Hash: prototypes/firebeforedark-concept/main.gd e3713aa8898b5ba69df00dc6f4a1db4c4d3f4786
Reviewed-Content-Hash: design/gdd/systems-index.md 614e2c754d1df9a5f2054bdbabe618d9ae5ee60a
