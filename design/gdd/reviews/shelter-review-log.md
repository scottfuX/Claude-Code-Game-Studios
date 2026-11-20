# Review Log — Shelter

## Review — 2026-11-20 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 2 | Recommended: 6
Summary: The work and thermal math fit the existing systems. Fire's new-site validation did not account for the proposed plot reservation, and the GDD needed to acknowledge the ADR gate for the deferred Shelter provider.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Core Rules / Interactions: make the Map-owned exclusion an input to FireController's Chapter 2 new-site validation and link it in both GDDs.
- [BLOCKING] Cross-References: identify the ADR and Control Manifest prerequisites before the Shelter provider can be implemented.
- [RECOMMENDED] Core Rules: define the walkable path measurement from drop to site centre.
- [RECOMMENDED] Core Rules: use the existing kit tarp and clarify no separate paracord charge.
- [RECOMMENDED] Acceptance Criteria: verify ambient exposure is at least the wind override.
- [RECOMMENDED] Interactions: clarify the absence of Shelter Morale events.
- [RECOMMENDED] Acceptance Criteria: verify Exhausted admission and non-retroactive insulation.
- [RECOMMENDED] Player Fantasy / Tuning Knobs: document the player's goal and tuning guardrails.
Reviewed-Content-Hash: design/gdd/shelter.md 9c583e7acf5505651880fc97dc3aa212546219d3
Reviewed-Content-Hash: design/registry/entities.yaml ade93f70815fb50a80dfcbf8dcef366a94d8973c
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/thermal-environment.md 22ffc45412d69d4b2292019fb8cccaaf30f0d6df
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md bbc3763d8e881ffe49f6127b8698a4b30a6e87c0
Reviewed-Content-Hash: design/gdd/item-database-and-inventory.md 54de45360089eb34fb5e1ed7e241f3ea5d1cf060
Reviewed-Content-Hash: design/gdd/gathering.md 83c7fc85a3eafe24bcadf5388f114aa633c943d2
Reviewed-Content-Hash: design/gdd/map-and-resource-distribution.md 11ba10e6d7bf4dd1b8dad40b3da1f831dc306d33
Reviewed-Content-Hash: design/gdd/fire.md 04e339ff5453785ebe02f75d7f7ceb3fe016c41b
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4a9e8ff5c3c3de01f13add708e620e40dc4c871c
Reviewed-Content-Hash: design/gdd/body-temperature.md 89da076cbc1c871c153a61856005427947aac01d
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/game-concept.md 947bfd5a053eed5c276acf53373853ad5dc5c3ee

## Review — 2026-11-20 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 0 | Recommended: 0
Summary: Independent re-review of `66d9dda` confirmed both blockers and all six recommendations were resolved. Approval covers the GDD only; Scott's chapter content decisions and the ADR/Control Manifest gate still apply.
The index stamp includes the approval row and total recorded after re-review; its design and dependency entries are unchanged.
Prior verdict resolved: Yes
Findings:
- [NICE-TO-HAVE] Fire Core Rules: fold the Chapter 2 exclusion into Rule 1 when the ADR lands.
- [NICE-TO-HAVE] Systems index: record approval after the re-review (done).
Reviewed-Content-Hash: design/gdd/shelter.md 12191fef508516f1417baadeeb7f994aa95018d5
Reviewed-Content-Hash: design/registry/entities.yaml ade93f70815fb50a80dfcbf8dcef366a94d8973c
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/thermal-environment.md 22ffc45412d69d4b2292019fb8cccaaf30f0d6df
Reviewed-Content-Hash: design/gdd/interaction-and-timed-actions.md bbc3763d8e881ffe49f6127b8698a4b30a6e87c0
Reviewed-Content-Hash: design/gdd/item-database-and-inventory.md 99bd99f7570a31032f5d598bbb5b0193988b8420
Reviewed-Content-Hash: design/gdd/gathering.md 83c7fc85a3eafe24bcadf5388f114aa633c943d2
Reviewed-Content-Hash: design/gdd/map-and-resource-distribution.md b5f45b6ce95027e8f8a7aeea64c81c255fe05d59
Reviewed-Content-Hash: design/gdd/fire.md 77e48a7543a24127f952326e6c2b558f4246dfca
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4a9e8ff5c3c3de01f13add708e620e40dc4c871c
Reviewed-Content-Hash: design/gdd/body-temperature.md 89da076cbc1c871c153a61856005427947aac01d
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/game-concept.md 947bfd5a053eed5c276acf53373853ad5dc5c3ee
Reviewed-Content-Hash: design/gdd/systems-index.md ccd595758800b9cc91240bcf3715814401180cd9
Reviewed-Content-Hash: production/milestones/three-day-survival.md 6f215bd3cd2338f60ca9e5c416fe825e8798d41d
Reviewed-Content-Hash: docs/architecture/control-manifest.md feb172a4ab81091fb234ef951ef778eedec1d1f9
Reviewed-Content-Hash: docs/architecture/architecture.md a4b7d0baf41a20f360684028d339711a40d51b6f
Reviewed-Content-Hash: docs/architecture/adr-0004-authored-map-jolt-terrain-snow-grid-and-persistent-trail-representation.md f9c39a5bd05b614d68a8c59e24ed4865fef5081a
Reviewed-Content-Hash: docs/architecture/adr-0006-thermal-spatial-queries-and-source-registration.md 72e3d8ceb682ddd6844400d71ab8ee25e4a1a4d6
Reviewed-Content-Hash: docs/architecture/adr-0011-fire-stage-machine-material-consumption-and-heat-light-publication.md c1b2b421b18fe1299bc89d483f7a4d7c0d0532a8
