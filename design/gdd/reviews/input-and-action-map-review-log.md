# Review Log — Input & Action Map

## Review — 2026-11-17 — Verdict: NEEDS REVISION (blocker resolved in-session → In Review)
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean)
Blocking items: 1 | Recommended: 1
Summary: Foundation doc is precise and testable — IN1–IN3 verified at boundaries, real-time-vs-game-time rule correct, prototype's R-key lesson applied. One self-contradiction found: the binding table gave `move` the full D-pad AND `diary_camera` "D-pad down", violating Rule 5's own same-context invariant — would have left the VS diary silently unbound on gamepad. Resolved in-session: `diary_camera` rebound to R3 (right stick click, the only free primary input).
Prior verdict resolved: First review
Findings:
- [BLOCKING] Rule 3: `diary_camera` "D-pad down" conflicts with `move` (D-pad) in the Gameplay context — Rule 5 would reject the diary binding at load. Resolved in-session: rebound to R3.
- [RECOMMENDED] Rule 5: clarify that multi-context actions (`pause_menu`, `radio`) must be conflict-free across every context they are live in, not just within each
Reviewed-Content-Hash: design/gdd/input-and-action-map.md d2410e4ef94ce6e844c89afc21af5e9bdccb53b1
Reviewed-Content-Hash: design/registry/entities.yaml cde837f9aa1ca6b5708dba909d5ca0765e9215b1
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/game-brief.md 65cbcbc13a4f7a1c2dc2b60b35688cdfb6e7dbba
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: prototypes/firebeforedark-concept/README.md 9c81477c2db94f92d7c184a5a87ec1dc45cba407
Reviewed-Content-Hash: design/gdd/systems-index.md 1a2c2e55ff93b72bc70bf789ded5f8d2d4ed8bc6

## Review — 2026-11-17 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: S
Specialists: none (lean)
Blocking items: 0 | Recommended: 2
Summary: Re-review in fresh session. Prior blocker verified resolved: diary_camera on R3 vs move_hurry on L3 vs zoom on the right-stick axis — no same-context conflicts. Cross-doc re-verified against changed registry (own constants stick_deadzone 0.2 / hold_confirm_s 1.5 match; no foreign values restated) and changed systems-index. All four downstream consumers (Character, Interaction, Camera, HUD) read the published action contract by name. Doc-accuracy fixes applied: cross-ref statuses marked approved; three resolved open questions annotated (move_hurry lunge, camera turn/zoom, tap-to-start).
Prior verdict resolved: Yes — NEEDS REVISION of 2026-11-17 resolved
Findings:
- [RECOMMENDED] Rule 5: multi-context actions (pause_menu, radio) should be conflict-free across every context they are live in, not only within each — advisory wording gap
- [RECOMMENDED] Dependencies: systems-index Camera row still omits Input from Depends On (soft-dep gap this doc flagged; index-side fix)
Reviewed-Content-Hash: design/gdd/input-and-action-map.md e08b34d9b8b590d53a593b6cedd7043fb7549e18
Reviewed-Content-Hash: design/registry/entities.yaml ed8c65618047175905363bd10475fd3e57e38167
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/game-brief.md 65cbcbc13a4f7a1c2dc2b60b35688cdfb6e7dbba
Reviewed-Content-Hash: docs/engine-reference/godot/modules/input.md 3406b1b813858898696e510ea0accfcc7df98af8
Reviewed-Content-Hash: prototypes/firebeforedark-concept/README.md 9c81477c2db94f92d7c184a5a87ec1dc45cba407
Reviewed-Content-Hash: design/gdd/systems-index.md af938e55d6883165c55eaa6f3b9a83d41478cf2e
Reviewed-Content-Hash: design/gdd/character-controller-and-animation.md e1326d9c24a02c4b668f098509ddc02630c9ca1f
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md 009b062413117c5874e212ae8b761cffad6a1d06
Reviewed-Content-Hash: design/gdd/camera.md 91b96489e1303dd346fc100d73b994284dfe7034
Reviewed-Content-Hash: design/gdd/hud.md 7bc65755721bac7ea2cebd9d628e3e7bc5c69513
