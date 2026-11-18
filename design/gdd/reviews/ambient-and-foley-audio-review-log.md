# Review Log — Ambient & Foley Audio

## Review — 2026-11-17 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 0 | Recommended: 1
Summary: Sound carries information — snow depth, wind, wood dryness, fire health — which is how this game avoids a HUD. Listener-at-the-survivor (AF5) solves the far-camera problem; "the absence of chatter in Hypothermic — silence is the warning" is the coldest line in the doc. All five formulas verified.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Formulas: AF2's lake example uses the wind-chill value 3.6 as wind_eff; the lake's wind_eff is 3.0 m/s → correct example is −12.0 dB (formula itself is right).
Reviewed-Content-Hash: design/gdd/ambient-and-foley-audio.md 1bd727cfa38a232dad204d894db9bea452ce34c7
Reviewed-Content-Hash: design/registry/entities.yaml ed8c65618047175905363bd10475fd3e57e38167
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/terrain-and-snow-surface.md 180a455f7b9bfec7ff67213c5c2f8b47b71fede3
Reviewed-Content-Hash: design/gdd/character-controller-and-animation.md e1326d9c24a02c4b668f098509ddc02630c9ca1f
Reviewed-Content-Hash: design/gdd/fire.md 6ed677eabe9f2712941f515045dd7380ae5c3051
Reviewed-Content-Hash: design/gdd/thermal-environment.md e562d08a3055b49147f7716aed69e0363452e11d
Reviewed-Content-Hash: design/gdd/emotional-feedback.md e99c300e51a3f325ea52af39ef4b0237bc91296c
Reviewed-Content-Hash: design/gdd/camera.md 91b96489e1303dd346fc100d73b994284dfe7034
Reviewed-Content-Hash: design/gdd/mishaps-and-failure.md aa38bc94c4768f844c46e7cfeb905818e41b8b72
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4f1252d3d0658bc27e6c910506fbb88a5ea3325b
Reviewed-Content-Hash: design/gdd/map-and-resource-distribution.md 5f8ec3d66c697d9292d13be030303d099db91d31
Reviewed-Content-Hash: design/gdd/time-and-day-cycle.md 1532944c4c8849a8c5821554f96eb83245869cac
Reviewed-Content-Hash: design/gdd/gathering.md 99fa5bfcff190822134be1a6c00fa6eeed928af6
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md 009b062413117c5874e212ae8b761cffad6a1d06
